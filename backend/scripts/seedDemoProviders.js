#!/usr/bin/env node
/**
 * Datos de demostración mínimos para poder recorrer el flujo completo
 * (buscar prestador → ver servicios → reservar) sin depender del catálogo real.
 *
 * Guardas, en este orden:
 *  1. `ALLOW_DEMO_SEED=1` — sin la bandera no hace nada. Evita sembrar por
 *     accidente desde un deploy o un cron.
 *  2. Idempotente por email: si el prestador ya existe, se salta. Correrlo dos
 *     veces debe reportar `creados=0`.
 *  3. Todo en una transacción: si algo falla no queda media siembra.
 *
 * El esquema no se adivina. `/api/providers` (src/controllers/providerController.js)
 * lee `perfiles_prestador` con INNER JOIN `usuarios` sobre el mismo id y filtra:
 *   is_active = true · estatus_verificacion = 'APROBADO'
 *   ubicacion IS NOT NULL · dentro del radio de platform_config.gps_*
 * Si falta cualquiera de esas cuatro, el prestador no aparece y el catálogo
 * sigue vacío aunque el seed diga «creados=3».
 *
 * Uso:
 *   ALLOW_DEMO_SEED=1 DATABASE_URL=... node scripts/seedDemoProviders.js
 *   ALLOW_DEMO_SEED=1 DATABASE_URL=... node scripts/seedDemoProviders.js --limpiar
 */

const { Pool } = require('pg');

const DOMINIO = '@glowapp.test';
const PASSWORD_DEMO = 'DemoGlow2026!';

// Centro por defecto. El real se lee de `platform_config` en cada corrida: si
// se cambia el centro de la plataforma y el seed sigue con una coordenada fija,
// los prestadores quedan fuera del radio y el catálogo vuelve a salir vacío sin
// que nada falle.
const CENTRO_POR_DEFECTO = { lat: 4.6735, lon: -74.1422 };

// 0,001° de latitud ≈ 111 m.
const DEMO = [
  {
    email: `demo.ana${DOMINIO}`,
    nombre: 'Ana Ríos',
    negocio: 'Studio Ana',
    descripcion: 'Especialista en color y tratamientos capilares.',
    dLat: 0,
    dLon: 0,
    rating: 4.9,
    votos: 128,
    servicios: [
      { nombre: 'Corte y peinado', precio: 65000, minutos: 45, categoria: 'Cabello' },
      { nombre: 'Color completo', precio: 180000, minutos: 120, categoria: 'Cabello' },
    ],
  },
  {
    email: `demo.carla${DOMINIO}`,
    nombre: 'Carla Méndez',
    negocio: 'Belleza Carla',
    descripcion: 'Uñas, pestañas y maquillaje para eventos.',
    dLat: 0.0012,
    dLon: 0.0009,
    rating: 4.7,
    votos: 86,
    servicios: [
      { nombre: 'Manicure semipermanente', precio: 55000, minutos: 50, categoria: 'Uñas' },
      { nombre: 'Maquillaje social', precio: 120000, minutos: 75, categoria: 'Maquillaje' },
    ],
  },
  {
    email: `demo.diana${DOMINIO}`,
    nombre: 'Diana Ospina',
    negocio: 'Glow House',
    descripcion: 'Faciales, limpieza profunda y skincare profesional.',
    dLat: -0.0015,
    dLon: 0.0018,
    rating: 5.0,
    votos: 41,
    servicios: [
      { nombre: 'Limpieza facial profunda', precio: 95000, minutos: 60, categoria: 'Facial' },
      { nombre: 'Hidratación con ácido hialurónico', precio: 150000, minutos: 80, categoria: 'Facial' },
    ],
  },
];

async function main() {
  if (process.env.ALLOW_DEMO_SEED !== '1') {
    console.error(
      'ABORTADO: exporta ALLOW_DEMO_SEED=1 para sembrar datos de demostración.'
    );
    process.exit(1);
  }
  if (!process.env.DATABASE_URL) {
    console.error('ABORTADO: falta DATABASE_URL.');
    process.exit(1);
  }

  const limpiar = process.argv.includes('--limpiar');
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const client = await pool.connect();
  let creados = 0;
  let saltados = 0;
  let borrados = 0;

  try {
    await client.query('BEGIN');

    if (limpiar) {
      const emails = DEMO.map((d) => d.email);
      const u = await client.query(
        'SELECT id FROM usuarios WHERE email = ANY($1::text[])',
        [emails]
      );
      const ids = u.rows.map((r) => r.id);
      if (ids.length) {
        await client.query('DELETE FROM services WHERE provider_id = ANY($1::int[])', [ids]);
        await client.query('DELETE FROM perfiles_prestador WHERE id = ANY($1::int[])', [ids]);
        await client.query('DELETE FROM usuarios WHERE id = ANY($1::int[])', [ids]);
      }
      borrados = ids.length;
      await client.query('COMMIT');
      console.log(`borrados=${borrados}`);
      return;
    }

    // Centro real de la plataforma. Cae al valor por defecto si falta.
    const cfg = await client.query(
      "SELECT key, value FROM platform_config WHERE key IN ('gps_centro_latitud', 'gps_centro_longitud')"
    );
    const mapa = Object.fromEntries(cfg.rows.map((r) => [r.key, parseFloat(r.value)]));
    const CENTRO = {
      lat: Number.isFinite(mapa.gps_centro_latitud) ? mapa.gps_centro_latitud : CENTRO_POR_DEFECTO.lat,
      lon: Number.isFinite(mapa.gps_centro_longitud) ? mapa.gps_centro_longitud : CENTRO_POR_DEFECTO.lon,
    };
    console.log(`centro=${CENTRO.lat},${CENTRO.lon}`);

    // El catálogo vive en el tenant de plataforma; si no hay, el más bajo.
    const t = await client.query(
      'SELECT id FROM tenants ORDER BY es_plataforma DESC, id ASC LIMIT 1'
    );
    const tenantId = t.rows.length ? t.rows[0].id : null;

    // Los prestadores demo tienen contraseña conocida para poder probar la app
    // provider de punta a punta. Solo se genera bajo la bandera.
    let hash = null;
    try {
      hash = require('bcryptjs').hashSync(PASSWORD_DEMO, 10);
    } catch (_) {
      console.warn('AVISO: sin bcryptjs; los usuarios demo no podrán iniciar sesión.');
    }

    for (const d of DEMO) {
      const ya = await client.query('SELECT id FROM usuarios WHERE email = $1', [d.email]);
      if (ya.rows.length) {
        saltados++;
        continue;
      }

      const u = await client.query(
        `INSERT INTO usuarios
           (email, nombre, auth_provider, provider_id, rol,
            password_hash, onboarding_completo, tenant_id)
         VALUES ($1, $2, 'LOCAL', $3, 'PRESTADOR', $4, true, $5)
         RETURNING id`,
        [d.email, d.nombre, `demo_${d.email.split('@')[0]}`, hash, tenantId]
      );
      const id = u.rows[0].id;

      // ubicacion y estatus_verificacion son obligatorios para aparecer en el
      // listado: sin ellos el registro existe pero es invisible.
      await client.query(
        `INSERT INTO perfiles_prestador
           (id, business_name, description, estatus_verificacion, is_active,
            rating_avg, rating_count, tenant_id, ubicacion)
         VALUES ($1, $2, $3, 'APROBADO', true, $4, $5, $6,
                 ST_SetSRID(ST_MakePoint($7, $8), 4326)::geography)`,
        [id, d.negocio, d.descripcion, d.rating, d.votos, tenantId,
         CENTRO.lon + d.dLon, CENTRO.lat + d.dLat]
      );

      for (const s of d.servicios) {
        await client.query(
          `INSERT INTO services (provider_id, name, price, duration_minutes, category, tenant_id)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [id, s.nombre, s.precio, s.minutos, s.categoria, tenantId]
        );
      }
      creados++;
    }

    await client.query('COMMIT');
    console.log(`creados=${creados} saltados=${saltados}`);
  } catch (e) {
    await client.query('ROLLBACK');
    console.error('FALLÓ, nada se escribió:', e.message);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

main();
