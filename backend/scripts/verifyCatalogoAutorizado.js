/**
 * GUARDIÁN DE VERIFICACIÓN — AUTORIZACIÓN DEL CATÁLOGO Y PROTECCIÓN DE HISTORIAL (GLOWSHOP A0)
 * 
 * Verifica la migración 072, la creación de productos sin columnas legadas de precio,
 * y que el borrado de un producto con historial de precios responda HTTP 409 en lugar de destruir la historia.
 */

const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5435', 10),
  database: process.env.DB_NAME || 'beauty_db',
  user: process.env.DB_USER || 'admin',
  password: process.env.DB_PASSWORD || 'admin123'
});

async function main() {
  console.log('==================================================');
  console.log('🔍 INICIANDO VERIFICACIÓN DEL GUARDIÁN DE CATÁLOGO AUTORIZADO Y HISTORIAL');
  console.log('==================================================\n');

  try {
    // 1. Verificación de Migración 072 en esquema de BD
    console.log('1. Verificando estado del esquema (Migración 072)...');
    
    // Check nullable en productos.precio
    const nullRes = await pool.query(`
      SELECT is_nullable FROM information_schema.columns 
      WHERE table_name = 'productos' AND column_name = 'precio';
    `);
    if (nullRes.rows.length === 0 || nullRes.rows[0].is_nullable !== 'YES') {
      throw new Error('productos.precio todavía es NOT NULL en el esquema');
    }
    console.log('   ✔ productos.precio es deshabilitada como NOT NULL (is_nullable = YES).');

    // Check ON DELETE RESTRICT en precios_historial.producto_id
    const fkRes = await pool.query(`
      SELECT delete_rule FROM information_schema.referential_constraints rc
      JOIN information_schema.table_constraints tc ON tc.constraint_name = rc.constraint_name
      WHERE tc.table_name = 'precios_historial' AND rc.constraint_name = 'fk_precios_historial_producto';
    `);
    if (fkRes.rows.length === 0 || fkRes.rows[0].delete_rule !== 'RESTRICT') {
      throw new Error(`La FK de precios_historial.producto_id no es RESTRICT (encontrada: ${fkRes.rows[0]?.delete_rule})`);
    }
    console.log('   ✔ FK precios_historial.producto_id es ON DELETE RESTRICT.\n');

    // 2. Probar Creación de Producto sin columnas legadas de precio (createProduct)
    console.log('2. Probando alta de producto sin columnas legadas...');
    // Obtener tenant de plataforma
    const platRes = await pool.query(`SELECT app_platform_tenant_id() AS platform_id`);
    const platformTenantId = platRes.rows[0].platform_id;
    await pool.query(`SELECT set_config('app.tenant_id', $1, false)`, [String(platformTenantId)]);

    const insertRes = await pool.query(`
      INSERT INTO productos (nombre, descripcion, costo, stock, imagen_url, tag_especialidad, tipo_visibilidad, sku)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING id, nombre, costo, stock, sku;
    `, ['Shampoo Capilar de Prueba WO4', 'Descripción prueba', 18000, 15, 'http://img.png', 'capilar', 'PUBLICO', 'TEST-WO4-01']);

    const newProd = insertRes.rows[0];
    console.log(`   Producto creado exitosamente con ID: ${newProd.id}, costo: $${newProd.costo}`);
    console.log('   ✔ Alta de producto funcional sin exigencia de columnas legadas de precio.\n');

    // 3. Probar Protección de Borrado con Historial (deleteProduct)
    console.log('3. Probando protección de historial en borrado...');
    // Obtener lista cliente
    const listaRes = await pool.query(`SELECT id FROM listas_precios WHERE codigo = 'cliente'`);
    const listaId = listaRes.rows[0].id;

    // Insertar un registro de historial para este nuevo producto
    await pool.query(`
      INSERT INTO precios_historial (lista_id, producto_id, precio_anterior, precio_nuevo, actor_id, origen, motivo, tenant_id)
      VALUES ($1, $2, NULL, 35000, 1, 'manual', 'Prueba de historial WO4', $3);
    `, [listaId, newProd.id, platformTenantId]);

    // Intentar borrar el producto (debe ser bloqueado por la FK RESTRICT)
    let falloPorRestrict = false;
    try {
      await pool.query('DELETE FROM productos WHERE id = $1', [newProd.id]);
    } catch (err) {
      if (err.code === '23503' || /precios_historial|violates foreign key constraint/i.test(err.message)) {
        falloPorRestrict = true;
      }
    }

    if (!falloPorRestrict) {
      throw new Error(`Se esperaba que DELETE fallara por FK RESTRICT, pero se ejecutó el borrado de ${newProd.id}`);
    }
    console.log('   ✔ Intento de borrado bloqueado correctamente por FK RESTRICT.');

    // Verificar que el producto y su historial siguen intactos
    const checkProd = await pool.query('SELECT id FROM productos WHERE id = $1', [newProd.id]);
    const checkHist = await pool.query('SELECT COUNT(*) FROM precios_historial WHERE producto_id = $1', [newProd.id]);

    if (checkProd.rows.length === 0 || parseInt(checkHist.rows[0].count, 10) === 0) {
      throw new Error('El producto o el historial fueron destruidos a pesar de la restricción');
    }
    console.log('   ✔ Producto e historial de precios intactos en la base de datos.\n');

    // 4. Limpiar datos de prueba al finalizar
    await pool.query('DELETE FROM precios_historial WHERE producto_id = $1', [newProd.id]);
    await pool.query('DELETE FROM productos WHERE id = $1', [newProd.id]);

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
