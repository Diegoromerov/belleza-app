const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const { pool } = require('../src/config/db');
const { resolverPrecio } = require('../src/services/precioService');
const { requireRol } = require('../src/middleware/roles');

async function main() {
  console.log('🔍 [GUARDIÁN] Iniciando comprobación de Precios por Lista...');
  let exitCode = 0;

  try {
    // 1. Existen las 3 listas y profesional/negocio arrancan con 0 precios
    const listasRes = await pool.query(`SELECT codigo, rol_destino, incluye_iva FROM listas_precios ORDER BY codigo`);
    console.log('✅ Listas de precios configuradas:', listasRes.rows);

    if (listasRes.rows.length !== 3) {
      console.error('❌ Error: Se esperaban 3 listas de precios');
      exitCode = 1;
    }

    const countRes = await pool.query(`
      SELECT l.codigo, count(p.producto_id) AS total_precios
      FROM listas_precios l
      LEFT JOIN precios_producto p ON p.lista_id = l.id
      GROUP BY l.codigo ORDER BY l.codigo
    `);
    console.log('📊 Precios actuales por lista:', countRes.rows);

    // 2. Obtener un producto de prueba
    const prodRes = await pool.query(`SELECT id, nombre, costo FROM productos ORDER BY id LIMIT 1`);
    if (prodRes.rows.length === 0) {
      console.error('❌ No hay productos en la base de datos para probar');
      process.exit(1);
    }
    const testProd = prodRes.rows[0];
    const pid = testProd.id;

    // 3. Probamos resolverPrecio con rol salon y cantidad = 5 -> debe lanzar MINIMO_NO_CUMPLIDO (mínimo es 6)
    const negocioListaRes = await pool.query(`SELECT id FROM listas_precios WHERE codigo = 'negocio'`);
    const negocioListaId = negocioListaRes.rows[0].id;

    await pool.query(`
      INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima)
      VALUES ($1, $2, 36000.00, 6)
      ON CONFLICT (lista_id, producto_id) DO UPDATE SET precio = 36000.00, unidad_minima = 6;
    `, [negocioListaId, pid]);

    try {
      await resolverPrecio({ rol: 'salon', productoId: pid, cantidad: 5 });
      console.error('❌ Error: resolverPrecio con cantidad=5 en rol salon debió fallar por unidad mínima');
      exitCode = 1;
    } catch (err) {
      if (err.code === 'MINIMO_NO_CUMPLIDO') {
        console.log('✅ MINIMO_NO_CUMPLIDO capturado correctamente para cantidad=5:', err.message);
      } else {
        console.error('❌ Error inesperado en validación de mínimo:', err);
        exitCode = 1;
      }
    }

    // Probar resolverPrecio con cantidad = 6 -> Debe pasar exitosamente
    const resCumple = await resolverPrecio({ rol: 'salon', productoId: pid, cantidad: 6 });
    if (resCumple && resCumple.precio === 36000 && resCumple.unidad_minima === 6) {
      console.log('✅ resolverPrecio con cantidad=6 retornó precio exitosamente:', resCumple);
    } else {
      console.error('❌ Error en resolverPrecio con cantidad=6:', resCumple);
      exitCode = 1;
    }

    // 4. Probar resolverPrecio para un producto sin precio en lista 'profesional' -> debe retornar estado: 'sin_precio'
    const sinPrecioRes = await resolverPrecio({ rol: 'provider', productoId: pid, cantidad: 1 });
    if (sinPrecioRes && sinPrecioRes.estado === 'sin_precio') {
      console.log('✅ resolverPrecio producto sin precio en profesional devolvió estado sin_precio:', sinPrecioRes);
    } else {
      console.error('❌ Error: resolverPrecio debió retornar sin_precio para lista vacía:', sinPrecioRes);
      exitCode = 1;
    }

    // 5. Verificar portero de roles (requireRol)
    const reqAdmin = requireRol('admin');
    let resCode = null;
    const mockRes = { status: (code) => { resCode = code; return { json: () => {} }; } };

    // Simular req de CLIENTE
    reqAdmin({ user: { role: 'client' } }, mockRes, () => { resCode = 200; });
    if (resCode === 403) {
      console.log('✅ requireRol(admin) devolvió 403 para usuario rol client');
    } else {
      console.error('❌ requireRol(admin) no bloqueó usuario client, status:', resCode);
      exitCode = 1;
    }

    // Simular req de PRESTADOR
    reqAdmin({ user: { role: 'provider' } }, mockRes, () => { resCode = 200; });
    if (resCode === 403) {
      console.log('✅ requireRol(admin) devolvió 403 para usuario rol provider');
    } else {
      console.error('❌ requireRol(admin) no bloqueó usuario provider, status:', resCode);
      exitCode = 1;
    }

    // Simular req de ADMIN -> pasa al next()
    let passAdmin = false;
    reqAdmin({ user: { role: 'admin' } }, mockRes, () => { passAdmin = true; });
    if (passAdmin) {
      console.log('✅ requireRol(admin) permitió acceso a usuario rol admin');
    } else {
      console.error('❌ requireRol(admin) bloqueó usuario admin');
      exitCode = 1;
    }

    // 6. Trazabilidad de precios_historial
    const histBefore = await pool.query(`SELECT COUNT(*) FROM precios_historial`);
    const countBefore = parseInt(histBefore.rows[0].count, 10);

    const clienteListaRes = await pool.query(`SELECT id FROM listas_precios WHERE codigo = 'cliente'`);
    const clienteListaId = clienteListaRes.rows[0].id;

    await pool.query(`
      INSERT INTO precios_historial (lista_id, producto_id, precio_anterior, precio_nuevo, origen, motivo, tenant_id)
      SELECT $1, $2, 45000, 46000, 'manual', 'Prueba guardián', tenant_id FROM listas_precios WHERE id = $1;
    `, [clienteListaId, pid]);

    const histAfter = await pool.query(`SELECT COUNT(*) FROM precios_historial`);
    const countAfter = parseInt(histAfter.rows[0].count, 10);

    if (countAfter === countBefore + 1) {
      console.log(`✅ Registro de historial comprobado: ${countBefore} -> ${countAfter}`);
    } else {
      console.error(`❌ Error en historial: antes=${countBefore}, después=${countAfter}`);
      exitCode = 1;
    }

  } catch (err) {
    console.error('❌ Error ejecutando el guardián:', err);
    exitCode = 1;
  }

  if (exitCode === 0) {
    console.log('🎉 [GUARDIÁN] VERIFICACIÓN COMPLETADA EXITOSAMENTE (VERDE)');
  } else {
    console.error('💥 [GUARDIÁN] VERIFICACIÓN FALLIDA (ROJO)');
  }
  process.exit(exitCode);
}

main();
