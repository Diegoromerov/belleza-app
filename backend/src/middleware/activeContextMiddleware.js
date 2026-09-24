// backend/src/middleware/activeContextMiddleware.js
const activeContextService = require('../services/activeContextService');

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * Node Contract — Active Context v1.0 Middleware
 * Intercepts requests, validates header x-active-membership-id structurally server-side,
 * and attaches validated active context to req.activeContext.
 */
const activeContextMiddleware = async (req, res, next) => {
  const membershipIdHeader = req.headers['x-active-membership-id'];

  if (!membershipIdHeader) {
    return res.status(400).json({
      error: 'MISSING_ACTIVE_MEMBERSHIP_HEADER',
      message: 'Header x-active-membership-id requerido para acceder al contexto activo.',
    });
  }

  const membershipId = typeof membershipIdHeader === 'string' ? membershipIdHeader.trim() : '';

  if (!UUID_REGEX.test(membershipId)) {
    return res.status(400).json({
      error: 'INVALID_MEMBERSHIP_UUID',
      message: 'Identificador de membresía en header x-active-membership-id es inválido.',
    });
  }

  if (!req.user || !req.user.id) {
    return res.status(401).json({
      error: 'IDENTITY_NOT_FOUND',
      message: 'No autorizado. Token de identidad requerido antes de validar contexto activo.',
    });
  }

  try {
    const activeContext = await activeContextService.validateAndResolveActiveContext(
      req.user.id,
      membershipId
    );

    // Attach validated context to request for downstream handlers
    req.activeContext = activeContext;
    req.tenantId = activeContext.tenant_id;
    req.establishmentId = activeContext.establishment_id;
    req.membershipId = activeContext.active_membership_id;

    next();
  } catch (error) {
    if (error.code === 'MEMBERSHIP_SELECTION_REQUIRED' || error.code === 'INVALID_MEMBERSHIP_UUID') {
      return res.status(400).json({
        error: error.code,
        message: error.message,
      });
    }

    if (error.code === 'IDENTITY_NOT_FOUND') {
      return res.status(401).json({
        error: error.code,
        message: 'Identidad no autorizada.',
      });
    }

    if (error.code === 'MEMBERSHIP_ACCESS_DENIED' || error.code === 'TENANT_MISMATCH' || error.code === 'MEMBERSHIP_NOT_ACTIVE') {
      return res.status(403).json({
        error: error.code,
        message: error.message,
      });
    }

    if (error.code === 'MEMBERSHIP_NOT_FOUND') {
      return res.status(404).json({
        error: error.code,
        message: 'Membresía no encontrada o inaccesible para la identidad.',
      });
    }

    console.error('Error in activeContextMiddleware:', error);
    return res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: 'Error interno al validar el contexto activo.',
    });
  }
};

module.exports = {
  activeContextMiddleware,
};
