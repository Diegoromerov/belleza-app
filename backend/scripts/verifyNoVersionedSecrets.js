#!/usr/bin/env node
/**
 * verifyNoVersionedSecrets.js
 * A360-2026-09-22/C-02 — Falla si hay credenciales reales en archivos TRACKEADOS.
 * WO B-02 — Reglas extendidas para valores literales por defecto en vars sensibles y tokens en URL.
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

const ALLOW_MARKERS = /(PLACEHOLDER|REPLACE_ME|YOUR_|TU_|REDACTED|\*\*\*|\.\.\.|xxxx|XXXX|dummy|example\.com|<[^>]+>)/;

const REGLAS = [
  {
    nombre: 'cadena de conexión con contraseña',
    buscar: 'postgres(ql)?://[^:"\'[:space:]]+:[^@"\'[:space:]]+@',
    validar: (linea) => {
      const re = /postgres(?:ql)?:\/\/([^:\s"'`<>]+):([^@\s"'`<>]+)@/g;
      let m;
      while ((m = re.exec(linea)) !== null) {
        const pw = m[2];
        if (pw !== '***' && !ALLOW_MARKERS.test(pw) && !/^(%|REDACTED|\$|\$\{|<|YOUR|TU_|password|pass|changeme|postgres|admin|admin123|root|test)/i.test(pw)) return true;
      }
      return false;
    },
  },
  {
    nombre: 'clave NVIDIA',
    buscar: 'nvapi-[A-Za-z0-9_-]{10,}',
    validar: (linea) => {
      const m = linea.match(/nvapi-[A-Za-z0-9_-]{10,}/);
      return m ? !ALLOW_MARKERS.test(m[0]) : false;
    }
  },
  {
    nombre: 'clave tipo OpenAI',
    buscar: '(^|[^A-Za-z0-9])sk-[A-Za-z0-9_-]{24,}',
    validar: (linea) => {
      const m = linea.match(/sk-[A-Za-z0-9_-]{24,}/);
      return m ? !ALLOW_MARKERS.test(m[0]) : false;
    }
  },
  {
    nombre: 'clave tipo Google API',
    buscar: '(^|[^A-Za-z0-9])AIza[A-Za-z0-9_-]{30,}',
    validar: (linea) => {
      const m = linea.match(/AIza[A-Za-z0-9_-]{30,}/);
      return m ? !ALLOW_MARKERS.test(m[0]) : false;
    }
  },
  {
    nombre: 'clave privada PEM',
    buscar: '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----',
    validar: (linea) => !ALLOW_MARKERS.test(linea)
  },
  {
    nombre: 'token de Slack/GitHub',
    buscar: '(xox[baprs]-[A-Za-z0-9-]{10,}|gh[pousr]_[A-Za-z0-9]{30,})',
    validar: (linea) => {
      const m = linea.match(/(xox[baprs]-[A-Za-z0-9-]{10,}|gh[pousr]_[A-Za-z0-9]{30,})/);
      return m ? !ALLOW_MARKERS.test(m[0]) : false;
    }
  },
  {
    nombre: 'valor por defecto literal para variable sensible',
    buscar: '(PASS|PASSWORD|SECRET|TOKEN|KEY|CLAVE|PWD)[A-Za-z0-9_]*[[:space:]]*(:|=|\\|\\||\\?\\?)[[:space:]]*',
    validar: (linea, archivo) => {
      if (!archivo) return false;
      if (/\.(test|spec)\.[jt]sx?$/.test(archivo)) return false;
      if (/scripts\/verify/.test(archivo)) return false;
      if (/^\s*(\/\/|\/\*|\*|#)/.test(linea.trim())) return false;

      const re = /(PASS|PASSWORD|SECRET|TOKEN|KEY|CLAVE|PWD)[A-Za-z0-9_]*\s*(?::|=|\|\||\?\?)\s*(?:['"]([^'"]+)['"]|([^\s#;,]+))/i;
      const m = re.exec(linea);
      if (!m) return false;
      const val = (m[2] !== undefined ? m[2] : m[3]) || '';
      if (!val) return false;
      if (val.length < 4) return false;
      if (val.startsWith('$') || val.startsWith('${') || val.includes('${') || /^process\.env\./i.test(val) || /^env\./i.test(val)) return false;
      if (/^(\*\*\*|REDACTED|TU_|YOUR_|changeme|PLACEHOLDER|xxx|example|admin123|test|ci_|dummy|REPLACE_ME)/i.test(val)) return false;
      if (ALLOW_MARKERS.test(val)) return false;
      return true;
    }
  },
  {
    nombre: 'token o JWT en parámetro de URL',
    buscar: '[?&]token=',
    validar: (linea, archivo) => {
      if (!archivo) return false;
      if (archivo.endsWith('.md')) return false;
      if (/\.(test|spec)\.[jt]sx?$/.test(archivo)) return false;
      if (/scripts\/verify/.test(archivo)) return false;
      if (/^\s*(\/\/|\/\*|\*|#)/.test(linea.trim())) return false;
      if (ALLOW_MARKERS.test(linea) || /<[^>]+>|\$\{[^}]+\}/.test(linea)) return false;
      return true;
    }
  }
];

// Rutas exentas (plantillas con placeholders, no credenciales).
const EXENTAS = [/^\.env\.example$/, /\.example$/, /^docs\/governance\//];
// Dependencias y artefactos regenerables: no son código del proyecto.
const VENDOR = [/node_modules\//, /\/gradle\/wrapper\//, /\.min\.js$/, /^backend\/public\//, /\.map$/];

function gitGrep(pattern) {
  try {
    return execFileSync('git', ['grep', '-n', '-E', '-I', '-e', pattern, '--', '.'], {
      cwd: REPO_ROOT,
      encoding: 'utf8',
      maxBuffer: 32 * 1024 * 1024,
      stdio: ['ignore', 'pipe', 'pipe'],
    });
  } catch (err) {
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
    if (!regla.validar(contenido, archivo)) continue;
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
