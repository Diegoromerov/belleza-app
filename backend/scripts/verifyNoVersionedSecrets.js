#!/usr/bin/env node
/**
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
