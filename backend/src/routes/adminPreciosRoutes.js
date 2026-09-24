const express = require('express');
const router = express.Router();
const multer = require('multer');
const { authMiddleware } = require('../middleware/auth');
const { requireRol } = require('../middleware/roles');
const {
  getPrecios,
  updatePrecioProducto,
  bulkUpdatePrecios,
  getCoherenciaReport,
  exportPreciosCsv,
  importPreciosCsv
} = require('../controllers/adminPreciosController');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB
});

// Todas las rutas de administración de precios están protegidas con autenticación y rol 'admin'
router.use(authMiddleware);
router.use(requireRol('admin'));

router.get('/precios', getPrecios);
router.get('/precios/coherencia', getCoherenciaReport);
router.get('/precios/export.csv', exportPreciosCsv);
router.post('/precios/import.csv', upload.single('archivo'), importPreciosCsv);
router.put('/precios/:productoId', updatePrecioProducto);
router.patch('/precios/bulk', bulkUpdatePrecios);

module.exports = router;
