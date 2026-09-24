// backend/src/controllers/crearDesdeCeroController.js
const crearDesdeCeroService = require('../services/crearDesdeCeroService');

/**
 * Node Contract — Crear Desde Cero v1.0 Controller
 * Handles HTTP requests for initial provisioning and Context Package compilation.
 * Protected by authMiddleware + activeContextMiddleware.
 */

/**
 * Handles POST /api/v1/saas/hub/onboarding/bootstrap
 * Compiles and returns the canonical transient Context Package for Pre-Nodo 01.
 */
const bootstrap = async (req, res) => {
  try {
    if (!req.user || !req.user.id) {
      return res.status(401).json({
        error: 'IDENTITY_NOT_FOUND',
        message: 'No autorizado. Token de identidad requerido.',
      });
    }

    if (!req.activeContext || !req.establishmentId || !req.tenantId) {
      return res.status(400).json({
        error: 'ACTIVE_CONTEXT_NOT_INITIALIZED',
        message: 'Contexto activo no inicializado o incompleto.',
      });
    }

    const result = await crearDesdeCeroService.compileContextPackage(
      req.user.id,
      req.tenantId,
      req.establishmentId,
      req.activeContext,
      req.body || {}
    );

    return res.status(200).json({
      status: 'success',
      data: result,
    });
  } catch (error) {
    if (error.code === 'INSUFFICIENT_PROVISIONING_ROLE') {
      return res.status(403).json({
        error: error.code,
        message: error.message,
      });
    }

    if (error.code === 'MEMBERSHIP_NOT_ACTIVE') {
      return res.status(403).json({
        error: error.code,
        message: error.message,
      });
    }

    if (error.code === 'ACTIVE_CONTEXT_REQUIRED') {
      return res.status(400).json({
        error: error.code,
        message: error.message,
      });
    }

    if (error.code === 'ESTABLISHMENT_NOT_FOUND') {
      return res.status(404).json({
        error: error.code,
        message: 'Establecimiento no encontrado o inaccesible para el tenant.',
      });
    }

    console.error('Error in crearDesdeCeroController.bootstrap:', error);
    return res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: 'Error interno al compilar el Context Package.',
    });
  }
};

module.exports = {
  bootstrap,
};
