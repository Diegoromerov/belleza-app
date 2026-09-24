// backend/src/controllers/nodo01Controller.js
const nodo01Service = require('../services/nodo01Service');

/**
 * Node Contract — NODO-01-v1.0 Controller
 * Express controller interface for Handover Ingestion & Downstream Adapter.
 * Protected by authMiddleware + activeContextMiddleware.
 */

/**
 * Handles POST /api/v1/nodo01/ingest
 * Ingests and adapts a Handover Boundary Contract v1.0 payload in memory.
 */
const ingest = async (req, res) => {
  try {
    if (!req.user || !req.user.id) {
      return res.status(401).json({
        success: false,
        error_code: 'IDENTITY_NOT_FOUND',
        error_message: 'No autorizado. Token de identidad requerido.',
      });
    }

    if (!req.activeContext) {
      return res.status(400).json({
        success: false,
        error_code: 'ACTIVE_CONTEXT_REQUIRED',
        error_message: 'Contexto activo no inicializado o incompleto.',
      });
    }

    const securityContext = {
      userId: req.user.id,
      role: req.activeContext.role,
      tenantId: req.tenantId,
      establishmentId: req.establishmentId,
    };

    const payload = req.body;
    const result = nodo01Service.ingestHandover(payload, securityContext);

    if (!result.success) {
      const statusCode = result.state === nodo01Service.NODE_STATES.REJECTED ? 422 : 400;
      return res.status(statusCode).json({
        status: 'error',
        data: result,
      });
    }

    return res.status(200).json({
      status: 'success',
      data: result,
    });
  } catch (error) {
    console.error('Error in nodo01Controller.ingest:', error);
    return res.status(500).json({
      success: false,
      error_code: 'INTERNAL_SERVER_ERROR',
      error_message: 'Error interno en la capa de ingestión de Nodo 01.',
    });
  }
};

module.exports = {
  ingest,
};
