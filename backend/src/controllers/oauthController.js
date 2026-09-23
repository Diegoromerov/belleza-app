// C:\beauty-app\backend\src\controllers\oauthController.js
const { OAuth2Client } = require('google-auth-library');
const jwt = require('jsonwebtoken');
const axios = require('axios');
const { pool } = require('../config/db');
const { getJwtSecret, toApiRole } = require('../config/jwt');

const DEFAULT_CLIENT_ID = '374223351186-0fukntsog02r0p1tofd2aju3c7lsr86j.apps.googleusercontent.com';

exports.googleSignIn = async (req, res) => {
  try {
    const { idToken, accessToken, role_intent } = req.body;
    if (!idToken && !accessToken) {
      return res.status(400).json({ error: 'Falta el idToken o accessToken de Google' });
    }

    let payload; // Declaración explícita: evita ReferenceError en modo estricto

    // Permitir token de prueba estrictamente en testing o con ALLOW_MOCK_AUTH === 'true'
    if ((process.env.NODE_ENV === 'test' || process.env.ALLOW_MOCK_AUTH === 'true') && idToken && idToken.startsWith('test_google_token_')) {
      const tokenSuffix = idToken.replace('test_google_token_', '');
      payload = {
        email: `${tokenSuffix}@gmail.com`,
        name: `User Google ${tokenSuffix}`,
        sub: `google_test_id_${tokenSuffix}`
      };
    } else if (idToken) {
      // PATH 1: Verificar idToken directamente (más seguro)
      const activeClientId = (process.env.GOOGLE_CLIENT_ID || DEFAULT_CLIENT_ID).trim();
      const oauthClient = new OAuth2Client(activeClientId);
      const ticket = await oauthClient.verifyIdToken({
        idToken: idToken,
        audience: [
          activeClientId,
          '374223351186-0fukntsog02r0p1tofd2aju3c7lsr86j.apps.googleusercontent.com',
          '374223351186-hi0m9k8778gfkg69spbkimgk73t51g5q.apps.googleusercontent.com',
          '466897054371-qaec2ipcc0pea91obs0ejcb9tene7kma.apps.googleusercontent.com'
        ].filter(Boolean)
      });
      payload = ticket.getPayload();
    } else {
      // PATH 2: Verificar accessToken via Google userinfo / tokeninfo API (fallback para GIS web flow)
      // google_sign_in_web 6.x con popup a veces solo devuelve accessToken, no idToken
      let userData;
      try {
        const userInfoRes = await axios.get('https://www.googleapis.com/oauth2/v3/userinfo', {
          headers: { Authorization: `Bearer ${accessToken}` }
        });
        userData = userInfoRes.data;
      } catch (err) {
        const tokenInfoRes = await axios.get(
          `https://oauth2.googleapis.com/tokeninfo?access_token=${encodeURIComponent(accessToken)}`
        ).catch(err2 => {
          throw new Error(`accessToken inválido: ${err2.response?.data?.error_description || err2.response?.data?.error || err2.message || err.message}`);
        });
        userData = tokenInfoRes.data;
      }

      if (!userData || !userData.email) {
        throw new Error('Google no devolvió email en la verificación del token');
      }
      payload = {
        email: userData.email,
        name: userData.name || userData.email,
        sub: userData.sub || userData.user_id
      };
    }

    const { email, name, sub: googleId } = payload;
    const cleanEmail = email.toLowerCase().trim();

    // Buscar si el usuario ya existe
    let userQuery = await pool.query('SELECT * FROM usuarios WHERE email = $1', [cleanEmail]);
    let user;

    if (userQuery.rows.length === 0) {
      // Determinar el rol según la intención enviada desde la UI
      const validRoles = ['CLIENTE', 'PRESTADOR', 'SALON'];
      const targetRole = (role_intent && validRoles.includes(role_intent.toUpperCase())) 
        ? role_intent.toUpperCase() 
        : null;
      const onboardingCompleto = targetRole === 'CLIENTE';

      const insertQuery = await pool.query(
        `INSERT INTO usuarios (nombre, email, auth_provider, provider_id, rol, onboarding_completo) 
         VALUES ($1, $2, 'GOOGLE', $3, $4, $5) 
         RETURNING id, nombre, email, rol, onboarding_completo`,
        [name || 'Usuario Google', cleanEmail, googleId, targetRole, onboardingCompleto]
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
      { id: user.id, email: user.email, role: toApiRole(user.rol), rol: user.rol },
      getJwtSecret(),
      { expiresIn: '24h' }
    );

    res.status(200).json({
      success: true,
      token: appToken,
      user: {
        id: user.id.toString(),
        full_name: user.nombre,
        email: user.email,
        role: toApiRole(user.rol),
        onboarding_completo: user.onboarding_completo
      }
    });

  } catch (error) {
    console.error('❌ ERROR GOOGLE SIGN-IN:', error.message);
    res.status(401).json({ 
      error: 'Autenticación de Google inválida o fallida',
      details: error.message
    });
  }
};
