// frontend/scripts/generateGoldenHashes.js
//
// 📌 GENERADOR Y VERIFICADOR DE HASHES DE GOLDENS — GLOWAPP
//
// Genera la tabla ANTES vs DESPUÉS leyéndola de los archivos reales (nada de transcribir
// a mano, que es lo que desfasó el walkthrough tres rondas seguidas) y a la vez VERIFICA
// que la evidencia de los goldens sea coherente.
//
// Uso:
//   node scripts/generateGoldenHashes.js
//   node scripts/generateGoldenHashes.js --root=test/golden   (otra raíz, útil para probar)
//   node scripts/generateGoldenHashes.js --json
//   node scripts/generateGoldenHashes.js --no-fail            (no falla por evidencia
//                                                              inconsistente; los errores de uso
//                                                              —carpeta inexistente o vacía—
//                                                              siguen saliendo con código 1)
//
// Sale con código 1 si la evidencia NO es coherente:
//   - 'before' o 'after' no existe, o está vacía
//   - un estado está en una carpeta y no en la otra
//   - algún par ANTES == DESPUÉS (no hay cambio que demostrar)
//   - hay hashes repetidos entre estados distintos (N estados exigen N hashes)
//
// Regla: si la herramienta no puede ejecutarse o no encuentra qué comparar, DEBE fallar
// explícitamente. Nunca imprimir una tabla parcial y salir con éxito.

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const args = process.argv.slice(2);
const jsonMode = args.includes('--json');
const noFail = args.includes('--no-fail');
const rootArg = args.find((a) => a.startsWith('--root='));
const goldenBaseDir = path.resolve(
  __dirname,
  '..',
  rootArg ? rootArg.split('=')[1] : path.join('test', 'golden')
);

const DIR_BEFORE = 'before';
const DIR_AFTER = 'after';

function getHash(filePath) {
  const fileBuffer = fs.readFileSync(filePath);
  return crypto.createHash('sha256').update(fileBuffer).digest('hex').toUpperCase();
}

function listPngs(dirPath) {
  if (!fs.existsSync(dirPath) || !fs.statSync(dirPath).isDirectory()) return null;
  return fs
    .readdirSync(dirPath)
    .filter((f) => f.toLowerCase().endsWith('.png'))
    .sort();
}

function abort(mensaje) {
  console.error(`❌ ${mensaje}`);
  process.exit(1);
}

// ------------------------------------------------------------- 1) recolección

const dirBefore = path.join(goldenBaseDir, DIR_BEFORE);
const dirAfter = path.join(goldenBaseDir, DIR_AFTER);

const archivosAntes = listPngs(dirBefore);
const archivosDespues = listPngs(dirAfter);

if (archivosAntes === null) {
  abort(`No existe la carpeta "${dirBefore}". Genera los goldens "antes" antes de correr esto.`);
}
if (archivosDespues === null) {
  abort(`No existe la carpeta "${dirAfter}". Genera los goldens "después" antes de correr esto.`);
}
if (archivosAntes.length === 0 || archivosDespues.length === 0) {
  abort(
    `Carpeta vacía: ${DIR_BEFORE}=${archivosAntes.length} archivo(s), ` +
      `${DIR_AFTER}=${archivosDespues.length} archivo(s). No hay nada que comparar.`
  );
}

// ------------------------------------------------------------- 2) comparación

const estados = Array.from(new Set([...archivosAntes, ...archivosDespues])).sort();
const filas = [];
const problemas = [];

for (const estado of estados) {
  const pAntes = path.join(dirBefore, estado);
  const pDespues = path.join(dirAfter, estado);

  const estaAntes = archivosAntes.includes(estado);
  const estaDespues = archivosDespues.includes(estado);

  if (!estaAntes) problemas.push(`FALTA en ${DIR_BEFORE}/: ${estado}`);
  if (!estaDespues) problemas.push(`FALTA en ${DIR_AFTER}/: ${estado}`);

  const hashAntes = estaAntes ? getHash(pAntes) : null;
  const hashDespues = estaDespues ? getHash(pDespues) : null;

  let veredicto;
  if (!hashAntes || !hashDespues) veredicto = '❌ incompleto';
  else if (hashAntes === hashDespues) veredicto = '❌ idénticos: no hay cambio';
  else veredicto = '✅ distintos';

  filas.push({
    estado,
    hashAntes,
    hashDespues,
    veredicto,
    bytesAntes: estaAntes ? fs.statSync(pAntes).size : null,
    bytesDespues: estaDespues ? fs.statSync(pDespues).size : null,
  });
}

// ------------------------------------------------------------- 3) duplicados

const porHash = new Map();
for (const f of filas) {
  for (const h of [f.hashAntes, f.hashDespues]) {
    if (!h) continue;
    if (!porHash.has(h)) porHash.set(h, []);
    porHash.get(h).push(f.estado);
  }
}

for (const [hash, nombres] of porHash.entries()) {
  if (nombres.length > 1) {
    problemas.push(
      `hash repetido en ${nombres.length} estados (${nombres.join(', ')}): ${hash.slice(0, 16)}…`
    );
  }
}

const totalHashes = filas.reduce((n, f) => n + (f.hashAntes ? 1 : 0) + (f.hashDespues ? 1 : 0), 0);
const unicos = porHash.size;

// ------------------------------------------------------------------ 4) salida

if (jsonMode) {
  console.log(
    JSON.stringify({ goldenBaseDir, estados: filas, problemas, totalHashes, unicos }, null, 2)
  );
} else {
  console.log('📌 GENERADOR Y VERIFICADOR DE HASHES DE GOLDENS — GLOWAPP');
  console.log(`📁 ${goldenBaseDir}\n`);

  console.log('| Estado | Hash ANTES | Hash DESPUÉS | Resultado |');
  console.log('|---|---|---|---|');
  for (const f of filas) {
    console.log(
      `| \`${f.estado}\` | \`${f.hashAntes || '—'}\` | \`${f.hashDespues || '—'}\` | ${f.veredicto} |`
    );
  }

  console.log(`\n📊 Estados: ${filas.length}`);
  console.log(`📊 Hashes: ${totalHashes} calculados, ${unicos} únicos`);
  for (const f of filas) {
    console.log(
      `   ${f.estado.padEnd(34)} antes ${String(f.bytesAntes ?? '—').padStart(7)} B` +
        `   después ${String(f.bytesDespues ?? '—').padStart(7)} B`
    );
  }
  console.log('\nHashes en mayúsculas para coincidir con Get-FileHash; la comparación es insensible a mayúsculas.');

  console.log('');
  if (problemas.length > 0) {
    for (const p of problemas) console.log(`❌ ${p}`);
    console.log(`\n❌ EVIDENCIA INCONSISTENTE (${problemas.length} problema(s)).`);
  } else {
    console.log(
      `✅ EVIDENCIA CONSISTENTE: ${filas.length} estados, ${unicos} hashes únicos, ningún par idéntico.`
    );
  }
}

process.exit(problemas.length > 0 && !noFail ? 1 : 0);
