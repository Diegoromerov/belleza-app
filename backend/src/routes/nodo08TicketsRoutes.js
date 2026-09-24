// backend/src/routes/nodo08TicketsRoutes.js
const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { activeContextMiddleware } = require('../middleware/activeContextMiddleware');
const nodo08TicketsController = require('../controllers/nodo08TicketsController');

/**
 * NODO-08 — SaaS Service Ticket & Financial Checkout Engine Routes
 * Base prefix: /api/saas/tickets
 * Protected by authMiddleware + activeContextMiddleware.
 */

// POST /api/saas/tickets — Crear ticket (DRAFT)
router.post('/', authMiddleware, activeContextMiddleware, nodo08TicketsController.createTicket);

// POST /api/saas/tickets/:id/items — Agregar ítem
router.post('/:id/items', authMiddleware, activeContextMiddleware, nodo08TicketsController.addItem);

// PATCH /api/saas/tickets/:id/items/:itemId — Modificar ítem
router.patch('/:id/items/:itemId', authMiddleware, activeContextMiddleware, nodo08TicketsController.updateItem);

// DELETE /api/saas/tickets/:id/items/:itemId — Eliminar ítem
router.delete('/:id/items/:itemId', authMiddleware, activeContextMiddleware, nodo08TicketsController.deleteItem);

// PATCH /api/saas/tickets/:id/adjustments — Aplicar ajustes de cabecera
router.patch('/:id/adjustments', authMiddleware, activeContextMiddleware, nodo08TicketsController.applyAdjustments);

// POST /api/saas/tickets/:id/confirm — Confirmar ticket (DRAFT -> OPEN)
router.post('/:id/confirm', authMiddleware, activeContextMiddleware, nodo08TicketsController.confirmTicket);

// POST /api/saas/tickets/:id/payments — Registrar pago (Split Tender)
router.post('/:id/payments', authMiddleware, activeContextMiddleware, nodo08TicketsController.addPayment);

// POST /api/saas/tickets/:id/close — Cerrar ticket (PAID -> CLOSED)
router.post('/:id/close', authMiddleware, activeContextMiddleware, nodo08TicketsController.closeTicket);

// POST /api/saas/tickets/:id/void — Anular ticket (VOID)
router.post('/:id/void', authMiddleware, activeContextMiddleware, nodo08TicketsController.voidTicket);

// GET /api/saas/tickets/:id — Detalle completo del ticket
router.get('/:id', authMiddleware, activeContextMiddleware, nodo08TicketsController.getTicketById);

// GET /api/saas/tickets — Listar tickets de la sede activa
router.get('/', authMiddleware, activeContextMiddleware, nodo08TicketsController.listTickets);

module.exports = router;
