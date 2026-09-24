// backend/src/services/nodo06AppointmentsService.js
const { pool } = require('../config/db');
const saasCalendarService = require('./saasCalendarService');

/**
 * NODO-06 — SaaS Internal Appointments & Operational Agenda Engine Service
 *
 * Implements:
 * 1. Appointment Creation with Snapshot, Dual Client Mode (Registered/Guest),
 *    Atomic Concurrency (EXCLUDE USING gist), and Availability Pre-Check.
 * 2. Operational State Machine Transitions with 16 strict rules.
 * 3. Daily Operational Agenda Projection in Memory.
 * 4. Multi-Tenant isolation and Active Context Role Governance.
 */

// Matriz canónica de transiciones permitidas (16 reglas de N06-DEC-05)
const VALID_TRANSITIONS = {
  SCHEDULED: ['CONFIRMED', 'CHECKED_IN', 'CANCELLED', 'NO_SHOW'],
  CONFIRMED: ['CHECKED_IN', 'CANCELLED', 'NO_SHOW'],
  CHECKED_IN: ['IN_SERVICE', 'CANCELLED'],
  IN_SERVICE: ['COMPLETED', 'CANCELLED'],
  COMPLETED: [],
  CANCELLED: [],
  NO_SHOW: []
};

/**
 * Parsea y formatea un Date o ISO string a representación local America/Bogota ISO
 */
function formatBogotaIso(date) {
  if (!date) return null;
  const d = new Date(date);
  // America/Bogota es UTC-5 sin DST fijo
  const bogotaOffsetMs = -5 * 60 * 60 * 1000;
  const bogotaTime = new Date(d.getTime() + bogotaOffsetMs);
  const iso = bogotaTime.toISOString().replace('.000Z', '-05:00').replace('Z', '-05:00');
  return iso;
}

/**
 * Parsea un target_date YYYY-MM-DD a límites temporales UTC según America/Bogota
 */
function getBogotaDayBounds(targetDateStr) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(targetDateStr)) {
    throw new Error('INVALID_DATE_FORMAT');
  }
  const [year, month, day] = targetDateStr.split('-').map(Number);
  
  // 00:00:00 America/Bogota (UTC-5) es 05:00:00Z del mismo día
  const startUtc = new Date(Date.UTC(year, month - 1, day, 5, 0, 0, 0));
  // 24:00:00 America/Bogota es 05:00:00Z del día siguiente
  const endUtc = new Date(Date.UTC(year, month - 1, day + 1, 5, 0, 0, 0));
  
  // Día de la semana (1 = Lunes, ..., 7 = Domingo)
  // Date.getUTCDay(): 0=Dom, 1=Lun, 2=Mar, 3=Mie, 4=Jue, 5=Vie, 6=Sab
  const jsDay = new Date(Date.UTC(year, month - 1, day, 12, 0, 0)).getUTCDay();
  const dayOfWeek = jsDay === 0 ? 7 : jsDay;

  return { startUtc, endUtc, dayOfWeek };
}

/**
 * 1. CREAR APPOINTMENT
 */
async function createAppointment(activeContext, data) {
  const tenantId = activeContext.tenant_id;
  const establishmentId = activeContext.establishment_id;
  const callerMembershipId = activeContext.active_membership_id;
  const callerRole = activeContext.role;

  const {
    service_offer_id,
    membership_id: targetMembershipId,
    scheduled_at,
    customer_user_id,
    guest_name,
    guest_phone,
    guest_email
  } = data;

  // 1. Validaciones de DTO
  if (!service_offer_id || !targetMembershipId || !scheduled_at) {
    const err = new Error('Missing required appointment parameters');
    err.status = 400;
    err.code = 'INVALID_TIME_FORMAT';
    throw err;
  }

  const scheduledDate = new Date(scheduled_at);
  if (isNaN(scheduledDate.getTime())) {
    const err = new Error('scheduled_at must be a valid ISO-8601 timestamp');
    err.status = 400;
    err.code = 'INVALID_TIME_FORMAT';
    throw err;
  }

  // 2. Validación de Modo Dual de Cliente (XOR)
  const isRegistered = customer_user_id !== undefined && customer_user_id !== null;
  const isGuest = guest_name !== undefined && guest_name !== null && guest_phone !== undefined && guest_phone !== null;

  if (isRegistered && (guest_name || guest_phone || guest_email)) {
    const err = new Error('Client mode conflict: Registered customer cannot contain guest fields');
    err.status = 400;
    err.code = 'INVALID_CLIENT_IDENTITY_MODE';
    throw err;
  }

  if (!isRegistered) {
    if (!guest_name || typeof guest_name !== 'string' || guest_name.trim().length < 2 ||
        !guest_phone || typeof guest_phone !== 'string' || guest_phone.trim().length < 7) {
      const err = new Error('Client mode conflict: Guest client requires valid guest_name (min 2 chars) and guest_phone (min 7 chars)');
      err.status = 400;
      err.code = 'INVALID_CLIENT_IDENTITY_MODE';
      throw err;
    }
  }

  // 3. Validación de Roles de Active Context
  const isPrivileged = ['OWNER', 'MANAGER', 'RECEPTIONIST'].includes(callerRole);
  const isSelfProfessional = callerRole === 'PROFESSIONAL' && callerMembershipId === targetMembershipId;

  if (!isPrivileged && !isSelfProfessional) {
    const err = new Error(`Role ${callerRole} is not authorized to create appointments for professional ${targetMembershipId}`);
    err.status = 403;
    err.code = 'UNAUTHORIZED_ROLE';
    throw err;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    // 4. Validar Oferta de Servicio
    const offerRes = await client.query(`
      SELECT id, name, base_duration, base_price
      FROM service_offers
      WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3
    `, [service_offer_id, establishmentId, tenantId]);

    if (offerRes.rows.length === 0) {
      const err = new Error(`Service offer ${service_offer_id} not found in establishment`);
      err.status = 404;
      err.code = 'SERVICE_OFFER_NOT_FOUND';
      throw err;
    }
    const offer = offerRes.rows[0];

    // 5. Validar Membresía y Estado Activo
    const memberRes = await client.query(`
      SELECT id, user_id, role, status
      FROM memberships
      WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3
    `, [targetMembershipId, establishmentId, tenantId]);

    if (memberRes.rows.length === 0) {
      const err = new Error(`Membership ${targetMembershipId} not found in establishment`);
      err.status = 422;
      err.code = 'INACTIVE_MEMBERSHIP';
      throw err;
    }
    const membership = memberRes.rows[0];

    if (membership.status !== 'ACTIVE') {
      const err = new Error(`Membership ${targetMembershipId} is not in ACTIVE status (current: ${membership.status})`);
      err.status = 422;
      err.code = 'INACTIVE_MEMBERSHIP';
      throw err;
    }

    // 6. Validar Asignación M:N
    const assignRes = await client.query(`
      SELECT id FROM service_assignments
      WHERE service_offer_id = $1 AND membership_id = $2 
        AND establishment_id = $3 AND tenant_id = $4
    `, [service_offer_id, targetMembershipId, establishmentId, tenantId]);

    if (assignRes.rows.length === 0) {
      const err = new Error(`Professional ${targetMembershipId} is not assigned to service offer ${service_offer_id}`);
      err.status = 422;
      err.code = 'INVALID_SERVICE_ASSIGNMENT';
      throw err;
    }

    // 7. Calcular end_time determinista
    const durationMinutes = offer.base_duration;
    const endTime = new Date(scheduledDate.getTime() + durationMinutes * 60 * 1000);

    // 8. Pre-Check de solapamiento en public.bookings (Read-Only)
    const b2cCollision = await client.query(`
      SELECT b.id, b.scheduled_at, s.duration_minutes
      FROM bookings b
      JOIN services s ON s.id = b.service_id
      WHERE b.tenant_id = $1 
        AND b.provider_id = $2
        AND b.estado IN ('CONFIRMADA', 'COMPLETADA', 'EN_PROGRESO', 'PENDIENTE_PAGO')
        AND b.scheduled_at < $3
        AND (b.scheduled_at + (s.duration_minutes * interval '1 minute')) > $4
      LIMIT 1;
    `, [tenantId, membership.user_id, endTime.toISOString(), scheduledDate.toISOString()]);

    if (b2cCollision.rows.length > 0) {
      const err = new Error('Time slot overlaps with an active marketplace booking');
      err.status = 409;
      err.code = 'APPOINTMENT_OCCUPANCY_COLLISION';
      throw err;
    }

    // 9. Inserción atómica con protección GiST en saas_appointments
    const insertRes = await client.query(`
      INSERT INTO saas_appointments (
        tenant_id,
        establishment_id,
        service_offer_id,
        membership_id,
        customer_user_id,
        guest_name,
        guest_phone,
        guest_email,
        scheduled_at,
        end_time,
        service_name_snapshot,
        duration_minutes_snapshot,
        price_snapshot,
        status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, 'SCHEDULED')
      RETURNING *;
    `, [
      tenantId,
      establishmentId,
      service_offer_id,
      targetMembershipId,
      isRegistered ? customer_user_id : null,
      !isRegistered ? guest_name.trim() : null,
      !isRegistered ? guest_phone.trim() : null,
      (!isRegistered && guest_email) ? guest_email.trim() : null,
      scheduledDate.toISOString(),
      endTime.toISOString(),
      offer.name,
      durationMinutes,
      offer.base_price
    ]);

    const created = insertRes.rows[0];

    // Non-blocking Calendar Sync Hook (GAP-04 / N06-G)
    await saasCalendarService.enqueueCalendarSync(client, {
      tenantId,
      establishmentId,
      membershipId: targetMembershipId,
      appointmentId: created.id,
      operation: 'CREATE_EVENT',
      payload: {
        service_name: offer.name,
        scheduled_at: scheduledDate.toISOString(),
        end_time: endTime.toISOString()
      }
    });

    await client.query('COMMIT');
    return {
      id: created.id,
      tenant_id: created.tenant_id,
      establishment_id: created.establishment_id,
      service_offer_id: created.service_offer_id,
      membership_id: created.membership_id,
      professional_user_id: membership.user_id,
      client_mode: isRegistered ? 'REGISTERED' : 'GUEST',
      customer_user_id: created.customer_user_id,
      guest_name: created.guest_name,
      guest_phone: created.guest_phone,
      guest_email: created.guest_email,
      scheduled_at: formatBogotaIso(created.scheduled_at),
      end_time: formatBogotaIso(created.end_time),
      service_name_snapshot: created.service_name_snapshot,
      duration_minutes_snapshot: created.duration_minutes_snapshot,
      price_snapshot: created.price_snapshot,
      status: created.status,
      cancellation_reason: created.cancellation_reason,
      created_at: created.created_at,
      updated_at: created.updated_at
    };
  } catch (err) {
    await client.query('ROLLBACK');
    if (err.code === '23P01' || (err.message && err.message.includes('uq_saas_appointments_no_overlap'))) {
      const collisionErr = new Error('Time slot overlaps with an existing active appointment for this professional');
      collisionErr.status = 409;
      collisionErr.code = 'APPOINTMENT_OCCUPANCY_COLLISION';
      throw collisionErr;
    }
    if (err.code === '23503' && err.constraint === 'fk_saas_appointments_customer_user_tenant') {
      const customerErr = new Error('Customer user does not exist in this tenant');
      customerErr.status = 404;
      customerErr.code = 'SERVICE_OFFER_NOT_FOUND';
      throw customerErr;
    }
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 2. TRANSICIONAR ESTADO DE APPOINTMENT
 */
async function transitionAppointmentStatus(activeContext, appointmentId, transitionData) {
  const tenantId = activeContext.tenant_id;
  const establishmentId = activeContext.establishment_id;
  const callerMembershipId = activeContext.active_membership_id;
  const callerRole = activeContext.role;
  const { status: targetStatus, cancellation_reason } = transitionData;

  if (!targetStatus) {
    const err = new Error('Target status is required');
    err.status = 400;
    err.code = 'INVALID_STATE_TRANSITION';
    throw err;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    // 1. Verificar estado de membresía ejecutora
    const callerMemberRes = await client.query(`
      SELECT id, status FROM memberships
      WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3
    `, [callerMembershipId, establishmentId, tenantId]);

    if (callerMemberRes.rows.length === 0 || callerMemberRes.rows[0].status !== 'ACTIVE') {
      const err = new Error('Executing membership is inactive and cannot perform operational transitions');
      err.status = 422;
      err.code = 'INACTIVE_MEMBERSHIP_CANNOT_EXECUTE';
      throw err;
    }

    // 2. Buscar cita con lock FOR UPDATE
    const apptRes = await client.query(`
      SELECT * FROM saas_appointments
      WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3
      FOR UPDATE;
    `, [appointmentId, establishmentId, tenantId]);

    if (apptRes.rows.length === 0) {
      const err = new Error(`Appointment ${appointmentId} not found in establishment`);
      err.status = 404;
      err.code = 'APPOINTMENT_NOT_FOUND';
      throw err;
    }

    const appt = apptRes.rows[0];
    const currentStatus = appt.status;

    // 3. Verificar permisos de rol
    const isPrivileged = ['OWNER', 'MANAGER', 'RECEPTIONIST'].includes(callerRole);
    const isOwnAppt = callerRole === 'PROFESSIONAL' && callerMembershipId === appt.membership_id;

    if (!isPrivileged && !isOwnAppt) {
      const err = new Error(`Role ${callerRole} is not authorized to transition appointments of other professionals`);
      err.status = 403;
      err.code = 'UNAUTHORIZED_ROLE';
      throw err;
    }

    // 4. Validar matriz de transiciones (16 reglas)
    const allowedTargets = VALID_TRANSITIONS[currentStatus] || [];
    if (!allowedTargets.includes(targetStatus)) {
      const err = new Error(`Transition from ${currentStatus} to ${targetStatus} is not allowed`);
      err.status = 422;
      err.code = 'INVALID_STATE_TRANSITION';
      throw err;
    }

    // 5. Validar Regla 12 (IN_SERVICE -> CANCELLED requiere cancellation_reason)
    if (currentStatus === 'IN_SERVICE' && targetStatus === 'CANCELLED') {
      if (!cancellation_reason || typeof cancellation_reason !== 'string' || cancellation_reason.trim().length === 0) {
        const err = new Error('cancellation_reason is strictly required when cancelling an in-service appointment');
        err.status = 422;
        err.code = 'CANCELLATION_REASON_REQUIRED';
        throw err;
      }
    }

    // 6. Actualizar cita
    const updateRes = await client.query(`
      UPDATE saas_appointments
      SET status = $1,
          cancellation_reason = $2,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $3
      RETURNING *;
    `, [
      targetStatus,
      targetStatus === 'CANCELLED' ? (cancellation_reason ? cancellation_reason.trim() : null) : null,
      appointmentId
    ]);

    const updated = updateRes.rows[0];

    // Non-blocking Calendar Sync Hook (GAP-04 / N06-G)
    if (targetStatus === 'CANCELLED') {
      await saasCalendarService.enqueueCalendarSync(client, {
        tenantId,
        establishmentId,
        membershipId: updated.membership_id,
        appointmentId: updated.id,
        operation: 'CANCEL_EVENT',
        payload: {
          status: 'CANCELLED',
          cancellation_reason: updated.cancellation_reason
        }
      });
    } else {
      await saasCalendarService.enqueueCalendarSync(client, {
        tenantId,
        establishmentId,
        membershipId: updated.membership_id,
        appointmentId: updated.id,
        operation: 'UPDATE_EVENT',
        payload: {
          status: targetStatus,
          scheduled_at: updated.scheduled_at,
          end_time: updated.end_time
        }
      });
    }

    await client.query('COMMIT');
    return {
      id: updated.id,
      tenant_id: updated.tenant_id,
      establishment_id: updated.establishment_id,
      service_offer_id: updated.service_offer_id,
      membership_id: updated.membership_id,
      client_mode: updated.customer_user_id ? 'REGISTERED' : 'GUEST',
      customer_user_id: updated.customer_user_id,
      guest_name: updated.guest_name,
      guest_phone: updated.guest_phone,
      guest_email: updated.guest_email,
      scheduled_at: formatBogotaIso(updated.scheduled_at),
      end_time: formatBogotaIso(updated.end_time),
      service_name_snapshot: updated.service_name_snapshot,
      duration_minutes_snapshot: updated.duration_minutes_snapshot,
      price_snapshot: updated.price_snapshot,
      status: updated.status,
      cancellation_reason: updated.cancellation_reason,
      created_at: updated.created_at,
      updated_at: updated.updated_at
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 3. PROYECTAR AGENDA OPERATIVA (READ-ONLY EN MEMORIA)
 */
async function getAgendaProjection(activeContext, query = {}) {
  const tenantId = activeContext.tenant_id;
  const establishmentId = activeContext.establishment_id;
  const callerMembershipId = activeContext.active_membership_id;
  const callerRole = activeContext.role;
  const { target_date, membership_id: filterMembershipId } = query;

  if (!target_date) {
    const err = new Error('target_date (YYYY-MM-DD) is required');
    err.status = 400;
    err.code = 'INVALID_TIME_FORMAT';
    throw err;
  }

  let bounds;
  try {
    bounds = getBogotaDayBounds(target_date);
  } catch (e) {
    const err = new Error('target_date must be in YYYY-MM-DD format');
    err.status = 400;
    err.code = 'INVALID_TIME_FORMAT';
    throw err;
  }

  // Filtrado por rol: PROFESSIONAL solo puede ver su propia agenda
  let targetMembershipFilter = filterMembershipId || null;
  if (callerRole === 'PROFESSIONAL') {
    targetMembershipFilter = callerMembershipId;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    // 1. Obtener profesionales activos de la sede
    let profQuery = `
      SELECT m.id AS membership_id, m.user_id, u.nombre
      FROM memberships m
      JOIN usuarios u ON u.id = m.user_id AND u.tenant_id = m.tenant_id
      WHERE m.tenant_id = $1 AND m.establishment_id = $2
        AND m.role IN ('PROFESSIONAL', 'OWNER', 'MANAGER')
        AND m.status = 'ACTIVE'
    `;
    const profParams = [tenantId, establishmentId];
    if (targetMembershipFilter) {
      profQuery += ` AND m.id = $3`;
      profParams.push(targetMembershipFilter);
    }
    profQuery += ` ORDER BY u.nombre ASC;`;

    const profRes = await client.query(profQuery, profParams);
    const professionals = profRes.rows;

    if (professionals.length === 0) {
      return {
        establishment_id: establishmentId,
        target_date: target_date,
        timezone: 'America/Bogota',
        professionals: []
      };
    }

    const membershipIds = professionals.map(p => p.membership_id);
    const userIds = professionals.map(p => p.user_id);

    // 2. Obtener turnos laborales del día (staff_schedules)
    const schedRes = await client.query(`
      SELECT membership_id, start_time, end_time
      FROM staff_schedules
      WHERE tenant_id = $1 AND establishment_id = $2
        AND day_of_week = $3
        AND membership_id = ANY($4)
      ORDER BY start_time ASC;
    `, [tenantId, establishmentId, bounds.dayOfWeek, membershipIds]);

    // 3. Obtener citas SaaS del día (saas_appointments)
    const apptRes = await client.query(`
      SELECT a.id, a.membership_id, a.scheduled_at, a.end_time,
             a.service_name_snapshot, a.status, a.customer_user_id,
             a.guest_name, u.nombre AS customer_name
      FROM saas_appointments a
      LEFT JOIN usuarios u ON u.id = a.customer_user_id AND u.tenant_id = a.tenant_id
      WHERE a.tenant_id = $1 AND a.establishment_id = $2
        AND a.membership_id = ANY($3)
        AND a.scheduled_at >= $4 AND a.scheduled_at < $5
      ORDER BY a.scheduled_at ASC;
    `, [tenantId, establishmentId, membershipIds, bounds.startUtc.toISOString(), bounds.endUtc.toISOString()]);

    // 4. Obtener reservas Marketplace B2C activas (public.bookings)
    const bookRes = await client.query(`
      SELECT b.id, b.provider_id, b.scheduled_at, b.estado, s.duration_minutes
      FROM bookings b
      JOIN services s ON s.id = b.service_id
      WHERE b.tenant_id = $1
        AND b.provider_id = ANY($2)
        AND b.scheduled_at >= $3 AND b.scheduled_at < $4
        AND b.estado IN ('CONFIRMADA', 'COMPLETADA', 'EN_PROGRESO', 'PENDIENTE_PAGO')
      ORDER BY b.scheduled_at ASC;
    `, [tenantId, userIds, bounds.startUtc.toISOString(), bounds.endUtc.toISOString()]);

    // 5. Consolidar en memoria por profesional
    const resultProfessionals = professionals.map(prof => {
      const profShifts = schedRes.rows
        .filter(s => s.membership_id === prof.membership_id)
        .map(s => ({
          start_time: s.start_time.substring(0, 5),
          end_time: s.end_time.substring(0, 5)
        }));

      const profAppointments = apptRes.rows
        .filter(a => a.membership_id === prof.membership_id)
        .map(a => {
          const clientDisplayName = a.customer_user_id 
            ? (a.customer_name || '').trim() || 'Cliente Registrado'
            : a.guest_name;

          return {
            id: a.id,
            start_time: formatBogotaIso(a.scheduled_at).substring(11, 16),
            end_time: formatBogotaIso(a.end_time).substring(11, 16),
            service_name: a.service_name_snapshot,
            client_name: clientDisplayName,
            status: a.status
          };
        });

      const profBookings = bookRes.rows
        .filter(b => b.provider_id === prof.user_id)
        .map(b => {
          const bStart = new Date(b.scheduled_at);
          const bEnd = new Date(bStart.getTime() + (b.duration_minutes || 30) * 60 * 1000);
          return {
            id: b.id,
            start_time: formatBogotaIso(bStart).substring(11, 16),
            end_time: formatBogotaIso(bEnd).substring(11, 16),
            status: b.estado
          };
        });

      return {
        membership_id: prof.membership_id,
        user_id: prof.user_id,
        name: (prof.nombre || '').trim() || 'Profesional',
        shifts: profShifts,
        appointments: profAppointments,
        marketplace_bookings: profBookings
      };
    });

    await client.query('COMMIT');
    return {
      establishment_id: establishmentId,
      target_date: target_date,
      timezone: 'America/Bogota',
      professionals: resultProfessionals
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 4. OBTENER APPOINTMENT POR ID
 */
async function getAppointmentById(activeContext, appointmentId) {
  const tenantId = activeContext.tenant_id;
  const establishmentId = activeContext.establishment_id;
  const callerMembershipId = activeContext.active_membership_id;
  const callerRole = activeContext.role;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const res = await client.query(`
      SELECT * FROM saas_appointments
      WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3;
    `, [appointmentId, establishmentId, tenantId]);

    if (res.rows.length === 0) {
      const err = new Error(`Appointment ${appointmentId} not found`);
      err.status = 404;
      err.code = 'APPOINTMENT_NOT_FOUND';
      throw err;
    }

    const appt = res.rows[0];

    // Verificar permisos
    if (callerRole === 'PROFESSIONAL' && appt.membership_id !== callerMembershipId) {
      const err = new Error('Professional can only view their own appointments');
      err.status = 403;
      err.code = 'UNAUTHORIZED_ROLE';
      throw err;
    }

    await client.query('COMMIT');
    return {
      id: appt.id,
      tenant_id: appt.tenant_id,
      establishment_id: appt.establishment_id,
      service_offer_id: appt.service_offer_id,
      membership_id: appt.membership_id,
      client_mode: appt.customer_user_id ? 'REGISTERED' : 'GUEST',
      customer_user_id: appt.customer_user_id,
      guest_name: appt.guest_name,
      guest_phone: appt.guest_phone,
      guest_email: appt.guest_email,
      scheduled_at: formatBogotaIso(appt.scheduled_at),
      end_time: formatBogotaIso(appt.end_time),
      service_name_snapshot: appt.service_name_snapshot,
      duration_minutes_snapshot: appt.duration_minutes_snapshot,
      price_snapshot: appt.price_snapshot,
      status: appt.status,
      cancellation_reason: appt.cancellation_reason,
      created_at: appt.created_at,
      updated_at: appt.updated_at
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

module.exports = {
  createAppointment,
  transitionAppointmentStatus,
  getAgendaProjection,
  getAppointmentById
};
