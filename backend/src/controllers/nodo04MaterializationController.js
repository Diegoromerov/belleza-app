// backend/src/controllers/nodo04MaterializationController.js
const nodo04MaterializationService = require('../services/nodo04MaterializationService');

function handleError(res, error, defaultMsg) {
  const statusCode = error.statusCode || 500;
  const errorCode = error.code || 'INTERNAL_SERVER_ERROR';
  const errorMessage = error.message || defaultMsg;

  if (statusCode === 500) {
    console.error('Unhandled Error in nodo04MaterializationController:', error);
  }

  return res.status(statusCode).json({
    status: 'error',
    code: errorCode,
    message: errorMessage,
  });
}

/**
 * OP-01: POST /api/v1/saas/hub/materializations/services
 */
const materializeService = async (req, res) => {
  try {
    const result = await nodo04MaterializationService.materializeServiceAssignment(
      req.tenantId,
      req.establishmentId,
      req.activeContext,
      req.body,
      req.user
    );

    return res.status(201).json({
      status: 'success',
      data: result,
    });
  } catch (error) {
    return handleError(res, error, 'Error al materializar el servicio hacia el catálogo B2C.');
  }
};

/**
 * OP-02: GET /api/v1/saas/hub/materializations/services
 */
const listMaterializations = async (req, res) => {
  try {
    const result = await nodo04MaterializationService.listMaterializations(
      req.tenantId,
      req.establishmentId,
      req.activeContext
    );

    return res.status(200).json({
      status: 'success',
      data: result,
    });
  } catch (error) {
    return handleError(res, error, 'Error al listar las materializaciones de la sede activa.');
  }
};

module.exports = {
  materializeService,
  listMaterializations,
};
