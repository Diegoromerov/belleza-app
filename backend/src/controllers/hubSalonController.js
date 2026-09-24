// backend/src/controllers/hubSalonController.js
const hubSalonService = require('../services/hubSalonService');

/**
 * Node Contract — Hub Salón v1.0 Controller
 * Handles HTTP requests for Hub Salón operational cockpit.
 * Requires authMiddleware + activeContextMiddleware.
 */

/**
 * Handles GET /api/v1/saas/hub/summary
 * Returns active establishment summary, organization details, active user context, and staff count.
 */
const getSummary = async (req, res) => {
  try {
    if (!req.activeContext || !req.establishmentId || !req.tenantId) {
      return res.status(400).json({
        error: 'ACTIVE_CONTEXT_NOT_INITIALIZED',
        message: 'Contexto activo no inicializado o incompleto.',
      });
    }

    const summaryData = await hubSalonService.getHubSummary(
      req.tenantId,
      req.establishmentId,
      req.activeContext
    );

    return res.status(200).json({
      status: 'success',
      data: summaryData,
    });
  } catch (error) {
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

    console.error('Error in hubSalonController.getSummary:', error);
    return res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: 'Error interno al obtener el resumen del salón.',
    });
  }
};

/**
 * Handles GET /api/v1/saas/hub/staff
 * Returns active staff members for the active establishment.
 */
const getStaff = async (req, res) => {
  try {
    if (!req.activeContext || !req.establishmentId || !req.tenantId) {
      return res.status(400).json({
        error: 'ACTIVE_CONTEXT_NOT_INITIALIZED',
        message: 'Contexto activo no inicializado o incompleto.',
      });
    }

    const staffData = await hubSalonService.getHubStaff(
      req.tenantId,
      req.establishmentId
    );

    return res.status(200).json({
      status: 'success',
      data: staffData,
    });
  } catch (error) {
    if (error.code === 'ACTIVE_CONTEXT_REQUIRED') {
      return res.status(400).json({
        error: error.code,
        message: error.message,
      });
    }

    console.error('Error in hubSalonController.getStaff:', error);
    return res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: 'Error interno al consultar el equipo del salón.',
    });
  }
};

module.exports = {
  getSummary,
  getStaff,
};
