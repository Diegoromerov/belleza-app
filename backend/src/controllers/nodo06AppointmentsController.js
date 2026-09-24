// backend/src/controllers/nodo06AppointmentsController.js
const nodo06AppointmentsService = require('../services/nodo06AppointmentsService');

/**
 * Controller para NODO-06: SaaS Internal Appointments & Operational Agenda Engine
 */

async function createAppointment(req, res) {
  try {
    const activeContext = req.activeContext;
    if (!activeContext) {
      return res.status(403).json({
        error: {
          code: 'UNAUTHORIZED_ROLE',
          message: 'Active context is required'
        }
      });
    }

    const result = await nodo06AppointmentsService.createAppointment(activeContext, req.body);
    return res.status(201).json(result);
  } catch (err) {
    const status = err.status || 500;
    const code = err.code || 'INTERNAL_SERVER_ERROR';
    return res.status(status).json({
      error: {
        code: code,
        message: err.message
      }
    });
  }
}

async function transitionAppointmentStatus(req, res) {
  try {
    const activeContext = req.activeContext;
    if (!activeContext) {
      return res.status(403).json({
        error: {
          code: 'UNAUTHORIZED_ROLE',
          message: 'Active context is required'
        }
      });
    }

    const { id } = req.params;
    const result = await nodo06AppointmentsService.transitionAppointmentStatus(activeContext, id, req.body);
    return res.status(200).json(result);
  } catch (err) {
    const status = err.status || 500;
    const code = err.code || 'INTERNAL_SERVER_ERROR';
    return res.status(status).json({
      error: {
        code: code,
        message: err.message
      }
    });
  }
}

async function getAgendaProjection(req, res) {
  try {
    const activeContext = req.activeContext;
    if (!activeContext) {
      return res.status(403).json({
        error: {
          code: 'UNAUTHORIZED_ROLE',
          message: 'Active context is required'
        }
      });
    }

    const result = await nodo06AppointmentsService.getAgendaProjection(activeContext, req.query);
    return res.status(200).json(result);
  } catch (err) {
    const status = err.status || 500;
    const code = err.code || 'INTERNAL_SERVER_ERROR';
    return res.status(status).json({
      error: {
        code: code,
        message: err.message
      }
    });
  }
}

async function getAppointmentById(req, res) {
  try {
    const activeContext = req.activeContext;
    if (!activeContext) {
      return res.status(403).json({
        error: {
          code: 'UNAUTHORIZED_ROLE',
          message: 'Active context is required'
        }
      });
    }

    const { id } = req.params;
    const result = await nodo06AppointmentsService.getAppointmentById(activeContext, id);
    return res.status(200).json(result);
  } catch (err) {
    const status = err.status || 500;
    const code = err.code || 'INTERNAL_SERVER_ERROR';
    return res.status(status).json({
      error: {
        code: code,
        message: err.message
      }
    });
  }
}

module.exports = {
  createAppointment,
  transitionAppointmentStatus,
  getAgendaProjection,
  getAppointmentById
};
