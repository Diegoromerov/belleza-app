// backend/src/controllers/staffAvailabilityController.js
const staffAvailabilityService = require('../services/staffAvailabilityService');

function handleError(res, error, defaultMsg) {
  const statusCode = error.statusCode || 500;
  const errorCode = error.code || 'INTERNAL_SERVER_ERROR';
  const errorMessage = error.message || defaultMsg;

  if (statusCode === 500) {
    console.error('Unhandled Error in staffAvailabilityController:', error);
  }

  return res.status(statusCode).json({
    status: 'error',
    code: errorCode,
    message: errorMessage,
  });
}

/**
 * OP-01: PUT /api/v1/saas/hub/staff/:membership_id/schedule
 */
const setStaffSchedule = async (req, res) => {
  try {
    const result = await staffAvailabilityService.setStaffSchedule(
      req.tenantId,
      req.establishmentId,
      req.activeContext,
      req.params.membership_id,
      req.body
    );

    return res.status(200).json({
      status: 'success',
      data: result,
    });
  } catch (error) {
    return handleError(res, error, 'Error al configurar el horario de disponibilidad del colaborador.');
  }
};

/**
 * OP-02: GET /api/v1/saas/hub/staff/:membership_id/schedule
 */
const getStaffSchedule = async (req, res) => {
  try {
    const result = await staffAvailabilityService.getStaffSchedule(
      req.tenantId,
      req.establishmentId,
      req.activeContext,
      req.params.membership_id
    );

    return res.status(200).json({
      status: 'success',
      data: result,
    });
  } catch (error) {
    return handleError(res, error, 'Error al consultar el horario de disponibilidad del colaborador.');
  }
};

/**
 * OP-03: GET /api/v1/saas/hub/staff/schedules
 */
const listEstablishmentStaffSchedules = async (req, res) => {
  try {
    const result = await staffAvailabilityService.listEstablishmentStaffSchedules(
      req.tenantId,
      req.establishmentId,
      req.activeContext
    );

    return res.status(200).json({
      status: 'success',
      data: result,
    });
  } catch (error) {
    return handleError(res, error, 'Error al listar las disponibilidades del personal de la sede.');
  }
};

/**
 * OP-04: DELETE /api/v1/saas/hub/staff/:membership_id/schedule
 */
const deleteStaffSchedule = async (req, res) => {
  try {
    const result = await staffAvailabilityService.deleteStaffSchedule(
      req.tenantId,
      req.establishmentId,
      req.activeContext,
      req.params.membership_id
    );

    return res.status(200).json({
      status: 'success',
      data: result,
    });
  } catch (error) {
    return handleError(res, error, 'Error al eliminar el horario de disponibilidad del colaborador.');
  }
};

module.exports = {
  setStaffSchedule,
  getStaffSchedule,
  listEstablishmentStaffSchedules,
  deleteStaffSchedule,
};
