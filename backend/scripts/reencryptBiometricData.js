#!/usr/bin/env node
/**
 * reencryptBiometricData.js — Re-cifra los datos biométricos que quedaron cifrados con
 * la clave LEGADA (derivada de JWT_SECRET) para que sigan siendo legibles después de
 * provisionar BIOMETRIC_ENCRYPTION_KEY (A360-2026-09-22/C-11).
 *
 * Por defecto corre en modo DRY-RUN: no escribe nada, solo mide.
 *
 *   node backend/scripts/reencryptBiometricData.js            # dry-run (seguro)
 *   node backend/scripts/reencryptBiometricData.js --apply    # escribe los cambios
 *
 * ORDEN CORRECTO DE DESPLIEGUE (importante):
 *   1) provisionar BIOMETRIC_ENCRYPTION_KEY en el entorno
 *   2) desplegar el código (fail-closed)
 *   3) ejecutar este script con --apply
 * Al revés, el arranque falla; y si se ejecuta el paso 3 antes que el 1, se re-cifra
 * con la misma clave legada y no sirve de nada.
 *
 * NO ejecutar contra producción sin copia de seguridad previa.
 */
const path = require('path');
const { pool, testConnection } = require(path.join(__dirname, '../src/config/db'));
const crypto = require('../src/services/biometricCryptoService');

const APLICAR = process.argv.includes('--apply');

// tabla, columna
const OBJETIVOS = [
  ['biometric_profiles', 'face_scores'],
  ['biometric_profiles', 'hands_diagnosis'],
  ['glow_cycles', 'encrypted_scores'],
];

async function procesar(tabla, columna) {
  let filas;
  try {
    const res = await pool.query(
      `SELECT id, ${columna} AS cifrado FROM ${tabla} WHERE ${columna} IS NOT NULL AND ${columna} <> ''`
    );
    filas = res.rows;
  } catch (err) {
    console.log(`   ⏭️  ${tabla}.${columna}: no se pudo leer (${err.message})`);
    return { tabla, columna, total: 0, legados: 0, migrados: 0, ilegibles: 0 };
  }

  let legados = 0, migrados = 0, ilegibles = 0;
  for (const fila of filas) {
    // 1) ¿lo descifra la clave ACTUAL? Entonces no hay nada que migrar.
    let claro = null;
    let esLegado = false;
    try {
      claro = crypto.decrypt(fila.cifrado);
    } catch (_) {
      esLegado = true;
      try {
        claro = crypto.decryptWithLegacyKey(fila.cifrado);
      } catch (legacyErr) {
        ilegibles++;
        continue;
      }
    }
    if (!esLegado) continue;

    legados++;
    if (APLICAR) {
      const nuevo = crypto.encrypt(claro);
      await pool.query(`UPDATE ${tabla} SET ${columna} = $1 WHERE id = $2`, [nuevo, fila.id]);
      migrados++;
    }
  }

  return { tabla, columna, total: filas.length, legados, migrados, ilegibles };
}

(async () => {
  console.log(`\n🔐 Re-cifrado de datos biométricos — modo ${APLICAR ? 'APPLY (escribe)' : 'DRY-RUN (no escribe)'}`);
  console.log(`   Huella de la clave activa: ${crypto.keyFingerprint()}\n`);

  const conectado = await testConnection();
  if (!conectado) {
    console.error('❌ Sin conexión a la base de datos. Abortado.');
    process.exit(1);
  }

  let totalLegados = 0, totalIlegibles = 0;
  for (const [tabla, columna] of OBJETIVOS) {
    const r = await procesar(tabla, columna);
    totalLegados += r.legados;
    totalIlegibles += r.ilegibles;
    console.log(`   ${r.tabla}.${r.columna}: ${r.total} filas · cifradas con la clave legada: ${r.legados} · migradas: ${r.migrados} · ilegibles: ${r.ilegibles}`);
  }

  console.log(`\n   TOTAL: ${totalLegados} registros con clave legada, ${totalIlegibles} ilegibles.`);
  if (!APLICAR) {
    console.log('   (dry-run) Repite con --apply para escribir los cambios.\n');
  } else {
    console.log('   ✅ Re-cifrado aplicado. Verifica con el mismo comando en dry-run: debe dar 0 legados.\n');
  }
  process.exit(0);
})().catch((err) => {
  console.error('❌ Error en el re-cifrado:', err);
  process.exit(1);
});
