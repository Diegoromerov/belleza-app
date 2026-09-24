/**
 * GUARDIÁN DE VERIFICACIÓN — IMPORTACIÓN Y EXPORTACIÓN MASIVA CSV DE PRECIOS GLOWSHOP
 * 
 * Verifica el funcionamiento contra PostgreSQL real en el puerto 5435.
 */

const { Pool } = require('pg');
const { parsearPreciosCsv, exportarPreciosCsv, aplicarPreciosCsv } = require('../src/services/preciosCsvService');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5435', 10),
  database: process.env.DB_NAME || 'beauty_db',
  user: process.env.DB_USER || 'admin',
  password: process.env.DB_PASSWORD || 'admin123'
});

async function main() {
  console.log('==================================================');
  console.log('🔍 INICIANDO VERIFICACIÓN DEL GUARDIÁN DE CSV DE PRECIOS');
  console.log('==================================================\n');

  try {
    // 1. Probar exportación a CSV
    console.log('1. Probrando exportarPreciosCsv()...');
    const csvExportado = await exportarPreciosCsv({ dbPool: pool });
    const lines = csvExportado.split('\n').filter(l => l.trim().length > 0);
    const header = lines[0];

    console.log(`   Header exportado: ${header}`);
    const expectedHeader = 'producto_id,sku,nombre,costo,stock,precio_cliente,precio_profesional,precio_negocio,unidad_minima_negocio';
    if (header !== expectedHeader) {
      throw new Error(`El encabezado exportado (${header}) no coincide con el esperado (${expectedHeader})`);
    }

    const countProdRes = await pool.query('SELECT COUNT(*) FROM productos');
    const totalProds = parseInt(countProdRes.rows[0].count, 10);
    console.log(`   Filas exportadas: ${lines.length - 1} (esperadas: ${totalProds})`);

    if (lines.length - 1 !== totalProds) {
      throw new Error(`Cantidad de filas exportadas (${lines.length - 1}) no coincide con el total de productos (${totalProds})`);
    }
    console.log('   ✔ Exportación CSV validada correctamente.\n');

    // 2. Probar parseo de función pura con errores de formato
    console.log('2. Proband parsearPreciosCsv() en modo puro...');
    const invalidCsv = `producto_id,sku,nombre,precio_cliente,precio_profesional
1042,SH-ARG-01,Shampoo,$45000,40000
1043,AC-COC-02,Acondicionador,38000,0`;

    const parsedInvalid = parsearPreciosCsv(invalidCsv);
    console.log(`   Errores detectados en CSV inválido: ${parsedInvalid.errores.length}`);
    if (parsedInvalid.errores.length !== 2) {
      throw new Error(`Se esperaban 2 errores en el CSV inválido, pero se obtuvieron ${parsedInvalid.errores.length}`);
    }
    console.log('   ✔ Analizador sintáctico puro validó errores correctamente.\n');

    // 3. Probar dry_run=true (sin mutación en base de datos)
    console.log('3. Probando aplicarPreciosCsv() con dryRun = true...');
    // Tomar 5 productos reales de la base
    const prodsRes = await pool.query('SELECT id, sku, nombre FROM productos ORDER BY id ASC LIMIT 5');
    const prods = prodsRes.rows;

    const sampleCsv = `producto_id,sku,nombre,costo,stock,precio_cliente,precio_profesional,precio_negocio,unidad_minima_negocio
${prods[0].id},${prods[0].sku || ''},${prods[0].nombre},25000,50,50000,45000,40000,6
${prods[1].id},${prods[1].sku || ''},${prods[1].nombre},30000,30,60000,54000,48000,6`;

    const parsedSample = parsearPreciosCsv(sampleCsv);
    const dryRunReport = await aplicarPreciosCsv({
      dbPool: pool,
      actorId: 1,
      filas: parsedSample.filas,
      errores: parsedSample.errores,
      totalLeidas: parsedSample.total_leidas,
      dryRun: true
    });

    console.log('   Reporte Dry Run:', JSON.stringify(dryRunReport.cambios));
    if (dryRunReport.con_error > 0) {
      throw new Error(`Error inesperado en dry run: ${JSON.stringify(dryRunReport.errores)}`);
    }
    console.log('   ✔ Dry run ejecutado sin alteraciones de datos.\n');

    // 4. Probar aplicarPreciosCsv() con dryRun = false (aplicar cambios reales)
    console.log('4. Probando aplicarPreciosCsv() con dryRun = false...');
    const applyReport = await aplicarPreciosCsv({
      dbPool: pool,
      actorId: 1,
      filas: parsedSample.filas,
      errores: parsedSample.errores,
      totalLeidas: parsedSample.total_leidas,
      dryRun: false
    });

    console.log('   Reporte Aplicación:', JSON.stringify(applyReport.cambios));
    if (applyReport.validas !== 2) {
      throw new Error(`Se esperaban 2 filas válidas aplicadas, pero fueron ${applyReport.validas}`);
    }

    // Verificar que se haya registrado auditoría en precios_historial con origen import_csv
    const histRes = await pool.query(`SELECT COUNT(*) FROM precios_historial WHERE origen = 'import_csv'`);
    const histCount = parseInt(histRes.rows[0].count, 10);
    console.log(`   Registros creados en precios_historial con origen 'import_csv': ${histCount}`);
    if (histCount === 0) {
      throw new Error('No se generaron registros en precios_historial con origen import_csv');
    }
    console.log('   ✔ Aplicación transaccional e historial de auditoría verificados.\n');

    // 5. Probar Idempotencia (reimportar el mismo archivo)
    console.log('5. Probando Idempotencia (reimportar mismo CSV)...');
    const reimportReport = await aplicarPreciosCsv({
      dbPool: pool,
      actorId: 1,
      filas: parsedSample.filas,
      errores: parsedSample.errores,
      totalLeidas: parsedSample.total_leidas,
      dryRun: true
    });

    console.log('   Reporte Reimportación:', JSON.stringify(reimportReport.cambios));
    if (reimportReport.cambios.nuevos !== 0 || reimportReport.cambios.modificados !== 0) {
      throw new Error(`La reimportación de los mismos datos debía resultar en 0 cambios (idempotente), obtuvo: ${JSON.stringify(reimportReport.cambios)}`);
    }
    console.log('   ✔ Idempotencia de importación confirmada (0 modificaciones).\n');

    console.log('==================================================');
    console.log('🎉 [GUARDIÁN] VERIFICACIÓN COMPLETADA EXITOSAMENTE (VERDE)');
    console.log('==================================================');

  } catch (err) {
    console.error('❌ Error en verificación del guardián:', err);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

main();
