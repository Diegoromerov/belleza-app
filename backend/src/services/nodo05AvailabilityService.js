// backend/src/services/nodo05AvailabilityService.js
const { pool } = require('../config/db');

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const DATE_REGEX = /^\d{4}-\d{2}-\d{2}$/;

function isValidUUID(val) {
  return typeof val === 'string' && UUID_REGEX.test(val);
}

function createError(code, message, statusCode = 400) {
  const err = new Error(message);
  err.code = code;
  err.statusCode = statusCode;
  return err;
}

/**
 * Validates whether a YYYY-MM-DD string represents a real, valid calendar date.
 */
function isValidDateString(dateStr) {
  if (typeof dateStr !== 'string' || !DATE_REGEX.test(dateStr)) {
    return false;
  }
  const [yearStr, monthStr, dayStr] = dateStr.split('-');
  const year = parseInt(yearStr, 10);
  const month = parseInt(monthStr, 10);
  const day = parseInt(dayStr, 10);

  if (year < 1900 || year > 2200 || month < 1 || month > 12 || day < 1 || day > 31) {
    return false;
  }

  const d = new Date(Date.UTC(year, month - 1, day, 12, 0, 0));
  return (
    d.getUTCFullYear() === year &&
    d.getUTCMonth() === month - 1 &&
    d.getUTCDate() === day
  );
}

/**
 * Calculates day of week (1=Monday ... 7=Sunday) for a target_date in America/Bogota.
 */
function getDayOfWeek(dateStr) {
  const [year, month, day] = dateStr.split('-').map(Number);
  const dt = new Date(Date.UTC(year, month - 1, day, 12, 0, 0));
  const jsDay = dt.getUTCDay(); // 0 = Sunday, 1 = Monday, ... 6 = Saturday
  return jsDay === 0 ? 7 : jsDay;
}

/**
 * Converts 'HH:MM' or 'HH:MM:SS' string or integer hour to minutes from midnight.
 */
function parseTimeToMinutes(timeVal) {
  if (typeof timeVal === 'number') {
    return timeVal * 60;
  }
  if (typeof timeVal !== 'string') {
    return null;
  }
  const parts = timeVal.trim().split(':');
  if (parts.length < 2) return null;
  const hours = parseInt(parts[0], 10);
  const minutes = parseInt(parts[1], 10);
  if (isNaN(hours) || isNaN(minutes)) return null;
  return hours * 60 + minutes;
}

/**
 * Converts minutes from midnight to 'HH:MM' format.
 */
function formatMinutesToTime(minutes) {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
}

/**
 * Polymorphic parser for establishment operating hours.
 * Supports day keys in English and Spanish, boolean flags (is_open, activo, active),
 * and string or numeric time formats.
 */
function parseOperatingHoursForDay(operatingHours, dayOfWeek) {
  if (!operatingHours || typeof operatingHours !== 'object') {
    return null;
  }

  const dayKeysMap = {
    1: ['monday', 'lunes', 'mon', 'lun', '1'],
    2: ['tuesday', 'martes', 'tue', 'mar', '2'],
    3: ['wednesday', 'miercoles', 'miércoles', 'wed', 'mie', 'mié', '3'],
    4: ['thursday', 'jueves', 'thu', 'jue', '4'],
    5: ['friday', 'viernes', 'fri', 'vie', '5'],
    6: ['saturday', 'sabado', 'sábado', 'sat', 'sab', 'sáb', '6'],
    7: ['sunday', 'domingo', 'sun', 'dom', '7'],
  };

  const candidateKeys = dayKeysMap[dayOfWeek] || [];
  let dayConfig = null;

  // Check top-level keys or nested schedule object
  const hoursObj = operatingHours.schedule || operatingHours.hours || operatingHours;

  for (const k of candidateKeys) {
    if (hoursObj[k] !== undefined) {
      dayConfig = hoursObj[k];
      break;
    }
    // Case insensitive search
    const matchingKey = Object.keys(hoursObj).find(
      (prop) => prop.toLowerCase() === k.toLowerCase()
    );
    if (matchingKey) {
      dayConfig = hoursObj[matchingKey];
      break;
    }
  }

  if (!dayConfig || typeof dayConfig !== 'object') {
    return null;
  }

  // Check open / active status
  const isOpen =
    dayConfig.is_open !== undefined
      ? Boolean(dayConfig.is_open)
      : dayConfig.activo !== undefined
      ? Boolean(dayConfig.activo)
      : dayConfig.active !== undefined
      ? Boolean(dayConfig.active)
      : dayConfig.abierto !== undefined
      ? Boolean(dayConfig.abierto)
      : true;

  if (!isOpen) {
    return { isOpen: false };
  }

  const openRaw =
    dayConfig.open_time ||
    dayConfig.open ||
    dayConfig.start_time ||
    dayConfig.start ||
    dayConfig.inicio ||
    dayConfig.hora_inicio ||
    dayConfig.desde;

  const closeRaw =
    dayConfig.close_time ||
    dayConfig.close ||
    dayConfig.end_time ||
    dayConfig.end ||
    dayConfig.fin ||
    dayConfig.hora_fin ||
    dayConfig.hasta;

  const startMinutes = parseTimeToMinutes(openRaw);
  const endMinutes = parseTimeToMinutes(closeRaw);

  if (startMinutes === null || endMinutes === null || startMinutes >= endMinutes) {
    return { isOpen: false };
  }

  return {
    isOpen: true,
    startMinutes,
    endMinutes,
  };
}

/**
 * NODO-05: Projects real-time availability slots for a service offer and target date.
 * Read-only computational projection runtime in America/Bogota (UTC-5).
 * Uses canonical transaction-scoped SET LOCAL (set_config(..., true)) for zero pool leakage.
 *
 * @param {number} tenantId
 * @param {string} establishmentId
 * @param {Object} activeContext
 * @param {Object} queryParams
 */
const projectAvailability = async (tenantId, establishmentId, activeContext, queryParams = {}) => {
  if (!tenantId || !establishmentId || !activeContext) {
    throw createError('ACTIVE_CONTEXT_REQUIRED', 'Contexto activo no inicializado o incompleto.', 400);
  }

  const {
    service_offer_id,
    target_date,
    projection_mode: rawProjectionMode,
    membership_id,
    step_minutes: rawStepMinutes,
  } = queryParams;

  // 1. Validation: service_offer_id
  if (!isValidUUID(service_offer_id)) {
    throw createError('INVALID_SERVICE_OFFER_ID', 'service_offer_id debe ser un UUID válido.', 400);
  }

  // 2. Validation: target_date
  if (!isValidDateString(target_date)) {
    throw createError('INVALID_TARGET_DATE', 'target_date debe tener un formato de fecha válido (YYYY-MM-DD).', 400);
  }

  // 3. Validation: step_minutes
  let stepMinutes = 15;
  if (rawStepMinutes !== undefined && rawStepMinutes !== null && rawStepMinutes !== '') {
    const parsedStep = Number(rawStepMinutes);
    if (!Number.isInteger(parsedStep) || parsedStep < 5 || parsedStep > 120) {
      throw createError('INVALID_STEP_MINUTES', 'step_minutes debe ser un entero entre 5 y 120.', 400);
    }
    stepMinutes = parsedStep;
  }

  // 4. Validation & Reconciliation: projection_mode and membership_id (Finding 2)
  let projectionMode;
  const hasMembershipId = membership_id !== undefined && membership_id !== null && membership_id !== '';

  if (hasMembershipId && !isValidUUID(membership_id)) {
    throw createError('INVALID_MEMBERSHIP_ID', 'membership_id debe ser un UUID válido.', 400);
  }

  if (rawProjectionMode !== undefined && rawProjectionMode !== null && rawProjectionMode !== '') {
    if (rawProjectionMode !== 'TARGETED' && rawProjectionMode !== 'AGGREGATED') {
      throw createError('INVALID_PROJECTION_MODE', 'projection_mode debe ser TARGETED o AGGREGATED.', 400);
    }

    if (rawProjectionMode === 'TARGETED') {
      if (!hasMembershipId) {
        throw createError('MEMBERSHIP_ID_REQUIRED', 'membership_id es requerido cuando projection_mode es TARGETED.', 400);
      }
      projectionMode = 'TARGETED';
    } else if (rawProjectionMode === 'AGGREGATED') {
      if (hasMembershipId) {
        throw createError('INVALID_PROJECTION_MODE', 'membership_id no debe suministrarse cuando projection_mode es AGGREGATED.', 400);
      }
      projectionMode = 'AGGREGATED';
    }
  } else {
    // projection_mode omitted: authorized canonical derivation based on membership_id presence
    projectionMode = hasMembershipId ? 'TARGETED' : 'AGGREGATED';
  }

  const isTargeted = projectionMode === 'TARGETED';
  const dayOfWeek = getDayOfWeek(target_date);

  const client = await pool.connect();
  try {
    // Transaction-scoped RLS context (Finding 1):
    // BEGIN + set_config(..., true) ensures setting is strictly local to this transaction
    // and is automatically cleared upon COMMIT or ROLLBACK.
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    // 5. Query Service Offer
    const offerRes = await client.query(
      `SELECT id, name, base_duration
       FROM public.service_offers
       WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3;`,
      [service_offer_id, establishmentId, tenantId]
    );

    if (offerRes.rows.length === 0) {
      await client.query('ROLLBACK');
      throw createError('SERVICE_OFFER_NOT_FOUND', 'La oferta de servicio especificada no existe en la sede activa.', 404);
    }

    const offer = offerRes.rows[0];
    const serviceDurationMinutes = parseInt(offer.base_duration, 10);
    if (isNaN(serviceDurationMinutes) || serviceDurationMinutes <= 0) {
      await client.query('ROLLBACK');
      throw createError('INVALID_SERVICE_OFFER', 'La oferta de servicio posee una duración inválida.', 400);
    }

    // 6. Query Establishment Operating Hours
    const estRes = await client.query(
      `SELECT id, operating_hours
       FROM public.establishments
       WHERE id = $1 AND tenant_id = $2;`,
      [establishmentId, tenantId]
    );

    if (estRes.rows.length === 0) {
      await client.query('ROLLBACK');
      throw createError('ESTABLISHMENT_NOT_FOUND', 'La sede activa no fue encontrada.', 404);
    }

    const establishment = estRes.rows[0];
    const estHours = parseOperatingHoursForDay(establishment.operating_hours, dayOfWeek);

    // Canonical response skeleton
    const responsePayload = {
      establishment_id: establishmentId,
      service_offer_id: service_offer_id,
      target_date: target_date,
      day_of_week: dayOfWeek,
      service_duration_minutes: serviceDurationMinutes,
      step_minutes: stepMinutes,
      projection_mode: projectionMode,
      slots: [],
    };

    // If establishment is closed on that day, commit transaction and return empty slots
    if (!estHours || !estHours.isOpen) {
      await client.query('COMMIT');
      return responsePayload;
    }

    // 7. Resolve Eligible Memberships
    let eligibleMembers = []; // Array of { id: membership_id, user_id }

    if (isTargeted) {
      // TARGETED Mode: Validate specific membership
      const memberRes = await client.query(
        `SELECT id, user_id, status, role
         FROM public.memberships
         WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3;`,
        [membership_id, establishmentId, tenantId]
      );

      if (memberRes.rows.length === 0) {
        await client.query('ROLLBACK');
        throw createError('MEMBERSHIP_NOT_FOUND', 'La membresía especificada no existe en la sede activa.', 404);
      }

      const member = memberRes.rows[0];
      if (member.status !== 'ACTIVE') {
        await client.query('ROLLBACK');
        throw createError('INACTIVE_MEMBERSHIP', 'La membresía del colaborador no se encuentra activa.', 422);
      }

      // Verify assignment to service offer
      const assignRes = await client.query(
        `SELECT id
         FROM public.service_assignments
         WHERE service_offer_id = $1 AND membership_id = $2;`,
        [service_offer_id, membership_id]
      );

      if (assignRes.rows.length === 0) {
        await client.query('ROLLBACK');
        throw createError('UNASSIGNED_PROFESSIONAL', 'El colaborador especificado no está asignado a esta oferta de servicio.', 422);
      }

      eligibleMembers = [{ id: member.id, user_id: member.user_id }];
    } else {
      // AGGREGATED Mode: Fetch all active assigned memberships
      const assignRes = await client.query(
        `SELECT sa.membership_id, m.user_id, m.status
         FROM public.service_assignments sa
         JOIN public.memberships m ON sa.membership_id = m.id
         WHERE sa.service_offer_id = $1
           AND m.establishment_id = $2
           AND m.tenant_id = $3
           AND m.status = 'ACTIVE';`,
        [service_offer_id, establishmentId, tenantId]
      );

      // Rule N05-DEC-06: Zero assignments returns 200 OK with slots: []
      if (assignRes.rows.length === 0) {
        await client.query('COMMIT');
        return responsePayload;
      }

      eligibleMembers = assignRes.rows.map((r) => ({
        id: r.membership_id,
        user_id: r.user_id,
      }));
    }

    const membershipIds = eligibleMembers.map((m) => m.id);
    const userIds = eligibleMembers.map((m) => m.user_id).filter(Boolean);

    // 8. Query Staff Schedules (Migration 069)
    const scheduleRes = await client.query(
      `SELECT membership_id, start_time, end_time
       FROM public.staff_schedules
       WHERE establishment_id = $1
         AND tenant_id = $2
         AND day_of_week = $3
         AND membership_id = ANY($4::uuid[]);`,
      [establishmentId, tenantId, dayOfWeek, membershipIds]
    );

    // Map schedules by membership_id
    const schedulesByMember = new Map();
    for (const row of scheduleRes.rows) {
      const sStart = parseTimeToMinutes(row.start_time);
      const sEnd = parseTimeToMinutes(row.end_time);
      if (sStart !== null && sEnd !== null && sStart < sEnd) {
        if (!schedulesByMember.has(row.membership_id)) {
          schedulesByMember.set(row.membership_id, []);
        }
        schedulesByMember.get(row.membership_id).push({
          startMinutes: sStart,
          endMinutes: sEnd,
        });
      }
    }

    // 9. Query Existing Active Bookings in America/Bogota (UTC-5)
    // Finding 3 & 4: Provider physical occupancy source of truth.
    // Day boundaries translated from America/Bogota to UTC:
    const [year, month, day] = target_date.split('-').map(Number);
    const startUtc = new Date(Date.UTC(year, month - 1, day, 5, 0, 0, 0)); // 00:00:00 COT
    const endUtc = new Date(Date.UTC(year, month - 1, day + 1, 4, 59, 59, 999)); // 23:59:59.999 COT

    let bookingsByUserId = new Map();
    if (userIds.length > 0) {
      const bookingRes = await client.query(
        `SELECT b.id, b.provider_id, b.scheduled_at, b.estado, s.duration_minutes
         FROM public.bookings b
         LEFT JOIN public.services s ON b.service_id = s.id
         WHERE b.provider_id = ANY($1::int[])
           AND b.estado != 'CANCELADA'
           AND b.scheduled_at >= $2
           AND b.scheduled_at <= $3;`,
        [userIds, startUtc.toISOString(), endUtc.toISOString()]
      );

      for (const row of bookingRes.rows) {
        // Finding 4: Use authoritative duration from services.duration_minutes.
        // If duration is missing/null/<=0, skip unresolvable duration without silent 60min assumption.
        const parsedDuration = parseInt(row.duration_minutes, 10);
        if (isNaN(parsedDuration) || parsedDuration <= 0) {
          continue;
        }

        const bDate = new Date(row.scheduled_at);
        // Translate UTC timestamp to America/Bogota local time (UTC-5)
        const localHour = (bDate.getUTCHours() - 5 + 24) % 24;
        const localMinute = bDate.getUTCMinutes();
        const bStartMinutes = localHour * 60 + localMinute;
        const bEndMinutes = bStartMinutes + parsedDuration;

        const pId = parseInt(row.provider_id, 10);
        if (!bookingsByUserId.has(pId)) {
          bookingsByUserId.set(pId, []);
        }
        bookingsByUserId.get(pId).push({
          start: bStartMinutes,
          end: bEndMinutes,
        });
      }
    }

    // 10. Generate Candidate Slots per Member and Intersect
    // Slot Map: startMinutes -> { start_time, end_time, memberships: Set<string> }
    const slotsMap = new Map();

    for (const member of eligibleMembers) {
      const memberSchedules = schedulesByMember.get(member.id) || [];
      const memberBookings = bookingsByUserId.get(member.user_id) || [];

      for (const sched of memberSchedules) {
        // Intersect staff schedule with establishment operating hours
        const windowStart = Math.max(sched.startMinutes, estHours.startMinutes);
        const windowEnd = Math.min(sched.endMinutes, estHours.endMinutes);

        if (windowStart >= windowEnd) continue;

        let t = windowStart;
        while (t + serviceDurationMinutes <= windowEnd) {
          const slotStart = t;
          const slotEnd = t + serviceDurationMinutes;

          // Check semi-open interval collision against active bookings:
          // Collision occurs IF AND ONLY IF (slotStart < bookEnd && slotEnd > bookStart)
          const hasCollision = memberBookings.some(
            (b) => slotStart < b.end && slotEnd > b.start
          );

          if (!hasCollision) {
            if (!slotsMap.has(slotStart)) {
              slotsMap.set(slotStart, {
                start_time: formatMinutesToTime(slotStart),
                end_time: formatMinutesToTime(slotEnd),
                memberships: new Set(),
              });
            }
            slotsMap.get(slotStart).memberships.add(member.id);
          }

          t += stepMinutes;
        }
      }
    }

    // 11. Format Deterministic Output (Chronological ASC, Member UUIDs ASC)
    const sortedStartKeys = Array.from(slotsMap.keys()).sort((a, b) => a - b);
    const finalSlots = sortedStartKeys.map((startKey) => {
      const slotData = slotsMap.get(startKey);
      const sortedMembers = Array.from(slotData.memberships).sort();
      return {
        start_time: slotData.start_time,
        end_time: slotData.end_time,
        available_memberships: sortedMembers,
      };
    });

    responsePayload.slots = finalSlots;

    await client.query('COMMIT');
    return responsePayload;
  } catch (error) {
    try {
      await client.query('ROLLBACK');
    } catch (rbErr) {
      // Silence rollback error if connection was terminated
    }
    throw error;
  } finally {
    client.release();
  }
};

module.exports = {
  projectAvailability,
  parseOperatingHoursForDay,
  getDayOfWeek,
  parseTimeToMinutes,
  formatMinutesToTime,
  isValidDateString,
  isValidUUID,
};
