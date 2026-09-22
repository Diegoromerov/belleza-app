// backend/src/utils/expressAsync.js
// Express 4 no propaga los rechazos de handlers `async` a `next(err)`: una promesa
// rechazada se convierte en `unhandledRejection` y, en Node >= 15, TERMINA EL PROCESO.
// En lugar de un 500 la API se caía (auditoría 2026-09-22, hallazgo T4 #3).

/** Envuelve un handler para que cualquier throw/reject llegue a next(err). */
const ah = (handler) => (req, res, next) => {
  try {
    return Promise.resolve(handler(req, res, next)).catch(next);
  } catch (err) {
    return next(err);
  }
};

/**
 * Envuelve TODAS las capas de un router ya declarado (rutas y middleware) sin
 * tocar cada handler: se aplica antes de exportar el router.
 */
const wrapRouterAsync = (router) => {
  if (!router || !Array.isArray(router.stack)) return router;
  for (const layer of router.stack) {
    if (layer.route && Array.isArray(layer.route.stack)) {
      for (const handlerLayer of layer.route.stack) {
        handlerLayer.handle = ah(handlerLayer.handle);
      }
    } else if (typeof layer.handle === 'function') {
      layer.handle = ah(layer.handle);
    }
  }
  return router;
};

module.exports = { ah, wrapRouterAsync };
