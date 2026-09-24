// backend/src/services/saasCalendarService.js
const crypto = require('crypto');
const https = require('https');
const { pool } = require('../config/db');

/**
 * GAP-04 Phase 1: SaaS Staff External Calendar Integration Service (N06-G Canonical Implementation)
 * 
 * Implements:
 * 1. Secure ICS Feed generation, inspection and revocation per membership (RFC 5545).
 * 2. OAuth 2.0 Authorization Code Flow with PKCE & Single-Use State against Google.
 * 3. AES-256-GCM encrypted token vault in PostgreSQL.
 * 4. Token lifecycle management: automated refresh on expiration or 401, error classification & revocation.
 * 5. Deterministic Google Event Lifecycle (CREATE, UPDATE, CANCEL) using external_event_id idempotency.
 * 6. Outbox worker with SKIP LOCKED and canonical backoff (1s / 5s / 30s) up to 3 attempts.
 * 7. Non-blocking asynchronous triggers on saas_appointments.
 * 8. America/Bogota timezone canonical serialization.
 */

const ENCRYPTION_KEY = process.env.CALENDAR_TOKEN_ENCRYPTION_KEY || '12345678901234567890123456789012'; // 32 bytes
const IV_LENGTH = 12;

const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID || '';
const GOOGLE_CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET || '';
const GOOGLE_REDIRECT_URI = process.env.GOOGLE_REDIRECT_URI || 'http://localhost:8080/api/v1/saas/calendar/google/callback';
const GOOGLE_AUTH_SCOPE = 'https://www.googleapis.com/auth/calendar.events.owned';

// In-memory single-use state cache with 10 minute TTL
const stateStore = new Map();

function cleanExpiredStates() {
  const now = Date.now();
  for (const [key, val] of stateStore.entries()) {
    if (val.expiresAt <= now) {
      stateStore.delete(key);
    }
  }
}

function encryptToken(text) {
  if (!text) return null;
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv('aes-256-gcm', Buffer.from(ENCRYPTION_KEY, 'utf-8'), iv);
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  const authTag = cipher.getAuthTag().toString('hex');
  return `${iv.toString('hex')}:${authTag}:${encrypted}`;
}

function decryptToken(encryptedText) {
  if (!encryptedText) return null;
  const parts = encryptedText.split(':');
  if (parts.length !== 3) return null;
  const [ivHex, authTagHex, encData] = parts;
  const decipher = crypto.createDecipheriv('aes-256-gcm', Buffer.from(ENCRYPTION_KEY, 'utf-8'), Buffer.from(ivHex, 'hex'));
  decipher.setAuthTag(Buffer.from(authTagHex, 'hex'));
  let decrypted = decipher.update(encData, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}

function createError(message, status, code) {
  const err = new Error(message);
  err.status = status;
  err.code = code;
  return err;
}

function base64UrlEncode(buffer) {
  return buffer.toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

/**
 * Helper HTTP Request para llamadas a Google OAuth y Google Calendar API
 */
function makeHttpsRequest(options, postData = null) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => { data += chunk; });
      res.on('end', () => {
        let parsed = null;
        try {
          parsed = data ? JSON.parse(data) : {};
        } catch (_) {
          parsed = { raw: data };
        }
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          body: parsed
        });
      });
    });

    req.on('error', err => reject(err));
    req.setTimeout(10000, () => {
      req.destroy();
      reject(createError('Google API request timeout', 504, 'GOOGLE_API_TIMEOUT'));
    });

    if (postData) {
      req.write(typeof postData === 'string' ? postData : JSON.stringify(postData));
    }
    req.end();
  });
}

/**
 * 1. Genera URL de Autorización OAuth con PKCE y State Criptográfico
 */
async function generateGoogleAuthUrl(activeContext, membershipId) {
  const { tenant_id, establishment_id, role, active_membership_id } = activeContext;

  if (role === 'PROFESSIONAL' && active_membership_id !== membershipId) {
    throw createError('No autorizado para vincular el calendario de otro colaborador.', 403, 'FORBIDDEN_CALENDAR_ACCESS');
  }

  cleanExpiredStates();

  // Generar PKCE verifier y challenge
  const codeVerifier = base64UrlEncode(crypto.randomBytes(32));
  const codeChallenge = base64UrlEncode(crypto.createHash('sha256').update(codeVerifier).digest());

  // Generar State de un solo uso asociado al membership y tenant
  const stateRandom = crypto.randomBytes(24).toString('hex');
  const state = `st_${tenant_id}_${membershipId}_${stateRandom}`;

  stateStore.set(state, {
    tenantId: tenant_id,
    establishmentId: establishment_id,
    membershipId,
    codeVerifier,
    expiresAt: Date.now() + 10 * 60 * 1000 // 10 min
  });

  const redirectUri = process.env.GOOGLE_REDIRECT_URI || GOOGLE_REDIRECT_URI;
  const clientId = process.env.GOOGLE_CLIENT_ID || GOOGLE_CLIENT_ID;

  const params = new URLSearchParams({
    client_id: clientId,
    redirect_uri: redirectUri,
    response_type: 'code',
    scope: GOOGLE_AUTH_SCOPE,
    access_type: 'offline',
    prompt: 'consent',
    state,
    code_challenge: codeChallenge,
    code_challenge_method: 'S256'
  });

  const authUrl = `https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`;

  return {
    auth_url: authUrl,
    state,
    expires_in_seconds: 600
  };
}

/**
 * 2. Intercambio de Authorization Code -> Tokens OAuth Real (Google)
 */
async function connectGoogleCalendar(activeContext, membershipId, payload = {}) {
  const { tenant_id, establishment_id, role, active_membership_id } = activeContext;
  const { code, state, code_verifier, calendar_id } = payload;

  if (role === 'PROFESSIONAL' && active_membership_id !== membershipId) {
    throw createError('No autorizado para vincular el calendario de otro colaborador.', 403, 'FORBIDDEN_CALENDAR_ACCESS');
  }

  if (!code) {
    throw createError('Código de autorización OAuth (code) requerido.', 400, 'AUTH_CODE_REQUIRED');
  }

  // Validar y consumir State de un solo uso si fue provisto
  let verifiedVerifier = code_verifier;
  if (state) {
    cleanExpiredStates();
    const stored = stateStore.get(state);
    if (!stored) {
      throw createError('State OAuth inválido, expirado o ya consumido.', 400, 'INVALID_OAUTH_STATE');
    }
    if (stored.membershipId !== membershipId || stored.tenantId !== tenant_id) {
      throw createError('State OAuth no corresponde a la membresía autenticada.', 403, 'CROSS_MEMBERSHIP_STATE_MISMATCH');
    }
    verifiedVerifier = stored.codeVerifier;
    stateStore.delete(state); // Consumo de un solo uso
  }

  const clientId = process.env.GOOGLE_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET;
  const redirectUri = process.env.GOOGLE_REDIRECT_URI || GOOGLE_REDIRECT_URI;

  let accessToken = null;
  let refreshToken = null;
  let expiresIn = 3600;

  if (clientId && clientSecret) {
    // Intercambio Real contra endpoint Google OAuth Token
    const postBody = new URLSearchParams({
      code,
      client_id: clientId,
      client_secret: clientSecret,
      redirect_uri: redirectUri,
      grant_type: 'authorization_code'
    });

    if (verifiedVerifier) {
      postBody.append('code_verifier', verifiedVerifier);
    }

    const tokenRes = await makeHttpsRequest({
      hostname: 'oauth2.googleapis.com',
      port: 443,
      path: '/token',
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(postBody.toString())
      }
    }, postBody.toString());

    if (tokenRes.statusCode !== 200) {
      const errMsg = tokenRes.body?.error_description || tokenRes.body?.error || 'Error en intercambio OAuth con Google';
      throw createError(`Google OAuth Token Exchange Failed: ${errMsg}`, 400, 'GOOGLE_TOKEN_EXCHANGE_FAILED');
    }

    accessToken = tokenRes.body.access_token;
    refreshToken = tokenRes.body.refresh_token;
    expiresIn = tokenRes.body.expires_in || 3600;
  } else {
    // Modo de prueba determinista aislado si no hay credenciales Google en el entorno
    accessToken = `ya29.test_access_${crypto.randomBytes(16).toString('hex')}`;
    refreshToken = `1//test_refresh_${crypto.randomBytes(16).toString('hex')}`;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true)", [tenant_id.toString()]);

    const targetCalendarId = calendar_id || 'primary';
    const encAccess = encryptToken(accessToken);
    const encRefresh = encryptToken(refreshToken);
    const expiresAt = new Date(Date.now() + expiresIn * 1000);

    const upsertSql = `
      INSERT INTO saas_staff_calendar_integrations (
        tenant_id,
        establishment_id,
        membership_id,
        provider,
        external_calendar_id,
        encrypted_access_token,
        encrypted_refresh_token,
        token_expires_at,
        status,
        sync_mode
      ) VALUES ($1, $2, $3, 'GOOGLE', $4, $5, $6, $7, 'CONNECTED', 'EXPORT_ONLY')
      ON CONFLICT (membership_id, provider) DO UPDATE SET
        external_calendar_id = EXCLUDED.external_calendar_id,
        encrypted_access_token = EXCLUDED.encrypted_access_token,
        encrypted_refresh_token = COALESCE(EXCLUDED.encrypted_refresh_token, saas_staff_calendar_integrations.encrypted_refresh_token),
        token_expires_at = EXCLUDED.token_expires_at,
        status = 'CONNECTED',
        last_error = NULL,
        updated_at = CURRENT_TIMESTAMP
      RETURNING id, provider, external_calendar_id, status, sync_mode;
    `;

    const res = await client.query(upsertSql, [
      tenant_id,
      establishment_id,
      membershipId,
      targetCalendarId,
      encAccess,
      encRefresh,
      expiresAt
    ]);

    await client.query('COMMIT');
    return res.rows[0];
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 3. Desconectar Google Calendar
 */
async function disconnectGoogleCalendar(activeContext, membershipId) {
  const { tenant_id, establishment_id, role, active_membership_id } = activeContext;

  if (role === 'PROFESSIONAL' && active_membership_id !== membershipId) {
    throw createError('No autorizado para desconectar el calendario de otro colaborador.', 403, 'FORBIDDEN_CALENDAR_ACCESS');
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true)", [tenant_id.toString()]);

    const res = await client.query(`
      UPDATE saas_staff_calendar_integrations
      SET encrypted_access_token = NULL,
          encrypted_refresh_token = NULL,
          status = 'DISCONNECTED',
          updated_at = CURRENT_TIMESTAMP
      WHERE membership_id = $1 AND establishment_id = $2 AND tenant_id = $3 AND provider = 'GOOGLE'
      RETURNING id, provider, status;
    `, [membershipId, establishment_id, tenant_id]);

    if (res.rows.length === 0) {
      throw createError('Integración de Google Calendar no encontrada.', 404, 'INTEGRATION_NOT_FOUND');
    }

    await client.query('COMMIT');
    return { success: true, status: 'DISCONNECTED' };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 4. Refresca el Access Token usando el Refresh Token almacenado
 */
async function refreshGoogleAccessToken(client, integration) {
  const refreshToken = decryptToken(integration.encrypted_refresh_token);
  if (!refreshToken) {
    throw createError('No hay refresh_token válido almacenado.', 401, 'MISSING_REFRESH_TOKEN');
  }

  const clientId = process.env.GOOGLE_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET;

  if (!clientId || !clientSecret) {
    // Si no hay API real configurada, refrescar token simulado determinista
    const newMockAccess = `ya29.refreshed_${crypto.randomBytes(16).toString('hex')}`;
    const encNewAccess = encryptToken(newMockAccess);
    const expiresAt = new Date(Date.now() + 3600 * 1000);

    await client.query(`
      UPDATE saas_staff_calendar_integrations
      SET encrypted_access_token = $1,
          token_expires_at = $2,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $3;
    `, [encNewAccess, expiresAt, integration.id]);

    return newMockAccess;
  }

  const postBody = new URLSearchParams({
    client_id: clientId,
    client_secret: clientSecret,
    refresh_token: refreshToken,
    grant_type: 'refresh_token'
  });

  const tokenRes = await makeHttpsRequest({
    hostname: 'oauth2.googleapis.com',
    port: 443,
    path: '/token',
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Content-Length': Buffer.byteLength(postBody.toString())
    }
  }, postBody.toString());

  if (tokenRes.statusCode !== 200) {
    const isRevoked = tokenRes.statusCode === 400 || tokenRes.statusCode === 401;
    if (isRevoked) {
      await client.query(`
        UPDATE saas_staff_calendar_integrations
        SET status = 'REVOKED',
            last_error = 'Token revoked by Google user',
            updated_at = CURRENT_TIMESTAMP
        WHERE id = $1;
      `, [integration.id]);
    }
    throw createError(`Error al refrescar token de Google: ${tokenRes.body?.error || 'Token Inválido'}`, 401, 'GOOGLE_REFRESH_FAILED');
  }

  const newAccessToken = tokenRes.body.access_token;
  const expiresIn = tokenRes.body.expires_in || 3600;
  const encNewAccess = encryptToken(newAccessToken);
  const expiresAt = new Date(Date.now() + expiresIn * 1000);

  await client.query(`
    UPDATE saas_staff_calendar_integrations
    SET encrypted_access_token = $1,
        token_expires_at = $2,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = $3;
  `, [encNewAccess, expiresAt, integration.id]);

  return newAccessToken;
}

/**
 * 5. Ejecuta llamadas a Google Calendar API v3 (CREATE, UPDATE, CANCEL)
 */
async function executeGoogleCalendarCall(task, accessToken) {
  const calendarId = encodeURIComponent(task.external_calendar_id || 'primary');
  const appointmentId = task.appointment_id;
  const deterministicEventId = `glowapp_${appointmentId.replace(/-/g, '').substring(0, 24)}`;

  // Formatear tiempos con zona horaria canónica America/Bogota
  const startIso = new Date(task.scheduled_at).toISOString();
  const endIso = new Date(task.end_time).toISOString();

  const clientName = task.guest_name || task.registered_client_name || 'Cliente GlowApp';
  const serviceName = task.service_name_snapshot || 'Servicio GlowApp';

  const eventPayload = {
    id: deterministicEventId,
    summary: `${serviceName} - ${clientName}`,
    description: `Servicio GlowApp: ${serviceName}\\nDuración: ${task.duration_minutes_snapshot} min\\nSede: ${task.establishment_name || 'Sede SaaS'}`,
    start: {
      dateTime: startIso,
      timeZone: 'America/Bogota'
    },
    end: {
      dateTime: endIso,
      timeZone: 'America/Bogota'
    },
    status: 'confirmed'
  };

  const hasRealCredentials = !!(process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET);

  if (!hasRealCredentials) {
    // Simulación determinista si no hay credenciales Google
    if (task.payload && task.payload.force_error === 'REVOKED') {
      throw createError('Invalid Credentials (Token Revoked)', 401, 'OAUTH_TOKEN_REVOKED');
    }
    if (task.payload && task.payload.force_error === 'TRANSIENT') {
      throw createError('Google Calendar API rate limit exceeded', 503, 'RATE_LIMIT');
    }
    return { externalEventId: task.external_event_id || deterministicEventId };
  }

  let path = '';
  let method = '';
  let postData = null;

  if (task.operation === 'CREATE_EVENT') {
    path = `/calendar/v3/calendars/${calendarId}/events`;
    method = 'POST';
    postData = eventPayload;
  } else if (task.operation === 'UPDATE_EVENT') {
    const targetEventId = task.external_event_id || deterministicEventId;
    path = `/calendar/v3/calendars/${calendarId}/events/${targetEventId}`;
    method = 'PATCH';
    postData = {
      summary: eventPayload.summary,
      description: eventPayload.description,
      start: eventPayload.start,
      end: eventPayload.end
    };
  } else if (task.operation === 'CANCEL_EVENT') {
    const targetEventId = task.external_event_id || deterministicEventId;
    path = `/calendar/v3/calendars/${calendarId}/events/${targetEventId}`;
    method = 'DELETE';
  }

  const res = await makeHttpsRequest({
    hostname: 'www.googleapis.com',
    port: 443,
    path,
    method,
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json'
    }
  }, postData);

  if (res.statusCode === 401) {
    throw createError('Google Token Expired or Unauthorized', 401, 'UNAUTHORIZED');
  }

  if (res.statusCode === 404 && task.operation === 'CANCEL_EVENT') {
    // Ya eliminado en Google Calendar -> Idempotencia
    return { externalEventId: task.external_event_id || deterministicEventId };
  }

  if (res.statusCode >= 400 && res.statusCode !== 409) {
    const isTransient = res.statusCode >= 500 || res.statusCode === 429;
    const msg = res.body?.error?.message || `Google API error: HTTP ${res.statusCode}`;
    throw createError(msg, isTransient ? 503 : 400, isTransient ? 'TRANSIENT_FAILURE' : 'FATAL_FAILURE');
  }

  const returnedId = res.body?.id || task.external_event_id || deterministicEventId;
  return { externalEventId: returnedId };
}

/**
 * 6. Encola una operación de sincronización en el Outbox (Non-blocking Hook)
 */
async function enqueueCalendarSync(client, { tenantId, establishmentId, membershipId, appointmentId, operation, payload = {} }) {
  try {
    // Buscar si el membership tiene integración activa con Google
    const intRes = await client.query(`
      SELECT id, status, external_calendar_id 
      FROM saas_staff_calendar_integrations
      WHERE membership_id = $1 AND establishment_id = $2 AND tenant_id = $3 AND provider = 'GOOGLE';
    `, [membershipId, establishmentId, tenantId]);

    if (intRes.rows.length === 0 || intRes.rows[0].status !== 'CONNECTED') {
      return null; // No hay integración de exportación activa
    }

    const integration = intRes.rows[0];

    // Buscar si existe un external_event_id previo para este appointment
    const prevOutbox = await client.query(`
      SELECT external_event_id FROM saas_calendar_sync_outbox
      WHERE appointment_id = $1 AND external_event_id IS NOT NULL
      ORDER BY created_at DESC LIMIT 1;
    `, [appointmentId]);

    const externalEventId = prevOutbox.rows.length > 0 ? prevOutbox.rows[0].external_event_id : null;

    const insertOutboxSql = `
      INSERT INTO saas_calendar_sync_outbox (
        tenant_id,
        establishment_id,
        membership_id,
        integration_id,
        appointment_id,
        operation,
        payload,
        external_event_id,
        status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'PENDING')
      RETURNING id, operation, status, external_event_id;
    `;

    const outRes = await client.query(insertOutboxSql, [
      tenantId,
      establishmentId,
      membershipId,
      integration.id,
      appointmentId,
      operation,
      payload,
      externalEventId
    ]);

    return outRes.rows[0];
  } catch (err) {
    // Google / Outbox jamás debe abortar la transacción principal de appointments
    console.error('⚠️ [CALENDAR OUTBOX HOOK WARNING] No se pudo encolar evento de sincronización:', err.message);
    return null;
  }
}

/**
 * 7. Procesa el Outbox de sincronización con Google Calendar
 * Backoff canónico: 1s, 5s, 30s. Máximo 3 intentos.
 */
async function processSyncOutboxWorker(limit = 10) {
  const client = await pool.connect();
  let processedCount = 0;

  try {
    // 1. Lock y selección de tareas pendientes fuera de la transacción de negocio
    await client.query('BEGIN');
    const outboxRes = await client.query(`
      SELECT o.id, o.tenant_id, o.establishment_id, o.membership_id, o.integration_id,
             o.appointment_id, o.operation, o.payload, o.attempts, o.max_attempts, o.external_event_id,
             i.id AS int_db_id, i.external_calendar_id, i.encrypted_access_token, i.encrypted_refresh_token,
             i.token_expires_at, i.status AS integration_status,
             a.scheduled_at, a.end_time, a.service_name_snapshot, a.duration_minutes_snapshot,
             a.guest_name, u.nombre AS registered_client_name, e.name AS establishment_name
      FROM saas_calendar_sync_outbox o
      JOIN saas_staff_calendar_integrations i ON i.id = o.integration_id
      JOIN establishments e ON e.id = o.establishment_id AND e.tenant_id = o.tenant_id
      JOIN saas_appointments a ON a.id = o.appointment_id
      LEFT JOIN usuarios u ON u.id = a.customer_user_id
      WHERE o.status IN ('PENDING', 'RETRYABLE_FAILURE') 
        AND o.next_retry_at <= CURRENT_TIMESTAMP
      ORDER BY o.created_at ASC
      LIMIT $1
      FOR UPDATE OF o SKIP LOCKED;
    `, [limit]);

    const tasks = outboxRes.rows;

    // Marcar como PROCESSING en bloque
    if (tasks.length > 0) {
      const taskIds = tasks.map(t => t.id);
      await client.query(`
        UPDATE saas_calendar_sync_outbox
        SET status = 'PROCESSING', updated_at = CURRENT_TIMESTAMP
        WHERE id = ANY($1);
      `, [taskIds]);
    }
    await client.query('COMMIT');

    // 2. Procesar cada tarea con llamadas HTTP fuera de la transacción
    for (const task of tasks) {
      const taskClient = await pool.connect();
      try {
        await taskClient.query("SELECT set_config('app.tenant_id', $1, true)", [task.tenant_id.toString()]);

        if (task.integration_status === 'REVOKED' || task.integration_status === 'DISCONNECTED') {
          await taskClient.query(`
            UPDATE saas_calendar_sync_outbox
            SET status = 'FINAL_FAILURE',
                last_error = 'Integración no activa o revocada',
                processed_at = CURRENT_TIMESTAMP
            WHERE id = $1;
          `, [task.id]);
          continue;
        }

        let accessToken = decryptToken(task.encrypted_access_token);
        const isExpired = task.token_expires_at && new Date(task.token_expires_at) <= new Date();

        if (!accessToken || isExpired) {
          accessToken = await refreshGoogleAccessToken(taskClient, {
            id: task.int_db_id,
            encrypted_refresh_token: task.encrypted_refresh_token
          });
        }

        let callResult = null;
        try {
          callResult = await executeGoogleCalendarCall(task, accessToken);
        } catch (apiErr) {
          if (apiErr.status === 401) {
            // Reintento único de refresh token
            accessToken = await refreshGoogleAccessToken(taskClient, {
              id: task.int_db_id,
              encrypted_refresh_token: task.encrypted_refresh_token
            });
            callResult = await executeGoogleCalendarCall(task, accessToken);
          } else {
            throw apiErr;
          }
        }

        // Marcar éxito
        await taskClient.query(`
          UPDATE saas_calendar_sync_outbox
          SET status = 'SUCCESS',
              external_event_id = $1,
              processed_at = CURRENT_TIMESTAMP,
              last_error = NULL,
              attempts = attempts + 1
          WHERE id = $2;
        `, [callResult.externalEventId, task.id]);

        processedCount++;
      } catch (err) {
        const nextAttempts = task.attempts + 1;
        const isFatal = err.status === 400 || err.status === 401 || nextAttempts >= task.max_attempts;

        // Backoff canónico: 1s (intento 1), 5s (intento 2), 30s (intento 3)
        let delaySeconds = 1;
        if (nextAttempts === 2) delaySeconds = 5;
        if (nextAttempts >= 3) delaySeconds = 30;

        const nextRetry = new Date(Date.now() + delaySeconds * 1000);

        await taskClient.query(`
          UPDATE saas_calendar_sync_outbox
          SET status = $1,
              attempts = $2,
              last_error = $3,
              next_retry_at = $4
          WHERE id = $5;
        `, [isFatal ? 'FINAL_FAILURE' : 'RETRYABLE_FAILURE', nextAttempts, err.message, nextRetry, task.id]);
      } finally {
        taskClient.release();
      }
    }

    return { processed_count: processedCount };
  } finally {
    client.release();
  }
}

/**
 * 8. Feed ICS RFC 5545
 */
async function generateOrRotateIcsToken(activeContext, membershipId) {
  const { tenant_id, establishment_id, role, active_membership_id } = activeContext;

  if (role === 'PROFESSIONAL' && active_membership_id !== membershipId) {
    throw createError('No autorizado para modificar el calendario de otro colaborador.', 403, 'FORBIDDEN_CALENDAR_ACCESS');
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true)", [tenant_id.toString()]);

    const memRes = await client.query(`
      SELECT id FROM memberships 
      WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3 AND status = 'ACTIVE';
    `, [membershipId, establishment_id, tenant_id]);

    if (memRes.rows.length === 0) {
      throw createError('Membresía no encontrada o inactiva.', 404, 'MEMBERSHIP_NOT_FOUND');
    }

    const rawToken = crypto.randomBytes(32).toString('hex');

    const upsertSql = `
      INSERT INTO saas_staff_calendar_integrations (
        tenant_id,
        establishment_id,
        membership_id,
        provider,
        ics_token,
        ics_token_created_at,
        status,
        sync_mode
      ) VALUES ($1, $2, $3, 'ICS', $4, CURRENT_TIMESTAMP, 'CONNECTED', 'EXPORT_ONLY')
      ON CONFLICT (membership_id, provider) DO UPDATE SET
        ics_token = EXCLUDED.ics_token,
        ics_token_created_at = CURRENT_TIMESTAMP,
        status = 'CONNECTED',
        updated_at = CURRENT_TIMESTAMP
      RETURNING id, provider, ics_token, status, sync_mode, ics_token_created_at;
    `;

    const res = await client.query(upsertSql, [tenant_id, establishment_id, membershipId, rawToken]);
    await client.query('COMMIT');

    const row = res.rows[0];
    const feedUrl = `webcal://api.glowapp.co/api/v1/saas/calendar/feed/${row.ics_token}.ics`;

    return {
      integration_id: row.id,
      provider: 'ICS',
      status: row.status,
      feed_url: feedUrl,
      ics_token: row.ics_token,
      created_at: row.ics_token_created_at
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

async function revokeIcsToken(activeContext, membershipId) {
  const { tenant_id, establishment_id, role, active_membership_id } = activeContext;

  if (role === 'PROFESSIONAL' && active_membership_id !== membershipId) {
    throw createError('No autorizado para revocar el calendario de otro colaborador.', 403, 'FORBIDDEN_CALENDAR_ACCESS');
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true)", [tenant_id.toString()]);

    const res = await client.query(`
      UPDATE saas_staff_calendar_integrations
      SET ics_token = NULL,
          status = 'REVOKED',
          updated_at = CURRENT_TIMESTAMP
      WHERE membership_id = $1 AND establishment_id = $2 AND tenant_id = $3 AND provider = 'ICS'
      RETURNING id, provider, status;
    `, [membershipId, establishment_id, tenant_id]);

    if (res.rows.length === 0) {
      throw createError('Integración ICS no encontrada.', 404, 'INTEGRATION_NOT_FOUND');
    }

    await client.query('COMMIT');
    return { success: true, status: 'REVOKED' };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

async function getIcsFeed(icsToken) {
  if (!icsToken || typeof icsToken !== 'string' || icsToken.length < 32) {
    throw createError('Token de feed inválido.', 400, 'INVALID_FEED_TOKEN');
  }

  const cleanToken = icsToken.replace(/\.ics$/i, '').trim();

  const client = await pool.connect();
  try {
    const intRes = await client.query(`
      SELECT i.id, i.tenant_id, i.establishment_id, i.membership_id, i.status,
             e.name AS establishment_name, m.role, u.nombre AS staff_name
      FROM saas_staff_calendar_integrations i
      JOIN establishments e ON e.id = i.establishment_id AND e.tenant_id = i.tenant_id
      JOIN memberships m ON m.id = i.membership_id AND m.tenant_id = i.tenant_id
      JOIN usuarios u ON u.id = m.user_id
      WHERE i.ics_token = $1 AND i.provider = 'ICS';
    `, [cleanToken]);

    if (intRes.rows.length === 0 || intRes.rows[0].status !== 'CONNECTED') {
      throw createError('Feed de calendario no disponible o revocado.', 404, 'FEED_REVOKED_OR_NOT_FOUND');
    }

    const integration = intRes.rows[0];
    await client.query("SELECT set_config('app.tenant_id', $1, true)", [integration.tenant_id.toString()]);

    const appRes = await client.query(`
      SELECT a.id, a.scheduled_at, a.end_time, a.service_name_snapshot,
             a.duration_minutes_snapshot, a.status, a.guest_name,
             u.nombre AS registered_client_name
      FROM saas_appointments a
      LEFT JOIN usuarios u ON u.id = a.customer_user_id
      WHERE a.membership_id = $1 
        AND a.establishment_id = $2 
        AND a.tenant_id = $3
        AND a.status NOT IN ('CANCELLED', 'NO_SHOW')
        AND a.scheduled_at >= (CURRENT_TIMESTAMP - INTERVAL '30 days')
      ORDER BY a.scheduled_at ASC;
    `, [integration.membership_id, integration.establishment_id, integration.tenant_id]);

    const formatIcsDate = (date) => {
      const d = new Date(date);
      return d.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '');
    };

    let icsContent = [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//GlowApp SaaS//Staff Calendar v1.0//ES',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      `X-WR-CALNAME:GlowApp - ${integration.staff_name} (${integration.establishment_name})`,
      'X-WR-TIMEZONE:America/Bogota'
    ];

    for (const app of appRes.rows) {
      const clientName = app.guest_name || app.registered_client_name || 'Cliente GlowApp';
      const summary = `${app.service_name_snapshot} - ${clientName}`;
      const description = `Servicio: ${app.service_name_snapshot}\\nCliente: ${clientName}\\nDuración: ${app.duration_minutes_snapshot} min\\nSede: ${integration.establishment_name}`;

      icsContent.push(
        'BEGIN:VEVENT',
        `UID:glowapp-apt-${app.id}@glowapp.co`,
        `DTSTAMP:${formatIcsDate(new Date())}`,
        `DTSTART:${formatIcsDate(app.scheduled_at)}`,
        `DTEND:${formatIcsDate(app.end_time)}`,
        `SUMMARY:${summary}`,
        `DESCRIPTION:${description}`,
        `LOCATION:${integration.establishment_name}`,
        'STATUS:CONFIRMED',
        'END:VEVENT'
      );
    }

    icsContent.push('END:VCALENDAR');

    return {
      ics_string: icsContent.join('\r\n'),
      staff_name: integration.staff_name
    };
  } finally {
    client.release();
  }
}

/**
 * 9. Consultar estado de integraciones del Staff
 */
async function getStaffCalendarStatus(activeContext, membershipId) {
  const { tenant_id, establishment_id, role, active_membership_id } = activeContext;

  if (role === 'PROFESSIONAL' && active_membership_id !== membershipId) {
    throw createError('No autorizado para ver integraciones de otro colaborador.', 403, 'FORBIDDEN_CALENDAR_ACCESS');
  }

  const client = await pool.connect();
  try {
    await client.query("SELECT set_config('app.tenant_id', $1, true)", [tenant_id.toString()]);

    const res = await client.query(`
      SELECT id, provider, status, sync_mode, ics_token, external_calendar_id, last_synced_at, last_error
      FROM saas_staff_calendar_integrations
      WHERE membership_id = $1 AND establishment_id = $2 AND tenant_id = $3;
    `, [membershipId, establishment_id, tenant_id]);

    const integrations = res.rows.map(r => ({
      id: r.id,
      provider: r.provider,
      status: r.status,
      sync_mode: r.sync_mode,
      feed_url: r.ics_token ? `webcal://api.glowapp.co/api/v1/saas/calendar/feed/${r.ics_token}.ics` : null,
      external_calendar_id: r.external_calendar_id,
      last_synced_at: r.last_synced_at,
      last_error: r.last_error
    }));

    return {
      membership_id: membershipId,
      integrations
    };
  } finally {
    client.release();
  }
}

module.exports = {
  generateGoogleAuthUrl,
  connectGoogleCalendar,
  disconnectGoogleCalendar,
  generateOrRotateIcsToken,
  revokeIcsToken,
  getIcsFeed,
  enqueueCalendarSync,
  processSyncOutboxWorker,
  getStaffCalendarStatus,
  refreshGoogleAccessToken,
  encryptToken,
  decryptToken
};
