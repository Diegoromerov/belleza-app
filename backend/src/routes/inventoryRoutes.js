// backend/src/routes/inventoryRoutes.js
const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const inventoryController = require('../controllers/inventoryController');

// 🔹 OBTENER INVENTARIO EN CONSIGNACIÓN Y ALERTAS
router.get('/inventory/consignacion', authMiddleware, inventoryController.getProviderConsignmentInventory);

// 🔹 REGISTRAR CONSUMO O VENTA DE INSUMO EN SALÓN SAAS
router.post('/inventory/consume', authMiddleware, inventoryController.consumeInventoryItem);

module.exports = router;
