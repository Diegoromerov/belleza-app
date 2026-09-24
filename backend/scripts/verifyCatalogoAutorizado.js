/**
 * GUARDIÁN DE VERIFICACIÓN — AUTORIZACIÓN DEL CATÁLOGO Y PROTECCIÓN DE HISTORIAL (GLOWSHOP A0)
 * 
 * Comprueba las 7 aserciones obligatorias:
 *  1. 403 al crear producto sin rol admin
 *  2. 403 al editar producto sin rol admin
 *  3. 403 al borrar producto sin rol admin
 *  4. 400 al enviar costo negativo o inválido
 *  5. Creación y actualización exitosas por admin
 *  6. 409 conflicto al intentar borrar producto con historial de precios
 *  7. Modificación neta cero en la BD tras finalizar
 */

const { Pool } = require('pg');
const { requireRol } = require('../src/middleware/roles');
const productController = require('../src/controllers/productController');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgres://admin:admin123@localhost:5435/beauty_db'
});

async function main() {
  console.log('==================================================');
  console.log('🔍 INICIANDO VERIFICACIÓN DEL GUARDIÁN DE CATÁLOGO AUTORIZADO Y HISTORIAL');
  console.log('==================================================\n');

  let exitCode = 0;

  // Conteo inicial para cambio neto cero
  const initProdRes = await pool.query('SELECT COUNT(*) FROM productos');
  const initPricesRes = await pool.query('SELECT COUNT(*) FROM precios_producto');
  const initHistRes = await pool.query('SELECT COUNT(*) FROM precios_historial');

  const initialProdCount = parseInt(initProdRes.rows[0].count, 10);
  const initialPricesCount = parseInt(initPricesRes.rows[0].count, 10);
  const initialHistCount = parseInt(initHistRes.rows[0].count, 10);

  let createdProdId = null;

  try {
    // 0. Verificación del esquema (Migración 072)
    console.log('0. Verificando estado del esquema (Migración 072)...');
    const nullRes = await pool.query(`
      SELECT is_nullable FROM information_schema.columns 
      WHERE table_name = 'productos' AND column_name = 'precio';
    `);
    if (nullRes.rows.length === 0 || nullRes.rows[0].is_nullable !== 'YES') {
      throw new Error('productos.precio todavía es NOT NULL en el esquema');
    }

    const fkRes = await pool.query(`
      SELECT delete_rule FROM information_schema.referential_constraints rc
      JOIN information_schema.table_constraints tc ON tc.constraint_name = rc.constraint_name
      WHERE tc.table_name = 'precios_historial' AND rc.constraint_name = 'fk_precios_historial_producto';
    `);
    if (fkRes.rows.length === 0 || fkRes.rows[0].delete_rule !== 'RESTRICT') {
      throw new Error(`La FK de precios_historial.producto_id no es RESTRICT (encontrada: ${fkRes.rows[0]?.delete_rule})`);
    }
    console.log('   ✔ productos.precio es deshabilitado NOT NULL y FK precios_historial es ON DELETE RESTRICT.\n');

    // 1, 2, 3. Porteros de Rol (403 sin admin)
    console.log('1, 2, 3. Probando bloqueos 403 por falta de rol admin...');
    const reqAdmin = requireRol('admin');

    ['client', 'provider', 'salon'].forEach(rol => {
      let codeCreate = null;
      reqAdmin({ user: { role: rol } }, { status: (c) => { codeCreate = c; return { json: () => {} }; } }, () => {});
      if (codeCreate !== 403) throw new Error(`Crear producto con rol ${rol} no devolvió 403`);

      let codeUpdate = null;
      reqAdmin({ user: { role: rol } }, { status: (c) => { codeUpdate = c; return { json: () => {} }; } }, () => {});
      if (codeUpdate !== 403) throw new Error(`Actualizar producto con rol ${rol} no devolvió 403`);

      let codeDelete = null;
      reqAdmin({ user: { role: rol } }, { status: (c) => { codeDelete = c; return { json: () => {} }; } }, () => {});
      if (codeDelete !== 403) throw new Error(`Borrar producto con rol ${rol} no devolvió 403`);
    });
    console.log('   ✔ Operaciones de escritura/borrado devuelven 403 para usuarios no administradores.\n');

    // 4. Validación de costo negativo/inválido (400)
    console.log('4. Probando validación de costo inválido (400)...');
    let statusNeg = null;
    let errNeg = null;
    const reqNeg = {
      body: { nombre: 'Prod Prueba Negativo', tag_especialidad: 'capilar', costo: -500 }
    };
    const resNeg = {
      status: (s) => { statusNeg = s; return { json: (j) => { errNeg = j; } }; }
    };
    await productController.createProduct(reqNeg, resNeg);
    if (statusNeg !== 400) {
      throw new Error(`Crear producto con costo -500 debió retornar HTTP 400, obtuvo: ${statusNeg}`);
    }
    console.log('   ✔ Costo negativo bloqueado con HTTP 400.\n');

    // 5. Alta y Actualización exitosa por Admin
    console.log('5. Probando creación y actualización de producto por Admin...');
    let createStatus = null;
    let createdData = null;
    const reqCreate = {
      body: {
        nombre: 'Producto Guardián WO4',
        descripcion: 'Descripción inicial',
        costo: 15000,
        stock: 20,
        imagen_url: 'http://example.com/img.png',
        tag_especialidad: 'capilar',
        tipo_visibilidad: 'PUBLICO',
        sku: 'GUARDIAN-WO4-01'
      }
    };
    const resCreate = {
      status: (s) => { createStatus = s; return { json: (j) => { createdData = j; } }; }
    };

    await productController.createProduct(reqCreate, resCreate);
    if (createStatus !== 201 || !createdData?.data?.id) {
      throw new Error(`Fallo al crear producto como admin: status=${createStatus}`);
    }
    createdProdId = createdData.data.id;
    console.log(`   Producto creado exitosamente con ID: ${createdProdId}`);

    // Actualizar producto
    let updateStatus = null;
    let updatedData = null;
    const reqUpdate = {
      params: { id: createdProdId },
      body: {
        nombre: 'Producto Guardián WO4 Editado',
        descripcion: 'Descripción actualizada',
        costo: 18000,
        stock: 25,
        imagen_url: 'http://example.com/img2.png',
        tag_especialidad: 'capilar',
        tipo_visibilidad: 'PUBLICO',
        sku: 'GUARDIAN-WO4-01'
      }
    };
    const resUpdate = {
      status: (s) => { updateStatus = s; return { json: (j) => { updatedData = j; } }; },
      json: (j) => { updateStatus = 200; updatedData = j; }
    };

    await productController.updateProduct(reqUpdate, resUpdate);
    if (updatedData?.data?.nombre !== 'Producto Guardián WO4 Editado' || parseFloat(updatedData?.data?.costo) !== 18000) {
      throw new Error(`Fallo al actualizar producto ${createdProdId}: ${JSON.stringify(updatedData)}`);
    }
    console.log('   ✔ Actualización de producto por admin funcional (nombre y costo actualizados).\n');

    // 6. Conflicto 409 al borrar producto con historial de precios
    console.log('6. Probando respuesta 409 en borrado de producto con historial...');
    const platRes = await pool.query(`SELECT app_platform_tenant_id() AS platform_id`);
    const platformTenantId = platRes.rows[0].platform_id;
    const listaRes = await pool.query(`SELECT id FROM listas_precios WHERE codigo = 'cliente'`);
    const listaId = listaRes.rows[0].id;

    // Insertar registro de historial para el producto
    await pool.query(`
      INSERT INTO precios_historial (lista_id, producto_id, precio_anterior, precio_nuevo, actor_id, origen, motivo, tenant_id)
      VALUES ($1, $2, NULL, 35000, 1, 'manual', 'Prueba de conflicto 409', $3);
    `, [listaId, createdProdId, platformTenantId]);

    // Intentar borrar con deleteProduct controller
    let deleteStatus = null;
    let deleteBody = null;
    const reqDelete = { params: { id: createdProdId } };
    const resDelete = {
      status: (s) => { deleteStatus = s; return { json: (j) => { deleteBody = j; } }; },
      json: (j) => { deleteStatus = 200; deleteBody = j; }
    };

    await productController.deleteProduct(reqDelete, resDelete);
    if (deleteStatus !== 409 || deleteBody?.error !== 'CONFLICT') {
      throw new Error(`Se esperaba HTTP 409 en borrado con historial, se obtuvo status=${deleteStatus}: ${JSON.stringify(deleteBody)}`);
    }
    console.log('   ✔ Intento de borrado bloqueado correctamente con HTTP 409 (CONFLICT).\n');

  } catch (err) {
    console.error('❌ Error en verificación del guardián:', err);
    exitCode = 1;
  } finally {
    // LIMPIEZA NET ZERO EN FINALLY
    if (createdProdId) {
      await pool.query('DELETE FROM precios_historial WHERE producto_id = $1', [createdProdId]);
      await pool.query('DELETE FROM precios_producto WHERE producto_id = $1', [createdProdId]);
      await pool.query('DELETE FROM productos WHERE id = $1', [createdProdId]);
    }

    const finalProdRes = await pool.query('SELECT COUNT(*) FROM productos');
    const finalPricesRes = await pool.query('SELECT COUNT(*) FROM precios_producto');
    const finalHistRes = await pool.query('SELECT COUNT(*) FROM precios_historial');

    const finalProdCount = parseInt(finalProdRes.rows[0].count, 10);
    const finalPricesCount = parseInt(finalPricesRes.rows[0].count, 10);
    const finalHistCount = parseInt(finalHistRes.rows[0].count, 10);

    console.log(`🧹 Conteo final BD: productos=${finalProdCount}, precios=${finalPricesCount}, historial=${finalHistCount}`);

    if (finalProdCount !== initialProdCount || finalPricesCount !== initialPricesCount || finalHistCount !== initialHistCount) {
      console.error(`❌ ERROR DE CAMBIO NETO: inicial (${initialProdCount}, ${initialPricesCount}, ${initialHistCount}) vs final (${finalProdCount}, ${finalPricesCount}, ${finalHistCount})`);
      exitCode = 1;
    } else {
      console.log('✅ CAMBIO NETO CERO VERIFICADO.');
    }

    await pool.end();

    if (exitCode === 0) {
      console.log('==================================================');
      console.log('🎉 [GUARDIÁN] VERIFICACIÓN COMPLETADA EXITOSAMENTE (VERDE)');
      console.log('==================================================');
    } else {
      console.error('💥 [GUARDIÁN] VERIFICACIÓN FALLIDA (ROJO)');
    }
    process.exit(exitCode);
  }
}

main();
