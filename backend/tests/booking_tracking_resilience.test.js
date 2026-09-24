// backend/tests/booking_tracking_resilience.test.js
const { pool } = require('../src/config/db');
const WebSocket = require('ws');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

const JWT_SECRET = process.env.JWT_SECRET || 'beauty_app_super_secret_key_2026_change_in_production';
const PORT = process.env.PORT || 8080;
const WS_URL = `ws://localhost:${PORT}/chat`;

function createWsClient() {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(WS_URL);
    ws.on('open', () => resolve(ws));
    ws.on('error', reject);
  });
}

function sendAndListen(ws, payload, filterFn, timeoutMs = 4000) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      ws.off('message', handler);
      reject(new Error(`Timeout waiting for message matching condition. Payload sent: ${JSON.stringify(payload)}`));
    }, timeoutMs);

    function handler(raw) {
      try {
        const msg = JSON.parse(raw.toString());
        if (filterFn(msg)) {
          clearTimeout(timer);
          ws.off('message', handler);
          resolve(msg);
        }
      } catch (err) {
        // ignore
      }
    }

    ws.on('message', handler);
    ws.send(JSON.stringify(payload));
  });
}

describe('N02-R2 — Canonical B2C Tracking Resilience & Security Test Suite', () => {
  let clientId, providerId, outsiderClientId, otherProviderId;
  let clientToken, providerToken, outsiderClientToken, otherProviderToken;
  let serviceId, bookingConfirmadaId, bookingEnProgresoId, bookingCompletadaId, bookingCanceladaId;

  beforeAll(async () => {
    // 1. Identificar/Crear usuarios de prueba
    const clientRes = await pool.query(`SELECT id FROM usuarios WHERE rol = 'CLIENTE' LIMIT 1;`);
    clientId = clientRes.rows[0]?.id || 1;
    clientToken = jwt.sign({ id: clientId, rol: 'CLIENTE' }, JWT_SECRET);

    const provRes = await pool.query(`SELECT id FROM perfiles_prestador LIMIT 1;`);
    providerId = provRes.rows[0]?.id || 2;
    providerToken = jwt.sign({ id: providerId, rol: 'PRESTADOR' }, JWT_SECRET);

    // Usuario cliente foráneo
    const outRes = await pool.query(
      `INSERT INTO usuarios (nombre, email, password_hash, rol) 
       VALUES ('Outsider Client N02', 'outsider_${Date.now()}@test.com', 'hash123', 'CLIENTE')
       RETURNING id`
    );
    outsiderClientId = outRes.rows[0].id;
    outsiderClientToken = jwt.sign({ id: outsiderClientId, rol: 'CLIENTE' }, JWT_SECRET);

    // Prestador foráneo
    const otherProvRes = await pool.query(
      `INSERT INTO usuarios (nombre, email, password_hash, rol) 
       VALUES ('Other Prov N02', 'otherprov_${Date.now()}@test.com', 'hash123', 'PRESTADOR')
       RETURNING id`
    );
    otherProviderId = otherProvRes.rows[0].id;
    otherProviderToken = jwt.sign({ id: otherProviderId, rol: 'PRESTADOR' }, JWT_SECRET);

    await pool.query(
      `INSERT INTO perfiles_prestador (id, business_name, is_online, is_active)
       VALUES ($1, 'Other Prov Studio', true, true)
       ON CONFLICT (id) DO NOTHING`,
      [otherProviderId]
    );

    const srvRes = await pool.query(`SELECT id FROM services WHERE provider_id = $1 LIMIT 1;`, [providerId]);
    serviceId = srvRes.rows[0]?.id;
    if (!serviceId) {
      const anySrv = await pool.query(`SELECT id FROM services LIMIT 1;`);
      serviceId = anySrv.rows[0].id;
    }

    // 2. Crear reservas de prueba para cada estado
    bookingConfirmadaId = crypto.randomUUID();
    await pool.query(
      `INSERT INTO bookings (id, client_id, provider_id, service_id, scheduled_at, estado, valor_bruto, paid_at)
       VALUES ($1, $2, $3, $4, NOW() + INTERVAL '2 hours', 'CONFIRMADA', 50000, NOW())`,
      [bookingConfirmadaId, clientId, providerId, serviceId]
    );

    bookingEnProgresoId = crypto.randomUUID();
    await pool.query(
      `INSERT INTO bookings (id, client_id, provider_id, service_id, scheduled_at, estado, valor_bruto, paid_at)
       VALUES ($1, $2, $3, $4, NOW() + INTERVAL '1 hour', 'EN_PROGRESO', 50000, NOW())`,
      [bookingEnProgresoId, clientId, providerId, serviceId]
    );

    bookingCompletadaId = crypto.randomUUID();
    await pool.query(
      `INSERT INTO bookings (id, client_id, provider_id, service_id, scheduled_at, estado, valor_bruto, paid_at)
       VALUES ($1, $2, $3, $4, NOW() - INTERVAL '1 hour', 'COMPLETADA', 50000, NOW() - INTERVAL '2 hours')`,
      [bookingCompletadaId, clientId, providerId, serviceId]
    );

    bookingCanceladaId = crypto.randomUUID();
    await pool.query(
      `INSERT INTO bookings (id, client_id, provider_id, service_id, scheduled_at, estado, valor_bruto, paid_at)
       VALUES ($1, $2, $3, $4, NOW() - INTERVAL '1 hour', 'CANCELADA', 50000, NOW() - INTERVAL '2 hours')`,
      [bookingCanceladaId, clientId, providerId, serviceId]
    );
  });

  afterAll(async () => {
    const ids = [bookingConfirmadaId, bookingEnProgresoId, bookingCompletadaId, bookingCanceladaId].filter(Boolean);
    if (ids.length > 0) {
      await pool.query(`DELETE FROM booking_tracking_logs WHERE booking_id = ANY($1::uuid[])`, [ids]);
      await pool.query(`DELETE FROM bookings WHERE id = ANY($1::uuid[])`, [ids]);
    }
    if (otherProviderId) {
      await pool.query(`DELETE FROM perfiles_prestador WHERE id = $1`, [otherProviderId]);
    }
    if (outsiderClientId || otherProviderId) {
      await pool.query(`DELETE FROM usuarios WHERE id IN ($1, $2)`, [outsiderClientId, otherProviderId]);
    }
    await pool.end();
  });

  // =========================================================================
  // 1. SEGURIDAD & AUTORIZACIÓN DE SALAS
  // =========================================================================
  describe('1. Seguridad y Autorización de Salas', () => {
    test('1.1: Socket sin register/JWT es rechazado con 403 UNAUTHORIZED', async () => {
      const ws = await createWsClient();
      try {
        const res = await sendAndListen(
          ws,
          { type: 'join_booking_room', bookingId: bookingConfirmadaId, role: 'client' },
          (m) => m.type === 'error' && m.code === 403
        );
        expect(res.error).toBe('UNAUTHORIZED');
      } finally {
        ws.close();
      }
    });

    test('1.2: Cliente propietario de la reserva se une exitosamente', async () => {
      const ws = await createWsClient();
      try {
        ws.send(JSON.stringify({ type: 'register', token: clientToken }));
        await new Promise((r) => setTimeout(r, 150));
        const res = await sendAndListen(
          ws,
          { type: 'join_booking_room', bookingId: bookingConfirmadaId, role: 'client' },
          (m) => m.type === 'joined_booking_room'
        );
        expect(res.bookingId).toBe(bookingConfirmadaId.toString());
        expect(res.role).toBe('client');
      } finally {
        ws.close();
      }
    });

    test('1.3: Prestador asignado a la reserva se une exitosamente', async () => {
      const ws = await createWsClient();
      try {
        ws.send(JSON.stringify({ type: 'register', token: providerToken }));
        await new Promise((r) => setTimeout(r, 150));
        const res = await sendAndListen(
          ws,
          { type: 'join_booking_room', bookingId: bookingConfirmadaId, role: 'provider' },
          (m) => m.type === 'joined_booking_room'
        );
        expect(res.bookingId).toBe(bookingConfirmadaId.toString());
        expect(res.role).toBe('provider');
      } finally {
        ws.close();
      }
    });

    test('1.4: Cliente de otra reserva es rechazado con 403 FORBIDDEN', async () => {
      const ws = await createWsClient();
      try {
        ws.send(JSON.stringify({ type: 'register', token: outsiderClientToken }));
        await new Promise((r) => setTimeout(r, 150));
        const res = await sendAndListen(
          ws,
          { type: 'join_booking_room', bookingId: bookingConfirmadaId, role: 'client' },
          (m) => m.type === 'error' && m.code === 403
        );
        expect(res.error).toBe('FORBIDDEN');
      } finally {
        ws.close();
      }
    });

    test('1.5: Prestador de otra reserva es rechazado con 403 FORBIDDEN', async () => {
      const ws = await createWsClient();
      try {
        ws.send(JSON.stringify({ type: 'register', token: otherProviderToken }));
        await new Promise((r) => setTimeout(r, 150));
        const res = await sendAndListen(
          ws,
          { type: 'join_booking_room', bookingId: bookingConfirmadaId, role: 'provider' },
          (m) => m.type === 'error' && m.code === 403
        );
        expect(res.error).toBe('FORBIDDEN');
      } finally {
        ws.close();
      }
    });
  });

  // =========================================================================
  // 2. MÁQUINA DE ESTADOS & TRACKING
  // =========================================================================
  describe('2. Máquina de Estados & Restricciones de Tracking', () => {
    test('2.1: CONFIRMADA permite tracking', async () => {
      const ws = await createWsClient();
      try {
        ws.send(JSON.stringify({ type: 'register', token: providerToken }));
        await new Promise((r) => setTimeout(r, 150));
        const res = await sendAndListen(
          ws,
          { type: 'join_booking_room', bookingId: bookingConfirmadaId, role: 'provider' },
          (m) => m.type === 'joined_booking_room'
        );
        expect(res.estado).toBe('CONFIRMADA');
      } finally {
        ws.close();
      }
    });

    test('2.2: EN_PROGRESO permite tracking según contrato existente', async () => {
      const ws = await createWsClient();
      try {
        ws.send(JSON.stringify({ type: 'register', token: providerToken }));
        await new Promise((r) => setTimeout(r, 150));
        const res = await sendAndListen(
          ws,
          { type: 'join_booking_room', bookingId: bookingEnProgresoId, role: 'provider' },
          (m) => m.type === 'joined_booking_room'
        );
        expect(res.estado).toBe('EN_PROGRESO');
      } finally {
        ws.close();
      }
    });

    test('2.3: COMPLETADA rechaza realtime con tracking_ended', async () => {
      const ws = await createWsClient();
      try {
        ws.send(JSON.stringify({ type: 'register', token: providerToken }));
        await new Promise((r) => setTimeout(r, 150));
        const res = await sendAndListen(
          ws,
          { type: 'join_booking_room', bookingId: bookingCompletadaId, role: 'provider' },
          (m) => m.type === 'tracking_ended'
        );
        expect(res.estado).toBe('COMPLETADA');
      } finally {
        ws.close();
      }
    });

    test('2.4: CANCELADA rechaza realtime con tracking_ended', async () => {
      const ws = await createWsClient();
      try {
        ws.send(JSON.stringify({ type: 'register', token: providerToken }));
        await new Promise((r) => setTimeout(r, 150));
        const res = await sendAndListen(
          ws,
          { type: 'join_booking_room', bookingId: bookingCanceladaId, role: 'provider' },
          (m) => m.type === 'tracking_ended'
        );
        expect(res.estado).toBe('CANCELADA');
      } finally {
        ws.close();
      }
    });
  });

  // =========================================================================
  // 3. TEMPORALIDAD COMPLETA & REGLA CANÓNICA >30s
  // =========================================================================
  describe('3. Temporalidad Completa & Staleness', () => {
    let wsProv, wsClient;

    beforeEach(async () => {
      wsProv = await createWsClient();
      wsClient = await createWsClient();

      wsProv.send(JSON.stringify({ type: 'register', token: providerToken }));
      wsClient.send(JSON.stringify({ type: 'register', token: clientToken }));
      await new Promise((r) => setTimeout(r, 150));

      await sendAndListen(wsProv, { type: 'join_booking_room', bookingId: bookingConfirmadaId, role: 'provider' }, m => m.type === 'joined_booking_room');
      await sendAndListen(wsClient, { type: 'join_booking_room', bookingId: bookingConfirmadaId, role: 'client' }, m => m.type === 'joined_booking_room');
    });

    afterEach(() => {
      wsProv.close();
      wsClient.close();
    });

    test('3.1: T <= 15s -> LIVE (is_stale: false)', async () => {
      const captured = new Date(Date.now() - 10000); // 10s old
      let clientMsg = null;
      wsClient.on('message', raw => {
        const m = JSON.parse(raw.toString());
        if (m.type === 'location_received') clientMsg = m;
      });

      const ack = await sendAndListen(
        wsProv,
        {
          type: 'location_update',
          bookingId: bookingConfirmadaId,
          latitude: 4.6735,
          longitude: -74.1422,
          accuracy: 10,
          captured_at: captured.toISOString()
        },
        m => m.type === 'location_ack'
      );
      expect(ack.status).toBe('ACCEPTED');
      await new Promise(r => setTimeout(r, 100));
      expect(clientMsg).toBeDefined();
      expect(clientMsg.is_stale).toBe(false);
    });

    test('3.2: T justo bajo el umbral (14.5s) -> LIVE (is_stale: false)', async () => {
      const captured = new Date(Date.now() - 14500); // 14.5s old
      let clientMsg = null;
      wsClient.on('message', raw => {
        const m = JSON.parse(raw.toString());
        if (m.type === 'location_received') clientMsg = m;
      });

      const ack = await sendAndListen(
        wsProv,
        {
          type: 'location_update',
          bookingId: bookingConfirmadaId,
          latitude: 4.6736,
          longitude: -74.1423,
          accuracy: 10,
          captured_at: captured.toISOString()
        },
        m => m.type === 'location_ack'
      );
      expect(ack.status).toBe('ACCEPTED');
      await new Promise(r => setTimeout(r, 100));
      expect(clientMsg).toBeDefined();
      expect(clientMsg.is_stale).toBe(false);
    });

    test('3.3: T justo sobre el umbral (16.0s) -> STALE (is_stale: true)', async () => {
      const captured = new Date(Date.now() - 16000); // 16s old
      let clientMsg = null;
      wsClient.on('message', raw => {
        const m = JSON.parse(raw.toString());
        if (m.type === 'location_received') clientMsg = m;
      });

      const ack = await sendAndListen(
        wsProv,
        {
          type: 'location_update',
          bookingId: bookingConfirmadaId,
          latitude: 4.6737,
          longitude: -74.1424,
          accuracy: 10,
          captured_at: captured.toISOString()
        },
        m => m.type === 'location_ack'
      );
      expect(ack.status).toBe('ACCEPTED');
      await new Promise(r => setTimeout(r, 100));
      expect(clientMsg).toBeDefined();
      expect(clientMsg.is_stale).toBe(true);
    });

    test('3.4: T dentro del rango stale (25.0s) -> STALE (is_stale: true)', async () => {
      const captured = new Date(Date.now() - 25000); // 25s old
      let clientMsg = null;
      wsClient.on('message', raw => {
        const m = JSON.parse(raw.toString());
        if (m.type === 'location_received') clientMsg = m;
      });

      const ack = await sendAndListen(
        wsProv,
        {
          type: 'location_update',
          bookingId: bookingConfirmadaId,
          latitude: 4.6738,
          longitude: -74.1425,
          accuracy: 10,
          captured_at: captured.toISOString()
        },
        m => m.type === 'location_ack'
      );
      expect(ack.status).toBe('ACCEPTED');
      await new Promise(r => setTimeout(r, 100));
      expect(clientMsg).toBeDefined();
      expect(clientMsg.is_stale).toBe(true);
    });

    test('3.5: T > 30s (35.0s) -> REJECTED_LIVE (Rechazo explícito, NO emitido como LIVE, NO en DB)', async () => {
      const captured = new Date(Date.now() - 35000); // 35s old
      let clientReceived = false;
      wsClient.on('message', raw => {
        const m = JSON.parse(raw.toString());
        if (m.type === 'location_received') clientReceived = true;
      });

      const rej = await sendAndListen(
        wsProv,
        {
          type: 'location_update',
          bookingId: bookingConfirmadaId,
          latitude: 4.6739,
          longitude: -74.1426,
          accuracy: 10,
          captured_at: captured.toISOString()
        },
        m => m.type === 'location_rejected'
      );
      expect(rej.code).toBe('REJECTED_LIVE');
      expect(clientReceived).toBe(false);
    });
  });

  // =========================================================================
  // 4. MONOTONICIDAD / OUT OF ORDER
  // =========================================================================
  describe('4. Monotonicidad / Out of Order', () => {
    let wsProv;

    beforeEach(async () => {
      wsProv = await createWsClient();
      wsProv.send(JSON.stringify({ type: 'register', token: providerToken }));
      await new Promise((r) => setTimeout(r, 150));
      await sendAndListen(wsProv, { type: 'join_booking_room', bookingId: bookingConfirmadaId, role: 'provider' }, m => m.type === 'joined_booking_room');
    });

    afterEach(() => {
      wsProv.close();
    });

    test('4.1: Secuencia 10:00:10 (ACCEPT) -> 10:00:09 (REJECTED_OUT_OF_ORDER) -> 10:00:10 (REJECTED_OUT_OF_ORDER)', async () => {
      const baseTime = Date.now() - 5000;
      const t10 = new Date(baseTime).toISOString();
      const t09 = new Date(baseTime - 1000).toISOString();

      // 1. First point at t10 -> ACCEPT
      const ack1 = await sendAndListen(
        wsProv,
        {
          type: 'location_update',
          bookingId: bookingConfirmadaId,
          latitude: 4.6740,
          longitude: -74.1420,
          accuracy: 15,
          captured_at: t10
        },
        m => m.type === 'location_ack'
      );
      expect(ack1.status).toBe('ACCEPTED');

      // 2. Second point at t09 (< t10) -> REJECTED_OUT_OF_ORDER
      const rej1 = await sendAndListen(
        wsProv,
        {
          type: 'location_update',
          bookingId: bookingConfirmadaId,
          latitude: 4.6741,
          longitude: -74.1421,
          accuracy: 15,
          captured_at: t09
        },
        m => m.type === 'location_rejected'
      );
      expect(rej1.code).toBe('REJECTED_OUT_OF_ORDER');

      // 3. Third point duplicate timestamp t10 (<= lastCapturedAt) -> REJECTED_OUT_OF_ORDER
      const rej2 = await sendAndListen(
        wsProv,
        {
          type: 'location_update',
          bookingId: bookingConfirmadaId,
          latitude: 4.6742,
          longitude: -74.1422,
          accuracy: 15,
          captured_at: t10
        },
        m => m.type === 'location_rejected'
      );
      expect(rej2.code).toBe('REJECTED_OUT_OF_ORDER');
    });
  });

  // =========================================================================
  // 5. ACCURACY COMPLETA (35m y 100m)
  // =========================================================================
  describe('5. Filtros de Precisión GPS (Accuracy)', () => {
    let wsProv;

    beforeEach(async () => {
      wsProv = await createWsClient();
      wsProv.send(JSON.stringify({ type: 'register', token: providerToken }));
      await new Promise((r) => setTimeout(r, 150));
      await sendAndListen(wsProv, { type: 'join_booking_room', bookingId: bookingConfirmadaId, role: 'provider' }, m => m.type === 'joined_booking_room');
    });

    afterEach(() => {
      wsProv.close();
    });

    test('5.1: 35.00m -> ACCEPT (status: ACCEPTED)', async () => {
      const ack = await sendAndListen(
        wsProv,
        {
          type: 'location_update',
          bookingId: bookingConfirmadaId,
          latitude: 4.6745,
          longitude: -74.1415,
          accuracy: 35.00,
          captured_at: new Date().toISOString()
        },
        m => m.type === 'location_ack'
      );
      expect(ack.status).toBe('ACCEPTED');
    });

    test('5.2: 35.01m -> LOW_ACCURACY (status: LOW_ACCURACY)', async () => {
      const ack = await sendAndListen(
        wsProv,
        {
          type: 'location_update',
          bookingId: bookingConfirmadaId,
          latitude: 4.6746,
          longitude: -74.1416,
          accuracy: 35.01,
          captured_at: new Date().toISOString()
        },
        m => m.type === 'location_ack'
      );
      expect(ack.status).toBe('LOW_ACCURACY');
    });

    test('5.3: 100.00m -> LOW_ACCURACY (status: LOW_ACCURACY)', async () => {
      const ack = await sendAndListen(
        wsProv,
        {
          type: 'location_update',
          bookingId: bookingConfirmadaId,
          latitude: 4.6747,
          longitude: -74.1417,
          accuracy: 100.00,
          captured_at: new Date().toISOString()
        },
        m => m.type === 'location_ack'
      );
      expect(ack.status).toBe('LOW_ACCURACY');
    });

    test('5.4: 100.01m -> REJECT (code: LOW_ACCURACY_REJECTED)', async () => {
      const rej = await sendAndListen(
        wsProv,
        {
          type: 'location_update',
          bookingId: bookingConfirmadaId,
          latitude: 4.6748,
          longitude: -74.1418,
          accuracy: 100.01,
          captured_at: new Date().toISOString()
        },
        m => m.type === 'location_rejected'
      );
      expect(rej.code).toBe('LOW_ACCURACY_REJECTED');
    });
  });

  // =========================================================================
  // 6. OFFLINE BUFFER SYNC & RECONEXIÓN
  // =========================================================================
  describe('6. Offline Buffer Sync & Flujo de Reconexión', () => {
    test('6.1: Sincronización de buffer vacío retorna synced_count: 0', async () => {
      const wsProv = await createWsClient();
      try {
        wsProv.send(JSON.stringify({ type: 'register', token: providerToken }));
        await new Promise((r) => setTimeout(r, 150));
        await sendAndListen(wsProv, { type: 'join_booking_room', bookingId: bookingConfirmadaId, role: 'provider' }, m => m.type === 'joined_booking_room');

        const res = await sendAndListen(
          wsProv,
          {
            type: 'sync_offline_locations',
            bookingId: bookingConfirmadaId,
            locations: []
          },
          m => m.type === 'sync_offline_ack'
        );
        expect(res.synced_count).toBe(0);
        expect(res.status).toBe('HISTORICAL');
      } finally {
        wsProv.close();
      }
    });

    test('6.2: Sincronización de buffer de 51 puntos se limita a máximo 50', async () => {
      const wsProv = await createWsClient();
      try {
        wsProv.send(JSON.stringify({ type: 'register', token: providerToken }));
        await new Promise((r) => setTimeout(r, 150));
        await sendAndListen(wsProv, { type: 'join_booking_room', bookingId: bookingConfirmadaId, role: 'provider' }, m => m.type === 'joined_booking_room');

        const points51 = [];
        for (let i = 0; i < 51; i++) {
          points51.push({
            latitude: 4.6700 + (i * 0.0001),
            longitude: -74.1400 - (i * 0.0001),
            accuracy: 12,
            captured_at: new Date(Date.now() - (60000 + i * 1000)).toISOString()
          });
        }

        const res = await sendAndListen(
          wsProv,
          {
            type: 'sync_offline_locations',
            bookingId: bookingConfirmadaId,
            locations: points51
          },
          m => m.type === 'sync_offline_ack'
        );
        expect(res.synced_count).toBe(50);
      } finally {
        wsProv.close();
      }
    });

    test('6.3: Flujo Completo: Desconexión -> Buffer Offline -> Reconexión (register -> join -> sync -> realtime)', async () => {
      // Cliente escuchando en sala
      const wsClient = await createWsClient();
      wsClient.send(JSON.stringify({ type: 'register', token: clientToken }));
      await new Promise((r) => setTimeout(r, 150));
      await sendAndListen(wsClient, { type: 'join_booking_room', bookingId: bookingConfirmadaId, role: 'client' }, m => m.type === 'joined_booking_room');

      let clientReceivedLive = null;
      wsClient.on('message', raw => {
        const m = JSON.parse(raw.toString());
        if (m.type === 'location_received') clientReceivedLive = m;
      });

      // 1. Prestador se reconecta
      const wsProv = await createWsClient();
      wsProv.send(JSON.stringify({ type: 'register', token: providerToken }));
      await new Promise((r) => setTimeout(r, 150));
      await sendAndListen(wsProv, { type: 'join_booking_room', bookingId: bookingConfirmadaId, role: 'provider' }, m => m.type === 'joined_booking_room');

      // 2. Sincroniza buffer offline
      const buffer = [
        { latitude: 4.6751, longitude: -74.1351, accuracy: 10, captured_at: new Date(Date.now() - 50000).toISOString() },
        { latitude: 4.6752, longitude: -74.1352, accuracy: 10, captured_at: new Date(Date.now() - 40000).toISOString() }
      ];

      const syncAck = await sendAndListen(
        wsProv,
        { type: 'sync_offline_locations', bookingId: bookingConfirmadaId, locations: buffer },
        m => m.type === 'sync_offline_ack'
      );
      expect(syncAck.synced_count).toBe(2);

      // Verificar que el sync histórico NO envió evento realtime al cliente
      expect(clientReceivedLive).toBeNull();

      // 3. Retorno a Realtime
      const liveAck = await sendAndListen(
        wsProv,
        {
          type: 'location_update',
          bookingId: bookingConfirmadaId,
          latitude: 4.6755,
          longitude: -74.1355,
          accuracy: 10,
          captured_at: new Date().toISOString()
        },
        m => m.type === 'location_ack'
      );
      expect(liveAck.status).toBe('ACCEPTED');

      // Verificar que el cliente ahora sí recibe el realtime
      await new Promise(r => setTimeout(r, 150));
      expect(clientReceivedLive).toBeDefined();
      expect(clientReceivedLive.latitude).toBe(4.6755);

      wsClient.close();
      wsProv.close();
    });
  });

  // =========================================================================
  // 7. RETENTION REAL (COUNT ANTES Y DESPUÉS)
  // =========================================================================
  describe('7. Retención Real de Telemetría (30 Días)', () => {
    test('7.1: Purga controlada elimina registros > 30 días y preserva < 30 días', async () => {
      // 1. Limpiar fixtures previos de retención
      await pool.query(`DELETE FROM booking_tracking_logs WHERE booking_id = $1`, [bookingConfirmadaId]);

      // 2. Insertar 3 registros controlados
      // Log 1: 31 días atrás (debe eliminarse)
      await pool.query(
        `INSERT INTO booking_tracking_logs (booking_id, provider_id, location, accuracy_meters, captured_at, created_at)
         VALUES ($1, $2, ST_SetSRID(ST_MakePoint(-74.1422, 4.6735), 4326)::geography, 10, NOW() - INTERVAL '31 days', NOW() - INTERVAL '31 days')`,
        [bookingConfirmadaId, providerId]
      );

      // Log 2: 29 días atrás (debe conservarse)
      await pool.query(
        `INSERT INTO booking_tracking_logs (booking_id, provider_id, location, accuracy_meters, captured_at, created_at)
         VALUES ($1, $2, ST_SetSRID(ST_MakePoint(-74.1422, 4.6735), 4326)::geography, 10, NOW() - INTERVAL '29 days', NOW() - INTERVAL '29 days')`,
        [bookingConfirmadaId, providerId]
      );

      // Log 3: Hoy (debe conservarse)
      await pool.query(
        `INSERT INTO booking_tracking_logs (booking_id, provider_id, location, accuracy_meters, captured_at, created_at)
         VALUES ($1, $2, ST_SetSRID(ST_MakePoint(-74.1422, 4.6735), 4326)::geography, 10, NOW(), NOW())`,
        [bookingConfirmadaId, providerId]
      );

      // Count ANTES
      const countBefore = await pool.query(
        `SELECT COUNT(*)::int as total FROM booking_tracking_logs WHERE booking_id = $1`,
        [bookingConfirmadaId]
      );
      expect(countBefore.rows[0].total).toBe(3);

      // 3. Ejecutar purga de retención canónica
      const deleteResult = await pool.query(
        `DELETE FROM booking_tracking_logs WHERE created_at < NOW() - INTERVAL '30 days'`
      );
      expect(deleteResult.rowCount).toBeGreaterThanOrEqual(1);

      // Count DESPUÉS
      const countAfter = await pool.query(
        `SELECT COUNT(*)::int as total FROM booking_tracking_logs WHERE booking_id = $1`,
        [bookingConfirmadaId]
      );
      expect(countAfter.rows[0].total).toBe(2);
    });
  });
});
