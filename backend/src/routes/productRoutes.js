// backend/src/routes/productRoutes.js
const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const productController = require('../controllers/productController');
const orderController = require('../controllers/orderController');

// Obtener catálogo de productos (soporta filtros por tag de especialidad)
router.get('/products', authMiddleware, productController.getProducts);

// Obtener un producto por ID
router.get('/products/:id', authMiddleware, productController.getProductById);

// Cargar un producto (Administrador)
router.post('/admin/products', authMiddleware, productController.createProduct);

// --- Rutas de Pedidos de GlowStore ---
router.post('/store/checkout', authMiddleware, orderController.createOrder);
router.get('/store/orders', authMiddleware, orderController.getOrders);
router.get('/store/orders/:id', authMiddleware, orderController.getOrderById);

module.exports = router;
