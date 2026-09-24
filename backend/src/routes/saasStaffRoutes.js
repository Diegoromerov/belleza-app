// backend/src/routes/saasStaffRoutes.js
const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');
const { getJwtSecret, toApiRole } = require('../config/jwt');
const { authMiddleware } = require('../middleware/auth');
const { activeContextMiddleware } = require('../middleware/activeContextMiddleware');
const saasStaffController = require('../controllers/saasStaffController');

/**
 * Optional Auth Middleware for Public Invitation Acceptance.
 * If Bearer token is provided, validates and sets req.user.
 * If no token is provided, proceeds with req.user = null.
 */
const optionalAuthMiddleware = async (req, res, next) => {
  const authHeader = req.header('Authorization') || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7).trim() : null;

  if (!token) {
    req.user = null;
    return next();
  }

  try {
    const verified = jwt.verify(token, getJwtSecret());
    const userRes = await pool.query('SELECT rol FROM usuarios WHERE id = $1', [verified.id]);
    if (userRes.rows.length > 0) {
      req.user = {
        id: verified.id,
        email: verified.email,
        role: toApiRole(userRes.rows[0].rol),
        token,
      };
    } else {
      req.user = null;
    }
    next();
  } catch (err) {
    // If invalid token provided, reject with 401
    return res.status(401).json({ error: 'Token inválido o expirado.', code: 'INVALID_TOKEN' });
  }
};

// ==========================================
// 1. PUBLIC INVITATION ENDPOINTS
// Base prefix: /api/saas/public/invitations
// ==========================================
const publicRouter = express.Router();

// GET /api/saas/public/invitations/:token — Validar token de invitación
publicRouter.get('/:token', saasStaffController.getInvitationByToken);

// POST /api/saas/public/invitations/:token/accept — Aceptar invitación (Público / Autenticado)
publicRouter.post('/:token/accept', optionalAuthMiddleware, saasStaffController.acceptInvitation);

// ==========================================
// 2. PROTECTED STAFF & INVITATION ENDPOINTS
// Base prefix: /api/saas/staff
// ==========================================
const staffRouter = express.Router();

// POST /api/saas/staff/invitations — Emitir nueva invitación
staffRouter.post('/invitations', authMiddleware, activeContextMiddleware, saasStaffController.createInvitation);

// GET /api/saas/staff/invitations — Listar invitaciones pendientes de la sede
staffRouter.get('/invitations', authMiddleware, activeContextMiddleware, saasStaffController.listInvitations);

// DELETE /api/saas/staff/invitations/:id — Revocar invitación
staffRouter.delete('/invitations/:id', authMiddleware, activeContextMiddleware, saasStaffController.revokeInvitation);

// POST /api/saas/staff/invitations/:id/resend — Reenviar invitación (+7 días)
staffRouter.post('/invitations/:id/resend', authMiddleware, activeContextMiddleware, saasStaffController.resendInvitation);

// GET /api/saas/staff — Listar personal de la sede
staffRouter.get('/', authMiddleware, activeContextMiddleware, saasStaffController.listStaff);

// PATCH /api/saas/staff/:membershipId/role — Modificar rol contextual
staffRouter.patch('/:membershipId/role', authMiddleware, activeContextMiddleware, saasStaffController.updateStaffRole);

// PATCH /api/saas/staff/:membershipId/status — Modificar estado (SUSPENDED / ACTIVE / REVOKED)
staffRouter.patch('/:membershipId/status', authMiddleware, activeContextMiddleware, saasStaffController.updateStaffStatus);

// PATCH /api/saas/staff/:membershipId/relation-type — Modificar relation_type (Exclusivo OWNER)
staffRouter.patch('/:membershipId/relation-type', authMiddleware, activeContextMiddleware, saasStaffController.updateStaffRelationType);

module.exports = {
  staffRouter,
  publicRouter,
};
