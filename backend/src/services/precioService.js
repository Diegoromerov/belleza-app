const { pool } = require('../config/db');

/**
 * Mapea roles de API ('client', 'provider', 'salon', 'admin') y de BD ('CLIENTE', 'PRESTADOR', 'SALON', 'ADMIN')
 * al código de lista correspondiente ('cliente', 'profesional', 'negocio').
 */
function rolACodigoLista(rol) {
  if (!rol) return 'cliente';
  const norm = String(rol).trim().toLowerCase();
  if (norm === 'provider' || norm === 'prestador') return 'profesional';
  if (norm === 'salon') return 'negocio';
  if (norm === 'client' || norm === 'cliente') return 'cliente';
  if (norm === 'admin') return 'cliente';
  return 'cliente';
}

/**
 * Servicio único para resolver precios por nivel de comercialización.
 *
 * @param {Object} params
 * @param {string} params.rol - Rol del comprador ('client'|'provider'|'salon'|'admin' o equivalente BD)
 * @param {number} [params.tenantId] - Contexto opcional de tenant
 * @param {number|string} params.productoId - ID del producto
 * @param {number} [params.cantidad=1] - Cantidad a comprar
 * @returns {Promise<{lista: string, precio?: number, unidad_minima: number, incluye_iva?: boolean, estado?: string}>}
 */
async function resolverPrecio({ rol, tenantId, productoId, cantidad = 1 }) {
  const parsedProductoId = parseInt(productoId, 10);
  if (isNaN(parsedProductoId)) {
    throw new Error('productoId inválido');
  }

  const codigoLista = rolACodigoLista(rol);
  const parsedCantidad = Math.max(1, parseInt(cantidad, 10) || 1);

  // 1. Obtener la lista activa correspondiente de plataforma
  const listaQuery = `
    SELECT id, codigo, nombre, rol_destino, incluye_iva
    FROM listas_precios
    WHERE codigo = $1
      AND estado = 'ACTIVA'
      AND vigente_desde <= CURRENT_DATE
      AND (vigente_hasta IS NULL OR vigente_hasta >= CURRENT_DATE)
    ORDER BY id LIMIT 1;
  `;
  const listaRes = await pool.query(listaQuery, [codigoLista]);

  const defaultMinima = codigoLista === 'negocio' ? 6 : 1;
  if (listaRes.rows.length === 0) {
    return {
      estado: 'sin_precio',
      lista: codigoLista,
      unidad_minima: defaultMinima
    };
  }

  const lista = listaRes.rows[0];

  // 2. Obtener el precio para el producto en esa lista
  const precioQuery = `
    SELECT p.precio, p.unidad_minima, p.vigente_desde, p.vigente_hasta
    FROM precios_producto p
    WHERE p.lista_id = $1
      AND p.producto_id = $2
      AND p.vigente_desde <= CURRENT_DATE
      AND (p.vigente_hasta IS NULL OR p.vigente_hasta >= CURRENT_DATE)
    LIMIT 1;
  `;
  const precioRes = await pool.query(precioQuery, [lista.id, parsedProductoId]);

  if (precioRes.rows.length === 0) {
    return {
      estado: 'sin_precio',
      lista: codigoLista,
      unidad_minima: codigoLista === 'negocio' ? 6 : 1
    };
  }

  const row = precioRes.rows[0];
  const unidadMinima = parseInt(row.unidad_minima, 10) || (codigoLista === 'negocio' ? 6 : 1);

  // 3. Validar mínimo de venta
  if (parsedCantidad < unidadMinima) {
    const error = new Error(`La cantidad solicitada (${parsedCantidad}) es menor a la unidad mínima de venta (${unidadMinima}) para la lista ${codigoLista}.`);
    error.code = 'MINIMO_NO_CUMPLIDO';
    error.unidad_minima = unidadMinima;
    error.lista = codigoLista;
    throw error;
  }

  return {
    lista: codigoLista,
    precio: parseFloat(row.precio),
    unidad_minima: unidadMinima,
    incluye_iva: lista.incluye_iva
  };
}

module.exports = {
  resolverPrecio,
  rolACodigoLista
};
