// backend/src/middleware/ownerGuard.js
//
// Guardas de autorización por salón (multi-sede).
//
// Motivo: la pertenencia y el sub_rol se verificaban con condicionales `if`
// duplicados dentro de cada controlador (salonController.js:159-166, :204-215).
// Eso permite que un endpoint nuevo olvide el chequeo. Este middleware lo
// centraliza y falla cerrado.
//
// Reglas de diseño (no negociables):
//  1. El salon_id NUNCA se toma como verdad desde el cliente: se valida forma
//     y luego se confirma contra salon_miembros para el usuario autenticado.
//  2. Ante error de base de datos NO se llama a next(): se falla cerrado.
//  3. El sub_rol se lee de la base, no de req.user.role. `req.user.role` viene
//     de toApiRole() (config/jwt.js) y es un mapeo para la API, no el sub_rol
//     del salón.

const { pool } = require('../config/db');

// Sub-roles válidos en salon_miembros (alineados con salonController.inviteMember)
const SUB_ROLES = Object.freeze({
  DUENO: 'DUEÑO',
  ADMINISTRADOR: 'ADMINISTRADOR',
  PRESTADOR_INDEPENDIENTE: 'PRESTADOR_INDEPENDIENTE',
  EMPLEADO: 'EMPLEADO',
  RECEPCIONISTA: 'RECEPCIONISTA',
});

const ESTATUS_ACTIVO = 'ACTIVO';

/**
 * Extrae el salon_id de la petición y lo valida como entero positivo.
 * Orden de precedencia: params.salonId -> body.salon_id -> body.salonId
 *                       -> query.salon_id -> query.salonId
 *                       -> headers['x-active-salon-id'] -> headers['x-salon-id']
 * @returns {number|null} entero positivo, o null si no es resoluble/válido.
 */
function resolveSalonId(req) {
  const raw =
    req.params?.salonId ??
    req.body?.salon_id ??
    req.body?.salonId ??
    req.query?.salon_id ??
    req.query?.salonId ??
    req.headers?.['x-active-salon-id'] ??
    req.headers?.['x-salon-id'];

  if (raw === undefined || raw === null) return null;
  const str = String(raw).trim();
  if (str === '' || !/^\d+$/.test(str)) return null;

  const n = Number(str);
  return Number.isSafeInteger(n) && n > 0 ? n : null;
}

/**
 * Membresía activa del usuario en el salón.
 * @returns {Promise<{sub_rol: string}|null>}
 */
async function getActiveMembership(salonId, userId) {
  const res = await pool.query(
    `SELECT sub_rol
       FROM salon_miembros
      WHERE salon_id = $1 AND user_id = $2 AND estatus = $3`,
    [salonId, userId, ESTATUS_ACTIVO]
  );
  if (res.rows.length === 0) return null;
  return { sub_rol: String(res.rows[0].sub_rol || '').toUpperCase() };
}

/**
 * Fábrica de middleware: exige que req.user sea miembro ACTIVO del salón de la
 * petición con uno de los sub_roles indicados.
 *
 * Deja disponible `req.salonId` y `req.salonMembership` para el controlador,
 * de modo que el chequeo no se repita ni se pueda desincronizar.
 *
 * @param {...string} allowedRoles sub_roles aceptados (por defecto DUEÑO)
 */
function makeSalonRoleGuard(roles, opts = {}) {
  const allowed = (roles.length > 0 ? roles : [SUB_ROLES.DUENO])
    .map((r) => String(r).toUpperCase());
  const notMemberMessage = opts.notMemberMessage || 'No perteneces a este salón.';
  const forbiddenMessage =
    opts.forbiddenMessage || 'No tienes permisos de administración en este salón.';

  return async function salonRoleGuard(req, res, next) {
    if (!req.user || !req.user.id) {
      return res.status(401).json({ error: 'Acceso denegado. Autenticación requerida.' });
    }

    const salonId = resolveSalonId(req);
    if (salonId === null) {
      return res.status(400).json({ error: 'salon_id es obligatorio.' });
    }

    try {
      const membership = await getActiveMembership(salonId, req.user.id);

      if (!membership) {
        return res.status(403).json({ error: notMemberMessage });
      }

      if (!allowed.includes(membership.sub_rol)) {
        return res.status(403).json({ error: forbiddenMessage });
      }

      req.salonId = salonId;
      req.salonMembership = membership;
      return next();
    } catch (error) {
      // Falla cerrado: un error de DB no debe otorgar acceso.
      console.error('❌ ERROR ownerGuard:', error.message);
      return res.status(500).json({ error: 'Error al verificar permisos del salón.' });
    }
  };
}

/**
 * Fábrica genérica: exige que req.user sea miembro ACTIVO del salón de la
 * petición con uno de los sub_roles indicados (por defecto DUEÑO).
 */
function requireSalonRole(...roles) {
  return makeSalonRoleGuard(roles);
}

/** Solo el propietario del salón. */
const requireOwnerRole = makeSalonRoleGuard([SUB_ROLES.DUENO]);

/**
 * Propietario o administrador. Conserva el mensaje exacto que ya devolvía
 * salonController.inviteMember (salonController.js:166) para no alterar el
 * contrato observable del endpoint en su ruta de error.
 */
const requireSalonAdmin = makeSalonRoleGuard([SUB_ROLES.DUENO, SUB_ROLES.ADMINISTRADOR], {
  forbiddenMessage:
    'No tienes permisos de administración en este salón para invitar personal.',
});

/**
 * Protege al propietario frente a endpoints de mutación de miembros.
 *
 * Los endpoints actuales (salonRoutes.js) no permiten modificar ni eliminar
 * miembros, así que esta guarda es preventiva: se adjunta a cualquier ruta
 * nueva que reciba un `user_id` objetivo y garantiza que
 *   (a) no se degrade/desactive a un DUEÑO activo, y
 *   (b) no se pueda dejar al salón sin ningún DUEÑO activo.
 *
 * Requiere que `requireSalonRole` haya corrido antes (usa req.salonId).
 */
async function protectOwnerMember(req, res, next) {
  const targetRaw =
    req.params?.userId ??
    req.params?.memberId ??
    req.body?.user_id ??
    req.body?.userId;
  const targetId = targetRaw === undefined ? null : Number(String(targetRaw).trim());

  if (targetId === null || !Number.isSafeInteger(targetId) || targetId <= 0) {
    return res.status(400).json({ error: 'user_id objetivo es obligatorio.' });
  }

  try {
    const owners = await pool.query(
      `SELECT user_id
         FROM salon_miembros
        WHERE salon_id = $1 AND sub_rol = $2 AND estatus = $3`,
      [req.salonId, SUB_ROLES.DUENO, ESTATUS_ACTIVO]
    );

    const ownerIds = owners.rows.map((r) => Number(r.user_id));

    if (ownerIds.includes(targetId) && ownerIds.length <= 1) {
      return res.status(409).json({
        error: 'No se puede modificar, degradar ni desactivar al único propietario del salón.',
      });
    }

    // Si el objetivo no es propietario, no hay riesgo de dejar el salón sin DUEÑO,
    // pero se rechaza de forma explícita si el salón ya no tuviera ninguno.
    if (ownerIds.length === 0) {
      return res.status(409).json({
        error: 'El salón no tiene un propietario activo. Operación bloqueada por seguridad.',
      });
    }

    req.targetUserId = targetId;
    return next();
  } catch (error) {
    console.error('❌ ERROR protectOwnerMember:', error.message);
    return res.status(500).json({ error: 'Error al verificar el miembro objetivo.' });
  }
}

/**
 * Exige que el usuario autenticado sea propietario (DUEÑO) de al menos una sede activa
 * (ya sea como id_dueno en salones o sub_rol = 'DUEÑO' en salon_miembros).
 * No requiere que la petición especifique un salon_id individual.
 */
async function requireAnyOwnerSede(req, res, next) {
  if (!req.user || !req.user.id) {
    return res.status(401).json({ error: 'Acceso denegado. Autenticación requerida.' });
  }

  try {
    const ownedRes = await pool.query(
      `SELECT DISTINCT s.id
         FROM salones s
    LEFT JOIN salon_miembros sm ON sm.salon_id = s.id AND sm.user_id = $1 AND sm.estatus = 'ACTIVO'
        WHERE s.id_dueno = $1 OR sm.sub_rol = 'DUEÑO'`,
      [req.user.id]
    );

    if (ownedRes.rows.length === 0) {
      return res.status(403).json({ error: 'No tienes sedes registradas como propietario.' });
    }

    req.ownedSalonIds = ownedRes.rows.map((r) => Number(r.id));
    return next();
  } catch (error) {
    console.error('❌ ERROR requireAnyOwnerSede:', error.message);
    return res.status(500).json({ error: 'Error al verificar pertenencia de sedes del propietario.' });
  }
}

module.exports = {
  SUB_ROLES,
  resolveSalonId,
  getActiveMembership,
  requireSalonRole,
  requireOwnerRole,
  requireSalonAdmin,
  protectOwnerMember,
  requireAnyOwnerSede,
};
