const jwt = require('jsonwebtoken');
const { getJwtSecret } = require('../../config/jwt');

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
      decoded = jwt.verify(token, getJwtSecret());
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        return res.status(401).json({ error: 'Sesión expirada. Por favor inicie sesión nuevamente.' });
      }
      return res.status(401).json({ error: 'Token de acceso inválido.' });
    }

    // Verificar que el payload del token contenga la información requerida
    const tokenRole = decoded.rol || decoded.role;
    if (!decoded || !decoded.id || !tokenRole) {
      return res.status(401).json({ error: 'Token de acceso malformado o incompleto.' });
    }

    // Validar rol estrictamente 'ADMIN'
    if (tokenRole.toUpperCase() !== 'ADMIN') {
      return res.status(403).json({ error: 'Acceso denegado. Se requieren permisos de administrador.' });
    }

    // Guardar los datos decodificados en el objeto de la petición (req)
    req.admin = {
      id: decoded.id,
      email: decoded.email,
      rol: 'ADMIN'
    };

    next();
  } catch (error) {
    console.error('Error en middleware authAdmin:', error);
    res.status(500).json({ error: 'Error interno al procesar autorización de administrador.' });
  }
}

module.exports = authAdmin;
