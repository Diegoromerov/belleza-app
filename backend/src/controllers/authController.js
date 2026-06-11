const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');
const { getJwtSecret, toApiRole } = require('../config/jwt');

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
    if (process.env.ALLOW_MOCK_AUTH !== 'true' && process.env.NODE_ENV !== 'test') {
      return res.status(410).json({
        error: 'OAuth directo deshabilitado. Usa /api/auth/google u otro proveedor verificado o configure ALLOW_MOCK_AUTH=true.'
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
    res.status(500).json({ error: 'Error al procesar OAuth' });
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
      // Prestador requiere documentación y entra en PENDIENTE
      await pool.query(
        `UPDATE usuarios 
         SET rol = 'PRESTADOR', onboarding_completo = true,
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
      
      console.log(`📋 Onboarding y aceptación legal completados para Proveedor ID ${userId}. Esperando revisión.`);
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
        role: toApiRole(mappedRol),
        onboarding_completo: true
      }
    });

  } catch (err) {
    console.error('❌ ERROR ONBOARDING:', err.message);
    res.status(500).json({ error: 'Error al guardar onboarding' });
  }
};
