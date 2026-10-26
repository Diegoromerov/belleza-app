/**
 * Controller para manejar operaciones de Lead (CRM).
 */
const { Lead, User, Salon } = require('../models');

module.exports = {
  // Crear nuevo lead
  async create(req, res) {
    try {
      const { name, email, phone, status, notes, salonId } = req.body;
      const lead = await Lead.create({
        name,
        email,
        phone,
        status: status || 'new',
        notes,
        userId: req.user.id, // asume middleware que agrega user al request
        salonId,
      });
      return res.status(201).json(lead);
    } catch (err) {
      console.error('Lead.create error', err);
      return res.status(500).json({ error: 'Error al crear lead' });
    }
  },

  // Obtener lista de leads (con filtro opcional por salon)
  async list(req, res) {
    try {
      const { salonId, status, page = 1, limit = 20 } = req.query;
      const where = {};
      if (salonId) where.salonId = salonId;
      if (status) where.status = status;
      const leads = await Lead.findAndCountAll({
        where,
        offset: (page - 1) * limit,
        limit: parseInt(limit),
        include: [{ model: Salon, as: 'salon' }, { model: User, as: 'creator', attributes: ['id', 'name', 'email'] }],
        order: [['createdAt', 'DESC']],
      });
      return res.json({
        total: leads.count,
        page: parseInt(page),
        limit: parseInt(limit),
        data: leads.rows,
      });
    } catch (err) {
      console.error('Lead.list error', err);
      return res.status(500).json({ error: 'Error al listar leads' });
    }
  },

  // Obtener detalle de un lead
  async get(req, res) {
    try {
      const lead = await Lead.findByPk(req.params.id, {
        include: [{ model: Salon, as: 'salon' }, { model: User, as: 'creator', attributes: ['id', 'name', 'email'] }],
      });
      if (!lead) return res.status(404).json({ error: 'Lead no encontrado' });
      return res.json(lead);
    } catch (err) {
      console.error('Lead.get error', err);
      return res.status(500).json({ error: 'Error al obtener lead' });
    }
  },

  // Actualizar lead
  async update(req, res) {
    try {
      const lead = await Lead.findByPk(req.params.id);
      if (!lead) return res.status(404).json({ error: 'Lead no encontrado' });
      await lead.update(req.body);
      return res.json(lead);
    } catch (err) {
      console.error('Lead.update error', err);
      return res.status(500).json({ error: 'Error al actualizar lead' });
    }
  },

  // Eliminar lead
  async delete(req, res) {
    try {
      const lead = await Lead.findByPk(req.params.id);
      if (!lead) return res.status(404).json({ error: 'Lead no encontrado' });
      await lead.destroy();
      return res.status(204).send();
    } catch (err) {
      console.error('Lead.delete error', err);
      return res.status(500).json({ error: 'Error al eliminar lead' });
    }
  },
};
