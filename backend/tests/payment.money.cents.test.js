/**
 * backend/tests/payment.money.cents.test.js
 *
 * P0 DINERO — hallazgo t_fix_pagos_06:
 *   `paymentRoutes.js` calculaba las retenciones de dispersión (retefuente, reteica,
 *   reteiva) y el monto neto del prestador con aritmética de punto flotante
 *   (`parseFloat(...)`, `Math.round(x*100)/100`). El error de representación de los
 *   dobles hace que un redondeo "de medio centavo" caiga hacia abajo:
 *
 *     IVA = 15% de una comisión de 1.50
 *       float : 1.5 * 0.15 * 100 = 22.499999999999996 -> Math.round = 22  -> 0.22
 *       exacto: 150 centavos * 15 / 100 = 22.5            -> half-up    = 23  -> 0.23
 *
 *   Un centavo por servicio, siempre a favor del sistema, sobre cada dispersión.
 *
 * Este test ejerce el handler real POST /bookings/:id/confirm-otp contra el arnés
 * pg-mem y comprueba el MONTO PERSISTIDO en centavos enteros. Falla (rojo) mientras
 * el cálculo siga en float y pasa (verde) cuando se hace en centavos enteros.
 */
const express = require('express');
const bodyParser = require('body-parser');
const request = require('supertest');
const bcrypt = require('bcryptjs');

const { pool } = require('../src/config/db');
const paymentRoutes = require('../src/routes/paymentRoutes');

const CODIGO = '123456';

// Tablas que el harness pg-mem no declara pero que el handler de dispersión usa.
// (ver glowapp-verification/references/pgmem-harness-integration-testing.md)
const SETUP_SQL = [
  `CREATE TABLE IF NOT EXISTS platform_config (key VARCHAR(100) PRIMARY KEY, value TEXT)`,
  `CREATE TABLE IF NOT EXISTS otp_validaciones (
     id SERIAL PRIMARY KEY, booking_id VARCHAR(36) UNIQUE, codigo_hash VARCHAR(255),
     estado VARCHAR(20), expira_at TIMESTAMP, intentos_fallidos INTEGER DEFAULT 0,
     usado_at TIMESTAMP, ip_generacion VARCHAR(45))`,
  `CREATE TABLE IF NOT EXISTS provider_wallet (
     provider_id INTEGER PRIMARY KEY, saldo_disponible NUMERIC(12,2) DEFAULT 0,
     saldo_pendiente NUMERIC(12,2) DEFAULT 0, total_ganado NUMERIC(12,2) DEFAULT 0,
     updated_at TIMESTAMP DEFAULT NOW())`,
  // metadata como TEXT: pg-mem no implementa el operador `jsonb || jsonb` y el
  // handler lo usa; el tipo de la columna es irrelevante para lo que aquí se mide.
  `CREATE TABLE IF NOT EXISTS wallet_transactions (
     id SERIAL PRIMARY KEY, provider_id INTEGER, booking_id VARCHAR(36), tipo VARCHAR(30),
     monto NUMERIC(12,2), saldo_resultante NUMERIC(12,2), estado VARCHAR(20),
     descripcion TEXT, metadata TEXT DEFAULT '{}')`,
  `CREATE TABLE IF NOT EXISTS pedidos_tienda (
     id SERIAL PRIMARY KEY, booking_id VARCHAR(36), comision_total_prestador NUMERIC(12,2),
     prestador_comisionado_id INTEGER)`,
  `CREATE TABLE IF NOT EXISTS audit_log (
     id SERIAL PRIMARY KEY, actor_id INTEGER, accion VARCHAR(50), tabla VARCHAR(50),
     registro_id VARCHAR(36), datos_antes JSONB, datos_despues JSONB, ip VARCHAR(45),
     created_at TIMESTAMP DEFAULT NOW())`,
];

// `base` es el pago_neto_prestador que deja el trigger de comisión.
// `esperado` es el neto tras retenciones, calculado a mano en CENTAVOS ENTEROS:
//   neto = round(base*100) - [round(b*4.0/100) + round(b*0.414/100) + round(c*15.0/100)]
const CASOS = [
  { caso: 'IVA de medio centavo (1.50 * 15%)', providerId: 700, base: 10.00, comision: 1.50, esperado: 9.33 },
  { caso: 'IVA de medio centavo (12.50)', providerId: 701, base: 12.50, comision: 1.50, esperado: 11.72 },
  { caso: 'comisión 4.10', providerId: 702, base: 20.50, comision: 4.10, esperado: 18.98 },
  { caso: 'comisión 3.30', providerId: 703, base: 21.97, comision: 3.30, esperado: 20.50 },
  { caso: 'control exacto (sin deriva de float)', providerId: 704, base: 100.00, comision: 20.00, esperado: 92.59 },
  { caso: 'control monto grande', providerId: 705, base: 33333.33, comision: 6666.67, esperado: 30862.00 },
];

function construirApp(clientId) {
  const app = express();
  app.use(bodyParser.json());
  // authMiddleware retorna next() si req.user ya está seteado: saltamos el JWT.
  app.use((req, res, next) => {
    req.user = { id: clientId, email: 'cliente.cents@glow.test', rol: 'CLIENTE' };
    next();
  });
  app.use('/api/payments', paymentRoutes);
  return app;
}

async function confirmar({ base, comision, providerId, clientId }) {
  const bookingId = `bk_cents_${providerId}`;
  const hash = await bcrypt.hash(CODIGO, 10);

  await pool.query(
    `INSERT INTO bookings (id, client_id, provider_id, service_id, valor_bruto,
                           comision_plataforma, pago_neto_prestador, estado)
     VALUES ($1, $2, $3, 'svc-money', $4, $5, $6, 'ESPERANDO_OTP')`,
    [bookingId, clientId, providerId, Number(base) + Number(comision), comision, base]
  );
  await pool.query(
    `INSERT INTO otp_validaciones (booking_id, codigo_hash, estado, expira_at, intentos_fallidos)
     VALUES ($1, $2, 'ACTIVO', NOW() + INTERVAL '45 minutes', 0)`,
    [bookingId, hash]
  );

  const res = await request(construirApp(clientId))
    .post(`/api/payments/bookings/${bookingId}/confirm-otp`)
    .send({ codigo: CODIGO });

  const wallet = await pool.query(
    'SELECT saldo_pendiente, total_ganado FROM provider_wallet WHERE provider_id = $1',
    [providerId]
  );
  const tx = await pool.query(
    `SELECT monto FROM wallet_transactions
     WHERE booking_id = $1 AND tipo = 'CREDITO_SERVICIO'`,
    [bookingId]
  );

  return { res, wallet: wallet.rows[0], tx: tx.rows[0] };
}

describe('P0 dinero — dispersión en centavos enteros (confirm-otp)', () => {
  beforeAll(async () => {
    for (const sql of SETUP_SQL) {
      await pool.query(sql);
    }
    await pool.query('ALTER TABLE bookings ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20)');
  });

  test.each(CASOS)('$caso: neto exacto en centavos', async ({ caso, providerId, base, comision, esperado }) => {
    const clientId = 5;
    const { res, wallet, tx } = await confirmar({ base, comision, providerId, clientId });

    expect(res.status).toBe(200);
    expect(res.body.ok).toBe(true);

    // El monto devuelto, el saldo y la transacción deben coincidir con el
    // resultado exacto en centavos (sin centavo perdido por float).
    expect(res.body.monto_neto_prestador).toBe(esperado);
    expect(Number(wallet.saldo_pendiente)).toBe(esperado);
    expect(Number(tx.monto)).toBe(esperado);

    // Todo monto persistido debe ser un valor exacto de 2 decimales.
    const centavos = Number(tx.monto) * 100;
    expect(Math.abs(centavos - Math.round(centavos))).toBeLessThan(1e-6);
  });

  test('un centavo no se pierde: neto == base - retenciones exactas (caso 10.00 / 1.50)', async () => {
    const { res } = await confirmar({ base: 10.00, comision: 1.50, providerId: 799, clientId: 5 });

    // En centavos enteros: 1000 - (40 + 4 + 23) = 933  =>  9.33
    expect(res.body.monto_neto_prestador).toBe(9.33);
    // El bug de float devolvía 9.34 (23 se redondeaba a 22 -> menos retención).
    expect(res.body.monto_neto_prestador).not.toBe(9.34);
  });

  test('utilidad money: aritmética de centavos sin deriva de float', () => {
    // La utilidad solo existe tras el fix; el require va dentro del test para que
    // el rojo de las pruebas de arriba sea por el bug y no por el import.
    const money = require('../src/utils/money');

    expect(money.aCentavos('1.50')).toBe(150);
    expect(money.aCentavos(10.00)).toBe(1000);
    expect(money.aCentavos(null)).toBe(0);
    expect(money.aCentavos('')).toBe(0);

    // 22.5 centavos -> 23 (half-up), no 22 como con float
    expect(money.porcentajeCentavos(150, 15.0)).toBe(23);
    expect(money.porcentajeCentavos(1000, 0.414)).toBe(4);
    expect(money.porcentajeCentavos(1000, 4.0)).toBe(40);

    const r = money.aplicarRetencionesCentavos({
      baseCentavos: 1000, comisionCentavos: 150,
      pctFuente: 4.0, pctIca: 0.414, pctIva: 15.0,
    });
    expect(r.fuenteCentavos).toBe(40);
    expect(r.icaCentavos).toBe(4);
    expect(r.ivaCentavos).toBe(23);
    expect(r.totalCentavos).toBe(67);
    expect(r.netoCentavos).toBe(933);
    expect(money.aDecimal(933)).toBe(9.33);
  });
});
