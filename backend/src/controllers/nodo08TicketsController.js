// backend/src/controllers/nodo08TicketsController.js
const nodo08TicketsService = require('../services/nodo08TicketsService');

/**
 * Controller for NODO-08: SaaS Service Ticket & Financial Checkout Engine
 */

function handleControllerError(res, err) {
  const status = err.status || 500;
  const code = err.code || 'INTERNAL_SERVER_ERROR';
  return res.status(status).json({
    error: {
      code: code,
      message: err.message
    }
  });
}

async function createTicket(req, res) {
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

    const result = await nodo08TicketsService.createTicket(activeContext, req.body);
    return res.status(201).json(result);
  } catch (err) {
    return handleControllerError(res, err);
  }
}

async function addItem(req, res) {
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
    const result = await nodo08TicketsService.addItem(activeContext, id, req.body);
    return res.status(201).json(result);
  } catch (err) {
    return handleControllerError(res, err);
  }
}

async function updateItem(req, res) {
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

    const { id, itemId } = req.params;
    const result = await nodo08TicketsService.updateItem(activeContext, id, itemId, req.body);
    return res.status(200).json(result);
  } catch (err) {
    return handleControllerError(res, err);
  }
}

async function deleteItem(req, res) {
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

    const { id, itemId } = req.params;
    const result = await nodo08TicketsService.deleteItem(activeContext, id, itemId);
    return res.status(200).json(result);
  } catch (err) {
    return handleControllerError(res, err);
  }
}

async function applyAdjustments(req, res) {
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
    const result = await nodo08TicketsService.applyAdjustments(activeContext, id, req.body);
    return res.status(200).json(result);
  } catch (err) {
    return handleControllerError(res, err);
  }
}

async function confirmTicket(req, res) {
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
    const result = await nodo08TicketsService.confirmTicket(activeContext, id);
    return res.status(200).json(result);
  } catch (err) {
    return handleControllerError(res, err);
  }
}

async function addPayment(req, res) {
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
    const result = await nodo08TicketsService.addPayment(activeContext, id, req.body);
    return res.status(201).json(result);
  } catch (err) {
    return handleControllerError(res, err);
  }
}

async function closeTicket(req, res) {
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
    const result = await nodo08TicketsService.closeTicket(activeContext, id);
    return res.status(200).json(result);
  } catch (err) {
    return handleControllerError(res, err);
  }
}

async function voidTicket(req, res) {
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
    const result = await nodo08TicketsService.voidTicket(activeContext, id, req.body);
    return res.status(200).json(result);
  } catch (err) {
    return handleControllerError(res, err);
  }
}

async function getTicketById(req, res) {
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
    const result = await nodo08TicketsService.getTicketById(activeContext, id);
    return res.status(200).json(result);
  } catch (err) {
    return handleControllerError(res, err);
  }
}

async function listTickets(req, res) {
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

    const result = await nodo08TicketsService.listTickets(activeContext, req.query);
    return res.status(200).json(result);
  } catch (err) {
    return handleControllerError(res, err);
  }
}

module.exports = {
  createTicket,
  addItem,
  updateItem,
  deleteItem,
  applyAdjustments,
  confirmTicket,
  addPayment,
  closeTicket,
  voidTicket,
  getTicketById,
  listTickets
};
