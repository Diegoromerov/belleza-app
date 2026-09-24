const { pool } = require('../config/db');
const { resolverPrecio, rolACodigoLista, conContextoDePlataforma } = require('../services/precioService');

// GET /api/products → Obtener catálogo de productos (filtrado por rol y nivel de precios)
exports.getProducts = async (req, res) => {
  try {
    const { tag } = req.query;
    const userRole = req.user ? req.user.role : 'client'; // 'client', 'provider', 'salon', 'admin'
    const codigoLista = rolACodigoLista(userRole);

    const executeGetProducts = async (dbClient) => {
      let query = `
        SELECT p.id, p.nombre, p.descripcion, p.stock, p.imagen_url, p.tag_especialidad, p.tipo_visibilidad,
               pp.precio, pp.unidad_minima
        FROM productos p
        INNER JOIN precios_producto pp ON pp.producto_id = p.id
        INNER JOIN listas_precios lp ON lp.id = pp.lista_id
        WHERE lp.codigo = $1
          AND lp.estado = 'ACTIVA'
          AND pp.precio IS NOT NULL
      `;
      const params = [codigoLista];

      if (tag) {
        query += ' AND p.tag_especialidad = $2';
        params.push(tag);
      }

      query += ' ORDER BY p.id ASC;';

      const { rows } = await dbClient.query(query, params);

      const formattedData = rows.map(r => ({
        id: r.id,
        nombre: r.nombre,
        descripcion: r.descripcion,
        precio: parseFloat(r.precio),
        unidad_minima: parseInt(r.unidad_minima, 10),
        stock: r.stock,
        imagen_url: r.imagen_url,
        tag_especialidad: r.tag_especialidad,
        tipo_visibilidad: r.tipo_visibilidad
      }));

      return res.json({
        success: true,
        count: formattedData.length,
        data: formattedData
      });
    };

    if (!req.user) {
      // Invitado público: ejecutar bajo contexto de plataforma explícito (sin BypassRLS)
      return await conContextoDePlataforma(pool, executeGetProducts);
    } else {
      return await executeGetProducts(pool);
    }
  } catch (error) {
    console.error('❌ ERROR EN GET /api/products:', error);
    return res.status(500).json({ error: 'Error al obtener productos' });
  }
};

// GET /api/products/:id → Obtener producto específico por ID
exports.getProductById = async (req, res) => {
  try {
    const productId = req.params.id;
    const userRole = req.user ? req.user.role : 'client';

    const executeGetProductById = async (dbClient) => {
      const { rows } = await dbClient.query(
        'SELECT id, nombre, descripcion, stock, imagen_url, tag_especialidad, tipo_visibilidad FROM productos WHERE id = $1;',
        [productId]
      );

      if (rows.length === 0) {
        return res.status(404).json({ error: 'Producto no encontrado' });
      }

      const product = rows[0];

      // Resolver precio por nivel de comprador
      const resPrecio = await resolverPrecio({
        rol: userRole,
        productoId: product.id,
        cantidad: 1
      });

      if (resPrecio.estado === 'sin_precio' || resPrecio.precio === null || resPrecio.precio === undefined) {
        return res.status(403).json({ error: 'No tienes acceso a este producto' });
      }

      const responseData = {
        id: product.id,
        nombre: product.nombre,
        descripcion: product.descripcion,
        precio: resPrecio.precio,
        unidad_minima: resPrecio.unidad_minima,
        stock: product.stock,
        imagen_url: product.imagen_url,
        tag_especialidad: product.tag_especialidad,
        tipo_visibilidad: product.tipo_visibilidad
      };

      return res.json({
        success: true,
        data: responseData
      });
    };

    if (!req.user) {
      return await conContextoDePlataforma(pool, executeGetProductById);
    } else {
      return await executeGetProductById(pool);
    }
  } catch (error) {
    console.error('❌ ERROR EN GET /api/products/:id:', error);
    return res.status(500).json({ error: 'Error al obtener producto' });
  }
};

// POST /api/admin/products → Cargar/crear nuevo producto (para el Dashboard)
exports.createProduct = async (req, res) => {
  try {
    // Validar rol del usuario logueado
    if (req.user.role !== 'admin' && req.user.role !== 'provider') {
      return res.status(403).json({ error: 'No autorizado para realizar esta acción' });
    }

    const { 
      nombre, 
      descripcion, 
      precio_al_publico, 
      precio_con_reserva, 
      precio_prestador, 
      comision_prestador, 
      stock, 
      imagen_url, 
      tag_especialidad,
      tipo_visibilidad
    } = req.body;

    if (!nombre || !tag_especialidad) {
      return res.status(400).json({ error: 'nombre y tag_especialidad son obligatorios' });
    }

    const query = `
      INSERT INTO productos (nombre, descripcion, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      RETURNING id, nombre, descripcion, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad;
    `;

    const { rows } = await pool.query(query, [
      nombre,
      descripcion || '',
      precio_al_publico || 0.00,
      precio_con_reserva || 0.00,
      precio_prestador || 0.00,
      comision_prestador || 0.00,
      stock || 0,
      imagen_url || '',
      tag_especialidad,
      tipo_visibilidad || 'PUBLICO'
    ]);

    res.status(201).json({
      success: true,
      data: rows[0]
    });
  } catch (error) {
    console.error('❌ ERROR EN POST /api/admin/products:', error);
    res.status(500).json({ error: 'Error al crear producto' });
  }
};

// PUT /api/admin/products/:id → Actualizar producto existente (para el Dashboard)
exports.updateProduct = async (req, res) => {
  try {
    if (req.user.role !== 'admin' && req.user.role !== 'provider') {
      return res.status(403).json({ error: 'No autorizado para realizar esta acción' });
    }

    const productId = req.params.id;
    const { 
      nombre, 
      descripcion, 
      precio_al_publico, 
      precio_con_reserva, 
      precio_prestador, 
      comision_prestador, 
      stock, 
      imagen_url, 
      tag_especialidad,
      tipo_visibilidad
    } = req.body;

    if (!nombre || !tag_especialidad) {
      return res.status(400).json({ error: 'nombre y tag_especialidad son obligatorios' });
    }

    const query = `
      UPDATE productos 
      SET nombre = $1, descripcion = $2, precio_al_publico = $3, precio_con_reserva = $4, 
          precio_prestador = $5, comision_prestador = $6, stock = $7, imagen_url = $8, 
          tag_especialidad = $9, tipo_visibilidad = $10
      WHERE id = $11
      RETURNING id, nombre, descripcion, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad;
    `;

    const { rows } = await pool.query(query, [
      nombre,
      descripcion || '',
      precio_al_publico || 0.00,
      precio_con_reserva || 0.00,
      precio_prestador || 0.00,
      comision_prestador || 0.00,
      stock || 0,
      imagen_url || '',
      tag_especialidad,
      tipo_visibilidad || 'PUBLICO',
      productId
    ]);

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Producto no encontrado' });
    }

    res.json({
      success: true,
      data: rows[0]
    });
  } catch (error) {
    console.error('❌ ERROR EN PUT /api/admin/products/:id:', error);
    res.status(500).json({ error: 'Error al actualizar producto' });
  }
};

// DELETE /api/admin/products/:id → Eliminar producto de la base de datos (para el Dashboard)
exports.deleteProduct = async (req, res) => {
  try {
    if (req.user.role !== 'admin' && req.user.role !== 'provider') {
      return res.status(403).json({ error: 'No autorizado para realizar esta acción' });
    }

    const productId = req.params.id;
    const { rowCount } = await pool.query('DELETE FROM productos WHERE id = $1;', [productId]);

    if (rowCount === 0) {
      return res.status(404).json({ error: 'Producto no encontrado' });
    }

    res.json({
      success: true,
      message: 'Producto eliminado con éxito'
    });
  } catch (error) {
    console.error('❌ ERROR EN DELETE /api/admin/products/:id:', error);
    res.status(500).json({ error: 'Error al eliminar producto' });
  }
};
