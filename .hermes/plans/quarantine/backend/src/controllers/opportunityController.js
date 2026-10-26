/**
 * Controller para manejar operaciones de Opportunity (CRM).
 */
const { Opportunity, Lead, User, Salon } = require('../models');

module.exports = {
  // Crear nueva oportunidad
  async create(req, res) {
    try {
      const { title, amount, stage, probability, expectedCloseDate, notes, leadId, salonId } = req.body;
      const opportunity = await Opportunity.create({
        title,
        amount,
        stage: stage || 'new',
        probability,
        expectedCloseDate,
        notes,
        leadId,
        userId: req.user.id, // owner
        salonId,
      });
      return res.status(201).json(opportunity);
    } catch (err) {
      console.error('Opportunity.create error', err);
      return res.status(500).json({ error: 'Error al crear oportunidad' });
    }
  },

  // Listar oportunidades (con filtros)
  async list(req, res) {
    try {
      const { salonId, stage, page = 1, limit = 20 } = req.query;
      const where = {};
      if (salonId) where.salonId = salonId;
      if (stage) where.stage = stage;
      const opps = await Opportunity.findAndCountAll({
        where,
        offset: (page - 1) * limit,
        limit: parseInt(limit),
        include: [
          { model: Lead, as: 'lead' },
          { model: User, as: 'owner', attributes: ['id', 'name', 'email'] },
          { model: Salon, as: 'salon' },
        ],
        order: [['createdAt', 'DESC']],
      });
      return res.json({
        total: opps.count,
        page: parseInt(page),
        limit: parseInt(limit),
        data: opps.rows,
      });
    } catch (err) {
      console.error('Opportunity.list error', err);
      return res.status(500).json({ error: 'Error al listar oportunidades' });
    }
  },

  // Detalle de oportunidad
  async get(req, res) {
    try {
      const opp = await Opportunity.findByPk(req.params.id, {
        include: [
          { model: Lead, as: 'lead' },
          { model: User, as: 'owner', attributes: ['id', 'name', 'email'] },
          { model: Salon, as: 'salon' },
        ],
      });
      if (!opp) return res.status(404).json({ error: 'Oportunidad no encontrada' });
      return res.json(opp);
    } catch (err) {
      console.error('Opportunity.get error', err);
      return res.status(500).json({ error: 'Error al obtener oportunidad' });
    }
  },

  // Actualizar oportunidad
  async update(req, res) {
    try {
      const opp = await Opportunity.findByPk(req.params.id);
      if (!opp) return res.status(404).json({ error: 'Oportunidad no encontrada' });
      await opp.update(req.body);
      return res.json(opp);
    } catch (err) {
      console.error('Opportunity.update error', err);
      return res.status(500).json({ error: 'Error al actualizar oportunidad' });
    }
  },

  // Eliminar oportunidad
  async delete(req, res) {
    try {
      const opp = await Opportunity.findByPk(req.params.id);
      if (!opp) return res.status(404).json({ error: 'Oportunidad no encontrada' });
      await opp.destroy();
      return res.status(204).send();
    } catch (err) {
      console.error('Opportunity.delete error', err);
      return res.status(500).json({ error: 'Error al eliminar oportunidad' });
    }
  },

  // Transición de etapa (pipeline)
  async transition(req, res) {
    try {
      const { stage } = req.body;
      const opp = await Opportunity.findByPk(req.params.id);
      if (!opp) return res.status(404).json({ error: 'Oportunidad no encontrada' });
      opp.stage = stage;
      await opp.save();
      // TODO: disparar notificación/email según la nueva etapa
      return res.json(opp);
    } catch (err) {
      console.error('Opportunity.transition error', err);
      return res.status(500).json({ error: 'Error al cambiar etapa' });
    }
  },
};
