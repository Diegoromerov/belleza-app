const jwt = require('jsonwebtoken');

// Clave secreta obtenida de las variables de entorno o fallback seguro
const JWT_SECRET = process.env.JWT_SECRET || 'glowapp_super_secret_admin_key_2026';

/**
 * Middleware para proteger rutas administrativas.
 * Valida la existencia de un JWT válido y comprueba que el rol del usuario sea estrictamente 'ADMIN'.
 */
async function authAdmin(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Acceso no autorizado. Se requiere token Bearer.' });
    }

    const token = authHeader.split(' ')[1];
    
    // Verificar firma y expiración del JWT
    let decoded;
    try {
      decoded = jwt.verify(token, JWT_SECRET);
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        return res.status(401).json({ error: 'Sesión expirada. Por favor inicie sesión nuevamente.' });
      }
      return res.status(401).json({ error: 'Token de acceso inválido.' });
    }

    // Verificar que el payload del token contenga la información requerida
    if (!decoded || !decoded.id || !decoded.rol) {
      return res.status(401).json({ error: 'Token de acceso malformado o incompleto.' });
    }

    // Validar rol estrictamente 'ADMIN'
    if (decoded.rol.toUpperCase() !== 'ADMIN') {
      return res.status(403).json({ error: 'Acceso denegado. Se requieren permisos de administrador.' });
    }

    // Guardar los datos decodificados en el objeto de la petición (req)
    req.admin = {
      id: decoded.id,
      email: decoded.email,
      rol: decoded.rol
    };

    next();
  } catch (error) {
    console.error('Error en middleware authAdmin:', error);
    res.status(500).json({ error: 'Error interno al procesar autorización de administrador.' });
  }
}

module.exports = authAdmin;
