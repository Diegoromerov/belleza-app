// backend/src/controllers/activeContextController.js
const activeContextService = require('../services/activeContextService');

/**
 * Handles explicit context activation.
 * POST /api/v1/saas/context/activate
 * Header: x-active-membership-id: <UUID> (ARCH-AC-001)
 */
const activateContext = async (req, res) => {
  try {
    if (!req.user || !req.user.id) {
      return res.status(401).json({
        error: 'IDENTITY_NOT_FOUND',
        message: 'No autorizado. Token de identidad requerido.',
      });
    }

    // Extract membership_id strictly from header (ARCH-AC-001)
    const membershipId = req.headers['x-active-membership-id'];

    if (!membershipId) {
      return res.status(400).json({
        error: 'MEMBERSHIP_SELECTION_REQUIRED',
        message: 'Identificador de membresía requerido en header x-active-membership-id.',
      });
    }

    const activeContext = await activeContextService.validateAndResolveActiveContext(
      req.user.id,
      membershipId
    );

    return res.status(200).json({
      status: 'success',
      data: {
        active_context: activeContext,
      },
    });
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

    console.error('Error in activateContext:', error);
    return res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: 'Error interno al activar el contexto.',
    });
  }
};

/**
 * Handles active context verification.
 * GET /api/v1/saas/context/active
 * Requires activeContextMiddleware to have populated req.activeContext.
 */
const getActiveContext = async (req, res) => {
  try {
    if (!req.activeContext) {
      return res.status(400).json({
        error: 'ACTIVE_CONTEXT_NOT_INITIALIZED',
        message: 'Contexto activo no inicializado.',
      });
    }

    return res.status(200).json({
      status: 'success',
      data: {
        active_context: req.activeContext,
      },
    });
  } catch (error) {
    console.error('Error in getActiveContext:', error);
    return res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: 'Error interno al consultar el contexto activo.',
    });
  }
};

module.exports = {
  activateContext,
  getActiveContext,
};
