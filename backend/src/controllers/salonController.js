const { pool } = require('../config/db');
const crypto = require('crypto');
const { hasEntitlement, PLAN_ENTITLEMENTS, SAAS_CAPABILITIES } = require('../config/saasEntitlements');

// ==========================================
// 🏢 OBTENER MI SALÓN DE BELLEZA (SaaS Owner Profile)
// ==========================================
exports.getMySalon = async (req, res) => {
  try {
    const ownerId = req.user.id;
    const salonRes = await pool.query(
      `SELECT s.id, s.nombre_salon, s.nit, s.direccion, s.telefono, s.ciudad, s.plan_saas, s.id_dueno,
              s.latitude, s.longitude, s.location_enabled, s.location_public
       FROM salones s
       WHERE s.id_dueno = $1
       LIMIT 1`,
      [ownerId]
    );

    let salon = salonRes.rows[0];
    if (!salon) {
      salon = {
        id: 1,
        nombre_salon: 'Salón Elegance Studio',
        nit: '901888777-1',
        direccion: 'Calle 127 # 7-18',
        telefono: '3109998877',
        ciudad: 'Bogotá',
        plan_saas: 'FREE_TRIAL',
        id_dueno: ownerId,
        latitude: 4.6735,
        longitude: -74.1422,
        location_enabled: true,
        location_public: true,
      };
    }

    const plan = salon.plan_saas || 'FREE_TRIAL';
    const activeEntitlements = PLAN_ENTITLEMENTS[plan.toUpperCase()] || [];

    const membersRes = await pool.query(
      `SELECT sm.id, sm.user_id, u.nombre, u.email, u.phone, sm.sub_rol, sm.estatus, sm.creado_at
       FROM salon_miembros sm
       JOIN usuarios u ON sm.user_id = u.id
       WHERE sm.salon_id = $1`,
      [salon.id]
    );

    res.json({
      success: true,
      salon: {
        ...salon,
        entitlements: activeEntitlements,
        can_show_on_map: salon.location_enabled && salon.location_public && hasEntitlement(plan, SAAS_CAPABILITIES.MAP_VISIBILITY)
      },
      members: membersRes.rows
    });
  } catch (error) {
    console.error('❌ ERROR GET MY SALON:', error.message);
    res.status(500).json({ error: 'Error al obtener información del salón' });
  }
};

// ==========================================
// 🏢 CREAR SALÓN DE BELLEZA (SaaS Owner Onboarding)
// ==========================================
exports.createSalon = async (req, res) => {
  console.log('🏢 [DEBUG] ENTERED createSalon. Body:', req.body, 'User:', req.user);
  try {
    const ownerId = req.user.id;
    const { nombre_salon, nit, direccion, telefono, ciudad, latitude, longitude, location_public } = req.body;

    if (!nombre_salon) {
      return res.status(400).json({ error: 'El nombre del salón es obligatorio.' });
    }

    const lat = latitude !== undefined && latitude !== null ? parseFloat(latitude) : null;
    const lon = longitude !== undefined && longitude !== null ? parseFloat(longitude) : null;
    const hasValidCoords = lat !== null && !isNaN(lat) && lon !== null && !isNaN(lon);
    const locationEnabled = hasValidCoords;
    const isPublic = location_public !== undefined ? Boolean(location_public) : true;

    // Insertar salón en la base de datos con PostGIS si hay coordenadas válidas
    const query = `
      INSERT INTO salones (
        nombre_salon, nit, direccion, telefono, ciudad, id_dueno, plan_saas,
        latitude, longitude, ubicacion, location_enabled, location_public
      )
      VALUES (
        $1, $2, $3, $4, $5, $6, 'FREE_TRIAL',
        $7, $8, 
        CASE WHEN $7::numeric IS NOT NULL AND $8::numeric IS NOT NULL 
             THEN ST_SetSRID(ST_MakePoint($8, $7), 4326)::geography 
             ELSE NULL END,
        $9, $10
      )
      RETURNING id, nombre_salon, nit, direccion, ciudad, telefono, plan_saas, latitude, longitude, location_enabled, location_public`;

    const salonRes = await pool.query(query, [
      nombre_salon,
      nit || null,
      direccion || null,
      telefono || null,
      ciudad || null,
      ownerId,
      hasValidCoords ? lat : null,
      hasValidCoords ? lon : null,
      locationEnabled,
      isPublic
    ]);

    const salon = salonRes.rows[0];

    // Asignar al usuario como DUEÑO en salon_miembros
    await pool.query(
      `INSERT INTO salon_miembros (salon_id, user_id, sub_rol, estatus)
       VALUES ($1, $2, 'DUEÑO', 'ACTIVO')
       ON CONFLICT (salon_id, user_id) DO UPDATE SET sub_rol = 'DUEÑO', estatus = 'ACTIVO'`,
      [salon.id, ownerId]
    );

    // Marcar rol del usuario como SALON y onboarding_completo = true
    await pool.query(
      `UPDATE usuarios SET rol = 'SALON', onboarding_completo = true WHERE id = $1`,
      [ownerId]
    );

    console.log(`🏢 Salón '${nombre_salon}' creado exitosamente para Dueño ID ${ownerId} (Ubicación: ${hasValidCoords ? `${lat}, ${lon}` : 'No especificada'})`);

    res.status(201).json({
      success: true,
      message: 'Salón registrado exitosamente en el sistema SaaS.',
      salon
    });
  } catch (error) {
    console.error('❌ ERROR CREATE SALON:', error.message);
    res.status(500).json({ error: 'Error al registrar el salón de belleza' });
  }
};

// ==========================================
// ✉️ INVITAR MIEMBRO AL EQUIPO DEL SALÓN
// ==========================================
exports.inviteMember = async (req, res) => {
  try {
    const inviterId = req.user.id;
    const { salon_id, email, sub_rol } = req.body;

    const validSubRoles = ['ADMINISTRADOR', 'PRESTADOR_INDEPENDIENTE', 'EMPLEADO', 'RECEPCIONISTA'];
    if (!salon_id || !email || !sub_rol || !validSubRoles.includes(sub_rol.toUpperCase())) {
      return res.status(400).json({
        error: 'salon_id, email y sub_rol válido (ADMINISTRADOR, PRESTADOR_INDEPENDIENTE, EMPLEADO, RECEPCIONISTA) son obligatorios.'
      });
    }

    const cleanEmail = email.trim().toLowerCase();
    const cleanSubRol = sub_rol.toUpperCase();

    // Verificar si el que invita es Dueño o Administrador del salón
    const memberCheck = await pool.query(
      `SELECT sub_rol FROM salon_miembros WHERE salon_id = $1 AND user_id = $2 AND estatus = 'ACTIVO'`,
      [salon_id, inviterId]
    );

    if (memberCheck.rows.length === 0 || !['DUEÑO', 'ADMINISTRADOR'].includes(memberCheck.rows[0].sub_rol)) {
      return res.status(403).json({ error: 'No tienes permisos de administración en este salón para invitar personal.' });
    }

    // Generar token de invitación único de 32 caracteres
    const invitationToken = crypto.randomBytes(16).toString('hex');
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 días de validez

    await pool.query(
      `INSERT INTO salon_invitaciones (salon_id, email, sub_rol, token_invitacion, expires_at, creado_por)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [salon_id, cleanEmail, cleanSubRol, invitationToken, expiresAt, inviterId]
    );

    const inviteLink = `https://glowapp-frontend-production.up.railway.app/#/accept-invitation?token=${invitationToken}`;

    console.log(`✉️ Invitación creada para ${cleanEmail} como ${cleanSubRol} en Salón ID ${salon_id}`);

    res.json({
      success: true,
      message: `Invitación generada exitosamente para ${cleanEmail}.`,
      invitation_token: invitationToken,
      invite_link: inviteLink
    });
  } catch (error) {
    console.error('❌ ERROR INVITE MEMBER:', error.message);
    res.status(500).json({ error: 'Error al enviar invitación de equipo' });
  }
};

// ==========================================
// 🤝 ACEPTAR INVITACIÓN DE SALÓN
// ==========================================
exports.acceptInvitation = async (req, res) => {
  try {
    const userId = req.user.id;
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({ error: 'El token de invitación es obligatorio.' });
    }

    // Buscar invitación válida
    const inviteRes = await pool.query(
      `SELECT id, salon_id, email, sub_rol, expires_at, usado
       FROM salon_invitaciones
       WHERE token_invitacion = $1 AND usado = false AND expires_at > NOW()`,
      [token]
    );

    if (inviteRes.rows.length === 0) {
      return res.status(400).json({ error: 'La invitación es inválida, ya fue usada o ha expirado.' });
    }

    const invitation = inviteRes.rows[0];

    // Asociar al usuario en salon_miembros
    await pool.query(
      `INSERT INTO salon_miembros (salon_id, user_id, sub_rol, estatus)
       VALUES ($1, $2, $3, 'ACTIVO')
       ON CONFLICT (salon_id, user_id) DO UPDATE SET sub_rol = EXCLUDED.sub_rol, estatus = 'ACTIVO'`,
      [invitation.salon_id, userId, invitation.sub_rol]
    );

    // Marcar invitación como usada
    await pool.query(
      `UPDATE salon_invitaciones SET usado = true WHERE id = $1`,
      [invitation.id]
    );

    console.log(`🤝 Usuario ID ${userId} aceptó invitación como ${invitation.sub_rol} en Salón ID ${invitation.salon_id}`);

    res.json({
      success: true,
      message: `Te has unedido exitosamente al salón con el rol de ${invitation.sub_rol}.`,
      salon_id: invitation.salon_id,
      sub_rol: invitation.sub_rol
    });
  } catch (error) {
    console.error('❌ ERROR ACCEPT INVITATION:', error.message);
    res.status(500).json({ error: 'Error al procesar la aceptación de la invitación' });
  }
};

// ==========================================
// 📋 LISTAR MIEMBROS DE UN SALÓN
// ==========================================
exports.getSalonMembers = async (req, res) => {
  try {
    const userId = req.user.id;
    const { salonId } = req.params;

    // Verificar que el usuario pertenece al salón
    const memberCheck = await pool.query(
      `SELECT sub_rol FROM salon_miembros WHERE salon_id = $1 AND user_id = $2 AND estatus = 'ACTIVO'`,
      [salonId, userId]
    );

    if (memberCheck.rows.length === 0) {
      return res.status(403).json({ error: 'No perteneces a este salón.' });
    }

    const membersRes = await pool.query(
      `SELECT sm.id, sm.user_id, u.nombre, u.email, u.phone, sm.sub_rol, sm.estatus, sm.creado_at
       FROM salon_miembros sm
       JOIN usuarios u ON sm.user_id = u.id
       WHERE sm.salon_id = $1
       ORDER BY sm.creado_at ASC`,
      [salonId]
    );

    res.json({
      success: true,
      members: membersRes.rows
    });
  } catch (error) {
    console.error('❌ ERROR GET SALON MEMBERS:', error.message);
    res.status(500).json({ error: 'Error al obtener la lista de miembros del salón' });
  }
};
