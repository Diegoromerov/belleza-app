const express = require('express');
const router = express.Router();
const { wrapRouterAsync } = require('../utils/expressAsync');
const multer = require('multer');
const { authMiddleware } = require('../middleware/auth');
const { requireRol } = require('../middleware/roles');
const {
  getPrecios,
  updatePrecioProducto,
  bulkUpdatePrecios,
  getCoherenciaReport,
  exportPreciosCsv,
  importPreciosCsv,
  getHistorialPrecios
} = require('../controllers/adminPreciosController');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB
});

const { adminAuditLog } = require('../middleware/adminAuditLog');

// Todas las rutas de administración de precios están protegidas con autenticación y rol 'admin'
router.use(authMiddleware);
router.use(requireRol('admin'));

router.get('/precios', getPrecios);
router.get('/precios/coherencia', getCoherenciaReport);
router.get('/precios/historial', getHistorialPrecios);
router.get('/precios/export.csv', exportPreciosCsv);
router.post('/precios/import.csv', upload.single('archivo'), adminAuditLog({ action: 'precios.import_csv', resource: 'precios' }), importPreciosCsv);
router.put('/precios/:productoId', adminAuditLog({ action: 'precios.update', resource: 'precios' }), updatePrecioProducto);
router.patch('/precios/bulk', adminAuditLog({ action: 'precios.bulk_update', resource: 'precios' }), bulkUpdatePrecios);

// Universal: envuelve TODOS los handlers async de este router (rutas y middleware)
// para que un rechazo async llegue a next(err) en vez de tumbar el proceso.
wrapRouterAsync(router);

module.exports = router;
