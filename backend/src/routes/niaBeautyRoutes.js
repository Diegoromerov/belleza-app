const express = require('express');
const router = express.Router();
const { processBiometricScan } = require('../services/aiOrchestrator');
const pool = require('../config/db'); // Asumiendo que tienes tu config de PG aquí

router.post('/scan', async (req, res) => {
  try {
    const { image_base64, user_id } = req.body;

    if (!image_base64) {
      return res.status(400).json({ error: 'Se requiere una imagen para el análisis.' });
    }

    // 1. Llamar al Worker de Python
    const biometricData = await processBiometricScan(image_base64);

    // 2. Guardar resultados en PostgreSQL (Tabla: user_biometrics)
    // Nota: Asegúrate de crear esta tabla en tu DB si no existe
    const query = `
      INSERT INTO user_biometrics (user_id, subtono, estacion, paleta, hidratacion, sebo, mensaje_aura)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *;
    `;
    
    const values = [
      user_id || 'guest', // Fallback si no hay usuario logueado
      biometricData.subtono,
      biometricData.estacion,
      JSON.stringify(biometricData.paleta),
      biometricData.hidratacion,
      biometricData.sebo,
      biometricData.mensaje_aura
    ];

    const result = await pool.query(query, values);

    // 3. Retornar éxito a Flutter
    res.status(200).json({
      message: 'Análisis completado exitosamente',
      data: result.rows[0]
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
