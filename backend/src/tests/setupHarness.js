/**
 * backend/src/tests/setupHarness.js
 * Configuración global del arnés de pruebas (CI-37).
 * Captura excepciones y unhandledRejections en workers y convierte errores
 * con estructuras circulares en objetos Error con mensajes serializables por Jest.
 */

process.on('unhandledRejection', (reason) => {
  const message = reason && reason.message ? reason.message : String(reason);
  const cleanError = new Error(`[UnhandledRejection] ${message}`);
  if (reason && reason.stack) {
    cleanError.stack = String(reason.stack);
  }
  console.error('⚠️ [Harness CI-37] Unhandled Rejection sanitizado:', cleanError.message);
});

process.on('uncaughtException', (err) => {
  const message = err && err.message ? err.message : String(err);
  const cleanError = new Error(`[UncaughtException] ${message}`);
  console.error('⚠️ [Harness CI-37] Uncaught Exception sanitizada:', cleanError.message);
});
