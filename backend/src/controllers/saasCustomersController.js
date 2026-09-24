// backend/src/controllers/saasCustomersController.js
const saasCustomersService = require('../services/saasCustomersService');

/**
 * Controller for Customer / Client Directory Engine
 */

function handleControllerError(res, err) {
  const status = err.status || 500;
  const code = err.code || 'INTERNAL_SERVER_ERROR';
  const response = {
    error: {
      code: code,
      message: err.message
    }
  };
  if (err.candidates) {
    response.error.candidates = err.candidates;
  }
  return res.status(status).json(response);
}

function checkActiveContext(req, res) {
  const activeContext = req.activeContext;
  if (!activeContext || !activeContext.tenant_id || !activeContext.establishment_id) {
    res.status(403).json({
      error: {
        code: 'ACTIVE_CONTEXT_REQUIRED',
        message: 'Active context is required to execute customer directory operations.'
      }
    });
    return null;
  }
  return activeContext;
}

async function searchCustomers(req, res) {
  try {
    const activeContext = checkActiveContext(req, res);
    if (!activeContext) return;

    const result = await saasCustomersService.searchCustomers(activeContext, req.query);
    return res.status(200).json(result);
  } catch (err) {
    return handleControllerError(res, err);
  }
}

async function listCustomers(req, res) {
  try {
    const activeContext = checkActiveContext(req, res);
    if (!activeContext) return;

    const result = await saasCustomersService.listCustomers(activeContext, req.query);
    return res.status(200).json(result);
  } catch (err) {
    return handleControllerError(res, err);
  }
}

async function createCustomer(req, res) {
  try {
    const activeContext = checkActiveContext(req, res);
    if (!activeContext) return;

    const result = await saasCustomersService.createCustomer(activeContext, req.body);
    return res.status(201).json(result);
  } catch (err) {
    return handleControllerError(res, err);
  }
}

async function getCustomerById(req, res) {
  try {
    const activeContext = checkActiveContext(req, res);
    if (!activeContext) return;

    const { id } = req.params;
    const result = await saasCustomersService.getCustomerById(activeContext, id);
    return res.status(200).json(result);
  } catch (err) {
    return handleControllerError(res, err);
  }
}

async function updateCustomer(req, res) {
  try {
    const activeContext = checkActiveContext(req, res);
    if (!activeContext) return;

    const { id } = req.params;
    const result = await saasCustomersService.updateCustomer(activeContext, id, req.body);
    return res.status(200).json(result);
  } catch (err) {
    return handleControllerError(res, err);
  }
}

async function createEstablishmentRelation(req, res) {
  try {
    const activeContext = checkActiveContext(req, res);
    if (!activeContext) return;

    const { id } = req.params;
    const result = await saasCustomersService.createEstablishmentRelation(activeContext, id, req.body);
    return res.status(201).json(result);
  } catch (err) {
    return handleControllerError(res, err);
  }
}

async function updateCurrentEstablishmentRelation(req, res) {
  try {
    const activeContext = checkActiveContext(req, res);
    if (!activeContext) return;

    const { id } = req.params;
    const result = await saasCustomersService.updateCurrentEstablishmentRelation(activeContext, id, req.body);
    return res.status(200).json(result);
  } catch (err) {
    return handleControllerError(res, err);
  }
}

async function linkUser(req, res) {
  try {
    const activeContext = checkActiveContext(req, res);
    if (!activeContext) return;

    const { id } = req.params;
    const result = await saasCustomersService.linkUser(activeContext, id, req.body);
    return res.status(200).json(result);
  } catch (err) {
    return handleControllerError(res, err);
  }
}

async function unlinkUser(req, res) {
  try {
    const activeContext = checkActiveContext(req, res);
    if (!activeContext) return;

    const { id } = req.params;
    const result = await saasCustomersService.unlinkUser(activeContext, id);
    return res.status(200).json(result);
  } catch (err) {
    return handleControllerError(res, err);
  }
}

async function getCustomerHistory(req, res) {
  try {
    const activeContext = checkActiveContext(req, res);
    if (!activeContext) return;

    const { id } = req.params;
    const result = await saasCustomersService.getCustomerHistory(activeContext, id);
    return res.status(200).json(result);
  } catch (err) {
    return handleControllerError(res, err);
  }
}

module.exports = {
  searchCustomers,
  listCustomers,
  createCustomer,
  getCustomerById,
  updateCustomer,
  createEstablishmentRelation,
  updateCurrentEstablishmentRelation,
  linkUser,
  unlinkUser,
  getCustomerHistory,
};
