const express = require('express');
const router = express.Router();
const { handleOrchestration } = require('../services/ai/orchestrator.service');

/**
 * @swagger
 * /api/ai/orchestrate:
 *   post:
 *     summary: Orquestador Multiagente IA Premium
 *     description: Recibe una tarea de reingeniería, la procesa con Hermes Agent-Nemotron y devuelve propuestas consultivas.
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               prompt:
 *                 type: string
 *                 example: "Rediseña la pantalla de resultados de escaneo de piel con estética premium"
 *     responses:
 *       200:
 *         description: Propuesta consultiva generada por el Agente Líder
 *       400:
 *         description: Falta el campo prompt
 *       500:
 *         description: Error interno del orquestador o API de NVIDIA
 */
router.post('/orchestrate', async (req, res) => {
  try {
    const { prompt } = req.body;

    // Validación defensiva
    if (!prompt || typeof prompt !== 'string' || prompt.trim().length === 0) {
      return res.status(400).json({ 
        error: 'Se requiere el campo "prompt" con una instrucción válida.' 
      });
    }

    // Llamar al servicio del orquestador
    const result = await handleOrchestration(prompt);

    // Devolver la respuesta estructurada
    res.json({
      success: true,
      timestamp: new Date().toISOString(),
      data: result
    });

  } catch (error) {
    console.error('❌ ERROR EN POST /api/ai/orchestrate:', error);
    
    // Manejo de errores específicos
    if (error.message.includes('NVIDIA_API_KEY')) {
      return res.status(503).json({ 
        error: 'Servicio de IA no configurado. Contacte al administrador.' 
      });
    }

    res.status(500).json({ 
      error: 'Error interno al procesar la solicitud del orquestador.',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Ruta de prueba GET para verificar que el endpoint está activo
router.get('/status', (req, res) => {
  res.json({
    service: 'AI Orchestrator Multi-Agent',
    status: 'active',
    model: 'Hermes Agent-Nemotron 3 550 Ultra',
    mode: 'consultative (Human-in-the-Loop)',
    timestamp: new Date().toISOString()
  });
});

module.exports = router;