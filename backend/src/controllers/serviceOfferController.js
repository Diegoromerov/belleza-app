// backend/src/controllers/serviceOfferController.js
const serviceOfferService = require('../services/serviceOfferService');

function handleError(res, error, defaultMsg) {
  const statusCode = error.statusCode || 500;
  const errorCode = error.code || 'INTERNAL_SERVER_ERROR';
  const errorMessage = error.message || defaultMsg;

  if (statusCode === 500) {
    console.error('Unhandled Error in serviceOfferController:', error);
  }

  return res.status(statusCode).json({
    status: 'error',
    code: errorCode,
    message: errorMessage,
  });
}

const createServiceOffer = async (req, res) => {
  try {
    const result = await serviceOfferService.createServiceOffer(
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
    return handleError(res, error, 'Error al crear la oferta de servicio.');
  }
};

const listServiceOffers = async (req, res) => {
  try {
    const result = await serviceOfferService.listServiceOffers(
      req.tenantId,
      req.establishmentId,
      req.activeContext
    );

    return res.status(200).json({
      status: 'success',
      data: result,
    });
  } catch (error) {
    return handleError(res, error, 'Error al listar las ofertas de servicio.');
  }
};

const getServiceOfferById = async (req, res) => {
  try {
    const result = await serviceOfferService.getServiceOfferById(
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
    return handleError(res, error, 'Error al obtener la oferta de servicio.');
  }
};

const updateServiceOffer = async (req, res) => {
  try {
    const result = await serviceOfferService.updateServiceOffer(
      req.tenantId,
      req.establishmentId,
      req.activeContext,
      req.params.id,
      req.body
    );

    return res.status(200).json({
      status: 'success',
      data: result,
    });
  } catch (error) {
    return handleError(res, error, 'Error al actualizar la oferta de servicio.');
  }
};

module.exports = {
  createServiceOffer,
  listServiceOffers,
  getServiceOfferById,
  updateServiceOffer,
};
