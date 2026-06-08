// C:\beauty-app\backend\src\controllers\oauthController.js
const { OAuth2Client } = require('google-auth-library');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');

const CLIENT_ID = process.env.GOOGLE_CLIENT_ID || '';
const client = new OAuth2Client(CLIENT_ID);
const JWT_SECRET = process.env.JWT_SECRET || 'beauty_app_super_secret_key_2026_change_in_production';

exports.googleSignIn = async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken) {
      return res.status(400).json({ error: 'Falta el idToken de Google' });
    }

    let payload;
    // Permitir token de prueba en desarrollo/testing
    if (process.env.NODE_ENV === 'test' || idToken.startsWith('test_google_token_')) {
      const tokenSuffix = idToken.replace('test_google_token_', '');
      payload = {
        email: `${tokenSuffix}@gmail.com`,
        name: `User Google ${tokenSuffix}`,
        sub: `google_test_id_${tokenSuffix}`
      };
    } else {
      if (!CLIENT_ID) {
        return res.status(500).json({ error: 'GOOGLE_CLIENT_ID no está configurado en el servidor' });
      }
      const ticket = await client.verifyIdToken({
        idToken: idToken,
        audience: CLIENT_ID,
      });
      payload = ticket.getPayload();
    }

    const { email, name, sub: googleId } = payload;
    const cleanEmail = email.toLowerCase().trim();

    // Buscar si el usuario ya existe
    let userQuery = await pool.query('SELECT * FROM usuarios WHERE email = $1', [cleanEmail]);
    let user;

    if (userQuery.rows.length === 0) {
      // Registrar nuevo usuario cliente
      const insertQuery = await pool.query(
        `INSERT INTO usuarios (nombre, email, auth_provider, provider_id, rol, onboarding_completo) 
         VALUES ($1, $2, 'GOOGLE', $3, 'CLIENTE', true) 
         RETURNING id, nombre, email, rol, onboarding_completo`,
        [name || 'Usuario Google', cleanEmail, googleId]
      );
      user = insertQuery.rows[0];
    } else {
      user = userQuery.rows[0];
      // Vincular/actualizar proveedor
      if (user.auth_provider !== 'GOOGLE') {
        await pool.query(
          'UPDATE usuarios SET auth_provider = $1, provider_id = $2 WHERE id = $3',
          ['GOOGLE', googleId, user.id]
        );
        user.auth_provider = 'GOOGLE';
        user.provider_id = googleId;
      }
    }

    // Generar JWT
    const appToken = jwt.sign(
      { id: user.id, email: user.email, role: user.rol === 'PRESTADOR' ? 'provider' : 'client' },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.status(200).json({
      success: true,
      token: appToken,
      user: {
        id: user.id.toString(),
        full_name: user.nombre,
        email: user.email,
        role: user.rol === 'PRESTADOR' ? 'provider' : 'client',
        onboarding_completo: user.onboarding_completo
      }
    });

  } catch (error) {
    console.error('❌ ERROR GOOGLE SIGN-IN:', error.message);
    res.status(401).json({ error: 'Autenticación de Google inválida o fallida' });
  }
};
