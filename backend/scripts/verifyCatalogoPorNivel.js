/**
 * GUARDIÁN DE VERIFICACIÓN — CATÁLOGO POR NIVEL Y CHECKOUT (GLOWSHOP A0)
 * 
 * Verifica el cálculo único de precios, la visibilidad por existencia de precio en lista,
 * la validación de unidad mínima y el contexto de plataforma para invitados sobre PostgreSQL real (puerto 5435).
 */

const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');
const { resolverPrecio, conContextoDePlataforma, rolACodigoLista } = require('../src/services/precioService');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5435', 10),
  database: process.env.DB_NAME || 'beauty_db',
  user: process.env.DB_USER || 'admin',
  password: process.env.DB_PASSWORD || 'admin123'
});

async function main() {
  console.log('==================================================');
  console.log('🔍 INICIANDO VERIFICACIÓN DEL GUARDIÁN DE CATÁLOGO Y CHECKOUT');
  console.log('==================================================\n');

  try {
    // 1. Auditoría estática de cero columnas heredadas en funciones de lectura
    console.log('1. Auditando estáticamente productController.js...');
    const controllerPath = path.join(__dirname, '../src/controllers/productController.js');
    const controllerContent = fs.readFileSync(controllerPath, 'utf8');

    // Extraer getProducts y getProductById
    const getProductsMatch = controllerContent.match(/exports\.getProducts =[\s\S]*?exports\.getProductById =[\s\S]*?exports\.createProduct/);
    const readCode = getProductsMatch ? getProductsMatch[0] : '';

    if (/precio_prestador|precio_al_publico|precio_con_reserva/.test(readCode)) {
      throw new Error('Se encontraron referencias a columnas legadas (precio_prestador, precio_al_publico) en las funciones de lectura de productController.js');
    }
    console.log('   ✔ Cero columnas legadas en funciones de lectura del catálogo.\n');

    // 2. Probar acceso de invitado sin sesión con contexto de plataforma
    console.log('2. Probando catálogo para invitado sin sesión (Contexto de Plataforma)...');
    const guestData = await conContextoDePlataforma(pool, async (client) => {
      const codigoLista = rolACodigoLista('client');
      const query = `
        SELECT p.id, p.nombre, pp.precio, pp.unidad_minima
        FROM productos p
        INNER JOIN precios_producto pp ON pp.producto_id = p.id
        INNER JOIN listas_precios lp ON lp.id = pp.lista_id
        WHERE lp.codigo = $1
          AND lp.estado = 'ACTIVA'
          AND pp.precio IS NOT NULL
        ORDER BY p.id ASC;
      `;
      const res = await client.query(query, [codigoLista]);
      return res.rows;
    });

    console.log(`   Productos devueltos para invitado (consumidor): ${guestData.length}`);
    if (guestData.length !== 296) {
      throw new Error(`Se esperaban 296 productos de plataforma con precio cliente, pero se obtuvieron ${guestData.length}`);
    }
    console.log('   ✔ Invitado ve los 296 productos con precio de consumidor.\n');

    // 3. Verificando que productos sin precio en listas B2B (profesional/negocio) devuelven sin_precio
    console.log('3. Verificando que productos sin precio en lista profesional devuelven sin_precio...');
    const insumosRes = await pool.query(`SELECT id, nombre FROM productos WHERE tipo_visibilidad = 'INSUMO_PRESTADOR' LIMIT 5`);
    for (const insumo of insumosRes.rows) {
      const resP = await resolverPrecio({ rol: 'provider', productoId: insumo.id, dbPool: pool });
      if (resP.estado !== 'sin_precio') {
        throw new Error(`El insumo ${insumo.nombre} (ID: ${insumo.id}) no debería tener precio en la lista profesional, pero obtuvo: ${JSON.stringify(resP)}`);
      }
    }
    console.log('   ✔ Productos sin tarifa en lista B2B devuelven estado sin_precio.\n');

    // 4. Coherencia entre precio de catálogo y precio de checkout
    console.log('4. Verificando coincidencia exacta entre catálogo y checkout...');
    const sampleProd = guestData[0];
    const resCheckout = await resolverPrecio({ rol: 'client', productoId: sampleProd.id, cantidad: 1, dbPool: pool });

    if (parseFloat(sampleProd.precio) !== resCheckout.precio) {
      throw new Error(`Discrepancia de precio entre catálogo (${sampleProd.precio}) y checkout (${resCheckout.precio})`);
    }
    console.log(`   ✔ Producto ${sampleProd.id}: Catálogo $${sampleProd.precio} == Checkout $${resCheckout.precio}.\n`);

    // 5. Validación de Unidad Mínima de Venta (B2B Negocio)
    console.log('5. Verificando validación de unidad mínima en nivel negocio...');
    const negocioProdId = sampleProd.id;

    // Probar 5 unidades (debe fallar con MINIMO_NO_CUMPLIDO)
    let fallosCorrectamente = false;
    try {
      await resolverPrecio({ rol: 'salon', productoId: negocioProdId, cantidad: 5, dbPool: pool });
    } catch (err) {
      if (err.code === 'MINIMO_NO_CUMPLIDO' && err.unidad_minima === 6) {
        fallosCorrectamente = true;
      }
    }

    if (!fallosCorrectamente) {
      throw new Error('No se lanzó error MINIMO_NO_CUMPLIDO al solicitar 5 unidades para rol salon');
    }
    console.log('   ✔ 5 unidades como salón -> Bloqueado correctamente por unidad mínima (6).');

    // Probar 6 unidades (debe pasar)
    // Primero sembrar temporalmente un precio en lista negocio para probar la validación completa
    const listaNegocioRes = await pool.query(`SELECT id FROM listas_precios WHERE codigo = 'negocio'`);
    const listaNegocioId = listaNegocioRes.rows[0].id;

    await pool.query(`
      INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima)
      VALUES ($1, $2, 35000, 6)
      ON CONFLICT (lista_id, producto_id) DO UPDATE SET precio = EXCLUDED.precio, unidad_minima = EXCLUDED.unidad_minima;
    `, [listaNegocioId, negocioProdId]);

    const resP6 = await resolverPrecio({ rol: 'salon', productoId: negocioProdId, cantidad: 6, dbPool: pool });
    if (resP6.unidad_minima !== 6 || resP6.precio !== 35000) {
      throw new Error(`Fallo en resolución para 6 unidades nivel negocio: ${JSON.stringify(resP6)}`);
    }

    // Limpiar precio de prueba
    await pool.query(`DELETE FROM precios_producto WHERE lista_id = $1 AND producto_id = $2`, [listaNegocioId, negocioProdId]);

    console.log('   ✔ 6 unidades como salón -> Pasa exitosamente con unidad_minima = 6.\n');

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
