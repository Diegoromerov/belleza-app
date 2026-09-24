/**
 * SCRIPT GUARDIÁN DE VERIFICACIÓN — AUTENTICACIÓN Y ACCESO ADMINISTRATIVO A PRECIOS (GLOWSHOP B-01)
 * 
 * Verificación obligatoria:
 *  1. POST /api/auth/login con credenciales ADMIN -> 200 y Token.
 *  2. Con el token ADMIN: GET /api/admin/precios -> HTTP 200.
 *  3. Con el token PRESTADOR (no admin): GET /api/admin/precios -> HTTP 403.
 *  4. PUT /api/admin/precios/1 con token ADMIN -> HTTP 200 y lectura de vuelta en BD.
 *  5. Limpieza asertiva comprobando cambio neto cero por valores en la BD.
 */

const express = require('express');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');
const { getJwtSecret } = require('../src/config/jwt');
const authController = require('../src/controllers/authController');
const { authMiddleware } = require('../src/middleware/auth');
const adminPreciosRoutes = require('../src/routes/adminPreciosRoutes');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgres://admin:admin123@localhost:5435/beauty_db'
});

async function getDbSnapshot(dbPool) {
  const prods = await dbPool.query('SELECT id, nombre, costo, stock, sku, tenant_id FROM productos ORDER BY id');
  const precios = await dbPool.query('SELECT lista_id, producto_id, precio, unidad_minima FROM precios_producto ORDER BY lista_id, producto_id');
  const historial = await dbPool.query('SELECT id, lista_id, producto_id, precio_anterior, precio_nuevo, origen FROM precios_historial ORDER BY id');
  return {
    prods: prods.rows,
    precios: precios.rows,
    historial: historial.rows
  };
}

function verifyValueSnapshot(snapshotPre, snapshotPost) {
  const preStr = JSON.stringify(snapshotPre);
  const postStr = JSON.stringify(snapshotPost);
  if (preStr !== postStr) {
    console.error('❌ ERROR DE CAMBIO NETO CERO EN VALORES EN BD:');
    if (snapshotPre.precios.length !== snapshotPost.precios.length) {
      console.error(`   Precios total: inicial=${snapshotPre.precios.length} vs final=${snapshotPost.precios.length}`);
    }
    return false;
  }
  return true;
}

async function main() {
  console.log('==================================================');
  console.log('🔍 VERIFICACIÓN COMPLETA DE AUTENTICACIÓN ADMIN Y ACCESO A PRECIOS');
  console.log('==================================================\n');

  let exitCode = 0;
  let server = null;
  const snapshotPre = await getDbSnapshot(pool);

  try {
    const adminEmail = process.env.ADMIN_EMAIL || 'admin_plataforma@glowapp.com';
    const adminPass = process.env.ADMIN_PASSWORD || 'GlowAdmin2026SecurePass!';

    // Montar servidor Express en puerto 0
    const app = express();
    app.use(express.json());

    // Rutas de auth y admin precios
    app.post('/api/auth/login', authController.login);
    app.use('/api/admin', adminPreciosRoutes);

    await new Promise((resolve) => {
      server = app.listen(0, resolve);
    });

    const port = server.address().port;
    const baseUrl = `http://127.0.0.1:${port}`;
    console.log(`   Servidor Express iniciado en ${baseUrl}\n`);

    // 1. POST /api/auth/login con credenciales Admin -> 200 y Token
    console.log('1. Probando POST /api/auth/login con credenciales de usuario ADMIN...');
    const loginRes = await fetch(`${baseUrl}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: adminEmail, password: adminPass })
    });

    if (loginRes.status !== 200) {
      throw new Error(`Login de admin falló con HTTP ${loginRes.status}`);
    }

    const loginData = await loginRes.json();
    const adminToken = loginData.token;
    if (!adminToken) {
      throw new Error('El login de admin no retornó un token JWT válido');
    }
    console.log('   ✔ Login de ADMIN exitoso (HTTP 200). Token JWT obtenido correctamente.\n');

    // 2. GET /api/admin/precios con token ADMIN -> HTTP 200
    console.log('2. Probando GET /api/admin/precios con token ADMIN...');
    const preciosRes = await fetch(`${baseUrl}/api/admin/precios`, {
      headers: { 'Authorization': `Bearer ${adminToken}` }
    });

    if (preciosRes.status !== 200) {
      throw new Error(`GET /api/admin/precios con admin retornó HTTP ${preciosRes.status} en lugar de 200`);
    }
    const preciosBody = await preciosRes.json();
    console.log(`   ✔ GET /api/admin/precios retornó HTTP 200. Total productos en respuesta: ${preciosBody.data?.length || 0}.\n`);

    // 3. GET /api/admin/precios con token PRESTADOR (no-admin) -> HTTP 403
    console.log('3. Probando GET /api/admin/precios con token PRESTADOR (no-admin)...');
    const secret = getJwtSecret();
    // Obtener id de un prestador existente
    const providerUserRes = await pool.query("SELECT id, email FROM usuarios WHERE rol = 'PRESTADOR' LIMIT 1");
    const providerUser = providerUserRes.rows[0];
    const providerToken = jwt.sign({ id: providerUser.id, email: providerUser.email }, secret);

    const providerPreciosRes = await fetch(`${baseUrl}/api/admin/precios`, {
      headers: { 'Authorization': `Bearer ${providerToken}` }
    });

    if (providerPreciosRes.status !== 403) {
      throw new Error(`GET /api/admin/precios con rol PRESTADOR debió retornar HTTP 403, obtuvo: ${providerPreciosRes.status}`);
    }
    console.log('   ✔ Acceso denegado correctamente con HTTP 403 para usuario rol PRESTADOR.\n');

    // 4. PUT /api/admin/precios/1 con token ADMIN -> HTTP 200 y lectura de vuelta en BD
    console.log('4. Probando PUT /api/admin/precios/1 con token ADMIN y lectura de vuelta en BD...');
    const putRes = await fetch(`${baseUrl}/api/admin/precios/1`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${adminToken}` },
      body: JSON.stringify({
        precios: [
          { lista: 'cliente', precio: 45000.00 }
        ],
        motivo: 'Verificación Entregable 1'
      })
    });

    if (putRes.status !== 200) {
      throw new Error(`PUT /api/admin/precios/1 retornó HTTP ${putRes.status}`);
    }

    // Lectura de vuelta directa en la BD para confirmar persistencia real
    const dbPriceRes = await pool.query(`
      SELECT pp.precio, lp.codigo 
      FROM precios_producto pp
      JOIN listas_precios lp ON lp.id = pp.lista_id
      WHERE pp.producto_id = 1 AND lp.codigo = 'cliente'
    `);

    const dbPrecio = parseFloat(dbPriceRes.rows[0]?.precio);
    if (dbPrecio !== 45000.00) {
      throw new Error(`El precio en BD no coincide tras PUT: ${dbPrecio} vs 45000.00`);
    }
    console.log(`   ✔ PUT /api/admin/precios/1 exitoso (HTTP 200). Leído de vuelta en BD: $${dbPrecio.toFixed(2)}.\n`);

  } catch (err) {
    console.error('❌ Error en verificación de autenticación admin:', err.message);
    exitCode = 1;
  } finally {
    if (server) {
      server.close();
    }

    // Restaurar cualquier cambio en historial generado durante la prueba si aplica
    await pool.query("DELETE FROM precios_historial WHERE motivo = 'Verificación Entregable 1'");

    const snapshotPost = await getDbSnapshot(pool);
    const passed = verifyValueSnapshot(snapshotPre, snapshotPost);

    if (!passed) {
      exitCode = 1;
    } else {
      console.log('✅ CAMBIO NETO CERO EN VALORES VERIFICADO EN BD.');
    }

    await pool.end();

    if (exitCode === 0) {
      console.log('==================================================');
      console.log('🎉 [ENTREGABLE 1] VERIFICACIÓN COMPLETADA EXITOSAMENTE (VERDE)');
      console.log('==================================================');
    } else {
      console.error('💥 [ENTREGABLE 1] VERIFICACIÓN FALLIDA (ROJO)');
    }
    process.exit(exitCode);
  }
}

main();
