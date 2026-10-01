// backend/src/utils/money.js
//
// ARITMÉTICA MONETARIA EN CENTAVOS ENTEROS
//
// Motivo (P0 dinero — t_fix_pagos_06):
//   Calcular montos con punto flotante pierde centavos. Ejemplo real de la
//   dispersión de pagos: el IVA del 15% sobre una comisión de 1.50 se obtenía así
//       Math.round(1.5 * (15 / 100) * 100) / 100
//   1.5 * 0.15 = 0.22499999999999998  ->  *100 = 22.499999999999996
//   Math.round(22.499999999999996) = 22  ->  0.22
//   Cuando el resultado exacto es 22.5 centavos, que redondeado half-up es 23 (0.23).
//   Un centavo de menos por cada dispersión con esa fracción, siempre en contra del
//   prestador (o a favor del sistema), y silencioso.
//
//   La regla es: NUNCA se opera en decimales. Todo se convierte a centavos enteros,
//   se calcula con enteros (Math.round sobre el producto entero) y solo al final se
//   vuelve a decimal para persistir en las columnas NUMERIC(x,2).

const CENTAVOS_POR_UNIDAD = 100;

/**
 * Convierte un monto (número o string tipo NUMERIC de PostgreSQL) a centavos enteros.
 * Acepta null/undefined/'' → 0. Los valores no finitos se tratan como 0 para no
 * propagar NaN a los saldos.
 */
function aCentavos(valor) {
  if (valor === null || valor === undefined || valor === '') return 0;
  const n = typeof valor === 'string' ? parseFloat(valor) : Number(valor);
  if (!Number.isFinite(n)) return 0;
  // Math.round corrige la representación binaria (p.ej. 1.005*100 = 100.49999...).
  return Math.round(n * CENTAVOS_POR_UNIDAD);
}

/** Convierte centavos enteros a decimal (número con 2 decimales exactos). */
function aDecimal(centavos) {
  return Math.round(Number(centavos) || 0) / CENTAVOS_POR_UNIDAD;
}

/**
 * Aplica un porcentaje sobre un monto en centavos y devuelve CENTAVOS ENTEROS.
 * El redondeo es half-up sobre el valor exacto en centavos, sin pasar por float
 * en el resultado: (centavos * pct) / 100.
 *   porcentajeCentavos(150, 15) -> (150 * 15) / 100 = 22.5 -> 23
 */
function porcentajeCentavos(centavos, pct) {
  const c = Math.round(Number(centavos) || 0);
  const p = Number(pct);
  if (!Number.isFinite(p)) return 0;
  return Math.round((c * p) / 100);
}

/**
 * Calcula las retenciones de una dispersión y el neto, todo en centavos enteros:
 *   fuente = % sobre el pago neto base
 *   ica    = % sobre el pago neto base
 *   iva    = % sobre la comisión de plataforma
 *   neto   = base - (fuente + ica + iva)
 */
function aplicarRetencionesCentavos({ baseCentavos, comisionCentavos, pctFuente, pctIca, pctIva }) {
  const baseC = Math.round(Number(baseCentavos) || 0);
  const comisionC = Math.round(Number(comisionCentavos) || 0);
  const fuenteCentavos = porcentajeCentavos(baseC, pctFuente);
  const icaCentavos = porcentajeCentavos(baseC, pctIca);
  const ivaCentavos = porcentajeCentavos(comisionC, pctIva);
  const totalCentavos = fuenteCentavos + icaCentavos + ivaCentavos;
  return {
    fuenteCentavos,
    icaCentavos,
    ivaCentavos,
    totalCentavos,
    netoCentavos: baseC - totalCentavos,
  };
}

/** Suma montos decimales sin deriva de float (vía centavos enteros). */
function sumarMontos(...montos) {
  return aDecimal(montos.reduce((acc, m) => acc + aCentavos(m), 0));
}

module.exports = {
  CENTAVOS_POR_UNIDAD,
  aCentavos,
  aDecimal,
  porcentajeCentavos,
  aplicarRetencionesCentavos,
  sumarMontos,
};
