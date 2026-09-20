// backend/src/controllers/serviceController.js
const { Op } = require('sequelize');
const Service = require('../models/Service');

/**
 * 💅 SERVICE CONTROLLER (GLOWAPP SAAS & PROVIDER ENGINE)
 * Handles service CRUD with strict multi-tenant isolation (Anti-Tenant-Leakage / Anti-IDOR).
 */

// Helper to build tenant isolation query condition
const buildTenantWhere = (req, extraWhere = {}) => {
  const businessProfileId = req.user?.businessProfileId;
  const providerId = req.user?.id;

  if (businessProfileId) {
    return {
      [Op.and]: [
        extraWhere,
        {
          [Op.or]: [
            { business_profile_id: businessProfileId },
            { provider_id: providerId }
          ]
        }
      ]
    };
  }

  return {
    [Op.and]: [
      extraWhere,
      { provider_id: providerId }
    ]
  };
};

// GET /api/services/provider → Lista servicios del establecimiento/provider activo
exports.getProviderServices = async (req, res) => {
  try {
    const businessProfileId = req.user?.businessProfileId;
    const providerId = req.user?.id;

    if (!businessProfileId && !providerId) {
      return res.status(403).json({ 
        error: 'FORBIDDEN', 
        message: 'No hay un contexto de negocio activo ni usuario autenticado.' 
      });
    }

    const whereClause = businessProfileId
      ? { [Op.or]: [{ business_profile_id: businessProfileId }, { provider_id: providerId }] }
      : { provider_id: providerId };

    const services = await Service.findAll({
      where: whereClause,
      order: [['name', 'ASC']]
    });

    const formattedServices = services.map(service => ({
      id: service.id,
      name: service.name,
      description: service.description || '',
      price: parseFloat(service.price) || 0.0,
      duration_minutes: parseInt(service.duration_minutes) || 30,
      category: service.category || '',
      is_active: !!service.is_active,
      business_profile_id: service.business_profile_id
    }));

    res.json({ success: true, count: formattedServices.length, data: formattedServices });
  } catch (error) {
    console.error('❌ ERROR EN GET /api/services/provider:', { message: error.message });
    res.status(500).json({ error: 'Error interno al obtener servicios' });
  }
};

// POST /api/services → Crea servicio asociado al establecimiento activo
exports.createService = async (req, res) => {
  try {
    const businessProfileId = req.user?.businessProfileId;
    const providerId = req.user?.id;

    const { name, description, price, duration_minutes, category, is_active } = req.body;
    if (!name || price === undefined || !duration_minutes) {
      return res.status(400).json({ error: 'Faltan campos obligatorios (nombre, precio, duración)' });
    }

    const parsedPrice = parseFloat(price);
    const parsedDuration = parseInt(duration_minutes);
    const isActiveVal = is_active !== false;

    if (isNaN(parsedPrice) || parsedPrice < 0) {
      return res.status(400).json({ error: 'Precio inválido' });
    }
    if (isNaN(parsedDuration) || parsedDuration <= 0) {
      return res.status(400).json({ error: 'Duración inválida' });
    }

    const service = await Service.create({
      provider_id: providerId,
      business_profile_id: businessProfileId || null,
      name,
      description: description || null,
      price: parsedPrice,
      duration_minutes: parsedDuration,
      category: category || null,
      is_active: isActiveVal
    });

    res.status(201).json({
      success: true,
      message: 'Servicio creado exitosamente',
      data: {
        id: service.id,
        provider_id: service.provider_id,
        business_profile_id: service.business_profile_id,
        name: service.name,
        description: service.description,
        price: parseFloat(service.price),
        duration_minutes: parseInt(service.duration_minutes),
        category: service.category,
        is_active: service.is_active
      }
    });
  } catch (error) {
    console.error('❌ ERROR EN POST /api/services:', { message: error.message });
    res.status(500).json({ error: 'Error interno al crear el servicio' });
  }
};

// PUT /api/services/:id → Actualiza servicio (IDOR & Multi-tenant Protected)
exports.updateService = async (req, res) => {
  try {
    const serviceId = req.params.id;
    const { name, description, price, duration_minutes, category, is_active } = req.body;

    const whereClause = buildTenantWhere(req, { id: serviceId });

    const service = await Service.findOne({ where: whereClause });

    if (!service) {
      return res.status(404).json({ 
        error: 'SERVICE_NOT_FOUND', 
        message: 'El servicio no existe o no tienes acceso a él.' 
      });
    }

    if (!name || price === undefined || !duration_minutes) {
      return res.status(400).json({ error: 'Faltan campos obligatorios (nombre, precio, duración)' });
    }

    const parsedPrice = parseFloat(price);
    const parsedDuration = parseInt(duration_minutes);

    if (isNaN(parsedPrice) || parsedPrice < 0) {
      return res.status(400).json({ error: 'Precio inválido' });
    }
    if (isNaN(parsedDuration) || parsedDuration <= 0) {
      return res.status(400).json({ error: 'Duración inválida' });
    }

    service.name = name;
    service.description = description || null;
    service.price = parsedPrice;
    service.duration_minutes = parsedDuration;
    service.category = category || null;
    if (is_active !== undefined) {
      service.is_active = is_active !== false;
    }

    await service.save();

    res.json({
      success: true,
      message: 'Servicio actualizado exitosamente',
      data: {
        id: service.id,
        provider_id: service.provider_id,
        business_profile_id: service.business_profile_id,
        name: service.name,
        description: service.description,
        price: parseFloat(service.price),
        duration_minutes: parseInt(service.duration_minutes),
        category: service.category,
        is_active: service.is_active
      }
    });
  } catch (error) {
    console.error('❌ ERROR EN PUT /api/services/:id:', { message: error.message });
    res.status(500).json({ error: 'Error interno al actualizar el servicio' });
  }
};

// DELETE /api/services/:id → Elimina / Desactiva servicio (IDOR & Multi-tenant Protected)
exports.deleteService = async (req, res) => {
  try {
    const serviceId = req.params.id;

    const whereClause = buildTenantWhere(req, { id: serviceId });

    const service = await Service.findOne({ where: whereClause });

    if (!service) {
      return res.status(404).json({ 
        error: 'SERVICE_NOT_FOUND', 
        message: 'El servicio no existe o no tienes acceso a él.' 
      });
    }

    service.is_active = false;
    await service.save();

    res.json({
      success: true,
      message: 'Servicio desactivado exitosamente',
      data: {
        id: service.id,
        name: service.name,
        is_active: service.is_active
      }
    });
  } catch (error) {
    console.error('❌ ERROR EN DELETE /api/services/:id:', { message: error.message });
    res.status(500).json({ error: 'Error interno al desactivar el servicio' });
  }
};
