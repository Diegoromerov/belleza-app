// backend/src/routes/nodo06AppointmentsRoutes.js
const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { activeContextMiddleware } = require('../middleware/activeContextMiddleware');
const nodo06AppointmentsController = require('../controllers/nodo06AppointmentsController');

/**
 * NODO-06 — SaaS Internal Appointments & Operational Agenda Engine Routes
 * Base prefix: /api/v1/saas/hub/appointments
 * Protected by authMiddleware + activeContextMiddleware.
 */

// POST /api/v1/saas/hub/appointments — Crear cita (Registered / Guest)
router.post('/', authMiddleware, activeContextMiddleware, nodo06AppointmentsController.createAppointment);

// GET /api/v1/saas/hub/appointments/agenda — Proyección de Agenda Operativa de Sede
router.get('/agenda', authMiddleware, activeContextMiddleware, nodo06AppointmentsController.getAgendaProjection);

// GET /api/v1/saas/hub/appointments/:id — Detalle de cita por ID
router.get('/:id', authMiddleware, activeContextMiddleware, nodo06AppointmentsController.getAppointmentById);

// PATCH /api/v1/saas/hub/appointments/:id/status — Transición de Estado Operacional
router.patch('/:id/status', authMiddleware, activeContextMiddleware, nodo06AppointmentsController.transitionAppointmentStatus);

// PUT /api/v1/saas/hub/appointments/:id/status — Soporte alternativo PUT
router.put('/:id/status', authMiddleware, activeContextMiddleware, nodo06AppointmentsController.transitionAppointmentStatus);

module.exports = router;
