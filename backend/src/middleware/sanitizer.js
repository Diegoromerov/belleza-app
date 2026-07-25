/**
 * Middleware de sanitización de entradas para prevenir XSS y ataques de inyección.
 * Limpia automáticamente tags <script>, pseudo-protocolos javascript: y atributos event handlers.
 */
function sanitizeValue(value) {
  if (typeof value === 'string') {
    return value
      .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
      .replace(/javascript:/gi, '')
      .replace(/on\w+\s*=/gi, '');
  } else if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
    const sanitized = {};
    for (const key in value) {
      if (Object.prototype.hasOwnProperty.call(value, key)) {
        sanitized[key] = sanitizeValue(value[key]);
      }
    }
    return sanitized;
  } else if (Array.isArray(value)) {
    return value.map(sanitizeValue);
  }
  return value;
}

module.exports = (req, res, next) => {
  if (req.body) {
    req.body = sanitizeValue(req.body);
  }
  if (req.query) {
    req.query = sanitizeValue(req.query);
  }
  if (req.params) {
    req.params = sanitizeValue(req.params);
  }
  next();
};
