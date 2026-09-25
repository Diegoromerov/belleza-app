#!/usr/bin/env node
/**
 * verifyNoVersionedSecrets.js
 * A360-2026-09-22/C-02 — Falla si hay credenciales reales en archivos TRACKEADOS.
 * WO B-02 — Reglas extendidas para valores literales por defecto en vars sensibles y tokens en URL.
 * ORDEN A-06 — Normalización CRLF/LF, acotamiento de alcance (código ejecutable) y exención de CI efímero.
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
      const cleanLine = linea.replace(/\r$/, '');
      const re = /postgres(?:ql)?:\/\/([^:\s"'`<>]+):([^@\s"'`<>]+)@/g;
      let m;
      while ((m = re.exec(cleanLine)) !== null) {
        const pw = m[2];
        if (pw !== '***' && !ALLOW_MARKERS.test(pw) && !/^(%|REDACTED|\$|\$\{|<|YOUR|TU_|password|pass|changeme|postgres|admin|admin123|root|test|ci_only_password)/i.test(pw)) return true;
      }
      return false;
    },
  },
  {
    nombre: 'clave NVIDIA',
    buscar: 'nvapi-[A-Za-z0-9_-]{10,}',
    validar: (linea) => {
      const cleanLine = linea.replace(/\r$/, '');
      const m = cleanLine.match(/nvapi-[A-Za-z0-9_-]{10,}/);
      return m ? !ALLOW_MARKERS.test(m[0]) : false;
    }
  },
  {
    nombre: 'clave tipo OpenAI',
    buscar: '(^|[^A-Za-z0-9])sk-[A-Za-z0-9_-]{24,}',
    validar: (linea) => {
      const cleanLine = linea.replace(/\r$/, '');
      const m = cleanLine.match(/sk-[A-Za-z0-9_-]{24,}/);
      return m ? !ALLOW_MARKERS.test(m[0]) : false;
    }
  },
  {
    nombre: 'clave tipo Google API',
    buscar: '(^|[^A-Za-z0-9])AIza[A-Za-z0-9_-]{30,}',
    validar: (linea) => {
      const cleanLine = linea.replace(/\r$/, '');
      const m = cleanLine.match(/AIza[A-Za-z0-9_-]{30,}/);
      return m ? !ALLOW_MARKERS.test(m[0]) : false;
    }
  },
  {
    nombre: 'clave privada PEM',
    buscar: '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----',
    validar: (linea) => !ALLOW_MARKERS.test(linea.replace(/\r$/, ''))
  },
  {
    nombre: 'token de Slack/GitHub',
    buscar: '(xox[baprs]-[A-Za-z0-9-]{10,}|gh[pousr]_[A-Za-z0-9]{30,})',
    validar: (linea) => {
      const cleanLine = linea.replace(/\r$/, '');
      const m = cleanLine.match(/(xox[baprs]-[A-Za-z0-9-]{10,}|gh[pousr]_[A-Za-z0-9]{30,})/);
      return m ? !ALLOW_MARKERS.test(m[0]) : false;
    }
  },
  {
    nombre: 'valor por defecto literal para variable sensible',
    buscar: '(PASS|PASSWORD|SECRET|TOKEN|KEY|CLAVE|PWD)[A-Za-z0-9_]*[[:space:]]*(:|=|\\|\\||\\?\\?)[[:space:]]*',
    validar: (linea, archivo) => {
      if (!archivo) return false;
      const cleanLine = linea.replace(/\r$/, '');
      if (/\.(test|spec)\.[jt]sx?$/.test(archivo)) return false;
      if (/scripts\/verify/.test(archivo)) return false;
      if (/^\s*(\/\/|\/\*|\*|#)/.test(cleanLine.trim())) return false;
      if (/^\s*(console\.(log|info|warn|error)|logger\.(log|info|warn|error))\b/.test(cleanLine.trim())) return false;

      const re = /(?:const|let|var|this\.)?\s*([A-Za-z0-9_]*(?:PASS|PASSWORD|SECRET|TOKEN|KEY|CLAVE|PWD)[A-Za-z0-9_]*)\s*(?::|=|\|\||\?\?)\s*(?:['"]([^'"]+)['"]|([^\s#;,]+))/gi;
      let m;
      while ((m = re.exec(cleanLine)) !== null) {
        const val = (m[2] !== undefined ? m[2] : m[3]) || '';
        if (!val || val.length < 4) continue;
        if (val.startsWith('$') || val.startsWith('${') || val.includes('${') || /^process\.env\./i.test(val) || /^env\./i.test(val)) continue;
        // Ignorar invocaciones a métodos / expresiones JS (ej: crypto.createHash, Buffer.from)
        if (val.includes('(') || val.includes(')') || /^crypto\./i.test(val) || /^Buffer\./i.test(val)) continue;
        if (m[2] === undefined && /^[A-Za-z_$][A-Za-z0-9_$]*$/.test(val)) continue;
        if (/^(\*\*\*|REDACTED|TU_|YOUR_|changeme|PLACEHOLDER|xxx|example|admin123|test|ci_|dummy|REPLACE_ME|postgres|root)/i.test(val)) continue;
        if (ALLOW_MARKERS.test(val)) continue;
        return true;
      }
      return false;
    }
  },
  {
    nombre: 'token o JWT en parámetro de URL',
    buscar: '[?&]token=',
    validar: (linea, archivo) => {
      if (!archivo) return false;
      const cleanLine = linea.replace(/\r$/, '');
      if (archivo.endsWith('.md')) return false;
      if (/\.(test|spec)\.[jt]sx?$/.test(archivo)) return false;
      if (/scripts\/verify/.test(archivo)) return false;
      if (/^\s*(\/\/|\/\*|\*|#)/.test(cleanLine.trim())) return false;
      if (ALLOW_MARKERS.test(cleanLine) || /<[^>]+>|\$\{[^}]+\}/.test(cleanLine)) return false;
      return true;
    }
  }
];

// Rutas exentas: archivos de documentación (.md, .env.example, .example) y caché de .hermes/
const EXENTAS = [
  /^\.env\.example$/,
  /\.example$/,
  /\.md$/i,
  /^\.hermes\//
];

// Dependencias y artefactos regenerables: no son código del proyecto.
const VENDOR = [/node_modules\//, /\/gradle\/wrapper\//, /\.min\.js$/, /^backend\/public\//, /\.map$/];

function gitGrep(pattern) {
  try {
    const rawOutput = execFileSync('git', ['grep', '-n', '-E', '-I', '-e', pattern, '--', '.'], {
      cwd: REPO_ROOT,
      encoding: 'utf8',
      maxBuffer: 32 * 1024 * 1024,
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    return rawOutput.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
  } catch (err) {
    if (err.status === 1) return '';
    throw err;
  }
}

function validarLinea(contenido, archivo, reglaNombre, normalize = true) {
  const regla = REGLAS.find(r => r.nombre === reglaNombre);
  if (!regla) return false;

  if (!normalize) {
    const rawLine = contenido; // conserva \r
    if (/^\s*(\/\/|\/\*|\*|#)/.test(rawLine.trim())) return { detected: false };
    const re = /(?:const|let|var|this\.)?\s*([A-Za-z0-9_]*(?:PASS|PASSWORD|SECRET|TOKEN|KEY|CLAVE|PWD)[A-Za-z0-9_]*)\s*(?::|=|\|\||\?\?)\s*(?:['"]([^'"]+)['"]|([^\s#;,]+))/gi;
    let m;
    while ((m = re.exec(rawLine)) !== null) {
      const val = (m[2] !== undefined ? m[2] : m[3]) || '';
      if (!val || val.length < 4) continue;
      if (val.startsWith('$') || val.startsWith('${') || val.includes('${') || /^process\.env\./i.test(val) || /^env\./i.test(val)) continue;
      if (val.includes('(') || val.includes(')') || /^crypto\./i.test(val) || /^Buffer\./i.test(val)) continue;
      if (m[2] === undefined && /^[A-Za-z_$][A-Za-z0-9_$]*$/.test(val)) continue;
      if (/^(\*\*\*|REDACTED|TU_|YOUR_|changeme|PLACEHOLDER|xxx|example|admin123|test|ci_|dummy|REPLACE_ME|postgres|root)/i.test(val)) continue;
      if (ALLOW_MARKERS.test(val)) continue;
      return { detected: true, val };
    }
    return { detected: false };
  }

  const linea = contenido.replace(/\r$/, '');
  return regla.validar(linea, archivo);
}

function runScanner() {
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
}

if (require.main === module) {
  runScanner();
} else {
  module.exports = { REGLAS, EXENTAS, VENDOR, ALLOW_MARKERS, validarLinea, runScanner };
}
