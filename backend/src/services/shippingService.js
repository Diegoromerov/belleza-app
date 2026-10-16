// backend/src/services/shippingService.js
// Motor de cotización de envío por zonas (L5)
const { pool } = require('../config/db');

/**
 * Cotiza el costo de envío para una dirección y valor de pedido.
 * 
 * @param {Object} params
 * @param {string} params.ciudad - Ciudad de destino
 * @param {string} params.departamento - Departamento de destino
 * @param {string} [params.codigo_postal] - Código postal (opcional, para match por prefijo)
 * @param {number} [params.peso_total_kg=0.5] - Peso estimado del paquete en kg
 * @param {number} [params.valor_pedido=0] - Valor total del pedido (para envío gratis por monto)
 * @returns {Promise<Object>} { costo, transportadora, dias_estimados, gratis, zona, tarifa_base, tarifa_por_kg }
 */
async function cotizarEnvio({ ciudad, departamento, codigo_postal, peso_total_kg = 0.5, valor_pedido = 0 }) {
  if (!ciudad || !departamento) {
    throw new Error('ciudad y departamento son obligatorios para cotizar envío');
  }

  const cp = codigo_postal || '';

  // 1. Buscar zona exacta: ciudad + departamento + prefijo CP (el más específico primero)
  let zonaRes = await pool.query(
    `SELECT * FROM zonas_envio 
     WHERE activa 
       AND lower(ciudad) = lower($1) 
       AND lower(departamento) = lower($2)
       AND (codigo_postal_prefijo IS NULL OR $3 LIKE codigo_postal_prefijo || '%')
     ORDER BY 
       CASE WHEN codigo_postal_prefijo IS NULL THEN 0 ELSE 1 END DESC,
       LENGTH(codigo_postal_prefijo) DESC
     LIMIT 1`,
    [ciudad, departamento, cp]
  );

  // 2. Fallback: solo ciudad + departamento (sin prefijo CP)
  if (zonaRes.rows.length === 0) {
    zonaRes = await pool.query(
      `SELECT * FROM zonas_envio 
       WHERE activa 
         AND lower(ciudad) = lower($1) 
         AND lower(departamento) = lower($2)
       LIMIT 1`,
      [ciudad, departamento]
    );
  }

  // 3. Fallback global "OTRO"
  if (zonaRes.rows.length === 0) {
    zonaRes = await pool.query(
      `SELECT * FROM zonas_envio WHERE activa AND ciudad = 'OTRO' LIMIT 1`
    );
  }

  if (zonaRes.rows.length === 0) {
    // Hardcoded fallback extremo (no debería ocurrir si seed tiene OTRO)
    return {
      costo: 15000,
      transportadora: 'Coordinadora',
      dias_estimados: '3-6 días hábiles',
      gratis: false,
      zona: 'Desconocida',
      tarifa_base: 15000,
      tarifa_por_kg: 800
    };
  }

  const z = zonaRes.rows[0];
  const tarifaBase = parseFloat(z.tarifa_base);
  const tarifaPorKg = parseFloat(z.tarifa_por_kg || 0);
  const gratisDesde = z.gratis_desde_monto ? parseFloat(z.gratis_desde_monto) : null;

  // Calcular costo: base + peso
  let costo = tarifaBase + (tarifaPorKg * peso_total_kg);

  // Envío gratis por monto
  const gratis = gratisDesde !== null && valor_pedido >= gratisDesde;
  if (gratis) costo = 0;

  return {
    costo: Math.round(costo),
    transportadora: z.transportadora_default || 'Coordinadora',
    dias_estimados: `${z.dias_estimados_min}-${z.dias_estimados_max} días hábiles`,
    gratis,
    zona: `${z.ciudad}, ${z.departamento}`,
    tarifa_base: tarifaBase,
    tarifa_por_kg: tarifaPorKg,
    gratis_desde_monto: gratisDesde
  };
}

/**
 * Obtiene todas las zonas activas (para admin)
 */
async function getAllZonas() {
  const res = await pool.query(
    `SELECT * FROM zonas_envio WHERE activa ORDER BY departamento, ciudad`
  );
  return res.rows;
}

/**
 * Crea o actualiza una zona (admin)
 */
async function upsertZona(zonaData) {
  const {
    ciudad,
    departamento,
    codigo_postal_prefijo,
    tarifa_base,
    tarifa_por_kg,
    gratis_desde_monto,
    transportadora_default,
    dias_estimados_min,
    dias_estimados_max,
    activa = true
  } = zonaData;

  const res = await pool.query(
    `INSERT INTO zonas_envio 
      (ciudad, departamento, codigo_postal_prefijo, tarifa_base, tarifa_por_kg, gratis_desde_monto, transportadora_default, dias_estimados_min, dias_estimados_max, activa)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
     ON CONFLICT (ciudad, departamento, codigo_postal_prefijo) DO UPDATE SET
      tarifa_base = EXCLUDED.tarifa_base,
      tarifa_por_kg = EXCLUDED.tarifa_por_kg,
      gratis_desde_monto = EXCLUDED.gratis_desde_monto,
      transportadora_default = EXCLUDED.transportadora_default,
      dias_estimados_min = EXCLUDED.dias_estimados_min,
      dias_estimados_max = EXCLUDED.dias_estimados_max,
      activa = EXCLUDED.activa
     RETURNING *`,
    [ciudad, departamento, codigo_postal_prefijo, tarifa_base, tarifa_por_kg, gratis_desde_monto, transportadora_default, dias_estimados_min, dias_estimados_max, activa]
  );
  return res.rows[0];
}

/**
 * Desactiva una zona (admin)
 */
async function deactivateZona(ciudad, departamento, codigo_postal_prefijo) {
  const res = await pool.query(
    `UPDATE zonas_envio SET activa = false WHERE lower(ciudad) = lower($1) AND lower(departamento) = lower($2) AND (codigo_postal_prefijo IS NULL AND $3 IS NULL OR codigo_postal_prefijo = $3) RETURNING *`,
    [ciudad, departamento, codigo_postal_prefijo]
  );
  return res.rows[0];
}

module.exports = {
  cotizarEnvio,
  getAllZonas,
  upsertZona,
  deactivateZona
};