#!/usr/bin/env node
/**
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
