const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { requireRol } = require('../middleware/roles');
const {
  getPrecios,
  updatePrecioProducto,
  bulkUpdatePrecios,
  getCoherenciaReport
} = require('../controllers/adminPreciosController');

// Todas las rutas de administración de precios están protegidas con autenticación y rol 'admin'
router.use(authMiddleware);
router.use(requireRol('admin'));

router.get('/precios', getPrecios);
router.get('/precios/coherencia', getCoherenciaReport);
router.put('/precios/:productoId', updatePrecioProducto);
router.patch('/precios/bulk', bulkUpdatePrecios);

module.exports = router;
