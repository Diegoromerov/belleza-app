const express = require('express');
const router = express.Router();
const {
  getOwnerSalones,
  switchSalon,
  getDashboardMetrics,
} = require('../controllers/ownerController');
const { authMiddleware } = require('../middleware/auth');
const {
  requireOwnerRole,
  requireAnyOwnerSede,
} = require('../middleware/ownerGuard');

// Lista todas las sedes pertenecientes o administradas por el Propietario
router.get('/salones', authMiddleware, requireAnyOwnerSede, getOwnerSalones);

// Cambiar o seleccionar sede activa
router.post('/switch-salon', authMiddleware, requireOwnerRole, switchSalon);

// Dashboard consolidado de métricas multi-sede
router.get('/dashboard-metrics', authMiddleware, requireAnyOwnerSede, getDashboardMetrics);

module.exports = router;
