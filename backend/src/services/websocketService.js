// backend/src/services/websocketService.js
const { WebSocketServer } = require('ws');
const { pool } = require('../config/db');
const jwt = require('jsonwebtoken');
const { getJwtSecret } = require('../config/jwt');

let wss = null;
const wsClients = new Map(); // userId -> Set of WS connections

const registerClient = (userId, ws) => {
  const userIdStr = userId.toString();
  if (!wsClients.has(userIdStr)) {
    wsClients.set(userIdStr, new Set());
  }
  wsClients.get(userIdStr).add(ws);
  console.log(`👤 Conexión WS registrada para usuario: ${userIdStr}`);
};

const unregisterClient = (ws) => {
  for (const [userId, connSet] of wsClients.entries()) {
    if (connSet.has(ws)) {
      connSet.delete(ws);
      if (connSet.size === 0) wsClients.delete(userId);
      console.log(`🔌 Conexión WS removida para usuario: ${userId}`);
      break;
    }
  }
};

const notifyUserChatMessage = (userId, messageData) => {
  const userIdStr = userId.toString();
  if (wsClients.has(userIdStr)) {
    const payload = JSON.stringify({
      type: 'chat_message',
      data: messageData
    });
    for (const conn of wsClients.get(userIdStr)) {
      if (conn.readyState === 1) { // OPEN
        conn.send(payload);
      }
    }
  }
};

const notifyUserAuraStatus = (userId, statusData) => {
  const userIdStr = userId.toString();
  if (wsClients.has(userIdStr)) {
    const payload = JSON.stringify({
      type: 'aura_status',
      data: statusData
    });
    for (const conn of wsClients.get(userIdStr)) {
      if (conn.readyState === 1) { // OPEN
        conn.send(payload);
      }
    }
  }
};

const initWebSocketServer = (server) => {
  wss = new WebSocketServer({ server });
  
  wss.on('connection', (ws) => {
    console.log('🔌 Nuevo cliente WebSocket conectado.');
    
    ws.on('message', (message) => {
      try {
        const data = JSON.parse(message);
        if (data.type === 'register') {
          if (data.token) {
            try {
              const decoded = jwt.verify(data.token, getJwtSecret());
              const verifiedUserId = decoded.id;
              ws.userId = verifiedUserId;
              registerClient(verifiedUserId, ws);
              ws.send(JSON.stringify({ status: 'registered', userId: verifiedUserId.toString() }));
            } catch (jwtErr) {
              console.error('WebSocket JWT verification failed:', jwtErr.message);
              ws.send(JSON.stringify({ type: 'error', code: 401, error: 'Token inválido o expirado' }));
            }
          } else if (data.userId) {
            console.warn(`⚠️ WebSocket registrado por ID plano (sin token) para pruebas. Usuario: ${data.userId}`);
            ws.userId = parseInt(data.userId);
            registerClient(data.userId, ws);
            ws.send(JSON.stringify({ status: 'registered', userId: data.userId.toString(), warning: 'No token verification' }));
          }
        }
        // =====================================================================
        // 🔹 N02 TRACKING RESILIENCE & SECURITY: SALAS Y TELEMETRÍA
        // =====================================================================
        if (data.type === 'join_booking_room' && data.bookingId) {
          if (!ws.userId) {
            ws.send(JSON.stringify({ type: 'error', code: 403, error: 'UNAUTHORIZED' }));
            return;
          }

          // Validar existencia y ownership en PostgreSQL
          pool.query(
            'SELECT id, client_id, provider_id, estado FROM public.bookings WHERE id = $1',
            [data.bookingId]
          ).then(({ rows }) => {
            if (rows.length === 0) {
              ws.send(JSON.stringify({ type: 'error', code: 404, error: 'BOOKING_NOT_FOUND' }));
              return;
            }

            const booking = rows[0];
            const isClient = booking.client_id === ws.userId;
            const isProvider = booking.provider_id === ws.userId;

            if (!isClient && !isProvider) {
              console.warn(`🚨 [SECURITY] Intento no autorizado a tracking: Usuario ${ws.userId} intentó unirse a booking ${data.bookingId}`);
              ws.send(JSON.stringify({ type: 'error', code: 403, error: 'FORBIDDEN' }));
              return;
            }

            if (booking.estado === 'COMPLETADA' || booking.estado === 'CANCELADA') {
              ws.send(JSON.stringify({ type: 'tracking_ended', estado: booking.estado, message: 'El servicio ha finalizado o fue cancelado' }));
              return;
            }

            ws.bookingId = data.bookingId;
            ws.role = isProvider ? 'provider' : 'client';
            ws.lastCapturedAt = null;

            console.log(`📡 [TRACKING SECURE] Socket autenticado (User ${ws.userId}, Rol ${ws.role}) unido a booking_${data.bookingId}`);
            ws.send(JSON.stringify({ 
              type: 'joined_booking_room', 
              bookingId: data.bookingId.toString(), 
              role: ws.role,
              estado: booking.estado 
            }));
          }).catch(err => {
            console.error('Error validando booking room:', err.message);
            ws.send(JSON.stringify({ type: 'error', code: 500, error: 'INTERNAL_ERROR' }));
          });
        }

        // Transmisión en Tiempo Real (Live Location)
        if (data.type === 'location_update' && data.bookingId) {
          if (!ws.userId || ws.role !== 'provider' || ws.bookingId !== data.bookingId.toString()) {
            ws.send(JSON.stringify({ type: 'error', code: 403, error: 'FORBIDDEN' }));
            return;
          }

          const lat = parseFloat(data.latitude ?? data.lat);
          const lon = parseFloat(data.longitude ?? data.lon);
          const accuracy = parseFloat(data.accuracy_meters ?? data.accuracy ?? 10.0);
          const capturedAt = data.captured_at ? new Date(data.captured_at) : new Date();
          const now = new Date();

          // 1. Validaciones Geográficas
          if (isNaN(lat) || lat < -90 || lat > 90 || isNaN(lon) || lon < -180 || lon > 180) {
            ws.send(JSON.stringify({ type: 'location_rejected', code: 'INVALID_LOCATION', error: 'INVALID_LOCATION' }));
            return;
          }

          // 2. Validación de Accuracy: > 100m REJECT
          if (accuracy > 100.0) {
            ws.send(JSON.stringify({ type: 'location_rejected', code: 'LOW_ACCURACY_REJECTED', error: 'LOW_ACCURACY_REJECTED' }));
            return;
          }

          // 3. Validación de Timestamp Futuro (> NOW() + 5s)
          if (capturedAt.getTime() > now.getTime() + 5000) {
            ws.send(JSON.stringify({ type: 'location_rejected', code: 'FUTURE_TIMESTAMP', error: 'FUTURE_TIMESTAMP' }));
            return;
          }

          // 4. Validación de Monotonicidad / Out-of-Order (<= lastCapturedAt)
          if (ws.lastCapturedAt && capturedAt.getTime() <= ws.lastCapturedAt.getTime()) {
            ws.send(JSON.stringify({ type: 'location_rejected', code: 'REJECTED_OUT_OF_ORDER', error: 'REJECTED_OUT_OF_ORDER' }));
            return;
          }

          // 5. Validación de Staleness / > 30s REJECTED_LIVE
          // Los puntos históricos provienen exclusivamente de sync_offline_locations
          const ageSeconds = (now.getTime() - capturedAt.getTime()) / 1000;
          if (ageSeconds > 30.0) {
            ws.send(JSON.stringify({ type: 'location_rejected', code: 'REJECTED_LIVE', error: 'REJECTED_LIVE' }));
            return;
          }

          ws.lastCapturedAt = capturedAt;

          const isStale = ageSeconds > 15.0;
          const isLowAccuracy = accuracy > 35.0;

          // 6. Persistir en Histórico (booking_tracking_logs)
          pool.query(
            `INSERT INTO public.booking_tracking_logs (booking_id, provider_id, location, accuracy_meters, captured_at)
             VALUES ($1, $2, ST_SetSRID(ST_MakePoint($4, $3), 4326)::geography, $5, $6)`,
            [data.bookingId, ws.userId, lat, lon, accuracy, capturedAt.toISOString()]
          ).catch(e => console.error('Error guardando booking_tracking_logs:', e.message));

          // Actualizar ubicación global del prestador
          pool.query(
            `UPDATE perfiles_prestador 
             SET ubicacion = ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography 
             WHERE id = $3`,
            [lat, lon, ws.userId]
          ).catch(e => console.error('Error actualizando ubicación global prestador:', e.message));

          // 7. Retransmitir al Cliente en Sala
          const payload = JSON.stringify({
            type: 'location_received',
            bookingId: data.bookingId.toString(),
            latitude: lat,
            longitude: lon,
            accuracy_meters: accuracy,
            captured_at: capturedAt.toISOString(),
            is_stale: isStale,
            is_low_accuracy: isLowAccuracy,
            timestamp: now.toISOString()
          });

          wss.clients.forEach((client) => {
            if (client !== ws && client.readyState === 1 && client.bookingId === data.bookingId.toString()) {
              client.send(payload);
            }
          });

          // Confirmar recepción al prestador
          ws.send(JSON.stringify({ 
            type: 'location_ack', 
            bookingId: data.bookingId.toString(), 
            status: isLowAccuracy ? 'LOW_ACCURACY' : 'ACCEPTED',
            captured_at: capturedAt.toISOString() 
          }));
        }

        // Sincronización de Buffer Offline (Historical)
        if (data.type === 'sync_offline_locations' && data.bookingId) {
          if (!ws.userId || ws.role !== 'provider' || ws.bookingId !== data.bookingId.toString()) {
            ws.send(JSON.stringify({ type: 'error', code: 403, error: 'FORBIDDEN' }));
            return;
          }

          const rawList = Array.isArray(data.locations) ? data.locations : (Array.isArray(data.points) ? data.points : []);
          const validPoints = rawList.slice(0, 50); // Límite máximo 50
          let inserted = 0;

          (async () => {
            for (const pt of validPoints) {
              const lat = parseFloat(pt.latitude ?? pt.lat);
              const lon = parseFloat(pt.longitude ?? pt.lon);
              const acc = parseFloat(pt.accuracy_meters ?? pt.accuracy ?? 15.0);
              const capAt = pt.captured_at ? new Date(pt.captured_at) : new Date();

              if (!isNaN(lat) && !isNaN(lon) && lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
                await pool.query(
                  `INSERT INTO public.booking_tracking_logs (booking_id, provider_id, location, accuracy_meters, captured_at)
                   VALUES ($1, $2, ST_SetSRID(ST_MakePoint($4, $3), 4326)::geography, $5, $6)`,
                  [data.bookingId, ws.userId, lat, lon, acc, capAt.toISOString()]
                ).catch(() => {});
                inserted++;
              }
            }
            ws.send(JSON.stringify({ 
              type: 'sync_offline_ack', 
              bookingId: data.bookingId.toString(), 
              synced_count: inserted, 
              status: 'HISTORICAL' 
            }));
            console.log(`📦 [TRACKING OFFLINE SYNC] Sincronizados ${inserted} puntos históricos para booking ${data.bookingId}`);
          })();
        }
      } catch (err) {
        console.error('Error procesando mensaje WebSocket:', err);
      }
    });
    
    ws.on('close', () => {
      unregisterClient(ws);
    });
  });
  
  return wss;
};

const notifyProviderNewBooking = (providerId, message) => {
  const providerIdStr = providerId.toString();
  if (wsClients.has(providerIdStr)) {
    const payload = JSON.stringify({
      type: 'new_booking',
      data: {
        message: message,
        sound_text: 'glowapp'
      }
    });
    for (const conn of wsClients.get(providerIdStr)) {
      if (conn.readyState === 1) { // OPEN
        conn.send(payload);
      }
    }
  }
};

module.exports = {
  registerClient,
  unregisterClient,
  notifyUserChatMessage,
  notifyUserAuraStatus,
  initWebSocketServer,
  notifyProviderNewBooking
};
