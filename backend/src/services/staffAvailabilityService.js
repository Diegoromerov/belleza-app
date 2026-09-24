// backend/src/services/staffAvailabilityService.js
const { pool } = require('../config/db');

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const TIME_REGEX = /^([01]\d|2[0-3]):([0-5]\d)(:([0-5]\d))?$/;

const DAY_MAP = {
  monday: 1,
  tuesday: 2,
  wednesday: 3,
  thursday: 4,
  friday: 5,
  saturday: 6,
  sunday: 7
};

const REVERSE_DAY_MAP = {
  1: 'monday',
  2: 'tuesday',
  3: 'wednesday',
  4: 'thursday',
  5: 'friday',
  6: 'saturday',
  7: 'sunday'
};

const SPANISH_DAY_MAP = {
  lunes: 'monday',
  martes: 'tuesday',
  miercoles: 'wednesday',
  miércoles: 'wednesday',
  jueves: 'thursday',
  viernes: 'friday',
  sabado: 'saturday',
  sábado: 'saturday',
  domingo: 'sunday'
};

function isValidUUID(val) {
  return typeof val === 'string' && UUID_REGEX.test(val);
}

function createError(code, message, statusCode = 400) {
  const err = new Error(message);
  err.code = code;
  err.statusCode = statusCode;
  return err;
}

function normalizeTime(timeStr) {
  if (!timeStr || typeof timeStr !== 'string') return null;
  const match = timeStr.trim().match(TIME_REGEX);
  if (!match) return null;
  const hours = match[1];
  const minutes = match[2];
  return `${hours}:${minutes}`;
}

function timeToMinutes(timeStr) {
  const parts = timeStr.split(':');
  return parseInt(parts[0], 10) * 60 + parseInt(parts[1], 10);
}

function parseAndValidateWeeklySchedule(weeklySchedule) {
  if (!weeklySchedule || typeof weeklySchedule !== 'object') {
    throw createError('INVALID_PAYLOAD', 'El horario semanal (weekly_schedule) debe ser un objeto.', 400);
  }

  const flattenedIntervals = [];

  for (const [dayKey, dayNum] of Object.entries(DAY_MAP)) {
    const dayConfig = weeklySchedule[dayKey];
    if (!dayConfig) {
      continue;
    }

    if (typeof dayConfig !== 'object') {
      throw createError('INVALID_DAY_STRUCTURE', `La configuración para el día '${dayKey}' debe ser un objeto.`, 400);
    }

    const isWorking = dayConfig.is_working !== false;
    const timeBlocks = Array.isArray(dayConfig.time_blocks) ? dayConfig.time_blocks : [];

    if (!isWorking || timeBlocks.length === 0) {
      continue;
    }

    const parsedBlocks = [];
    for (let i = 0; i < timeBlocks.length; i++) {
      const block = timeBlocks[i];
      if (!block || typeof block !== 'object') {
        throw createError('INVALID_TIME_BLOCK', `Bloque de horario inválido en el día '${dayKey}'.`, 400);
      }

      const startNorm = normalizeTime(block.start_time);
      const endNorm = normalizeTime(block.end_time);

      if (!startNorm || !endNorm) {
        throw createError('INVALID_TIME_FORMAT', `Formato de hora inválido en el día '${dayKey}'. Se requiere formato HH:MM (00:00 a 23:59).`, 400);
      }

      const startMin = timeToMinutes(startNorm);
      const endMin = timeToMinutes(endNorm);

      if (startMin >= endMin) {
        throw createError('INVALID_TIME_ORDER', `La hora de inicio (${startNorm}) debe ser estrictamente menor a la hora de fin (${endNorm}) en el día '${dayKey}'.`, 400);
      }

      parsedBlocks.push({
        day_of_week: dayNum,
        day_name: dayKey,
        start_time: startNorm,
        end_time: endNorm,
        start_min: startMin,
        end_min: endMin
      });
    }

    parsedBlocks.sort((a, b) => a.start_min - b.start_min);

    for (let k = 0; k < parsedBlocks.length - 1; k++) {
      const current = parsedBlocks[k];
      const next = parsedBlocks[k + 1];

      if (next.start_min < current.end_min) {
        throw createError(
          'OVERLAPPING_INTERVALS',
          `Se detectó solapamiento de intervalos en el día '${dayKey}': [${current.start_time}-${current.end_time}) y [${next.start_time}-${next.end_time}).`,
          400
        );
      }
    }

    for (const b of parsedBlocks) {
      flattenedIntervals.push(b);
    }
  }

  return flattenedIntervals;
}

function evaluateOperatingHoursWarning(flattenedIntervals, establishmentOperatingHours) {
  if (!establishmentOperatingHours || typeof establishmentOperatingHours !== 'object') {
    return false;
  }

  for (const interval of flattenedIntervals) {
    const dayName = interval.day_name;
    const spanishDay = Object.keys(SPANISH_DAY_MAP).find(k => SPANISH_DAY_MAP[k] === dayName);
    const dayHours = establishmentOperatingHours[dayName] || (spanishDay ? establishmentOperatingHours[spanishDay] : null);

    if (!dayHours) {
      return true;
    }

    const isDayActive = dayHours.activo === true || dayHours.is_open === true || dayHours.active === true;
    if (!isDayActive) {
      return true;
    }

    let estStartMin = 0;
    let estEndMin = 1440;

    if (typeof dayHours.inicio === 'number' && typeof dayHours.fin === 'number') {
      estStartMin = dayHours.inicio * 60;
      estEndMin = dayHours.fin * 60;
    } else if (typeof dayHours.start_time === 'string' && typeof dayHours.end_time === 'string') {
      const s = normalizeTime(dayHours.start_time);
      const e = normalizeTime(dayHours.end_time);
      if (s && e) {
        estStartMin = timeToMinutes(s);
        estEndMin = timeToMinutes(e);
      }
    }

    if (interval.start_min < estStartMin || interval.end_min > estEndMin) {
      return true;
    }
  }

  return false;
}

function buildStaffScheduleDTO(membershipId, establishmentId, tenantId, rows, warningFlag = false) {
  const weeklySchedule = {
    monday: { is_working: false, time_blocks: [] },
    tuesday: { is_working: false, time_blocks: [] },
    wednesday: { is_working: false, time_blocks: [] },
    thursday: { is_working: false, time_blocks: [] },
    friday: { is_working: false, time_blocks: [] },
    saturday: { is_working: false, time_blocks: [] },
    sunday: { is_working: false, time_blocks: [] }
  };

  const hasConfiguredRows = rows && rows.length > 0;

  if (hasConfiguredRows) {
    for (const r of rows) {
      const dayName = REVERSE_DAY_MAP[r.day_of_week];
      if (dayName && weeklySchedule[dayName]) {
        weeklySchedule[dayName].is_working = true;
        
        const startTimeFormatted = typeof r.start_time === 'string' ? r.start_time.substring(0, 5) : r.start_time;
        const endTimeFormatted = typeof r.end_time === 'string' ? r.end_time.substring(0, 5) : r.end_time;

        weeklySchedule[dayName].time_blocks.push({
          start_time: startTimeFormatted,
          end_time: endTimeFormatted
        });
      }
    }

    for (const day of Object.values(weeklySchedule)) {
      day.time_blocks.sort((a, b) => a.start_time.localeCompare(b.start_time));
    }
  }

  return {
    membership_id: membershipId,
    establishment_id: establishmentId,
    tenant_id: tenantId,
    schedule_state: hasConfiguredRows ? 'CONFIGURED' : 'NOT_CONFIGURED',
    out_of_operating_hours_warning: warningFlag,
    weekly_schedule: weeklySchedule
  };
}

/**
 * OP-01: SET_STAFF_SCHEDULE (Atomic Weekly Schedule Replacement)
 */
const setStaffSchedule = async (tenantId, establishmentId, activeContext, targetMembershipId, payload) => {
  if (!tenantId || !establishmentId || !activeContext) {
    throw createError('ACTIVE_CONTEXT_REQUIRED', 'Contexto activo no inicializado o incompleto.', 400);
  }

  if (!isValidUUID(targetMembershipId)) {
    throw createError('INVALID_PAYLOAD', 'El identificador de la membresía (membership_id) debe ser un UUID válido.', 400);
  }

  const actorMembershipId = activeContext.active_membership_id || activeContext.membershipId;

  // Authorization Matrix (N03A-DEC-01):
  if (['RECEPTIONIST'].includes(activeContext.role)) {
    throw createError('FORBIDDEN_ROLE', 'El rol RECEPTIONIST no tiene autorización para gestionar horarios de disponibilidad.', 403);
  }

  if (activeContext.role === 'PROFESSIONAL' && actorMembershipId !== targetMembershipId) {
    throw createError('FORBIDDEN_SELF_MANAGEMENT_ONLY', 'Un colaborador con rol PROFESSIONAL solo puede gestionar su propia disponibilidad operativa.', 403);
  }

  if (!['OWNER', 'MANAGER', 'PROFESSIONAL'].includes(activeContext.role)) {
    throw createError('FORBIDDEN_ROLE', 'Rol no autorizado para configurar disponibilidad operativa.', 403);
  }

  const intervals = parseAndValidateWeeklySchedule(payload?.weekly_schedule);

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Set Tenant Context for RLS
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    // 2. Lock target membership row to guarantee concurrency consistency
    const memQuery = `
      SELECT id, status, role, establishment_id, tenant_id 
      FROM memberships 
      WHERE id = $1
      FOR UPDATE;
    `;
    const memRes = await client.query(memQuery, [targetMembershipId]);
    if (memRes.rows.length === 0) {
      throw createError('MEMBERSHIP_NOT_FOUND', 'La membresía destino no existe.', 404);
    }

    const targetMem = memRes.rows[0];

    if (targetMem.establishment_id !== establishmentId || targetMem.tenant_id !== tenantId) {
      throw createError('CROSS_ESTABLISHMENT_MISMATCH', 'La membresía destino no pertenece al establecimiento activo o tenant.', 422);
    }

    if (targetMem.status !== 'ACTIVE') {
      throw createError('INACTIVE_MEMBERSHIP', 'La membresía destino no se encuentra en estado ACTIVE.', 422);
    }

    // 3. Fetch establishment operating hours for warning check
    const estQuery = `
      SELECT operating_hours FROM establishments 
      WHERE id = $1 AND tenant_id = $2;
    `;
    const estRes = await client.query(estQuery, [establishmentId, tenantId]);
    const estHours = estRes.rows[0]?.operating_hours || {};
    const warningFlag = evaluateOperatingHoursWarning(intervals, estHours);

    // 4. Atomic Replacement: Delete old intervals for this staff member in this establishment
    const delQuery = `
      DELETE FROM staff_schedules 
      WHERE establishment_id = $1 AND membership_id = $2 AND tenant_id = $3;
    `;
    await client.query(delQuery, [establishmentId, targetMembershipId, tenantId]);

    // 5. Insert new intervals batch
    if (intervals.length > 0) {
      for (const item of intervals) {
        const insertQuery = `
          INSERT INTO staff_schedules (
            tenant_id, establishment_id, membership_id, day_of_week, start_time, end_time
          ) VALUES ($1, $2, $3, $4, $5, $6);
        `;
        await client.query(insertQuery, [
          tenantId,
          establishmentId,
          targetMembershipId,
          item.day_of_week,
          item.start_time,
          item.end_time
        ]);
      }
    }

    // 6. Fetch saved intervals
    const fetchQuery = `
      SELECT id, day_of_week, start_time, end_time 
      FROM staff_schedules 
      WHERE establishment_id = $1 AND membership_id = $2 AND tenant_id = $3
      ORDER BY day_of_week ASC, start_time ASC;
    `;
    const savedRes = await client.query(fetchQuery, [establishmentId, targetMembershipId, tenantId]);

    await client.query('COMMIT');

    return buildStaffScheduleDTO(
      targetMembershipId,
      establishmentId,
      tenantId,
      savedRes.rows,
      warningFlag
    );
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

/**
 * OP-02: GET_STAFF_SCHEDULE (Consult Staff Weekly Schedule)
 */
const getStaffSchedule = async (tenantId, establishmentId, activeContext, targetMembershipId) => {
  if (!tenantId || !establishmentId || !activeContext) {
    throw createError('ACTIVE_CONTEXT_REQUIRED', 'Contexto activo no inicializado o incompleto.', 400);
  }

  if (!isValidUUID(targetMembershipId)) {
    throw createError('INVALID_PAYLOAD', 'El identificador de la membresía (membership_id) debe ser un UUID válido.', 400);
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const memQuery = `
      SELECT id, status, role, establishment_id, tenant_id 
      FROM memberships 
      WHERE id = $1;
    `;
    const memRes = await client.query(memQuery, [targetMembershipId]);
    if (memRes.rows.length === 0) {
      throw createError('MEMBERSHIP_NOT_FOUND', 'La membresía destino no existe.', 404);
    }

    const targetMem = memRes.rows[0];
    if (targetMem.establishment_id !== establishmentId || targetMem.tenant_id !== tenantId) {
      throw createError('CROSS_ESTABLISHMENT_MISMATCH', 'La membresía destino no pertenece al establecimiento activo o tenant.', 422);
    }

    const fetchQuery = `
      SELECT id, day_of_week, start_time, end_time 
      FROM staff_schedules 
      WHERE establishment_id = $1 AND membership_id = $2 AND tenant_id = $3
      ORDER BY day_of_week ASC, start_time ASC;
    `;
    const scheduleRes = await client.query(fetchQuery, [establishmentId, targetMembershipId, tenantId]);

    const estQuery = `
      SELECT operating_hours FROM establishments 
      WHERE id = $1 AND tenant_id = $2;
    `;
    const estRes = await client.query(estQuery, [establishmentId, tenantId]);
    const estHours = estRes.rows[0]?.operating_hours || {};

    let warningFlag = false;
    if (scheduleRes.rows.length > 0) {
      const flattened = scheduleRes.rows.map(r => ({
        day_of_week: r.day_of_week,
        day_name: REVERSE_DAY_MAP[r.day_of_week],
        start_time: r.start_time.substring(0, 5),
        end_time: r.end_time.substring(0, 5),
        start_min: timeToMinutes(r.start_time.substring(0, 5)),
        end_min: timeToMinutes(r.end_time.substring(0, 5))
      }));
      warningFlag = evaluateOperatingHoursWarning(flattened, estHours);
    }

    await client.query('COMMIT');

    return buildStaffScheduleDTO(
      targetMembershipId,
      establishmentId,
      tenantId,
      scheduleRes.rows,
      warningFlag
    );
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch (_) {}
    throw err;
  } finally {
    client.release();
  }
};

/**
 * OP-03: LIST_ESTABLISHMENT_STAFF_SCHEDULES (List All Staff Schedules in Establishment)
 */
const listEstablishmentStaffSchedules = async (tenantId, establishmentId, activeContext) => {
  if (!tenantId || !establishmentId || !activeContext) {
    throw createError('ACTIVE_CONTEXT_REQUIRED', 'Contexto activo no inicializado o incompleto.', 400);
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const query = `
      SELECT 
        m.id AS membership_id, 
        m.status, 
        m.role,
        u.nombre,
        s.id AS schedule_id, 
        s.day_of_week, 
        s.start_time, 
        s.end_time
      FROM memberships m
      JOIN usuarios u ON m.user_id = u.id
      LEFT JOIN staff_schedules s 
        ON m.id = s.membership_id AND s.establishment_id = m.establishment_id
      WHERE m.establishment_id = $1 AND m.tenant_id = $2 AND m.status = 'ACTIVE'
      ORDER BY m.id, s.day_of_week ASC, s.start_time ASC;
    `;
    const res = await client.query(query, [establishmentId, tenantId]);

    const grouped = new Map();
    for (const row of res.rows) {
      if (!grouped.has(row.membership_id)) {
        grouped.set(row.membership_id, {
          membership_id: row.membership_id,
          user_name: row.nombre || '',
          role: row.role,
          status: row.status,
          rows: []
        });
      }

      if (row.schedule_id) {
        grouped.get(row.membership_id).rows.push({
          id: row.schedule_id,
          day_of_week: row.day_of_week,
          start_time: row.start_time,
          end_time: row.end_time
        });
      }
    }

    const results = [];
    for (const [memId, staffData] of grouped.entries()) {
      const dto = buildStaffScheduleDTO(
        memId,
        establishmentId,
        tenantId,
        staffData.rows,
        false
      );
      results.push({
        membership_id: memId,
        user_name: staffData.user_name,
        role: staffData.role,
        schedule_state: dto.schedule_state,
        weekly_schedule: dto.weekly_schedule
      });
    }

    await client.query('COMMIT');

    return results;
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch (_) {}
    throw err;
  } finally {
    client.release();
  }
};

/**
 * OP-04: DELETE_STAFF_SCHEDULE (Delete Entire Staff Schedule in Establishment)
 */
const deleteStaffSchedule = async (tenantId, establishmentId, activeContext, targetMembershipId) => {
  if (!tenantId || !establishmentId || !activeContext) {
    throw createError('ACTIVE_CONTEXT_REQUIRED', 'Contexto activo no inicializado o incompleto.', 400);
  }

  if (!isValidUUID(targetMembershipId)) {
    throw createError('INVALID_PAYLOAD', 'El identificador de la membresía (membership_id) debe ser un UUID válido.', 400);
  }

  if (!['OWNER', 'MANAGER'].includes(activeContext.role)) {
    throw createError('FORBIDDEN_ROLE', 'Solo los roles OWNER o MANAGER pueden eliminar la disponibilidad de un colaborador.', 403);
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const memQuery = `
      SELECT id, status, role, establishment_id, tenant_id 
      FROM memberships 
      WHERE id = $1
      FOR UPDATE;
    `;
    const memRes = await client.query(memQuery, [targetMembershipId]);
    if (memRes.rows.length === 0) {
      throw createError('MEMBERSHIP_NOT_FOUND', 'La membresía destino no existe.', 404);
    }

    const targetMem = memRes.rows[0];
    if (targetMem.establishment_id !== establishmentId || targetMem.tenant_id !== tenantId) {
      throw createError('CROSS_ESTABLISHMENT_MISMATCH', 'La membresía destino no pertenece al establecimiento activo o tenant.', 422);
    }

    const delQuery = `
      DELETE FROM staff_schedules 
      WHERE establishment_id = $1 AND membership_id = $2 AND tenant_id = $3;
    `;
    await client.query(delQuery, [establishmentId, targetMembershipId, tenantId]);

    await client.query('COMMIT');

    return {
      success: true,
      message: 'Staff schedule deleted successfully. State reverted to NOT_CONFIGURED.',
      membership_id: targetMembershipId,
      schedule_state: 'NOT_CONFIGURED'
    };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

module.exports = {
  setStaffSchedule,
  getStaffSchedule,
  listEstablishmentStaffSchedules,
  deleteStaffSchedule,
  parseAndValidateWeeklySchedule,
  evaluateOperatingHoursWarning,
  buildStaffScheduleDTO
};
