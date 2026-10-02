/**
 * tests/authOnboardingRoleEnum.test.js
 * ---------------------------------------------------------------------------
 * P0 t_fix_backend_05 — "onboarding rol sin enum estricto"
 * Archivo señalado por el hallazgo: backend/src/controllers/authController.js:306
 *
 * Guarda de regresión ESTÁTICA (solo `fs`/`path`/`assert`; NO requiere
 * `node_modules` ni base de datos): lee el código fuente y verifica que el rol
 * del onboarding se valide contra un ENUM ESTRICTO de Zod antes de usarse.
 *
 * Reproduce el defecto original: el guard era
 *   `['CLIENTE','PRESTADOR','SALON'].includes(rol.toUpperCase())`
 * Es decir, una coerción de método sobre entrada SIN validar:
 *   - un `rol` no-string (número/objeto/array) hacía estallar `.toUpperCase()`
 *     → TypeError → 500 en vez de un 400 controlado;
 *   - no existía un tipo enumerado que restringiera el valor canónico.
 *
 * Es dual: corre bajo Jest (`describe`/`it`) y también directo con
 * `node tests/authOnboardingRoleEnum.test.js`.
 */

const fs = require('fs');
const path = require('path');
const assert = require('assert');

const BACKEND = path.resolve(__dirname, '..');
const leer = (rel) => fs.readFileSync(path.join(BACKEND, rel), 'utf8');
const leerSiExiste = (rel) => {
  const p = path.join(BACKEND, rel);
  return fs.existsSync(p) ? fs.readFileSync(p, 'utf8') : null;
};
// Al buscar fabricaciones/ausencias hay que mirar el CÓDIGO, no los comentarios.
const soloCodigo = (src) => (src || '')
  .split('\n')
  .filter((l) => !/^\s*(\/\/|\*|\/\*)/.test(l))
  .join('\n');

// Aísla el cuerpo de `exports.<nombre> = ...` hasta el siguiente `exports.`.
const bloqueFuncion = (src, nombre) => {
  const i = src.indexOf(`exports.${nombre} = `);
  if (i === -1) return '';
  const j = src.indexOf('\nexports.', i + 1);
  return j === -1 ? src.slice(i) : src.slice(i, j);
};

const SCHEMA_REL = 'src/schemas/role.schema.js';
const CONTROLLER_REL = 'src/controllers/authController.js';
// Los tres roles canónicos del dominio.
const ROLES_CANONICOS = ['CLIENTE', 'PRESTADOR', 'SALON'];
// Guard ad-hoc del defecto: coerción sobre entrada sin validar.
const GUARD_AD_HOC = "['CLIENTE', 'PRESTADOR', 'SALON'].includes(rol.toUpperCase())";

const casos = [];
const caso = (name, fn) => casos.push({ name, fn });

// ---------------------------------------------------------------------------
// 1. Existe un enum Zod estricto para el rol
// ---------------------------------------------------------------------------

caso('existe backend/src/schemas/role.schema.js con el enum Zod de roles', () => {
  assert.ok(
    leerSiExiste(SCHEMA_REL),
    `No existe ${SCHEMA_REL}: el rol del onboarding (authController.js:306) sigue sin enum Zod.`
  );
});

caso('el esquema de rol declara zod y construye un tipo enumerado', () => {
  const src = leerSiExiste(SCHEMA_REL);
  assert.ok(src, `Falta ${SCHEMA_REL}`);
  const codigo = soloCodigo(src);
  assert.match(codigo, /require\(['"]zod['"]\)/, 'role.schema.js debe requerir el paquete zod');
  assert.match(codigo, /\bz\s*\.\s*enum\s*\(/, 'role.schema.js debe declarar un z.enum(...)');
});

caso('el enum restringe EXACTAMENTE a CLIENTE, PRESTADOR y SALON', () => {
  const src = leerSiExiste(SCHEMA_REL);
  assert.ok(src, `Falta ${SCHEMA_REL}`);
  const m = soloCodigo(src).match(/const\s+ROLES_USUARIO\s*=\s*\[([^\]]*)\]/);
  assert.ok(m, 'Role.schema.js debe exponer ROLES_USUARIO = [ ... ] como fuente canónica del enum');
  const valores = m[1]
    .split(',')
    .map((s) => s.trim().replace(/^['"]|['"]$/g, ''))
    .filter(Boolean);
  assert.deepStrictEqual(
    [...valores].sort(),
    [...ROLES_CANONICOS].sort(),
    `ROLES_USUARIO debe ser exactamente ${ROLES_CANONICOS.join('/')}, pero es [${valores.join(', ')}]`
  );
});

caso('el esquema del rol normaliza el caso ANTES de exigir pertenencia al enum (sin romper al cliente)', () => {
  const src = leerSiExiste(SCHEMA_REL);
  assert.ok(src, `Falta ${SCHEMA_REL}`);
  const codigo = soloCodigo(src);
  assert.match(codigo, /\.string\s*\(/, 'el rol debe validarse como string (rechaza número/objeto/array)');
  assert.match(codigo, /\.toUpperCase\s*\(/, 'el esquema debe normalizar el caso con .toUpperCase()');
  assert.match(codigo, /\.pipe\s*\(\s*ROL_USUARIO\s*\)/, 'el esquema debe encadenar .pipe(ROL_USUARIO) para aplicar el enum estricto');
});

// ---------------------------------------------------------------------------
// 2. El controlador usa el enum Zod en el onboarding
// ---------------------------------------------------------------------------

caso('authController importa el esquema de rol (enum Zod)', () => {
  const src = leer(CONTROLLER_REL);
  assert.match(
    soloCodigo(src),
    /require\(['"]\.\.\/schemas\/role\.schema['"]\)/,
    'authController debe requerir ../schemas/role.schema'
  );
});

caso('onboarding valida `rol` con el enum Zod (safeParse) antes de usarlo', () => {
  const bloque = soloCodigo(bloqueFuncion(leer(CONTROLLER_REL), 'onboarding'));
  assert.ok(bloque, 'No se pudo aislar exports.onboarding');
  assert.match(bloque, /\.safeParse\s*\(\s*rol\s*\)/, 'onboarding debe validar el rol con <schema>.safeParse(rol)');
});

caso('onboarding dejó atrás el guard ad-hoc que no era un enum estricto', () => {
  const bloque = soloCodigo(bloqueFuncion(leer(CONTROLLER_REL), 'onboarding'));
  assert.ok(
    !bloque.includes(GUARD_AD_HOC),
    "onboarding no debe usar el guard ad-hoc `['CLIENTE', 'PRESTADOR', 'SALON'].includes(rol.toUpperCase())`"
  );
  assert.ok(
    !/rol\s*\.\s*toUpperCase\s*\(/.test(bloque),
    'onboarding no debe invocar `rol.toUpperCase()` sobre la entrada sin validar (un no-string lanza TypeError → 500)'
  );
});

caso('onboarding rechaza un rol inválido con 400 controlado (no 500)', () => {
  const bloque = soloCodigo(bloqueFuncion(leer(CONTROLLER_REL), 'onboarding'));
  assert.ok(bloque, 'No se pudo aislar exports.onboarding');
  // El rechazo debe colgar del resultado de la validación con enum y devolver 400.
  assert.ok(
    /safeParse\s*\(\s*rol\s*\)[\s\S]*?status\s*\(\s*400\s*\)/.test(bloque),
    'el rechazo del rol debe devolver 400 tras la validación con enum'
  );
  assert.ok(/ROL_USUARIO|ROLES_USUARIO/.test(bloque), 'el mensaje/uso del rechazo debe derivar del enum de roles');
});

// ---------------------------------------------------------------------------
// 3. Regresiones del onboarding (no romper lo que ya funcionaba)
// ---------------------------------------------------------------------------

caso('onboarding sigue exigiendo Habeas Data y Términos', () => {
  const bloque = soloCodigo(bloqueFuncion(leer(CONTROLLER_REL), 'onboarding'));
  assert.match(bloque, /aceptar_habeas_data\s*!==\s*true/, 'debe seguir validando aceptar_habeas_data');
  assert.match(bloque, /aceptar_terminos\s*!==\s*true/, 'debe seguir validando aceptar_terminos');
});

caso('A360 C-06 (regresión): authController sigue sin imprimir la contraseña', () => {
  const src = leer(CONTROLLER_REL);
  assert.doesNotMatch(src, /"Password:",\s*password/, 'no debe registrarse el valor de la contraseña en logs');
});

// ---------------------------------------------------------------------------
// Runner dual
// ---------------------------------------------------------------------------

const bajoJest = typeof describe === 'function' && typeof it === 'function';
if (bajoJest) {
  describe('P0 t_fix_backend_05 — enum estricto del rol en onboarding (estático)', () => {
    casos.forEach(({ name, fn }) => it(name, fn));
  });
} else {
  let fallos = 0;
  for (const { name, fn } of casos) {
    try {
      fn();
      console.log(`PASS  ${name}`);
    } catch (e) {
      fallos += 1;
      console.log(`FAIL  ${name}`);
      console.log(`      ${e.message}`);
    }
  }
  console.log(`\n${casos.length - fallos}/${casos.length} pruebas estáticas OK`);
  process.exitCode = fallos ? 1 : 0;
}
