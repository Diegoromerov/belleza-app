// backend/src/services/glowContracts.js
/**
 * GLOW IA+ SEMANTIC CONTRACTS (CONTRACT_01, CONTRACT_02, CONTRACT_03)
 */

const METRIC_DEFINITIONS = {
  hydration: { direction: 'INCREASE_IS_BETTER', min: 0, max: 100, label: 'Hidratación' },
  elasticity: { direction: 'INCREASE_IS_BETTER', min: 0, max: 100, label: 'Elasticidad' },
  barrier: { direction: 'INCREASE_IS_BETTER', min: 0, max: 100, label: 'Barrera Cutánea' },
  firmness: { direction: 'INCREASE_IS_BETTER', min: 0, max: 100, label: 'Firmeza' },
  pores: { direction: 'DECREASE_IS_BETTER', min: 0, max: 100, label: 'Tamaño de Poros' },
  wrinkles: { direction: 'DECREASE_IS_BETTER', min: 0, max: 100, label: 'Arrugas / Líneas de Expresión' },
  spots: { direction: 'DECREASE_IS_BETTER', min: 0, max: 100, label: 'Manchas / Pigmentación' },
  redness: { direction: 'DECREASE_IS_BETTER', min: 0, max: 100, label: 'Enrojecimiento / Sensibilidad' },
  oiliness: { direction: 'DECREASE_IS_BETTER', min: 0, max: 100, label: 'Exceso de Sebo' }
};

/**
 * Obtiene la definición formal de una métrica
 */
function getMetricDefinition(metricKey) {
  const keyLower = String(metricKey || '').toLowerCase();
  return METRIC_DEFINITIONS[keyLower] || {
    direction: 'INCREASE_IS_BETTER',
    min: 0,
    max: 100,
    label: metricKey
  };
}

/**
 * CONTRACT_01: Calcula el delta semántico entre un valor base y el valor actual
 * Para métricas DECREASE_IS_BETTER (ej. poros), reducir el valor es una mejora (delta positivo).
 */
function calculateSemanticDelta(metricKey, baselineValue, currentValue) {
  const base = parseFloat(baselineValue) || 0;
  const current = parseFloat(currentValue) || 0;
  const def = getMetricDefinition(metricKey);

  if (def.direction === 'DECREASE_IS_BETTER') {
    return base - current;
  }
  return current - base;
}

/**
 * CONTRACT_01: Determina si el valor actual satisface la condición de objetivo alcanzado
 */
function isGoalReached(metricKey, currentValue, targetValue) {
  const current = parseFloat(currentValue);
  const target = parseFloat(targetValue);
  if (isNaN(current) || isNaN(target)) return false;

  const def = getMetricDefinition(metricKey);

  if (def.direction === 'DECREASE_IS_BETTER') {
    return current <= target;
  }
  return current >= target;
}

/**
 * CONTRACT_02 & CONTRACT_03: Normaliza una medición biométrica con datos de trazabilidad y calidad
 */
function normalizeMeasurement(rawScores = {}, provenance = {}) {
  const normalizedScores = {};
  for (const [key, val] of Object.entries(rawScores)) {
    const num = parseFloat(val);
    if (!isNaN(num)) {
      normalizedScores[key.toLowerCase()] = num;
    }
  }

  const qualityScore = typeof provenance.qualityScore === 'number'
    ? Math.min(1.0, Math.max(0.0, provenance.qualityScore))
    : 0.90;

  const getBogotaDateString = () => {
    return new Intl.DateTimeFormat('sv-SE', { timeZone: 'America/Bogota' }).format(new Date());
  };

  return {
    scores: normalizedScores,
    provenance: {
      source: provenance.source || 'YOUCAM',
      analysisId: provenance.analysisId || `analysis_${Date.now()}`,
      confidenceLevel: provenance.confidenceLevel || (qualityScore >= 0.8 ? 'HIGH' : qualityScore >= 0.5 ? 'MEDIUM' : 'LOW'),
      qualityScore,
      timestamp: provenance.timestamp || new Date().toISOString(),
      localDate: getBogotaDateString()
    }
  };
}

module.exports = {
  METRIC_DEFINITIONS,
  getMetricDefinition,
  calculateSemanticDelta,
  isGoalReached,
  normalizeMeasurement
};
