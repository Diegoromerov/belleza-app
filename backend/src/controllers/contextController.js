// backend/src/controllers/contextController.js
const contextResolutionService = require('../services/contextResolutionService');

/**
 * Handles GET /api/v1/saas/context/available
 * Resolves Available Contexts for the authenticated Identity.
 */
const getAvailableContexts = async (req, res) => {
  try {
    if (!req.user || !req.user.id) {
      return res.status(401).json({
        error: 'IDENTITY_NOT_FOUND',
        message: 'No autorizado. Token de identidad requerido.',
      });
    }

    const identityId = req.user.id;
    const result = await contextResolutionService.resolveAvailableContexts(identityId);

    return res.status(200).json({
      status: 'success',
      data: result,
    });
  } catch (error) {
    if (error.code === 'IDENTITY_NOT_FOUND') {
      return res.status(error.statusCode || 404).json({
        error: error.code,
        message: 'Identidad no encontrada.',
      });
    }
    if (error.code === 'TENANT_NOT_FOUND') {
      return res.status(error.statusCode || 404).json({
        error: error.code,
        message: 'Tenant no encontrado para la identidad.',
      });
    }

    console.error('Error in getAvailableContexts:', error);
    return res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: 'Error interno resolviendo el contexto disponible.',
    });
  }
};

module.exports = {
  getAvailableContexts,
};