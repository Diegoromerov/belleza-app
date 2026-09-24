// backend/src/controllers/serviceAssignmentController.js
const serviceAssignmentService = require('../services/serviceAssignmentService');

function handleError(res, error, defaultMsg) {
  const statusCode = error.statusCode || 500;
  const errorCode = error.code || 'INTERNAL_SERVER_ERROR';
  const errorMessage = error.message || defaultMsg;

  if (statusCode === 500) {
    console.error('Unhandled Error in serviceAssignmentController:', error);
  }

  return res.status(statusCode).json({
    status: 'error',
    code: errorCode,
    message: errorMessage,
  });
}

const createAssignment = async (req, res) => {
  try {
    const result = await serviceAssignmentService.createAssignment(
      req.tenantId,
      req.establishmentId,
      req.activeContext,
      req.body
    );

    return res.status(201).json({
      status: 'success',
      data: result,
    });
  } catch (error) {
    return handleError(res, error, 'Error al crear la asignación.');
  }
};

const listEstablishmentAssignments = async (req, res) => {
  try {
    const result = await serviceAssignmentService.listEstablishmentAssignments(
      req.tenantId,
      req.establishmentId,
      req.activeContext
    );

    return res.status(200).json({
      status: 'success',
      data: result,
    });
  } catch (error) {
    return handleError(res, error, 'Error al listar las asignaciones de la sede.');
  }
};

const getAssignmentsByStaff = async (req, res) => {
  try {
    const result = await serviceAssignmentService.getAssignmentsByStaff(
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
    return handleError(res, error, 'Error al consultar las asignaciones del colaborador.');
  }
};

const getAssignmentsByOffer = async (req, res) => {
  try {
    const result = await serviceAssignmentService.getAssignmentsByOffer(
      req.tenantId,
      req.establishmentId,
      req.activeContext,
      req.params.service_offer_id
    );

    return res.status(200).json({
      status: 'success',
      data: result,
    });
  } catch (error) {
    return handleError(res, error, 'Error al consultar las asignaciones de la oferta.');
  }
};

const deleteAssignment = async (req, res) => {
  try {
    const result = await serviceAssignmentService.deleteAssignment(
      req.tenantId,
      req.establishmentId,
      req.activeContext,
      req.params.id
    );

    return res.status(200).json({
      status: 'success',
      data: result,
    });
  } catch (error) {
    return handleError(res, error, 'Error al eliminar la asignación.');
  }
};

module.exports = {
  createAssignment,
  listEstablishmentAssignments,
  getAssignmentsByStaff,
  getAssignmentsByOffer,
  deleteAssignment,
};
