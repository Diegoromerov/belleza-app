/**
 * GATE 4 — Destino de las pantallas inalcanzables.
 *
 * Comprueba los dos criterios literales del plan:
 *   1. Cada ruta declarada en lib/main.dart tiene al menos 1 navegación en lib/
 *      (una ruta que nadie abre es una pantalla inalcanzable).
 *   2. Cada archivo de pantalla/widget tiene al menos 1 referencia externa a su
 *      clase pública (un archivo que nadie menciona es código muerto).
 *
 * main.dart cuenta como referenciador para el criterio 2 (es el router) pero NO
 * para el criterio 1 (una ruta no se "navega a sí misma" por estar declarada).
 *
 * Uso: node scripts/verifyNoDeadRoutes.js
 * Exit 0 = sin rutas huérfanas ni archivos muertos. Exit 1 = hay hallazgos.
 */
const fs = require('fs');
const path = require('path');

const LIB = path.join(__dirname, '..', 'lib');
const MAIN = path.join(LIB, 'main.dart');
const TEST = path.join(__dirname, '..', 'test');

function walk(dir) {
  if (!fs.existsSync(dir)) return [];
  const out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...walk(full));
    else if (entry.name.endsWith('.dart')) out.push(full);
  }
  return out;
}

const todos = walk(LIB);
const contenidos = new Map(todos.map((f) => [f, fs.readFileSync(f, 'utf8')]));
const mainSrc = contenidos.get(MAIN);
const pruebas = walk(TEST);
const contenidoPruebas = new Map(pruebas.map((f) => [f, fs.readFileSync(f, 'utf8')]));

// ── Criterio 1: rutas declaradas sin navegación ──────────────────────────────
const rutas = [...mainSrc.matchAll(/^\s*'(\/[A-Za-z0-9\-/_]*)':/gm)].map((m) => m[1]);
const otros = todos.filter((f) => f !== MAIN);

const sinNavegacion = [];
for (const ruta of rutas) {
  const aguja = `'${ruta}'`;
  // La propia línea de declaración ('/x': (_) => ...) no cuenta como navegación.
  const declaracion = new RegExp(`^\\s*'${ruta}'\\s*:`);
  // main.dart SÍ puede navegar (p. ej. _checkAuthAndNavigate('/chat')).
  const enMain = mainSrc.split(/\r?\n/).some((linea) => linea.includes(aguja) && !declaracion.test(linea));
  const refs = todos.filter((f) => f !== MAIN && contenidos.get(f).includes(aguja));
  if (!enMain && refs.length === 0) sinNavegacion.push(ruta);
}

// ── Criterio 2: archivos de pantalla/widget sin referencia externa ───────────
const candidatos = todos.filter(
  (f) => f.includes(`${path.sep}screens${path.sep}`) || f.includes(`${path.sep}widgets${path.sep}`)
);

// Dos categorías: muerto en lib Y en test (hay que borrarlo) vs usado solo por
// un test (no es código muerto, pero tampoco es alcanzable por el usuario).
const huerfanos = [];
const soloPruebas = [];

for (const archivo of candidatos) {
  const src = contenidos.get(archivo);
  // Identificadores que el archivo ofrece al resto del proyecto: clases, mixins,
  // enums, typedefs, extensiones, funciones de nivel superior (columna 0) y
  // constantes finales. Un widget exportado como FUNCIÓN (p. ej.
  // showWompiCheckoutSheet) no es una clase: mirar solo clases da falsos
  // positivos y borra archivos vivos.
  const nombres = [
    ...src.matchAll(/^\s*(?:abstract\s+|final\s+)?class\s+([A-Za-z_]\w*)/gm),
    ...src.matchAll(/^\s*mixin\s+([A-Za-z_]\w*)/gm),
    ...src.matchAll(/^\s*enum\s+([A-Za-z_]\w*)/gm),
    ...src.matchAll(/^\s*typedef\s+\S+\s+([A-Za-z_]\w*)/gm),
    ...src.matchAll(/^\s*extension\s+([A-Za-z_]\w*)/gm),
    ...src.matchAll(/^(?:[A-Za-z_][\w<>,?. ]*\s+)?([a-z_]\w{3,})\s*\(/gm),
    ...src.matchAll(/^\s*const\s+[\w<>,?. ]+\s+([A-Za-z_]\w{4,})\s*=/gm),
  ]
    .map((m) => m[1])
    .filter((n, i, arr) => n && (n.length >= 5 || /[A-Z]/.test(n)) && arr.indexOf(n) === i);

  if (nombres.length === 0) continue;

  const enLib = todos.some(
    (otro) => otro !== archivo && nombres.some((n) => new RegExp(`\\b${n}\\b`).test(contenidos.get(otro)))
  );
  if (enLib) continue;

  const enTest = pruebas.some((otro) => nombres.some((n) => new RegExp(`\\b${n}\\b`).test(contenidoPruebas.get(otro))));
  if (enTest) soloPruebas.push({ archivo: path.relative(LIB, archivo), clases: nombres });
  else huerfanos.push({ archivo: path.relative(LIB, archivo), clases: nombres });
}

// ── Informe ─────────────────────────────────────────────────────────────────
console.log(`Rutas declaradas en main.dart: ${rutas.length}`);
console.log(`Archivos de pantalla/widget: ${candidatos.length}\n`);

if (sinNavegacion.length) {
  console.log(`❌ RUTAS SIN NINGUNA NAVEGACIÓN (${sinNavegacion.length}):`);
  sinNavegacion.forEach((r) => console.log(`   · ${r}`));
} else {
  console.log('✅ Toda ruta declarada tiene al menos una navegación');
}

console.log();

if (huerfanos.length) {
  console.log(`❌ ARCHIVOS MUERTOS, sin referencia en lib/ NI en test/ (${huerfanos.length}):`);
  huerfanos.forEach((h) => console.log(`   · ${h.archivo}  [${h.clases.join(', ')}]`));
} else {
  console.log('✅ Ningún archivo de pantalla/widget queda muerto');
}

if (soloPruebas.length) {
  console.log(`\n⚠️  USADOS SOLO POR TESTS, no alcanzables desde la UI (${soloPruebas.length}) — no se borran:`);
  soloPruebas.forEach((h) => console.log(`   · ${h.archivo}  [${h.clases.join(', ')}]`));
}

const fallos = sinNavegacion.length + huerfanos.length;
console.log(`\n${fallos === 0 ? '✅ GATE 4 OK' : `❌ GATE 4 RED — ${fallos} hallazgo(s)`}`);
process.exit(fallos === 0 ? 0 : 1);
