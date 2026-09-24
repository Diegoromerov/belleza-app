// backend/src/controllers/nodo05AvailabilityController.js
const nodo05AvailabilityService = require('../services/nodo05AvailabilityService');

function handleError(res, error, defaultMsg) {
  const statusCode = error.statusCode || 500;
  const errorCode = error.code || 'INTERNAL_SERVER_ERROR';
  const errorMessage = error.message || defaultMsg;

  if (statusCode === 500) {
    console.error('Unhandled Error in nodo05AvailabilityController:', error);
  }

  return res.status(statusCode).json({
    status: 'error',
    code: errorCode,
    message: errorMessage,
  });
}

/**
 * GET /api/v1/saas/hub/availability/projection
 * Protected by authMiddleware + activeContextMiddleware.
 */
const getAvailabilityProjection = async (req, res) => {
  try {
    const result = await nodo05AvailabilityService.projectAvailability(
      req.tenantId,
      req.establishmentId,
      req.activeContext,
      req.query
    );

    return res.status(200).json({
      status: 'success',
      data: result,
    });
  } catch (error) {
    return handleError(res, error, 'Error al proyectar la disponibilidad de la sede.');
  }
};

module.exports = {
  getAvailabilityProjection,
};
