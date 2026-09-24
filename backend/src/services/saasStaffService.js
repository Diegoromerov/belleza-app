// backend/src/services/saasStaffService.js
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const { pool } = require('../config/db');

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const VALID_ROLES = ['OWNER', 'MANAGER', 'PROFESSIONAL', 'RECEPTIONIST'];
const VALID_RELATION_TYPES = ['OWNER_PARTNER', 'STAFF_EMPLOYEE', 'INDEPENDENT_PROVIDER'];
const VALID_STATUSES = ['INVITED', 'ACTIVE', 'SUSPENDED', 'REVOKED'];

/**
 * Creates a new staff invitation with a cryptographic token.
 */
const createInvitation = async (tenantId, establishmentId, activeContext, { email, role, relation_type }) => {
  if (!tenantId || !establishmentId || !activeContext) {
    const err = new Error('ACTIVE_CONTEXT_REQUIRED');
    err.code = 'ACTIVE_CONTEXT_REQUIRED';
    err.statusCode = 400;
    throw err;
  }

  // RBAC Authorization
  const actorRole = activeContext.role;
  if (actorRole === 'OWNER') {
    // Owner can invite any valid role
  } else if (actorRole === 'MANAGER') {
    if (role === 'OWNER' || role === 'MANAGER') {
      const err = new Error('UNAUTHORIZED_ROLE');
      err.code = 'UNAUTHORIZED_ROLE';
      err.statusCode = 403;
      throw err;
    }
  } else {
    const err = new Error('UNAUTHORIZED_ROLE');
    err.code = 'UNAUTHORIZED_ROLE';
    err.statusCode = 403;
    throw err;
  }

  // Input Validation
  if (!email || typeof email !== 'string' || !EMAIL_REGEX.test(email.trim())) {
    const err = new Error('INVALID_EMAIL');
    err.code = 'INVALID_EMAIL';
    err.statusCode = 400;
    throw err;
  }

  const cleanEmail = email.trim().toLowerCase();
  const cleanRole = role ? role.toUpperCase() : 'PROFESSIONAL';
  const cleanRelation = relation_type ? relation_type.toUpperCase() : 'STAFF_EMPLOYEE';

  if (!VALID_ROLES.includes(cleanRole)) {
    const err = new Error('INVALID_ROLE');
    err.code = 'INVALID_ROLE';
    err.statusCode = 400;
    throw err;
  }

  if (!VALID_RELATION_TYPES.includes(cleanRelation)) {
    const err = new Error('INVALID_RELATION_TYPE');
    err.code = 'INVALID_RELATION_TYPE';
    err.statusCode = 400;
    throw err;
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    // 1. Check if user is already an ACTIVE member of this establishment
    const existingMemberQuery = `
      SELECT m.id 
      FROM memberships m
      INNER JOIN usuarios u ON u.id = m.user_id AND u.tenant_id = m.tenant_id
      WHERE m.establishment_id = $1 
        AND m.tenant_id = $2 
        AND LOWER(u.email) = $3 
        AND m.status = 'ACTIVE';
    `;
    const memberRes = await client.query(existingMemberQuery, [establishmentId, tenantId, cleanEmail]);
    if (memberRes.rows.length > 0) {
      await client.query('ROLLBACK');
      const err = new Error('USER_ALREADY_MEMBER');
      err.code = 'USER_ALREADY_MEMBER';
      err.statusCode = 409;
      throw err;
    }

    // 2. Check if there is already a PENDING unexpired invitation
    const existingInvQuery = `
      SELECT id 
      FROM staff_invitations 
      WHERE establishment_id = $1 
        AND tenant_id = $2 
        AND LOWER(email) = $3 
        AND status = 'PENDING' 
        AND expires_at > CURRENT_TIMESTAMP;
    `;
    const invRes = await client.query(existingInvQuery, [establishmentId, tenantId, cleanEmail]);
    if (invRes.rows.length > 0) {
      await client.query('ROLLBACK');
      const err = new Error('INVITATION_ALREADY_PENDING');
      err.code = 'INVITATION_ALREADY_PENDING';
      err.statusCode = 409;
      throw err;
    }

    // 3. Generate Cryptographic Token & Hash
    const rawToken = crypto.randomBytes(32).toString('hex');
    const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

    // 4. Insert Invitation
    const insertQuery = `
      INSERT INTO staff_invitations (
        tenant_id, establishment_id, email, role, relation_type,
        invited_by_membership_id, token_hash, status, expires_at
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, 'PENDING', $8
      ) RETURNING id, tenant_id, establishment_id, email, role, relation_type,
                  invited_by_membership_id, status, expires_at, created_at, updated_at;
    `;

    const insertRes = await client.query(insertQuery, [
      tenantId,
      establishmentId,
      cleanEmail,
      cleanRole,
      cleanRelation,
      activeContext.active_membership_id,
      tokenHash,
      expiresAt.toISOString(),
    ]);

    await client.query('COMMIT');

    const inv = insertRes.rows[0];
    return {
      invitation: {
        id: inv.id,
        tenant_id: inv.tenant_id,
        establishment_id: inv.establishment_id,
        email: inv.email,
        role: inv.role,
        relation_type: inv.relation_type,
        invited_by_membership_id: inv.invited_by_membership_id,
        status: inv.status,
        expires_at: inv.expires_at instanceof Date ? inv.expires_at.toISOString() : inv.expires_at,
        created_at: inv.created_at instanceof Date ? inv.created_at.toISOString() : inv.created_at,
        updated_at: inv.updated_at instanceof Date ? inv.updated_at.toISOString() : inv.updated_at,
      },
      raw_token: rawToken,
    };
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch (_) {}
    throw err;
  } finally {
    client.release();
  }
};

/**
 * Lists active pending invitations for the establishment.
 */
const listInvitations = async (tenantId, establishmentId, activeContext) => {
  if (!tenantId || !establishmentId || !activeContext) {
    const err = new Error('ACTIVE_CONTEXT_REQUIRED');
    err.code = 'ACTIVE_CONTEXT_REQUIRED';
    err.statusCode = 400;
    throw err;
  }

  const actorRole = activeContext.role;
  if (actorRole !== 'OWNER' && actorRole !== 'MANAGER') {
    const err = new Error('UNAUTHORIZED_ROLE');
    err.code = 'UNAUTHORIZED_ROLE';
    err.statusCode = 403;
    throw err;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const query = `
      SELECT 
        si.id,
        si.tenant_id,
        si.establishment_id,
        si.email,
        si.role,
        si.relation_type,
        si.invited_by_membership_id,
        u.nombre AS inviter_name,
        si.status,
        si.expires_at,
        si.created_at,
        si.updated_at
      FROM staff_invitations si
      INNER JOIN memberships m ON m.id = si.invited_by_membership_id AND m.tenant_id = si.tenant_id
      INNER JOIN usuarios u ON u.id = m.user_id AND u.tenant_id = m.tenant_id
      WHERE si.establishment_id = $1 
        AND si.tenant_id = $2 
        AND si.status = 'PENDING'
        AND si.expires_at > CURRENT_TIMESTAMP
      ORDER BY si.created_at DESC;
    `;

    const result = await client.query(query, [establishmentId, tenantId]);
    await client.query('COMMIT');

    return {
      invitations: result.rows.map((row) => ({
        id: row.id,
        tenant_id: row.tenant_id,
        establishment_id: row.establishment_id,
        email: row.email,
        role: row.role,
        relation_type: row.relation_type,
        invited_by_membership_id: row.invited_by_membership_id,
        inviter_name: row.inviter_name,
        status: row.status,
        expires_at: row.expires_at instanceof Date ? row.expires_at.toISOString() : row.expires_at,
        created_at: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
        updated_at: row.updated_at instanceof Date ? row.updated_at.toISOString() : row.updated_at,
      })),
    };
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch (_) {}
    throw err;
  } finally {
    client.release();
  }
};

/**
 * Revokes a pending invitation.
 */
const revokeInvitation = async (tenantId, establishmentId, activeContext, invitationId) => {
  if (!tenantId || !establishmentId || !activeContext || !invitationId) {
    const err = new Error('ACTIVE_CONTEXT_REQUIRED');
    err.code = 'ACTIVE_CONTEXT_REQUIRED';
    err.statusCode = 400;
    throw err;
  }

  const actorRole = activeContext.role;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const selectQuery = `
      SELECT id, role, status 
      FROM staff_invitations 
      WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3
      FOR UPDATE;
    `;
    const res = await client.query(selectQuery, [invitationId, establishmentId, tenantId]);

    if (res.rows.length === 0) {
      await client.query('ROLLBACK');
      const err = new Error('INVITATION_NOT_FOUND');
      err.code = 'INVITATION_NOT_FOUND';
      err.statusCode = 404;
      throw err;
    }

    const inv = res.rows[0];

    // RBAC: Manager can only revoke operative invitations
    if (actorRole === 'MANAGER') {
      if (inv.role === 'OWNER' || inv.role === 'MANAGER') {
        await client.query('ROLLBACK');
        const err = new Error('UNAUTHORIZED_ROLE');
        err.code = 'UNAUTHORIZED_ROLE';
        err.statusCode = 403;
        throw err;
      }
    } else if (actorRole !== 'OWNER') {
      await client.query('ROLLBACK');
      const err = new Error('UNAUTHORIZED_ROLE');
      err.code = 'UNAUTHORIZED_ROLE';
      err.statusCode = 403;
      throw err;
    }

    if (inv.status !== 'PENDING') {
      await client.query('ROLLBACK');
      const err = new Error('INVITATION_NOT_PENDING');
      err.code = 'INVITATION_NOT_PENDING';
      err.statusCode = 422;
      throw err;
    }

    const updateQuery = `
      UPDATE staff_invitations 
      SET status = 'REVOKED', updated_at = CURRENT_TIMESTAMP 
      WHERE id = $1;
    `;
    await client.query(updateQuery, [invitationId]);
    await client.query('COMMIT');

    return { success: true, revoked_invitation_id: invitationId };
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch (_) {}
    throw err;
  } finally {
    client.release();
  }
};

/**
 * Resends a pending invitation (renews token and expiration).
 */
const resendInvitation = async (tenantId, establishmentId, activeContext, invitationId) => {
  if (!tenantId || !establishmentId || !activeContext || !invitationId) {
    const err = new Error('ACTIVE_CONTEXT_REQUIRED');
    err.code = 'ACTIVE_CONTEXT_REQUIRED';
    err.statusCode = 400;
    throw err;
  }

  const actorRole = activeContext.role;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const selectQuery = `
      SELECT id, email, role, relation_type, status 
      FROM staff_invitations 
      WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3
      FOR UPDATE;
    `;
    const res = await client.query(selectQuery, [invitationId, establishmentId, tenantId]);

    if (res.rows.length === 0) {
      await client.query('ROLLBACK');
      const err = new Error('INVITATION_NOT_FOUND');
      err.code = 'INVITATION_NOT_FOUND';
      err.statusCode = 404;
      throw err;
    }

    const inv = res.rows[0];

    // RBAC: Manager can only resend operative invitations
    if (actorRole === 'MANAGER') {
      if (inv.role === 'OWNER' || inv.role === 'MANAGER') {
        await client.query('ROLLBACK');
        const err = new Error('UNAUTHORIZED_ROLE');
        err.code = 'UNAUTHORIZED_ROLE';
        err.statusCode = 403;
        throw err;
      }
    } else if (actorRole !== 'OWNER') {
      await client.query('ROLLBACK');
      const err = new Error('UNAUTHORIZED_ROLE');
      err.code = 'UNAUTHORIZED_ROLE';
      err.statusCode = 403;
      throw err;
    }

    if (inv.status !== 'PENDING') {
      await client.query('ROLLBACK');
      const err = new Error('INVITATION_NOT_PENDING');
      err.code = 'INVITATION_NOT_PENDING';
      err.statusCode = 422;
      throw err;
    }

    const rawToken = crypto.randomBytes(32).toString('hex');
    const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    const updateQuery = `
      UPDATE staff_invitations 
      SET token_hash = $1, expires_at = $2, updated_at = CURRENT_TIMESTAMP 
      WHERE id = $3
      RETURNING id, tenant_id, establishment_id, email, role, relation_type, status, expires_at, updated_at;
    `;
    const updRes = await client.query(updateQuery, [tokenHash, expiresAt.toISOString(), invitationId]);
    await client.query('COMMIT');

    const updated = updRes.rows[0];
    return {
      success: true,
      invitation: {
        id: updated.id,
        tenant_id: updated.tenant_id,
        establishment_id: updated.establishment_id,
        email: updated.email,
        role: updated.role,
        relation_type: updated.relation_type,
        status: updated.status,
        expires_at: updated.expires_at instanceof Date ? updated.expires_at.toISOString() : updated.expires_at,
        updated_at: updated.updated_at instanceof Date ? updated.updated_at.toISOString() : updated.updated_at,
      },
      raw_token: rawToken,
    };
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch (_) {}
    throw err;
  } finally {
    client.release();
  }
};

/**
 * Public inspection of an invitation by its raw token.
 */
const getInvitationByToken = async (rawToken) => {
  if (!rawToken || typeof rawToken !== 'string' || !rawToken.trim()) {
    const err = new Error('INVALID_TOKEN');
    err.code = 'INVALID_TOKEN';
    err.statusCode = 400;
    throw err;
  }

  const tokenHash = crypto.createHash('sha256').update(rawToken.trim()).digest('hex');
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const query = `
      SELECT 
        si.id,
        si.tenant_id,
        si.establishment_id,
        si.email,
        si.role,
        si.relation_type,
        si.status,
        si.expires_at,
        e.name AS establishment_name,
        t.name AS tenant_name
      FROM staff_invitations si
      INNER JOIN establishments e ON e.id = si.establishment_id AND e.tenant_id = si.tenant_id
      INNER JOIN tenants t ON t.id = si.tenant_id
      WHERE si.token_hash = $1;
    `;

    const res = await client.query(query, [tokenHash]);

    if (res.rows.length === 0) {
      await client.query('ROLLBACK');
      const err = new Error('INVITATION_NOT_FOUND');
      err.code = 'INVITATION_NOT_FOUND';
      err.statusCode = 404;
      throw err;
    }

    const inv = res.rows[0];

    // Check expiration
    const isExpired = new Date(inv.expires_at) < new Date();
    if (inv.status === 'EXPIRED' || (inv.status === 'PENDING' && isExpired)) {
      if (inv.status === 'PENDING') {
        await client.query("UPDATE staff_invitations SET status = 'EXPIRED' WHERE id = $1;", [inv.id]);
      }
      await client.query('COMMIT');
      const err = new Error('INVITATION_EXPIRED');
      err.code = 'INVITATION_EXPIRED';
      err.statusCode = 410;
      throw err;
    }

    if (inv.status === 'REVOKED') {
      await client.query('ROLLBACK');
      const err = new Error('INVITATION_REVOKED');
      err.code = 'INVITATION_REVOKED';
      err.statusCode = 410;
      throw err;
    }

    if (inv.status === 'ACCEPTED') {
      await client.query('ROLLBACK');
      const err = new Error('INVITATION_ALREADY_PROCESSED');
      err.code = 'INVITATION_ALREADY_PROCESSED';
      err.statusCode = 409;
      throw err;
    }

    // Check if user already exists
    const userQuery = 'SELECT id FROM usuarios WHERE LOWER(email) = LOWER($1) AND tenant_id = $2;';
    const userRes = await client.query(userQuery, [inv.email, inv.tenant_id]);
    const userExists = userRes.rows.length > 0;

    await client.query('COMMIT');

    return {
      valid: true,
      email: inv.email,
      role: inv.role,
      relation_type: inv.relation_type,
      establishment_id: inv.establishment_id,
      establishment_name: inv.establishment_name,
      tenant_name: inv.tenant_name,
      expires_at: inv.expires_at instanceof Date ? inv.expires_at.toISOString() : inv.expires_at,
      user_exists: userExists,
    };
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch (_) {}
    throw err;
  } finally {
    client.release();
  }
};

/**
 * Accepts an invitation. Supports both authenticated existing users and new user registration.
 */
const acceptInvitation = async (rawToken, authUserId, registrationData) => {
  if (!rawToken || typeof rawToken !== 'string' || !rawToken.trim()) {
    const err = new Error('INVALID_TOKEN');
    err.code = 'INVALID_TOKEN';
    err.statusCode = 400;
    throw err;
  }

  const tokenHash = crypto.createHash('sha256').update(rawToken.trim()).digest('hex');
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1. Lock invitation
    const query = `
      SELECT 
        si.id,
        si.tenant_id,
        si.establishment_id,
        si.email,
        si.role,
        si.relation_type,
        si.status,
        si.expires_at
      FROM staff_invitations si
      WHERE si.token_hash = $1
      FOR UPDATE;
    `;

    const res = await client.query(query, [tokenHash]);

    if (res.rows.length === 0) {
      await client.query('ROLLBACK');
      const err = new Error('INVITATION_NOT_FOUND');
      err.code = 'INVITATION_NOT_FOUND';
      err.statusCode = 404;
      throw err;
    }

    const inv = res.rows[0];

    // Check expiration / status
    if (new Date(inv.expires_at) < new Date() || inv.status === 'EXPIRED') {
      await client.query("UPDATE staff_invitations SET status = 'EXPIRED' WHERE id = $1;", [inv.id]);
      await client.query('COMMIT');
      const err = new Error('INVITATION_EXPIRED');
      err.code = 'INVITATION_EXPIRED';
      err.statusCode = 410;
      throw err;
    }

    if (inv.status === 'REVOKED') {
      await client.query('ROLLBACK');
      const err = new Error('INVITATION_REVOKED');
      err.code = 'INVITATION_REVOKED';
      err.statusCode = 410;
      throw err;
    }

    if (inv.status === 'ACCEPTED') {
      await client.query('ROLLBACK');
      const err = new Error('INVITATION_ALREADY_PROCESSED');
      err.code = 'INVITATION_ALREADY_PROCESSED';
      err.statusCode = 409;
      throw err;
    }

    // 2. Resolve User ID
    let resolvedUserId = null;

    if (authUserId) {
      // Authenticated User Flow
      const userRes = await client.query(
        'SELECT id, email, tenant_id FROM usuarios WHERE id = $1;',
        [Number(authUserId)]
      );

      if (userRes.rows.length === 0) {
        await client.query('ROLLBACK');
        const err = new Error('USER_NOT_FOUND');
        err.code = 'USER_NOT_FOUND';
        err.statusCode = 404;
        throw err;
      }

      const u = userRes.rows[0];
      if (u.email.toLowerCase() !== inv.email.toLowerCase()) {
        await client.query('ROLLBACK');
        const err = new Error('IDENTITY_MISMATCH');
        err.code = 'IDENTITY_MISMATCH';
        err.statusCode = 403;
        throw err;
      }

      if (u.tenant_id !== inv.tenant_id) {
        await client.query('ROLLBACK');
        const err = new Error('TENANT_MISMATCH');
        err.code = 'TENANT_MISMATCH';
        err.statusCode = 403;
        throw err;
      }

      resolvedUserId = u.id;
    } else {
      // New User Registration Flow
      if (!registrationData || !registrationData.full_name || !registrationData.password) {
        await client.query('ROLLBACK');
        const err = new Error('REGISTRATION_REQUIRED');
        err.code = 'REGISTRATION_REQUIRED';
        err.statusCode = 400;
        throw err;
      }

      // Check if user already exists
      const checkUser = await client.query(
        'SELECT id FROM usuarios WHERE LOWER(email) = LOWER($1);',
        [inv.email]
      );

      if (checkUser.rows.length > 0) {
        await client.query('ROLLBACK');
        const err = new Error('AUTHENTICATION_REQUIRED');
        err.code = 'AUTHENTICATION_REQUIRED';
        err.statusCode = 401;
        throw err;
      }

      const hashedPassword = await bcrypt.hash(registrationData.password, 10);
      const providerId = 'local_' + inv.email.toLowerCase();

      const insertUserQuery = `
        INSERT INTO usuarios (
          nombre, email, password_hash, auth_provider, provider_id,
          rol, onboarding_completo, is_active, tenant_id
        ) VALUES (
          $1, $2, $3, 'LOCAL', $4,
          'PRESTADOR', TRUE, TRUE, $5
        ) RETURNING id;
      `;

      const newUserRes = await client.query(insertUserQuery, [
        registrationData.full_name.trim(),
        inv.email.toLowerCase(),
        hashedPassword,
        providerId,
        inv.tenant_id,
      ]);

      resolvedUserId = newUserRes.rows[0].id;
    }

    // 3. Upsert Membership to ACTIVE
    const membershipQuery = `
      INSERT INTO memberships (
        tenant_id, establishment_id, user_id, role, relation_type, status, joined_at
      ) VALUES (
        $1, $2, $3, $4, $5, 'ACTIVE', CURRENT_TIMESTAMP
      )
      ON CONFLICT (establishment_id, user_id) 
      DO UPDATE SET 
        role = EXCLUDED.role,
        relation_type = EXCLUDED.relation_type,
        status = 'ACTIVE',
        joined_at = CURRENT_TIMESTAMP,
        revoked_at = NULL,
        updated_at = CURRENT_TIMESTAMP
      RETURNING id;
    `;

    const memRes = await client.query(membershipQuery, [
      inv.tenant_id,
      inv.establishment_id,
      resolvedUserId,
      inv.role,
      inv.relation_type,
    ]);

    const membershipId = memRes.rows[0].id;

    // 4. Mark Invitation as ACCEPTED
    const updateInvQuery = `
      UPDATE staff_invitations 
      SET status = 'ACCEPTED', 
          accepted_at = CURRENT_TIMESTAMP, 
          accepted_user_id = $1, 
          updated_at = CURRENT_TIMESTAMP 
      WHERE id = $2;
    `;
    await client.query(updateInvQuery, [resolvedUserId, inv.id]);

    await client.query('COMMIT');

    return {
      success: true,
      membership_id: membershipId,
      establishment_id: inv.establishment_id,
      role: inv.role,
    };
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch (_) {}
    throw err;
  } finally {
    client.release();
  }
};

/**
 * Lists all staff members in the establishment.
 */
const listStaff = async (tenantId, establishmentId, activeContext) => {
  if (!tenantId || !establishmentId || !activeContext) {
    const err = new Error('ACTIVE_CONTEXT_REQUIRED');
    err.code = 'ACTIVE_CONTEXT_REQUIRED';
    err.statusCode = 400;
    throw err;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const query = `
      SELECT 
        m.id AS membership_id,
        m.tenant_id,
        m.establishment_id,
        m.user_id,
        u.nombre AS user_name,
        u.email AS user_email,
        m.role,
        m.relation_type,
        m.status,
        m.joined_at,
        m.revoked_at,
        m.created_at,
        m.updated_at
      FROM memberships m
      INNER JOIN usuarios u ON u.id = m.user_id AND u.tenant_id = m.tenant_id
      WHERE m.establishment_id = $1 
        AND m.tenant_id = $2
      ORDER BY 
        CASE m.role 
          WHEN 'OWNER' THEN 1 
          WHEN 'MANAGER' THEN 2 
          WHEN 'PROFESSIONAL' THEN 3 
          WHEN 'RECEPTIONIST' THEN 4 
          ELSE 5 
        END,
        m.joined_at ASC;
    `;

    const result = await client.query(query, [establishmentId, tenantId]);
    await client.query('COMMIT');

    return {
      establishment_id: establishmentId,
      members: result.rows.map((row) => ({
        membership_id: row.membership_id,
        tenant_id: row.tenant_id,
        establishment_id: row.establishment_id,
        user_id: row.user_id,
        user_name: row.user_name,
        user_email: row.user_email,
        role: row.role,
        relation_type: row.relation_type,
        status: row.status,
        joined_at: row.joined_at instanceof Date ? row.joined_at.toISOString() : row.joined_at,
        revoked_at: row.revoked_at instanceof Date ? row.revoked_at.toISOString() : row.revoked_at,
        created_at: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
        updated_at: row.updated_at instanceof Date ? row.updated_at.toISOString() : row.updated_at,
      })),
    };
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch (_) {}
    throw err;
  } finally {
    client.release();
  }
};

/**
 * Mutates a staff member's role with Anti-Orphan and RBAC verification.
 */
const updateStaffRole = async (tenantId, establishmentId, activeContext, targetMembershipId, newRole) => {
  if (!tenantId || !establishmentId || !activeContext || !targetMembershipId || !newRole) {
    const err = new Error('ACTIVE_CONTEXT_REQUIRED');
    err.code = 'ACTIVE_CONTEXT_REQUIRED';
    err.statusCode = 400;
    throw err;
  }

  const cleanRole = newRole.toUpperCase();
  if (!VALID_ROLES.includes(cleanRole)) {
    const err = new Error('INVALID_ROLE');
    err.code = 'INVALID_ROLE';
    err.statusCode = 400;
    throw err;
  }

  const actorRole = activeContext.role;
  const actorMembershipId = activeContext.active_membership_id;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    // 1. Lock Target Membership
    const selectQuery = `
      SELECT id, role, status 
      FROM memberships 
      WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3
      FOR UPDATE;
    `;
    const res = await client.query(selectQuery, [targetMembershipId, establishmentId, tenantId]);

    if (res.rows.length === 0) {
      await client.query('ROLLBACK');
      const err = new Error('MEMBERSHIP_NOT_FOUND');
      err.code = 'MEMBERSHIP_NOT_FOUND';
      err.statusCode = 404;
      throw err;
    }

    const target = res.rows[0];

    // 2. Anti-Self Role Mutation
    if (actorMembershipId === targetMembershipId && cleanRole !== target.role) {
      await client.query('ROLLBACK');
      const err = new Error('SELF_ROLE_MUTATION_PROHIBITED');
      err.code = 'SELF_ROLE_MUTATION_PROHIBITED';
      err.statusCode = 403;
      throw err;
    }

    // 3. RBAC Enforcement
    if (actorRole === 'MANAGER') {
      // Manager can only toggle between PROFESSIONAL and RECEPTIONIST
      const isOperativeTarget = target.role === 'PROFESSIONAL' || target.role === 'RECEPTIONIST';
      const isOperativeNewRole = cleanRole === 'PROFESSIONAL' || cleanRole === 'RECEPTIONIST';

      if (!isOperativeTarget || !isOperativeNewRole) {
        await client.query('ROLLBACK');
        const err = new Error('UNAUTHORIZED_ROLE_MUTATION');
        err.code = 'UNAUTHORIZED_ROLE_MUTATION';
        err.statusCode = 403;
        throw err;
      }
    } else if (actorRole === 'OWNER') {
      // If target is currently OWNER and being downgraded
      if (target.role === 'OWNER' && cleanRole !== 'OWNER') {
        const ownerCountQuery = `
          SELECT COUNT(*)::int AS count 
          FROM memberships 
          WHERE establishment_id = $1 AND tenant_id = $2 AND role = 'OWNER' AND status = 'ACTIVE';
        `;
        const countRes = await client.query(ownerCountQuery, [establishmentId, tenantId]);
        const activeOwners = countRes.rows[0]?.count || 0;

        if (activeOwners <= 1) {
          await client.query('ROLLBACK');
          const err = new Error('CANNOT_ORPHAN_ESTABLISHMENT');
          err.code = 'CANNOT_ORPHAN_ESTABLISHMENT';
          err.statusCode = 422;
          throw err;
        }
      }
    } else {
      await client.query('ROLLBACK');
      const err = new Error('UNAUTHORIZED_ROLE');
      err.code = 'UNAUTHORIZED_ROLE';
      err.statusCode = 403;
      throw err;
    }

    // 4. Update Role
    const updateQuery = `
      UPDATE memberships 
      SET role = $1, updated_at = CURRENT_TIMESTAMP 
      WHERE id = $2
      RETURNING id, tenant_id, establishment_id, user_id, role, relation_type, status, updated_at;
    `;
    const updRes = await client.query(updateQuery, [cleanRole, targetMembershipId]);
    await client.query('COMMIT');

    return { success: true, member: updRes.rows[0] };
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch (_) {}
    throw err;
  } finally {
    client.release();
  }
};

/**
 * Mutates a staff member's status (SUSPENDED / ACTIVE / REVOKED).
 */
const updateStaffStatus = async (tenantId, establishmentId, activeContext, targetMembershipId, newStatus) => {
  if (!tenantId || !establishmentId || !activeContext || !targetMembershipId || !newStatus) {
    const err = new Error('ACTIVE_CONTEXT_REQUIRED');
    err.code = 'ACTIVE_CONTEXT_REQUIRED';
    err.statusCode = 400;
    throw err;
  }

  const cleanStatus = newStatus.toUpperCase();
  if (!VALID_STATUSES.includes(cleanStatus)) {
    const err = new Error('INVALID_STATUS');
    err.code = 'INVALID_STATUS';
    err.statusCode = 400;
    throw err;
  }

  const actorRole = activeContext.role;
  const actorMembershipId = activeContext.active_membership_id;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const selectQuery = `
      SELECT id, role, status 
      FROM memberships 
      WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3
      FOR UPDATE;
    `;
    const res = await client.query(selectQuery, [targetMembershipId, establishmentId, tenantId]);

    if (res.rows.length === 0) {
      await client.query('ROLLBACK');
      const err = new Error('MEMBERSHIP_NOT_FOUND');
      err.code = 'MEMBERSHIP_NOT_FOUND';
      err.statusCode = 404;
      throw err;
    }

    const target = res.rows[0];

    // If already in target status
    if (target.status === cleanStatus) {
      await client.query('COMMIT');
      return { success: true, member: target };
    }

    // Terminal Status Check: REVOKED is terminal
    if (target.status === 'REVOKED') {
      await client.query('ROLLBACK');
      const err = new Error('INVALID_STATE_TRANSITION');
      err.code = 'INVALID_STATE_TRANSITION';
      err.statusCode = 422;
      throw err;
    }

    // Self-Status Mutation Protection
    if (actorMembershipId === targetMembershipId) {
      if (actorRole !== 'OWNER') {
        await client.query('ROLLBACK');
        const err = new Error('SELF_STATUS_MUTATION_PROHIBITED');
        err.code = 'SELF_STATUS_MUTATION_PROHIBITED';
        err.statusCode = 403;
        throw err;
      }
      if (cleanStatus === 'SUSPENDED' || cleanStatus === 'REVOKED') {
        const ownerCountQuery = `
          SELECT COUNT(*)::int AS count 
          FROM memberships 
          WHERE establishment_id = $1 AND tenant_id = $2 AND role = 'OWNER' AND status = 'ACTIVE';
        `;
        const countRes = await client.query(ownerCountQuery, [establishmentId, tenantId]);
        const activeOwners = countRes.rows[0]?.count || 0;

        if (activeOwners <= 1) {
          await client.query('ROLLBACK');
          const err = new Error('CANNOT_ORPHAN_ESTABLISHMENT');
          err.code = 'CANNOT_ORPHAN_ESTABLISHMENT';
          err.statusCode = 422;
          throw err;
        }
      }
    }

    // RBAC Permissions
    if (actorRole === 'MANAGER') {
      // Manager can only suspend/reactivate PROFESSIONAL and RECEPTIONIST
      const isOperative = target.role === 'PROFESSIONAL' || target.role === 'RECEPTIONIST';
      const isAllowedStatus = cleanStatus === 'SUSPENDED' || cleanStatus === 'ACTIVE';

      if (!isOperative || !isAllowedStatus) {
        await client.query('ROLLBACK');
        const err = new Error('UNAUTHORIZED_STATUS_MUTATION');
        err.code = 'UNAUTHORIZED_STATUS_MUTATION';
        err.statusCode = 403;
        throw err;
      }
    } else if (actorRole === 'OWNER') {
      // Owner anti-orphan check if targeting an active OWNER
      if (target.role === 'OWNER' && (cleanStatus === 'SUSPENDED' || cleanStatus === 'REVOKED')) {
        const ownerCountQuery = `
          SELECT COUNT(*)::int AS count 
          FROM memberships 
          WHERE establishment_id = $1 AND tenant_id = $2 AND role = 'OWNER' AND status = 'ACTIVE';
        `;
        const countRes = await client.query(ownerCountQuery, [establishmentId, tenantId]);
        const activeOwners = countRes.rows[0]?.count || 0;

        if (activeOwners <= 1) {
          await client.query('ROLLBACK');
          const err = new Error('CANNOT_ORPHAN_ESTABLISHMENT');
          err.code = 'CANNOT_ORPHAN_ESTABLISHMENT';
          err.statusCode = 422;
          throw err;
        }
      }
    } else {
      await client.query('ROLLBACK');
      const err = new Error('UNAUTHORIZED_ROLE');
      err.code = 'UNAUTHORIZED_ROLE';
      err.statusCode = 403;
      throw err;
    }

    // Apply Transition
    let updateQuery;
    let queryParams;

    if (cleanStatus === 'REVOKED') {
      updateQuery = `
        UPDATE memberships 
        SET status = 'REVOKED', revoked_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP 
        WHERE id = $1
        RETURNING id, tenant_id, establishment_id, user_id, role, relation_type, status, joined_at, revoked_at, updated_at;
      `;
      queryParams = [targetMembershipId];
    } else {
      updateQuery = `
        UPDATE memberships 
        SET status = $1, updated_at = CURRENT_TIMESTAMP 
        WHERE id = $2
        RETURNING id, tenant_id, establishment_id, user_id, role, relation_type, status, joined_at, revoked_at, updated_at;
      `;
      queryParams = [cleanStatus, targetMembershipId];
    }

    const updRes = await client.query(updateQuery, queryParams);
    await client.query('COMMIT');

    return { success: true, member: updRes.rows[0] };
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch (_) {}
    throw err;
  } finally {
    client.release();
  }
};

/**
 * Mutates relation_type (Exclusively OWNER).
 */
const updateStaffRelationType = async (tenantId, establishmentId, activeContext, targetMembershipId, newRelationType) => {
  if (!tenantId || !establishmentId || !activeContext || !targetMembershipId || !newRelationType) {
    const err = new Error('ACTIVE_CONTEXT_REQUIRED');
    err.code = 'ACTIVE_CONTEXT_REQUIRED';
    err.statusCode = 400;
    throw err;
  }

  const cleanRelation = newRelationType.toUpperCase();
  if (!VALID_RELATION_TYPES.includes(cleanRelation)) {
    const err = new Error('INVALID_RELATION_TYPE');
    err.code = 'INVALID_RELATION_TYPE';
    err.statusCode = 400;
    throw err;
  }

  if (activeContext.role !== 'OWNER') {
    const err = new Error('UNAUTHORIZED_ROLE');
    err.code = 'UNAUTHORIZED_ROLE';
    err.statusCode = 403;
    throw err;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const updateQuery = `
      UPDATE memberships 
      SET relation_type = $1, updated_at = CURRENT_TIMESTAMP 
      WHERE id = $2 AND establishment_id = $3 AND tenant_id = $4
      RETURNING id, tenant_id, establishment_id, user_id, role, relation_type, status, updated_at;
    `;
    const updRes = await client.query(updateQuery, [cleanRelation, targetMembershipId, establishmentId, tenantId]);

    if (updRes.rows.length === 0) {
      await client.query('ROLLBACK');
      const err = new Error('MEMBERSHIP_NOT_FOUND');
      err.code = 'MEMBERSHIP_NOT_FOUND';
      err.statusCode = 404;
      throw err;
    }

    await client.query('COMMIT');
    return { success: true, member: updRes.rows[0] };
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch (_) {}
    throw err;
  } finally {
    client.release();
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
