/**
 * GLOWAPP BUSINESS ROUTES
 * Express router for GlowApp Business Engine REST API (/api/v1/business).
 */

const express = require('express');
const router = express.Router();
const businessController = require('../controllers/businessController');
const { authMiddleware, adminMiddleware } = require('../middleware/auth');
<<<<<<< HEAD
const subirEvidencia = require('../middleware/evidenceUpload');
=======
const membershipMiddleware = require('../middleware/membership.middleware');
const { requirePermission, RESOURCES, ACTIONS } = require('../middleware/authorization.middleware');
>>>>>>> origin/main

// 1. Ruta Pública de Catálogo (Sin autenticación requerida para descubrimiento)
router.get('/verticals', businessController.getVerticals);

// 2. Rutas Privadas del Negocio (Protegidas por Cadena SaaS: Auth -> Membership -> RBAC)
router.post(
  '/diagnostic',
  authMiddleware,
  membershipMiddleware,
  requirePermission(RESOURCES.BUSINESS_PROFILE, ACTIONS.UPDATE),
  businessController.runDiagnostic
);

<<<<<<< HEAD
// Tasks & Guided Workflows (Protected by authMiddleware)
router.get('/tasks', authMiddleware, businessController.getTasks);
router.post('/tasks/:id/advance', authMiddleware, businessController.advanceTask);
// La evidencia se sube como archivo real (multipart, campo "file"): el servidor
// genera la ruta. Ver src/middleware/evidenceUpload.js
router.post('/tasks/:id/evidence', authMiddleware, subirEvidencia, businessController.submitEvidence);
=======
router.get(
  '/summary',
  authMiddleware,
  membershipMiddleware,
  requirePermission(RESOURCES.BUSINESS_PROFILE, ACTIONS.READ),
  businessController.getSummary
);
>>>>>>> origin/main

// Tareas y Flujos Guiados
router.get(
  '/tasks',
  authMiddleware,
  membershipMiddleware,
  requirePermission(RESOURCES.BUSINESS_PROFILE, ACTIONS.READ),
  businessController.getTasks
);

router.post(
  '/tasks/:id/advance',
  authMiddleware,
  membershipMiddleware,
  requirePermission(RESOURCES.BUSINESS_PROFILE, ACTIONS.UPDATE),
  businessController.advanceTask
);

router.post(
  '/tasks/:id/evidence',
  authMiddleware,
  membershipMiddleware,
  requirePermission(RESOURCES.BUSINESS_PROFILE, ACTIONS.UPDATE),
  businessController.submitEvidence
);

// Generador Documental y Firmas
router.get(
  '/templates',
  authMiddleware,
  membershipMiddleware,
  requirePermission(RESOURCES.SETTINGS, ACTIONS.READ),
  businessController.getTemplates
);

router.post(
  '/documents/generate',
  authMiddleware,
  membershipMiddleware,
  requirePermission(RESOURCES.BUSINESS_PROFILE, ACTIONS.CREATE),
  businessController.generateDocument
);

router.get(
  '/documents/:id/download',
  authMiddleware,
  membershipMiddleware,
  requirePermission(RESOURCES.BUSINESS_PROFILE, ACTIONS.READ),
  businessController.downloadDocument
);

router.post(
  '/documents/:id/request-signature',
  authMiddleware,
  membershipMiddleware,
  requirePermission(RESOURCES.BUSINESS_PROFILE, ACTIONS.UPDATE),
  businessController.requestDocumentSignature
);

router.post(
  '/documents/:id/sign',
  authMiddleware,
  membershipMiddleware,
  requirePermission(RESOURCES.BUSINESS_PROFILE, ACTIONS.UPDATE),
  businessController.signDocument
);

router.post(
  '/documents/:id/version',
  authMiddleware,
  membershipMiddleware,
  requirePermission(RESOURCES.BUSINESS_PROFILE, ACTIONS.UPDATE),
  businessController.createDocumentVersion
);

router.get(
  '/documents/:id/audit',
  authMiddleware,
  membershipMiddleware,
  requirePermission(RESOURCES.BUSINESS_PROFILE, ACTIONS.READ),
  businessController.getDocumentAuditTrail
);

// 3. Rutas de Administración del Sistema (Protegidas por Admin Middleware)
router.get('/admin/queue', authMiddleware, adminMiddleware, businessController.getAdminQueue);
router.put('/admin/evidence/:id', authMiddleware, adminMiddleware, businessController.reviewEvidence);

module.exports = router;
