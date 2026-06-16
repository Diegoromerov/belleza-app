// backend/src/controllers/productController.js
const { sequelize } = require('../config/database');
const { QueryTypes } = require('sequelize');

// GET /api/products → Obtener catálogo de productos
exports.getProducts = async (req, res) => {
  try {
    const { tag } = req.query;
    let query = 'SELECT id, nombre, descripcion, precio, stock, imagen_url, tag_especialidad FROM productos';
    const replacements = {};

    if (tag) {
      query += ' WHERE tag_especialidad = :tag';
      replacements.tag = tag;
    }

    query += ' ORDER BY id ASC;';

    const products = await sequelize.query(query, {
      replacements,
      type: QueryTypes.SELECT
    });

    res.json({
      success: true,
      count: products.length,
      data: products
    });
  } catch (error) {
    console.error('❌ ERROR EN GET /api/products:', error);
    res.status(500).json({ error: 'Error al obtener productos' });
  }
};

// GET /api/products/:id → Obtener producto específico por ID
exports.getProductById = async (req, res) => {
  try {
    const productId = req.params.id;
    const query = 'SELECT id, nombre, descripcion, precio, stock, imagen_url, tag_especialidad FROM productos WHERE id = :productId;';
    
    const results = await sequelize.query(query, {
      replacements: { productId },
      type: QueryTypes.SELECT
    });

    if (results.length === 0) {
      return res.status(404).json({ error: 'Producto no encontrado' });
    }

    res.json({
      success: true,
      data: results[0]
    });
  } catch (error) {
    console.error('❌ ERROR EN GET /api/products/:id:', error);
    res.status(500).json({ error: 'Error al obtener producto' });
  }
};

// POST /api/admin/products → Cargar/crear nuevo producto (para el Dashboard)
exports.createProduct = async (req, res) => {
  try {
    // Validar rol del usuario logueado
    if (req.user.rol !== 'ADMIN' && req.user.rol !== 'PRESTADOR') {
      return res.status(403).json({ error: 'No autorizado para realizar esta acción' });
    }

    const { nombre, descripcion, precio, stock, imagen_url, tag_especialidad } = req.body;

    if (!nombre || !precio || !tag_especialidad) {
      return res.status(400).json({ error: 'nombre, precio y tag_especialidad son obligatorios' });
    }

    const query = `
      INSERT INTO productos (nombre, descripcion, precio, stock, imagen_url, tag_especialidad)
      VALUES (:nombre, :descripcion, :precio, :stock, :imagen_url, :tag_especialidad)
      RETURNING id, nombre, descripcion, precio, stock, imagen_url, tag_especialidad;
    `;

    const results = await sequelize.query(query, {
      replacements: {
        nombre,
        descripcion: descripcion || '',
        precio,
        stock: stock || 0,
        imagen_url: imagen_url || '',
        tag_especialidad
      },
      type: QueryTypes.INSERT
    });

    const createdProduct = results[0][0];

    res.status(201).json({
      success: true,
      data: createdProduct
    });
  } catch (error) {
    console.error('❌ ERROR EN POST /api/admin/products:', error);
    res.status(500).json({ error: 'Error al crear producto' });
  }
};
