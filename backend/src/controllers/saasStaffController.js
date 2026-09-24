// backend/src/controllers/saasStaffController.js
const saasStaffService = require('../services/saasStaffService');

/**
 * Emits a new staff invitation.
 * POST /api/saas/staff/invitations
 */
const createInvitation = async (req, res) => {
  try {
    const { tenant_id, establishment_id } = req.activeContext;
    const { email, role, relation_type } = req.body;

    const result = await saasStaffService.createInvitation(
      tenant_id,
      establishment_id,
      req.activeContext,
      { email, role, relation_type }
    );

    return res.status(201).json(result);
  } catch (error) {
    console.error('❌ Error in createInvitation:', error.message);
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      error: error.message,
      code: error.code || 'INTERNAL_ERROR',
    });
  }
};

/**
 * Lists pending staff invitations for the active establishment.
 * GET /api/saas/staff/invitations
 */
const listInvitations = async (req, res) => {
  try {
    const { tenant_id, establishment_id } = req.activeContext;
    const result = await saasStaffService.listInvitations(
      tenant_id,
      establishment_id,
      req.activeContext
    );

    return res.status(200).json(result);
  } catch (error) {
    console.error('❌ Error in listInvitations:', error.message);
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      error: error.message,
      code: error.code || 'INTERNAL_ERROR',
    });
  }
};

/**
 * Revokes a pending staff invitation.
 * DELETE /api/saas/staff/invitations/:id
 */
const revokeInvitation = async (req, res) => {
  try {
    const { tenant_id, establishment_id } = req.activeContext;
    const { id } = req.params;

    const result = await saasStaffService.revokeInvitation(
      tenant_id,
      establishment_id,
      req.activeContext,
      id
    );

    return res.status(200).json(result);
  } catch (error) {
    console.error('❌ Error in revokeInvitation:', error.message);
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      error: error.message,
      code: error.code || 'INTERNAL_ERROR',
    });
  }
};

/**
 * Resends a pending staff invitation.
 * POST /api/saas/staff/invitations/:id/resend
 */
const resendInvitation = async (req, res) => {
  try {
    const { tenant_id, establishment_id } = req.activeContext;
    const { id } = req.params;

    const result = await saasStaffService.resendInvitation(
      tenant_id,
      establishment_id,
      req.activeContext,
      id
    );

    return res.status(200).json(result);
  } catch (error) {
    console.error('❌ Error in resendInvitation:', error.message);
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      error: error.message,
      code: error.code || 'INTERNAL_ERROR',
    });
  }
};

/**
 * Public inspection of an invitation token.
 * GET /api/saas/public/invitations/:token
 */
const getInvitationByToken = async (req, res) => {
  try {
    const { token } = req.params;
    const result = await saasStaffService.getInvitationByToken(token);
    return res.status(200).json(result);
  } catch (error) {
    console.error('❌ Error in getInvitationByToken:', error.message);
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      error: error.message,
      code: error.code || 'INTERNAL_ERROR',
    });
  }
};

/**
 * Accepts a staff invitation (public or authenticated).
 * POST /api/saas/public/invitations/:token/accept
 */
const acceptInvitation = async (req, res) => {
  try {
    const { token } = req.params;
    const authUserId = req.user ? req.user.id : null;
    const { full_name, password } = req.body || {};

    const result = await saasStaffService.acceptInvitation(
      token,
      authUserId,
      { full_name, password }
    );

    return res.status(200).json(result);
  } catch (error) {
    console.error('❌ Error in acceptInvitation:', error.message);
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      error: error.message,
      code: error.code || 'INTERNAL_ERROR',
    });
  }
};

/**
 * Lists all staff members in the active establishment.
 * GET /api/saas/staff
 */
const listStaff = async (req, res) => {
  try {
    const { tenant_id, establishment_id } = req.activeContext;
    const result = await saasStaffService.listStaff(
      tenant_id,
      establishment_id,
      req.activeContext
    );

    return res.status(200).json(result);
  } catch (error) {
    console.error('❌ Error in listStaff:', error.message);
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      error: error.message,
      code: error.code || 'INTERNAL_ERROR',
    });
  }
};

/**
 * Updates a staff member's role.
 * PATCH /api/saas/staff/:membershipId/role
 */
const updateStaffRole = async (req, res) => {
  try {
    const { tenant_id, establishment_id } = req.activeContext;
    const { membershipId } = req.params;
    const { role } = req.body;

    const result = await saasStaffService.updateStaffRole(
      tenant_id,
      establishment_id,
      req.activeContext,
      membershipId,
      role
    );

    return res.status(200).json(result);
  } catch (error) {
    console.error('❌ Error in updateStaffRole:', error.message);
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      error: error.message,
      code: error.code || 'INTERNAL_ERROR',
    });
  }
};

/**
 * Updates a staff member's status (SUSPENDED / ACTIVE / REVOKED).
 * PATCH /api/saas/staff/:membershipId/status
 */
const updateStaffStatus = async (req, res) => {
  try {
    const { tenant_id, establishment_id } = req.activeContext;
    const { membershipId } = req.params;
    const { status } = req.body;

    const result = await saasStaffService.updateStaffStatus(
      tenant_id,
      establishment_id,
      req.activeContext,
      membershipId,
      status
    );

    return res.status(200).json(result);
  } catch (error) {
    console.error('❌ Error in updateStaffStatus:', error.message);
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      error: error.message,
      code: error.code || 'INTERNAL_ERROR',
    });
  }
};

/**
 * Updates a staff member's relation_type (Exclusively OWNER).
 * PATCH /api/saas/staff/:membershipId/relation-type
 */
const updateStaffRelationType = async (req, res) => {
  try {
    const { tenant_id, establishment_id } = req.activeContext;
    const { membershipId } = req.params;
    const { relation_type } = req.body;

    const result = await saasStaffService.updateStaffRelationType(
      tenant_id,
      establishment_id,
      req.activeContext,
      membershipId,
      relation_type
    );

    return res.status(200).json(result);
  } catch (error) {
    console.error('❌ Error in updateStaffRelationType:', error.message);
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      error: error.message,
      code: error.code || 'INTERNAL_ERROR',
    });
  }
};

module.exports = {
  createInvitation,
  listInvitations,
  revokeInvitation,
  resendInvitation,
  getInvitationByToken,
  acceptInvitation,
  listStaff,
  updateStaffRole,
  updateStaffStatus,
  updateStaffRelationType,
};
