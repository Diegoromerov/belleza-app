'use strict';
// backend/src/utils/money.js
// FASE C · t_fix_backend_04 — Aritmética monetaria en CENTAVOS ENTEROS.
//
// Regla dura: el dinero NUNCA se suma, resta ni acumula en float.
// Se convierte a centavos (enteros), se opera en enteros y se redondea UNA sola vez
// al centavo. Sin esto, `100.10 - (4.00 + 0.41 + 0.90)` da 94.78999999999999.
//
// La moneda del negocio es COP con 2 decimales → 1 unidad = 100 centavos.
// Los montos que llegan de PostgreSQL (`numeric`) se reciben como string y se
// convierten por parseo decimal exacto (no `Number(x) * 100`), evitando la deriva binaria.

const CENTAVOS_POR_UNIDAD = 100;

function esEntero(v) {
  return typeof v === 'number' && Number.isInteger(v);
}

function assertEntero(valor, etiqueta) {
  if (!esEntero(valor)) {
    throw new TypeError(`${etiqueta} debe ser un entero de centavos; recibido: ${JSON.stringify(valor)}`);
  }
}

/**
 * Convierte un monto en unidades (pesos) a centavos enteros, con redondeo half-up
 * al tercer decimal. Acepta string (formato de columna `numeric` en pg) o number.
 */
function toCents(valor) {
  if (valor === null || valor === undefined || valor === '') return 0;

  if (typeof valor === 'number' && !Number.isFinite(valor)) {
    throw new TypeError(`Monto no finito: ${valor}`);
  }

  const texto = typeof valor === 'string' ? valor.trim() : String(valor);

  // Parseo decimal exacto: evita heredar el error binario del float.
  const m = /^([+-]?)(\d+)(?:\.(\d+))?$/.exec(texto);
  if (m) {
    const signo = m[1] === '-' ? -1 : 1;
    const entero = parseInt(m[2], 10);
    const decimales = (m[3] || '').padEnd(3, '0');
    const centavos = Number(decimales.slice(0, 2)) + (Number(decimales[2]) >= 5 ? 1 : 0);
    return signo * (entero * CENTAVOS_POR_UNIDAD + centavos);
  }

  // Notación exponencial u otros formatos numéricos: conversión controlada.
  const numero = Number(texto);
  if (!Number.isFinite(numero)) {
    throw new TypeError(`Monto no numérico: ${JSON.stringify(valor)}`);
  }
  return Math.round(numero * CENTAVOS_POR_UNIDAD);
}

/**
 * Inverso de toCents: centavos enteros → unidades (pesos).
 * El valor devuelto es apto para columnas `numeric` (2 decimales).
 */
function fromCents(centavos) {
  assertEntero(centavos, 'fromCents(centavos)');
  return centavos / CENTAVOS_POR_UNIDAD;
}

/**
 * Suma una lista de montos YA expresados en centavos enteros.
 */
function sumarCents(...listaCentavos) {
  let total = 0;
  for (const c of listaCentavos) {
    assertEntero(c, 'sumarCents(…centavos)');
    total += c;
  }
  return total;
}

/**
 * Porcentaje de un monto en centavos → centavos enteros (redondeo half-up).
 * `porcentaje` es un punto porcentual tal como se guarda en platform_config
 * (p. ej. 4.0, 0.414, 15.0).
 */
function pctOf(centavos, porcentaje) {
  assertEntero(centavos, 'pctOf(centavos, …)');
  const pct = Number(porcentaje);
  if (!Number.isFinite(pct)) {
    throw new TypeError(`Porcentaje no numérico: ${JSON.stringify(porcentaje)}`);
  }
  return Math.round((centavos * pct) / 100);
}

/**
 * Liquidación de un servicio: retenciones colombianas y neto del prestador,
 * TODO en centavos enteros. La suma del total no puede derivar.
 *
 * @param {object} p
 * @param {number} p.basePagoNetoCents         pago_neto_prestador en centavos
 * @param {number} p.comisionPlataformaCents   comision_plataforma en centavos
 * @param {number|string} p.retefuentePct      %
 * @param {number|string} p.reteicaPct         %
 * @param {number|string} p.reteivaPct         %
 */
function calcularRetenciones({
  basePagoNetoCents,
  comisionPlataformaCents,
  retefuentePct,
  reteicaPct,
  reteivaPct
}) {
  assertEntero(basePagoNetoCents, 'basePagoNetoCents');
  assertEntero(comisionPlataformaCents, 'comisionPlataformaCents');

  const retencionFuenteCents = pctOf(basePagoNetoCents, retefuentePct);
  const retencionIcaCents = pctOf(basePagoNetoCents, reteicaPct);
  const retencionIvaCents = pctOf(comisionPlataformaCents, reteivaPct);

  const totalRetencionesCents = sumarCents(
    retencionFuenteCents,
    retencionIcaCents,
    retencionIvaCents
  );
  const montoNetoCents = basePagoNetoCents - totalRetencionesCents;

  return {
    retencionFuenteCents,
    retencionIcaCents,
    retencionIvaCents,
    totalRetencionesCents,
    montoNetoCents
  };
}

module.exports = {
  CENTAVOS_POR_UNIDAD,
  toCents,
  fromCents,
  sumarCents,
  pctOf,
  calcularRetenciones
};
