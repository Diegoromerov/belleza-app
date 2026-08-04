// backend/src/routes/academyRoutes.js
const express = require('express');
const router = express.Router();
const { pool } = require('../config/db');
const { authMiddleware } = require('../middleware/auth');

/**
 * GET /api/academy/courses
 * Lista todos los cursos de capacitación con progreso del prestador.
 */
router.get('/courses', authMiddleware, async (req, res) => {
  try {
    const { rows: courses } = await pool.query(`
      SELECT c.*,
        (SELECT COUNT(*) FROM academy_lessons l
         JOIN academy_modules m ON l.module_id = m.id
         WHERE m.course_id = c.id) as total_lessons,
        (SELECT COUNT(*) FROM academy_progress p
         JOIN academy_lessons l ON p.lesson_id = l.id
         JOIN academy_modules m ON l.module_id = m.id
         WHERE m.course_id = c.id AND p.provider_id = $1) as completed_lessons,
        (SELECT COUNT(*) FROM academy_quizzes q WHERE q.course_id = c.id) as total_quiz_questions,
        EXISTS(SELECT 1 FROM academy_certificates cert WHERE cert.course_id = c.id AND cert.provider_id = $1) as has_certificate
      FROM academy_courses c
      ORDER BY c.created_at ASC
    `, [req.user.id]);

    res.json(courses);
  } catch (err) {
    console.error('Error al obtener cursos de la academia:', err);
    res.status(500).json({ error: 'Error al obtener cursos.' });
  }
});

/**
 * GET /api/academy/courses/:id
 * Detalle de un curso con sus módulos, lecciones y estado de progreso.
 */
router.get('/courses/:id', authMiddleware, async (req, res) => {
  const courseId = req.params.id;
  try {
    const courseRes = await pool.query('SELECT * FROM academy_courses WHERE id = $1', [courseId]);
    if (!courseRes.rows.length) {
      return res.status(404).json({ error: 'Curso no encontrado.' });
    }

    const modulesRes = await pool.query(`
      SELECT m.id as module_id, m.title as module_title, m.sort_order as module_order
      FROM academy_modules m
      WHERE m.course_id = $1
      ORDER BY m.sort_order ASC
    `, [courseId]);

    const lessonsRes = await pool.query(`
      SELECT l.id as lesson_id, l.module_id, l.title as lesson_title, l.video_url, l.content_text, l.sort_order as lesson_order,
             (p.completed IS NOT NULL AND p.completed = true) as lesson_completed
      FROM academy_lessons l
      JOIN academy_modules m ON l.module_id = m.id
      LEFT JOIN academy_progress p ON p.lesson_id = l.id AND p.provider_id = $2
      WHERE m.course_id = $1
      ORDER BY l.sort_order ASC
    `, [courseId, req.user.id]);

    const hasCertificateRes = await pool.query(
      'SELECT 1 FROM academy_certificates WHERE provider_id = $1 AND course_id = $2',
      [req.user.id, courseId]
    );

    // Organizar lecciones por módulo
    const modules = modulesRes.rows.map(m => {
      return {
        id: m.module_id,
        title: m.module_title,
        order: m.module_order,
        lessons: lessonsRes.rows.filter(l => l.module_id === m.module_id)
      };
    });

    res.json({
      course: courseRes.rows[0],
      hasCertificate: hasCertificateRes.rows.length > 0,
      modules
    });
  } catch (err) {
    console.error('Error al obtener detalle del curso:', err);
    res.status(500).json({ error: 'Error al obtener detalle del curso.' });
  }
});

/**
 * POST /api/academy/lessons/:id/complete
 * Marca una lección como completada por el prestador.
 */
router.post('/lessons/:id/complete', authMiddleware, async (req, res) => {
  const lessonId = req.params.id;
  try {
    await pool.query(`
      INSERT INTO academy_progress (provider_id, lesson_id, completed, completed_at)
      VALUES ($1, $2, true, NOW())
      ON CONFLICT (provider_id, lesson_id) 
      DO UPDATE SET completed = true, completed_at = NOW()
    `, [req.user.id, lessonId]);

    res.json({ ok: true, mensaje: 'Lección marcada como completada.' });
  } catch (err) {
    console.error('Error al completar lección:', err);
    res.status(500).json({ error: 'Error al completar lección.' });
  }
});

/**
 * POST /api/academy/consent
 * Registra o actualiza consentimiento Habeas Data Ley 1581
 */
router.post('/consent', authMiddleware, async (req, res) => {
  try {
    const { aceptado } = req.body;
    const result = await pool.query(`
      INSERT INTO academy_consentimientos (provider_id, aceptado, fecha_aceptacion, fecha_revocacion)
      VALUES ($1, $2, NOW(), NULL)
      ON CONFLICT (provider_id)
      DO UPDATE SET aceptado = $2, fecha_aceptacion = NOW(), fecha_revocacion = NULL
      RETURNING id, aceptado
    `, [req.user.id, aceptado === true]);
    
    res.json({ ok: true, consentId: result.rows[0].id, aceptado: result.rows[0].aceptado });
  } catch (err) {
    console.error('Error al registrar consentimiento:', err);
    res.status(500).json({ error: 'Error al registrar consentimiento.' });
  }
});

/**
 * GET /api/academy/consent/status
 * Verifica el estado actual del consentimiento biométrico
 */
router.get('/consent/status', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query('SELECT id, aceptado FROM academy_consentimientos WHERE provider_id = $1', [req.user.id]);
    if (result.rows.length === 0) {
      return res.json({ hasConsent: false, aceptado: false });
    }
    res.json({ hasConsent: true, consentId: result.rows[0].id, aceptado: result.rows[0].aceptado });
  } catch (err) {
    console.error('Error al obtener estado del consentimiento:', err);
    res.status(500).json({ error: 'Error al consultar consentimiento.' });
  }
});

/**
 * POST /api/academy/worksheets/submit
 * Envía respuestas del taller práctico e imágenes de evidencia
 */
router.post('/worksheets/submit', authMiddleware, async (req, res) => {
  try {
    const { lessonId, respuestas, evidenciaFotoUrl, consentId } = req.body;
    
    // Validar existencia de consentimiento activo si hay imágenes biométricas
    if (evidenciaFotoUrl) {
      const consentCheck = await pool.query('SELECT 1 FROM academy_consentimientos WHERE id = $1 AND provider_id = $2 AND aceptado = true', [consentId, req.user.id]);
      if (consentCheck.rows.length === 0) {
        return res.status(400).json({ error: 'Debe aceptar y firmar el consentimiento de Habeas Data antes de subir fotografías.' });
      }
    }

    await pool.query(`
      INSERT INTO academy_worksheet_submissions (provider_id, lesson_id, respuestas_texto, evidencia_foto_url, consentimiento_id, enviado_at)
      VALUES ($1, $2, $3::jsonb, $4, $5, NOW())
      ON CONFLICT (provider_id, lesson_id)
      DO UPDATE SET respuestas_texto = $3::jsonb, evidencia_foto_url = $4, consentimiento_id = $5, enviado_at = NOW()
    `, [req.user.id, lessonId, JSON.stringify(respuestas || {}), evidenciaFotoUrl || null, consentId || null]);

    res.json({ ok: true, mensaje: 'Respuestas del taller enviadas con éxito.' });
  } catch (err) {
    console.error('Error al subir worksheet:', err);
    res.status(500).json({ error: 'Error al enviar el taller.' });
  }
});

/**
 * POST /api/academy/ai-discrepancy/log
 * Guarda discrepancias de diagnóstico entre el motor de IA y el estilista (Módulo 6)
 */
router.post('/ai-discrepancy/log', authMiddleware, async (req, res) => {
  try {
    const { leccionId, diagnosticoIA, criterioHumano, comentarios } = req.body;
    
    await pool.query(`
      INSERT INTO academy_ai_discrepancy_log (provider_id, leccion_id, diagnostico_ia, criterio_humano, comentarios, created_at)
      VALUES ($1, $2, $3::jsonb, $4::jsonb, $5, NOW())
    `, [req.user.id, leccionId, JSON.stringify(diagnosticoIA), JSON.stringify(criterioHumano), comentarios || '']);

    res.json({ ok: true, mensaje: 'Discrepancia registrada para reentrenamiento de IA.' });
  } catch (err) {
    console.error('Error al registrar logs de discrepancia IA:', err);
    res.status(500).json({ error: 'Error interno de calibración de IA.' });
  }
});

/**
 * GET /api/academy/courses/:id/quiz
 * Obtiene el cuestionario evaluativo de un curso.
 */
router.get('/courses/:id/quiz', authMiddleware, async (req, res) => {
  const courseId = req.params.id;
  try {
    const { rows: quizzes } = await pool.query(
      'SELECT id, question, options FROM academy_quizzes WHERE course_id = $1',
      [courseId]
    );
    res.json(quizzes);
  } catch (err) {
    console.error('Error al obtener examen:', err);
    res.status(500).json({ error: 'Error al obtener examen.' });
  }
});

/**
 * POST /api/academy/courses/:id/submit-quiz
 * Califica el cuestionario del curso y desbloquea el certificado/insignia.
 */
router.post('/courses/:id/submit-quiz', authMiddleware, async (req, res) => {
  const courseId = req.params.id;
  const { answers } = req.body; // { "quiz_id_1": index, "quiz_id_2": index }

  if (!answers || typeof answers !== 'object') {
    return res.status(400).json({ error: 'Formato de respuestas incorrecto.' });
  }

  try {
    const { rows: quizzes } = await pool.query(
      'SELECT id, correct_index FROM academy_quizzes WHERE course_id = $1',
      [courseId]
    );

    if (!quizzes.length) {
      return res.status(404).json({ error: 'No hay examen registrado para este curso.' });
    }

    let score = 0;
    const total = quizzes.length;

    for (const quiz of quizzes) {
      const userAnswer = answers[quiz.id];
      if (userAnswer !== undefined && parseInt(userAnswer) === quiz.correct_index) {
        score++;
      }
    }

    const passPct = parseInt(process.env.QUIZ_PASS_PCT) || 80;
    const correctPct = (score / total) * 100;
    const approved = correctPct >= passPct;

    if (approved) {
      await pool.query(`
        INSERT INTO academy_certificates (provider_id, course_id, obtained_at)
        VALUES ($1, $2, NOW())
        ON CONFLICT (provider_id, course_id) DO NOTHING
      `, [req.user.id, courseId]);

      const courseRes = await pool.query('SELECT badge_name FROM academy_courses WHERE id = $1', [courseId]);

      res.json({
        approved: true,
        score,
        total,
        badgeName: courseRes.rows[0]?.badge_name || 'Certificado de Aprobación',
        mensaje: `¡Excelente! Aprobaste con ${score} de ${total} aciertos (${correctPct.toFixed(0)}%). Insignia de certificación obtenida.`
      });
    } else {
      res.json({
        approved: false,
        score,
        total,
        mensaje: `No has aprobado. Obtuviste ${score} de ${total} aciertos (${correctPct.toFixed(0)}%). El mínimo requerido para aprobar es ${passPct}%.`
      });
    }
  } catch (err) {
    console.error('Error al calificar examen:', err);
    res.status(500).json({ error: 'Error al procesar calificación.' });
  }
});

module.exports = router;
