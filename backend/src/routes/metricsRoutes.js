// backend/src/routes/metricsRoutes.js
const express = require('express');
const router = express.Router();
const { authMiddleware, adminMiddleware } = require('../middleware/auth');
const { getProductionMetrics, getMetricsByDay, getMetricsWithComparison } = require('../services/ragMetrics');

// Middleware: autenticación + admin
router.use(authMiddleware);
router.use(adminMiddleware);

/**
 * GET /api/metrics/rag
 * Retorna métricas de producción del RAG
 * Query params: timeRange (24h, 7d, 30d, 90d), compare (true/false)
 */
router.get('/rag', async (req, res) => {
  try {
    const timeRange = req.query.timeRange || '24h';
    const compare = req.query.compare === 'true';
    
    let metrics;
    if (compare) {
      metrics = await getMetricsWithComparison(timeRange);
    } else {
      metrics = await getProductionMetrics(timeRange);
    }
    
    res.json({
      success: true,
      data: metrics
    });
  } catch (error) {
    console.error('❌ Error GET /api/metrics/rag:', error.message);
    res.status(500).json({ 
      error: 'internal_error', 
      message: 'Error obteniendo métricas RAG' 
    });
  }
});

/**
 * GET /api/metrics/rag/daily
 * Retorna serie temporal diaria para dashboard
 * Query params: days (default 30)
 */
router.get('/rag/daily', async (req, res) => {
  try {
    const days = parseInt(req.query.days) || 30;
    const metrics = await getMetricsByDay(days);
    
    res.json({
      success: true,
      data: metrics
    });
  } catch (error) {
    console.error('❌ Error GET /api/metrics/rag/daily:', error.message);
    res.status(500).json({ 
      error: 'internal_error', 
      message: 'Error obteniendo métricas diarias RAG' 
    });
  }
});

/**
 * GET /api/metrics/rag/health
 * Health check rápido de calidad RAG
 */
router.get('/rag/health', async (req, res) => {
  try {
    const metrics = await getProductionMetrics('24h');
    const { checkQualityGates } = require('../config/qualityGates');
    const gateResult = checkQualityGates({ summary: metrics });
    
    res.json({
      success: true,
      data: {
        healthy: gateResult.passed,
        time_range: '24h',
        total_queries: metrics.overview.total_queries,
        error_rate: metrics.overview.error_rate,
        fallback_rate: metrics.overview.fallback_rate,
        p95_latency_ms: metrics.latency.p95_ms,
        avg_top_score: metrics.retrieval.avg_top_score,
        gates: {
          passed: gateResult.passed,
          failures: gateResult.failures.length,
          warnings: gateResult.warnings.length
        }
      }
    });
  } catch (error) {
    console.error('❌ Error GET /api/metrics/rag/health:', error.message);
    res.status(500).json({ 
      error: 'internal_error', 
      message: 'Error health check RAG' 
    });
  }
});

module.exports = router;