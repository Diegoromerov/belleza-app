// backend/src/routes/productRoutes.js
const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const productController = require('../controllers/productController');

// Obtener catálogo de productos (soporta filtros por tag de especialidad)
router.get('/products', authMiddleware, productController.getProducts);

// Obtener un producto por ID
router.get('/products/:id', authMiddleware, productController.getProductById);

// Cargar un producto (Administrador)
router.post('/admin/products', authMiddleware, productController.createProduct);

module.exports = router;
