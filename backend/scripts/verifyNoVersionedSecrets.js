#!/usr/bin/env node
/**
<<<<<<< HEAD
 * C1 — Guard de secretos versionados.
 *
 * Dos comprobaciones sobre lo que de verdad viaja en el repositorio:
 *   1. Ningún archivo `.env*` está RASTREADO en git, salvo los `.example`.
 *   2. Ningún archivo rastreado de texto lleva un valor de secreto incrustado
 *      (JWT_SECRET, ENCRYPTION_KEY, API keys, contraseñas, tokens largos).
 *
 * Se salta a propósito: `node_modules`, `build`, `.dart_tool` y los `.example`
 * (cuyo contenido son marcadores de posición, no valores reales).
 *
 * Salida: EXIT 1 si encuentra algo. Nunca imprime el valor del secreto, solo
 * el archivo, la línea y el NOMBRE de la variable.
 */
const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const RAIZ = path.join(__dirname, '..', '..');

function archivosRastreados() {
  // maxBuffer explícito: el valor por defecto (1 MB) no alcanza para un
  // repositorio con miles de archivos rastreados y el proceso muere con ENOBUFS.
  const salida = execFileSync('git', ['ls-files'], {
    cwd: RAIZ,
    encoding: 'utf8',
    maxBuffer: 64 * 1024 * 1024,
  });
  return salida.split(/\r?\n/).filter(Boolean);
}

const rastreados = archivosRastreados();

// ── 1. Archivos .env rastreados ─────────────────────────────────────────────
const esEjemplo = (p) => /\.example$/i.test(p);
const envRastreados = rastreados.filter((p) => {
  const base = path.basename(p);
  return /^\.env/i.test(base) && !esEjemplo(base);
});

// ── 2. Valores de secreto incrustados ───────────────────────────────────────
const CLAVES = /(JWT_SECRET|ENCRYPTION_KEY|API_KEY|APIKEY|SECRET_KEY|ACCESS_TOKEN|CLIENT_SECRET|SERVICE_ROLE|PRIVATE_KEY|WEBHOOK_SECRET|DB_PASSWORD|DATABASE_PASSWORD)/i;
const ASIGNACION = new RegExp(
  `(?:${CLAVES.source})\\s*[:=]\\s*[\`'"]([A-Za-z0-9_\\-+/=.]{20,})[\`'"]`
);
const EXCLUIDAS = /^(node_modules|build|\.dart_tool|\.git|dist|coverage)\//;
const TEXTO = /\.(js|ts|jsx|tsx|json|ya?ml|dart|py|sh|sql|env|tf|toml|ini|properties)$/i;

// Los archivos de prueba fijan variables de entorno con valores inventados a
// propósito (JWT_SECRET = 'aaaa…', etc.): eso no es una credencial. Se avisa,
// no se falla. Fallar por un fixture vuelve el guard inútil y enseña a
// ignorarlo.
const ES_PRUEBA = /(^|\/)(tests?|__tests__)\/|\.(test|spec)\.(js|ts|jsx|tsx|dart|py)$/i;
const esValorDeRelleno = (v) =>
  /^(.)\1+$/.test(v) ||                       // un solo carácter repetido
  /^(0123456789abcdef)+$/i.test(v) ||         // secuencia obvia
  /test|fake|dummy|placeholder|example|changeme|sample|mock/i.test(v) ||
  /^(tu|mi|your)[_-]/i.test(v) ||
  /aqui|aquí/i.test(v);

const incrustados = []; // fallos: archivo que no es de prueba, valor que no es relleno
const avisos = [];      // fixtures y valores de relleno

for (const rel of rastreados) {
  if (EXCLUIDAS.test(rel)) continue;
  if (!TEXTO.test(rel) || esEjemplo(rel)) continue;
  let contenido;
  try {
    contenido = fs.readFileSync(path.join(RAIZ, rel), 'utf8');
  } catch {
    continue; // binario o ilegible: no es un sitio donde poner una asignación
  }
  contenido.split(/\r?\n/).forEach((linea, i) => {
    const m = linea.match(ASIGNACION);
    if (!m) return;
    const variable = m[0].split(/[:=]/)[0].trim();
    const entrada = { archivo: rel, linea: i + 1, variable, longitud: m[1].length };
    if (ES_PRUEBA.test(rel) || esValorDeRelleno(m[1])) avisos.push(entrada);
    else incrustados.push(entrada);
  });
}

// ── Informe ─────────────────────────────────────────────────────────────────
console.log(`Archivos rastreados analizados: ${rastreados.length}`);

if (envRastreados.length) {
  console.log(`\n❌ ARCHIVOS .env RASTREADOS (${envRastreados.length}):`);
  envRastreados.forEach((p) => console.log(`   · ${p}`));
} else {
  console.log('✅ Ningún .env real está rastreado (solo los .example)');
}

if (incrustados.length) {
  console.log(`\n❌ VALORES DE SECRETO INCRUSTADOS EN ARCHIVOS QUE NO SON DE PRUEBA (${incrustados.length}):`);
  incrustados.forEach((h) => console.log(`   · ${h.archivo}:${h.linea} → ${h.variable} (longitud ${h.longitud})`));
  console.log('   (el valor no se imprime nunca, solo la ubicación)');
} else {
  console.log('✅ Ningún valor de secreto incrustado fuera de tests');
}

if (avisos.length) {
  console.log(`\n⚠️  Fixtures de prueba o valores de relleno, no son credenciales (${avisos.length}) — no bloquean:`);
  avisos.forEach((h) => console.log(`   · ${h.archivo}:${h.linea} → ${h.variable}`));
}

const fallos = envRastreados.length + incrustados.length;
console.log(`\n${fallos === 0 ? '✅ GUARD C1 OK' : `❌ GUARD C1 RED — ${fallos} hallazgo(s)`}`);
process.exit(fallos === 0 ? 0 : 1);
=======
 * verifyNoVersionedSecrets.js
 * A360-2026-09-22/C-02 — Falla si hay credenciales reales en archivos TRACKEADOS.
 *
 * Sin dependencias externas: usa `git grep` sobre el índice/árbol de trabajo.
 * Nunca imprime el valor del secreto, solo archivo:línea y el tipo de patrón.
 *
 * Uso:  node backend/scripts/verifyNoVersionedSecrets.js
 * CI:   agregado como paso bloqueante en .github/workflows/ci.yml
 */
const { execFileSync } = require('child_process');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '../..');

// Buscadores gruesos (git grep -E) + validador fino en JS.
const REGLAS = [
  {
    nombre: 'cadena de conexión con contraseña',
    buscar: 'postgres(ql)?://[^:"\'[:space:]]+:[^@"\'[:space:]]+@',
    validar: (linea) => {
      const re = /postgres(?:ql)?:\/\/([^:\s"'`<>]+):([^@\s"'`<>]+)@/g;
      let m;
      while ((m = re.exec(linea)) !== null) {
        const pw = m[2];
        if (pw !== '***' && !/^(%|REDACTED|\$|\$\{|<|YOUR|TU_|password|pass|changeme)/i.test(pw)) return true;
      }
      return false;
    },
  },
  { nombre: 'clave NVIDIA', buscar: 'nvapi-[A-Za-z0-9_-]{10,}', validar: () => true },
  { nombre: 'clave tipo OpenAI', buscar: '(^|[^A-Za-z0-9])sk-[A-Za-z0-9_-]{24,}', validar: () => true },
  { nombre: 'clave tipo Google API', buscar: '(^|[^A-Za-z0-9])AIza[A-Za-z0-9_-]{30,}', validar: () => true },
  { nombre: 'clave privada PEM', buscar: '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----', validar: () => true },
  { nombre: 'token de Slack/GitHub', buscar: '(xox[baprs]-[A-Za-z0-9-]{10,}|gh[pousr]_[A-Za-z0-9]{30,})', validar: () => true },
];

// Rutas exentas (plantillas con placeholders, no credenciales).
const EXENTAS = [/^\.env\.example$/, /\.example$/, /^docs\/governance\//];
// Dependencias y artefactos regenerables: no son código del proyecto.
const VENDOR = [/node_modules\//, /\/gradle\/wrapper\//, /\.min\.js$/, /^backend\/public\//, /\.map$/];

const ALLOW_MARKERS = /(PLACEHOLDER|REPLACE_ME|YOUR_|TU_|REDACTED|\*\*\*|xxxx|XXXX|dummy|example\.com|localhost|127\.0\.0\.1|<[^>]+>)/;

function gitGrep(pattern) {
  try {
    // `-e <patrón>`: sin esto, un patrón que empieza con `-` (la cabecera PEM)
    // se interpreta como una opción y git grep aborta.
    return execFileSync('git', ['grep', '-n', '-E', '-I', '-e', pattern, '--', '.'], {
      cwd: REPO_ROOT,
      encoding: 'utf8',
      maxBuffer: 32 * 1024 * 1024,
      stdio: ['ignore', 'pipe', 'pipe'],
    });
  } catch (err) {
    // git grep devuelve exit 1 cuando no hay coincidencias
    if (err.status === 1) return '';
    throw err;
  }
}

const hallazgos = [];

for (const regla of REGLAS) {
  const salida = gitGrep(regla.buscar);
  for (const linea of salida.split('\n')) {
    if (!linea.trim()) continue;
    const m = linea.match(/^([^:]+):(\d+):(.*)$/);
    if (!m) continue;
    const [, archivo, numLinea, contenido] = m;
    if (EXENTAS.some((re) => re.test(archivo))) continue;
    if (VENDOR.some((re) => re.test(archivo))) continue;
    if (ALLOW_MARKERS.test(contenido)) continue;
    if (!regla.validar(contenido)) continue;
    hallazgos.push({ archivo, numLinea, nombre: regla.nombre });
  }
}

if (hallazgos.length === 0) {
  console.log('✅ Sin credenciales versionadas en archivos trackeados.');
  process.exit(0);
}

console.error(`❌ ${hallazgos.length} credencial(es) en archivos TRACKEADOS (no se imprime ningún valor):`);
for (const h of hallazgos) {
  console.error(`   ${h.archivo}:${h.numLinea} — ${h.nombre}`);
}
console.error('\nAcción: mover el valor a una variable de entorno, rotarlo y purgar del historial (A360-2026-09-22/C-02).');
process.exit(1);
>>>>>>> origin/main
