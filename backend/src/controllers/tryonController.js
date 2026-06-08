// backend/src/controllers/tryonController.js
const { pool } = require('../config/db');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { findCachedJob, enqueueTryonJob } = require('../services/queueService');

// POST /api/nail-tryon → Iniciar trabajo de prueba virtual
exports.createTryonJob = async (req, res) => {
  try {
    const userId = req.user.id;
    const { color_hex, shape, finish, decoration_style } = req.body;

    if (!req.file) {
      return res.status(400).json({ error: 'Se requiere una imagen de la mano o uñas.' });
    }

    // Calcular el hash MD5 de la imagen para control de caché
    const fileBuffer = fs.readFileSync(req.file.path);
    const imageHash = crypto.createHash('md5').update(fileBuffer).digest('hex');

    // Buscar si ya existe el resultado en caché
    const cachedJob = await findCachedJob(imageHash, color_hex, shape, finish, decoration_style);
    
    if (cachedJob) {
      console.log(`🎯 Caché hit para prueba virtual. Retornando preview de trabajo previo.`);
      
      const jobId = crypto.randomUUID();
      const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);
      
      const insertCachedQuery = `
        INSERT INTO nail_tryon_jobs (id, user_id, status, color_hex, shape, finish, decoration_style, original_image_url, preview_url, image_hash, expires_at)
        VALUES ($1, $2, 'completed', $3, $4, $5, $6, $7, $8, $9, $10)
        RETURNING id, status, preview_url;
      `;
      
      const host = req.get('host');
      const originalImageUrl = `${req.protocol}://${host}/uploads/${req.file.filename}`;
      
      const result = await pool.query(insertCachedQuery, [
        jobId,
        userId,
        color_hex || null,
        shape || null,
        finish || null,
        decoration_style || null,
        originalImageUrl,
        cachedJob.preview_url,
        imageHash,
        expiresAt
      ]);
      
      return res.status(201).json({
        success: true,
        message: 'Resultado recuperado de la caché.',
        job: result.rows[0]
      });
    }

    // Si no hay caché, crear un nuevo trabajo pendiente
    const jobId = crypto.randomUUID();
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);
    const host = req.get('host');
    const originalImageUrl = `${req.protocol}://${host}/uploads/${req.file.filename}`;

    const insertQuery = `
      INSERT INTO nail_tryon_jobs (id, user_id, status, color_hex, shape, finish, decoration_style, original_image_url, image_hash, expires_at)
      VALUES ($1, $2, 'pending', $3, $4, $5, $6, $7, $8, $9)
      RETURNING id, status;
    `;

    const result = await pool.query(insertQuery, [
      jobId,
      userId,
      color_hex || null,
      shape || null,
      finish || null,
      decoration_style || null,
      originalImageUrl,
      imageHash,
      expiresAt
    ]);

    // Encolar trabajo en Redis de forma asíncrona
    await enqueueTryonJob(jobId, userId, {
      color_hex,
      shape,
      finish,
      decoration_style
    }, originalImageUrl, imageHash);

    res.status(201).json({
      success: true,
      message: 'Trabajo de prueba virtual creado y encolado.',
      job: result.rows[0]
    });

  } catch (error) {
    console.error('❌ ERROR EN POST /api/nail-tryon:', error);
    res.status(500).json({ error: 'Error al crear la prueba virtual de uñas.' });
  }
};

// GET /api/nail-tryon/:id → Obtener estado del trabajo
exports.getTryonJob = async (req, res) => {
  try {
    const { id } = req.params;
    const query = `
      SELECT id, status, color_hex, shape, finish, decoration_style, original_image_url, preview_url, error_message, created_at
      FROM nail_tryon_jobs
      WHERE id = $1 AND user_id = $2;
    `;
    const result = await pool.query(query, [id, req.user.id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Trabajo no encontrado.' });
    }
    
    res.json({ success: true, job: result.rows[0] });
  } catch (error) {
    console.error('❌ ERROR EN GET /api/nail-tryon/:id:', error);
    res.status(500).json({ error: 'Error al obtener estado de la prueba virtual.' });
  }
};

// POST /api/nail-tryon/:id/complete → Reportar terminación de trabajo
exports.completeTryonJob = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, preview_url, error_message } = req.body;

    if (!['completed', 'failed'].includes(status)) {
      return res.status(400).json({ error: 'Estado de finalización inválido.' });
    }

    const query = `
      UPDATE nail_tryon_jobs
      SET status = $1, preview_url = $2, error_message = $3
      WHERE id = $4
      RETURNING id, user_id, status, preview_url, error_message;
    `;
    const result = await pool.query(query, [status, preview_url || null, error_message || null, id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Trabajo no encontrado para actualización.' });
    }

    const updatedJob = result.rows[0];
    console.log(`📢 Trabajo de prueba virtual actualizado por IA Worker: ${id} (${status})`);

    // Notificar al cliente vía WebSocket usando helper registrado en app
    const notifyUserJobUpdate = req.app.get('notifyUserJobUpdate');
    if (notifyUserJobUpdate) {
      notifyUserJobUpdate(updatedJob.user_id, updatedJob);
    }

    res.json({ success: true, message: 'Trabajo actualizado y notificado.' });
  } catch (error) {
    console.error('❌ ERROR EN POST /api/nail-tryon/:id/complete:', error);
    res.status(500).json({ error: 'Error al reportar finalización del trabajo.' });
  }
};
