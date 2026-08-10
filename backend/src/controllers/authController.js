const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');
const { getJwtSecret, toApiRole } = require('../config/jwt');
const redisClient = require('../config/redis');
const emailService = require('../services/email.service');


// ==========================================
// 📝 REGISTRO LOCAL
// ==========================================
exports.register = async (req, res) => {
  try {
    const { full_name, email, password, phone, role } = req.body;
    
    if (!full_name || !email || !password) {
      return res.status(400).json({ error: 'Faltan campos obligatorios' });
    }

    const cleanEmail = email.trim().toLowerCase();
    const hashedPassword = await bcrypt.hash(password, 10);
    const providerId = 'local_' + cleanEmail;

    // Determinar el rol y estado de onboarding
    const userRole = (role && role.toUpperCase() === 'PRESTADOR') ? 'PRESTADOR' : 'CLIENTE';
    const onboarding = (userRole === 'CLIENTE'); // true para cliente (completo), false para prestador (requiere docs)

    const result = await pool.query(
      `INSERT INTO usuarios (nombre, email, password_hash, phone, auth_provider, provider_id, rol, onboarding_completo) 
       VALUES ($1, $2, $3, $4, 'LOCAL', $5, $6, $7) 
       RETURNING id, nombre, email, rol, onboarding_completo`,
      [full_name, cleanEmail, hashedPassword, phone || null, providerId, userRole, onboarding]
    );

    const user = result.rows[0];
    res.status(201).json({ 
      success: true, 
      user: {
        id: user.id.toString(),
        full_name: user.nombre,
        email: user.email,
        role: toApiRole(user.rol),
        onboarding_completo: user.onboarding_completo
      }
    });

  } catch (err) {
    if (err.code === '23505') return res.status(400).json({ error: 'El email ya está registrado' });
    console.error('❌ ERROR REGISTER:', err.message);
    res.status(500).json({ error: 'Error al registrar usuario' });
  }
};

// ==========================================
// 🔐 INICIO DE SESIÓN LOCAL (LOGIN)
// ==========================================
exports.login = async (req, res) => {
  try {

    const { email, password } = req.body;
    
    if (!email || !password) {
      console.log("❌ VALIDACIÓN FALLIDA: Faltan campos. Email:", email, "Password:", password);
      return res.status(400).json({ error: 'Email y contraseña son obligatorios' });
    }

    const cleanEmail = email.trim().toLowerCase();

    const result = await pool.query(
      `SELECT id, nombre, email, password_hash, rol, onboarding_completo, is_active 
       FROM usuarios 
       WHERE LOWER(email) = $1 AND auth_provider = 'LOCAL'`, 
      [cleanEmail]
    );
    
    if (result.rows.length === 0) {
      console.log('❌ RECHAZADO: El correo local no existe en la BD.');
      return res.status(401).json({ error: 'Credenciales inválidas' });
    }
    
    const user = result.rows[0];

    if (user.is_active === false) {
      console.log('❌ RECHAZADO: El usuario está desactivado.');
      return res.status(403).json({ error: 'Tu cuenta ha sido desactivada por el administrador.' });
    }

    const isValid = await bcrypt.compare(password, user.password_hash);
    if (!isValid) {
      console.log('❌ RECHAZADO: La contraseña es incorrecta.');
      return res.status(401).json({ error: 'Credenciales inválidas' });
    }
    
    // Generación del Token JWT
    const token = jwt.sign(
      { id: user.id, email: user.email, role: toApiRole(user.rol), rol: user.rol }, 
      getJwtSecret(), 
      { expiresIn: '7d' }
    );
    
    console.log('✅ LOGIN LOCAL EXITOSO para:', user.email);

    res.json({ 
      success: true, 
      token, 
      user: { 
        id: user.id.toString(), 
        full_name: user.nombre, 
        email: user.email, 
        role: toApiRole(user.rol),
        onboarding_completo: user.onboarding_completo
      } 
    });

  } catch (err) {
    console.error('❌ ERROR LOGIN LOCAL:', err.message);
    res.status(500).json({ error: 'Error al iniciar sesión' });
  }
};

// ==========================================
// 🔗 INICIO DE SESIÓN FEDERADO (OAuth 2.0)
// ==========================================
exports.oauth = async (req, res) => {
  try {
    // 🛡️ PARCHE DE SEGURIDAD (OWASP API2:2023): Bloquear mock OAuth en producción
    if (process.env.NODE_ENV === 'production' || (process.env.ALLOW_MOCK_AUTH !== 'true' && process.env.NODE_ENV !== 'test')) {
      return res.status(403).json({
        error: 'El método OAuth directo de pruebas está deshabilitado en este entorno. Usa /api/auth/google.'
      });
    }

    const { email, nombre, foto_url, auth_provider, provider_id } = req.body;

    if (!email || !nombre || !auth_provider || !provider_id) {
      return res.status(400).json({ error: 'Faltan campos requeridos para OAuth' });
    }

    const cleanEmail = email.trim().toLowerCase();
    const provider = auth_provider.toUpperCase(); // GOOGLE, OUTLOOK, LOCAL

    // Buscamos si existe por la cuenta federada o por email
    let userQuery = await pool.query(
      `SELECT id, nombre, email, rol, onboarding_completo, is_active 
       FROM usuarios 
       WHERE (auth_provider = $1 AND provider_id = $2) OR LOWER(email) = $3`,
      [provider, provider_id, cleanEmail]
    );

    let user;

    if (userQuery.rows.length > 0) {
      user = userQuery.rows[0];
      
      if (user.is_active === false) {
        console.log('❌ RECHAZADO OAUTH: El usuario está desactivado.');
        return res.status(403).json({ error: 'Tu cuenta ha sido desactivada por el administrador.' });
      }

      // Si existía (ej. local) pero ahora ingresa con oauth, actualizamos proveedor federado
      await pool.query(
        `UPDATE usuarios 
         SET auth_provider = $1, provider_id = $2, foto_url = COALESCE(foto_url, $3) 
         WHERE id = $4`,
        [provider, provider_id, foto_url || null, user.id]
      );
      // Recargar datos actualizados
      const updated = await pool.query('SELECT id, nombre, email, rol, onboarding_completo, is_active FROM usuarios WHERE id = $1', [user.id]);
      user = updated.rows[0];
    } else {
      // Registrar nuevo usuario federado con rol = NULL y onboarding_completo = false
      const insertRes = await pool.query(
        `INSERT INTO usuarios (nombre, email, foto_url, auth_provider, provider_id, rol, onboarding_completo) 
         VALUES ($1, $2, $3, $4, $5, NULL, false) 
         RETURNING id, nombre, email, rol, onboarding_completo`,
        [nombre, cleanEmail, foto_url || null, provider, provider_id]
      );
      user = insertRes.rows[0];
    }

    // Firmar Token JWT
    const token = jwt.sign(
      { id: user.id, email: user.email, role: toApiRole(user.rol), rol: user.rol }, 
      getJwtSecret(), 
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      token,
      user: {
        id: user.id.toString(),
        full_name: user.nombre,
        email: user.email,
        role: toApiRole(user.rol),
        onboarding_completo: user.onboarding_completo
      }
    });

  } catch (err) {
    console.error('❌ ERROR OAUTH:', err.message);
    res.status(500).json({ 
      error: 'Error al procesar OAuth',
      details: process.env.ALLOW_MOCK_AUTH === 'true' ? err.message : undefined
    });
  }
};

// ==========================================
// 📋 COMPLETAR ONBOARDING (Ley 1581 Habeas Data y Términos y Condiciones)
// ==========================================
exports.onboarding = async (req, res) => {
  try {
    const userId = req.user.id;
    const { rol, documento_id_url, rut_url, certificacion_url, aceptar_habeas_data, aceptar_terminos } = req.body;

    if (!rol || !['CLIENTE', 'PRESTADOR'].includes(rol.toUpperCase())) {
      return res.status(400).json({ error: 'Rol inválido o ausente' });
    }

    if (aceptar_habeas_data !== true || aceptar_terminos !== true) {
      return res.status(400).json({ error: 'Debe aceptar la Política de Tratamiento de Datos Personales (Habeas Data) y los Términos y Condiciones para continuar.' });
    }

    const mappedRol = rol.toUpperCase();
    const clientIp = req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress;

    if (mappedRol === 'PRESTADOR') {
      // 🛡️ PARCHE DE SEGURIDAD (GLOW-SEC-01): El usuario que realiza el onboarding de prestador
      // NO obtiene el rol en la tabla usuarios de forma inmediata. Se almacena su solicitud
      // y archivos en perfiles_prestador como PENDIENTE, pero su cuenta de autenticación
      // sigue siendo CLIENTE hasta aprobación administrativa.
      await pool.query(
        `UPDATE usuarios 
         SET onboarding_completo = true,
             habeas_data_accepted_at = NOW(), habeas_data_ip = $2,
             terminos_accepted_at = NOW(), terminos_ip = $2
         WHERE id = $1`,
        [userId, clientIp]
      );

      // Crear o actualizar perfil en perfiles_prestador (requiere revisión administrativa)
      await pool.query(
        `INSERT INTO perfiles_prestador (id, documento_id_url, rut_url, certificacion_url, estatus_verificacion, is_active)
         VALUES ($1, $2, $3, $4, 'PENDIENTE', true)
         ON CONFLICT (id) DO UPDATE SET
           documento_id_url = EXCLUDED.documento_id_url,
           rut_url = EXCLUDED.rut_url,
           certificacion_url = EXCLUDED.certificacion_url,
           estatus_verificacion = 'PENDIENTE';`,
         [userId, documento_id_url || null, rut_url || null, certificacion_url || null]
      );
      
      console.log(`📋 Onboarding y aceptación legal completados para Proveedor ID ${userId}. Estatus: PENDIENTE.`);
    } else {
      // Cliente se marca completo inmediatamente
      await pool.query(
        `UPDATE usuarios 
         SET rol = 'CLIENTE', onboarding_completo = true,
             habeas_data_accepted_at = NOW(), habeas_data_ip = $2,
             terminos_accepted_at = NOW(), terminos_ip = $2
         WHERE id = $1`,
        [userId, clientIp]
      );
      console.log(`📋 Onboarding y aceptación legal completados para Cliente ID ${userId}.`);
    }

    res.json({
      success: true,
      message: 'Onboarding completado exitosamente',
      user: {
        role: mappedRol === 'PRESTADOR' ? 'client' : 'client', // Permanece como client hasta aprobación
        onboarding_completo: true
      }
    });

  } catch (err) {
    console.error('❌ ERROR ONBOARDING:', err.message);
    res.status(500).json({ error: 'Error al guardar onboarding' });
  }
};

// ==========================================
// 👁️ REGISTRAR CONSENTIMIENTO BIOMÉTRICO E IA (Ley 1581)
// ==========================================
exports.acceptBiometricsConsent = async (req, res) => {
  try {
    const userId = req.user.id;
    const { consentimiento_otorgado, version_politica, dispositivo } = req.body;

    if (consentimiento_otorgado === undefined || !version_politica) {
      return res.status(400).json({ error: 'consentimiento_otorgado y version_politica son obligatorios.' });
    }

    const clientIp = req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress;

    // Registrar en auditoría de consentimiento biométrico
    await pool.query(
      `INSERT INTO auditoria_consentimiento_biometrico (user_id, consentimiento_otorgado, version_politica, ip_registro, dispositivo)
       VALUES ($1, $2, $3, $4, $5)`,
      [parseInt(userId, 10), consentimiento_otorgado, version_politica, clientIp, dispositivo || 'Unknown']
    );

    console.log(`🛡️ Auditoría de consentimiento biométrico registrada para usuario ID ${userId}. Consentimiento: ${consentimiento_otorgado}`);

    res.json({
      success: true,
      message: 'Aceptación y auditoría de datos biométricos registrada exitosamente.',
      consentimiento_otorgado
    });
  } catch (error) {
    console.error('❌ ERROR ACCEPT BIOMETRICS CONSENT:', error.message);
    res.status(500).json({ error: 'Error al guardar el consentimiento de datos biométricos.' });
  }
};

// ==========================================
// 🔔 GUARDAR TOKEN DE NOTIFICACIONES PUSH (FCM)
// ==========================================
exports.saveFcmToken = async (req, res) => {
  try {
    const userId = req.user.id;
    const { fcm_token, device_os } = req.body;

    if (!fcm_token) {
      return res.status(400).json({ error: 'fcm_token es requerido' });
    }

    await pool.query(
      `UPDATE usuarios 
       SET fcm_token = $1, last_active_at = NOW() 
       WHERE id = $2`,
      [fcm_token, userId]
    );

    console.log(`🔔 Token FCM registrado para usuario ID ${userId} (${device_os || 'web/mobile'})`);

    res.json({
      success: true,
      message: 'Token FCM registrado exitosamente'
    });
  } catch (error) {
    console.error('❌ ERROR SAVE FCM TOKEN:', error.message);
    res.status(500).json({ error: 'Error al registrar token FCM' });
  }
};

// ==========================================
// 🎁 OBTENER CÓDIGO E INFORMACIÓN DE REFERIDOS (K-FACTOR)
// ==========================================
exports.getReferralInfo = async (req, res) => {
  try {
    const userId = req.user.id;

    // Obtener o generar código de referido de 6 caracteres único para el usuario
    const userRes = await pool.query(
      `SELECT id, nombre, email, referral_code FROM usuarios WHERE id = $1`,
      [userId]
    );

    if (userRes.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    let user = userRes.rows[0];
    let referralCode = user.referral_code;

    if (!referralCode) {
      // Generar código único ej: GLOW + 4 caracteres aleatorios
      const crypto = require('crypto');
      referralCode = 'GLOW' + crypto.randomBytes(2).toString('hex').toUpperCase();
      await pool.query(`UPDATE usuarios SET referral_code = $1 WHERE id = $2`, [referralCode, userId]);
    }

    const shareUrl = `https://glowapp-frontend-production.up.railway.app/#/register?ref=${referralCode}`;
    const shareMessage = `¡Te regalo $10.000 COP para tu primer servicio de belleza en GlowApp! Usá mi código ${referralCode} o registrate aquí: ${shareUrl}`;

    res.json({
      success: true,
      referral_code: referralCode,
      share_url: shareUrl,
      share_message: shareMessage,
      reward_per_referral: 10000,
    });
  } catch (error) {
    console.error('❌ ERROR GET REFERRAL INFO:', error.message);
    res.status(500).json({ error: 'Error al obtener información de referidos' });
  }
};

// ==========================================
// ⚖️ CUMPLIMIENTO APPLE APP STORE 5.1.1(v): ELIMINACIÓN DE CUENTA DE USUARIO
// ==========================================
exports.deleteAccount = async (req, res) => {
  const userId = req.user.id;
  try {
    // 1. Anonimizar datos personales en la base de datos
    await pool.query(
      `UPDATE usuarios 
       SET nombre = 'Usuario Eliminado', 
           email = $1, 
           password_hash = '', 
           phone = NULL, 
           is_active = false,
           fcm_token = NULL
       WHERE id = $2`,
      [`deleted_${userId}_${Date.now()}@glowapp.deleted`, userId]
    );

    // 2. Revocar consentimientos biométricos activos si la tabla existe
    await pool.query(
      `UPDATE biometric_consents SET active = false, revoked_at = NOW() WHERE user_id = $1`,
      [userId]
    ).catch(() => {});

    console.log(`⚖️ [LEGAL COMPLIANCE] Cuenta de usuario ID ${userId} eliminada a solicitud del titular.`);

        res.json({
          success: true,
          message: 'Tu cuenta y datos personales han sido eliminados de GlowApp exitosamente.'
        });
      } catch (error) {
        console.error('❌ Error al eliminar cuenta:', error.message);
        res.status(500).json({ error: 'Error al procesar la solicitud de eliminación de cuenta.' });
      }
    };

// ==========================================
// 🔐 CAMBIAR CONTRASEÑA (Usuario autenticado conoce contraseña actual)
// ==========================================
exports.changePassword = async (req, res) => {
      try {
        const userId = req.user.id;
        const { current_password, new_password } = req.body;

        if (!current_password || !new_password) {
          return res.status(400).json({ error: 'Contraseña actual y nueva contraseña son requeridas.' });
        }

        if (new_password.length < 6) {
          return res.status(400).json({ error: 'La nueva contraseña debe tener al menos 6 caracteres.' });
        }

        // Obtener hash actual del usuario
        const userRes = await pool.query(
          `SELECT password_hash, auth_provider FROM usuarios WHERE id = $1`,
          [userId]
        );

        if (userRes.rows.length === 0) {
          return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        const user = userRes.rows[0];

        // Solo permitir cambio de contraseña para usuarios LOCAL (no OAuth)
        if (user.auth_provider !== 'LOCAL') {
          return res.status(400).json({ 
            error: 'No se puede cambiar contraseña: usuario autenticado via OAuth. Use "Olvidé mi contraseña" en su proveedor.' 
          });
        }

        // Verificar contraseña actual
        const isValid = await bcrypt.compare(current_password, user.password_hash);
        if (!isValid) {
          return res.status(401).json({ error: 'Contraseña actual incorrecta.' });
        }

        // Hash de la nueva contraseña
        const hashedPassword = await bcrypt.hash(new_password, 10);
        await pool.query(
          `UPDATE usuarios SET password_hash = $1 WHERE id = $2`,
          [hashedPassword, userId]
        );

        // Opcional: invalidar otros tokens (excepto el actual) - requiere lista negra en Redis
        // Por ahora solo cambiamos el hash; el token actual sigue válido hasta expirar

        console.log(`🔐 [CHANGE PASSWORD] Contraseña cambiada exitosamente para usuario ID ${userId}`);

        res.json({
          success: true,
          message: 'Contraseña actualizada exitosamente.'
        });
      } catch (error) {
        console.error('❌ ERROR CHANGE PASSWORD:', error.message);
        res.status(500).json({ error: 'Error al cambiar contraseña' });
      }
    };

    // ==========================================
    // 🚪 CIERRE DE SESIÓN (LOGOUT & TOKEN BLACKLISTING)
// ==========================================
exports.logout = async (req, res) => {
  try {
    const authHeader = req.header('Authorization') || '';
    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7).trim() : null;

    if (token) {
      const decoded = jwt.decode(token);
      let ttl = 7 * 24 * 60 * 60; // 7 días por defecto
      if (decoded && decoded.exp) {
        const now = Math.floor(Date.now() / 1000);
        ttl = Math.max(decoded.exp - now, 60);
      }
      try {
        await redisClient.setEx(`beauty:token_blacklist:${token}`, ttl, 'revoked');
      } catch (redisErr) {
        console.warn('⚠️ No se pudo registrar token en la lista negra de Redis:', redisErr.message);
      }
    }

    res.json({
      success: true,
      message: 'Sesión cerrada exitosamente.'
    });
  } catch (error) {
    console.error('❌ ERROR LOGOUT:', error.message);
    res.status(500).json({ error: 'Error al cerrar sesión' });
  }
};

// ==========================================
// 🔑 SOLICITAR RECUPERACIÓN DE CONTRASEÑA (FORGOT PASSWORD OTP)
// ==========================================
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ error: 'El correo electrónico es obligatorio.' });
    }

    const cleanEmail = email.trim().toLowerCase();

    // Verificar si el usuario existe
    const userRes = await pool.query(
      `SELECT id, nombre FROM usuarios WHERE LOWER(email) = $1 AND auth_provider = 'LOCAL'`,
      [cleanEmail]
    );

    if (userRes.rows.length === 0) {
      // Retornar mensaje genérico por seguridad
      return res.json({
        success: true,
        message: 'Si el correo está registrado, recibirás un código OTP de recuperación.'
      });
    }

    // Generar código OTP de 6 dígitos aleatorio
    const crypto = require('crypto');
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Guardar OTP en Redis con TTL de 10 minutos (600s)
    try {
      await redisClient.setEx(`beauty:otp:${cleanEmail}`, 600, otp);
    } catch (redisErr) {
      console.warn('⚠️ Error guardando OTP en Redis:', redisErr.message);
    }

    console.log(`🔑 [PASSWORD RESET] Código OTP generado para ${cleanEmail}: ${otp}`);

    // Enviar correo transaccional con el código OTP
    try {
      await emailService.sendOtpEmail({
        to: cleanEmail,
        otp,
        userName: userRes.rows[0].nombre,
      });
    } catch (emailErr) {
      console.warn('⚠️ Error al enviar correo OTP:', emailErr.message);
    }

    res.json({
      success: true,
      message: 'Código de recuperación enviado a tu correo electrónico.',
      otp: process.env.NODE_ENV !== 'production' ? otp : undefined
    });
  } catch (error) {
    console.error('❌ ERROR FORGOT PASSWORD:', error.message);
    res.status(500).json({ error: 'Error al solicitar recuperación de contraseña' });
  }
};

// ==========================================
// 🔄 RESTABLECER CONTRASEÑA CON OTP (RESET PASSWORD)
// ==========================================
exports.resetPassword = async (req, res) => {
  try {
    const { email, otp, new_password } = req.body;

    if (!email || !otp || !new_password) {
      return res.status(400).json({ error: 'Email, OTP y nueva contraseña son requeridos.' });
    }

    if (new_password.length < 6) {
      return res.status(400).json({ error: 'La nueva contraseña debe tener al menos 6 caracteres.' });
    }

    const cleanEmail = email.trim().toLowerCase();

    // Validar OTP desde Redis
    let storedOtp = null;
    try {
      storedOtp = await redisClient.get(`beauty:otp:${cleanEmail}`);
    } catch (redisErr) {
      console.warn('⚠️ Error leyendo OTP de Redis:', redisErr.message);
    }

    if (!storedOtp || storedOtp !== otp.toString().trim()) {
      return res.status(400).json({ error: 'Código OTP inválido o expirado. Por favor solicita uno nuevo.' });
    }

    // Hash de la nueva contraseña y actualización en BD
    const hashedPassword = await bcrypt.hash(new_password, 10);
    await pool.query(
      `UPDATE usuarios SET password_hash = $1 WHERE LOWER(email) = $2 AND auth_provider = 'LOCAL'`,
      [hashedPassword, cleanEmail]
    );

    // Eliminar el OTP usado de Redis
    try {
      await redisClient.del(`beauty:otp:${cleanEmail}`);
    } catch (_) {}

    console.log(`✅ [PASSWORD RESET] Contraseña restablecida con éxito para ${cleanEmail}`);

    res.json({
      success: true,
      message: 'Contraseña actualizada exitosamente. Ya puedes iniciar sesión con tu nueva clave.'
    });
  } catch (error) {
    console.error('❌ ERROR RESET PASSWORD:', error.message);
    res.status(500).json({ error: 'Error al restablecer la contraseña' });
  }
};



