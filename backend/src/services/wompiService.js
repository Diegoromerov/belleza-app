const { pool } = require('../config/db');
const crypto = require('crypto');

/**
 * Genera una referencia Wompi DETERMINISTA (idempotente) a partir de la clave de
 * negocio de la operación.
 *
 * Antes se usaba `Math.random()`, que no es idempotente ni garantiza unicidad:
 * un reintento del mismo pago generaba una referencia distinta, creando
 * dispersiones duplicadas y rompiendo la conciliación con Wompi.
 *
 * Ahora: misma operación -> misma referencia (un reintento es reconocible como el
 * mismo pago); operaciones distintas -> referencias distintas (colisión
 * despreciable con SHA-256 truncado a 16 hex / 64 bits).
 */
const generarReferenciaIdempotente = (prefijo, ...claves) => {
  const huella = crypto
    .createHash('sha256')
    .update(claves.map((clave) => String(clave)).join('|'))
    .digest('hex')
    .slice(0, 16)
    .toUpperCase();
  return `${prefijo}_${huella}`;
};

/**
 * El simulador de dispersión NO puede marcar dinero como pagado en producción sin
 * pasarela real: estas funciones generaban una referencia aleatoria y escribían
 * `transactions.status='paid'` / `retiros.estado='COMPLETADO'` sin llamar a Wompi
 * (A360-2026-09-22/C-05). El dinero "salía del sistema" sin salir.
 */
const simuladorPermitido = () =>
  process.env.NODE_ENV !== 'production' || process.env.ALLOW_PAYMENT_SIMULATOR === 'true';

const rechazarSimulacion = (etiqueta, id) => {
  throw new Error(
    `[WOMPI] Dispersión simulada de ${etiqueta} (${id}) rechazada: la pasarela real no está integrada ` +
    `y ALLOW_PAYMENT_SIMULATOR no está activo en producción.`
  );
};

/**
 * Realiza la dispersión de fondos simulada de forma asíncrona usando Nequi a través de Wompi.
 * @param {string} bookingId ID de la cita.
 * @param {number} amount Monto neto a transferir al prestador.
 * @param {string} nequiNumber Número telefónico / Nequi del prestador.
 * @param {string} documentId Cédula / Identidad del titular.
 */
exports.disbursePayout = async (bookingId, amount, nequiNumber, documentId) => {
  if (!simuladorPermitido()) rechazarSimulacion('pago al prestador', bookingId);
  // Desacoplado: Ejecutar en segundo plano simulando la latencia de red de la API de Wompi (1.5s)
  setTimeout(async () => {
    try {
      console.log(`\n💸 [WOMPI PAYOUT] Iniciando dispersión automática:`);
      console.log(`   - Cita ID: ${bookingId}`);
      console.log(`   - Monto Neto: $${amount} COP`);
      console.log(`   - Cuenta Nequi: ${nequiNumber}`);
      console.log(`   - Cédula Titular: ${documentId}`);

      if (!nequiNumber) {
        throw new Error('El prestador no tiene configurado un número de cuenta Nequi.');
      }

      // Referencia idempotente: misma cita + mismo monto => misma referencia Wompi
      const referenceToken = generarReferenciaIdempotente('wompi_ref', bookingId, amount);

      // Guardar registro de la transferencia en la tabla transactions
      const query = `
        INSERT INTO transactions (booking_id, amount, status, payment_method, external_id)
        VALUES ($1, $2, 'paid', 'NEQUI', $3)
        ON CONFLICT (booking_id) 
        DO UPDATE SET 
          amount = EXCLUDED.amount,
          status = 'paid', 
          payment_method = 'NEQUI',
          external_id = EXCLUDED.external_id;
      `;
      await pool.query(query, [bookingId, amount, referenceToken]);

      console.log(`✅ [WOMPI PAYOUT] Dispersión completada con éxito. Referencia: ${referenceToken} guardada en BD.`);
    } catch (err) {
      console.error(`❌ [WOMPI PAYOUT ERROR] Error al realizar el pago para la cita ${bookingId}:`, err.message);
      
      // Intentar guardar la transacción como fallida para auditoría
      try {
        const queryFailed = `
          INSERT INTO transactions (booking_id, amount, status, payment_method)
          VALUES ($1, $2, 'failed', 'NEQUI')
          ON CONFLICT (booking_id) 
          DO UPDATE SET status = 'failed';
        `;
        await pool.query(queryFailed, [bookingId, amount]);
      } catch (dbErr) {
        console.error(`❌ [WOMPI PAYOUT ERROR] No se pudo guardar estado de fallo en la BD:`, dbErr.message);
      }
    }
  }, 1500);
};

/**
 * Realiza un retiro / payout automático o por demanda a través de Wompi.
 * @param {object} params Datos del retiro
 */
exports.crearPayout = async ({ retiroId, providerId, amount, numeroCuenta, banco, automatico = false }) => {
  if (!simuladorPermitido()) rechazarSimulacion('retiro', retiroId);
  // Simular la llamada de Wompi con latencia
  setTimeout(async () => {
    try {
      console.log(`\n💸 [WOMPI PAYOUT RETIRO] Procesando dispersión de retiro (${automatico ? 'AUTOMÁTICO' : 'DEMANDA'}):`);
      console.log(`   - Retiro ID: ${retiroId}`);
      console.log(`   - Prestador ID: ${providerId}`);
      console.log(`   - Monto: $${amount} COP`);
      console.log(`   - Banco/Método: ${banco}`);
      console.log(`   - Cuenta: ${numeroCuenta}`);

      // Referencia idempotente: mismo retiro + prestador + monto => misma referencia
      const referenceToken = generarReferenciaIdempotente('wompi_ret', retiroId, providerId, amount);

      // Actualizar el estado del retiro a COMPLETADO y guardar el ID externo
      await pool.query(
        `UPDATE retiros 
         SET estado = 'COMPLETADO', 
             referencia_wompi = $2,
             procesado_at = NOW() 
         WHERE id = $1`,
        [retiroId, referenceToken]
      );

      // Registrar el desenlace del retiro como evento append-only (el ledger es inmutable)
      await pool.query(
        `INSERT INTO wallet_ledger_events (tx_id, provider_id, evento, detalle)
         SELECT wt.id, wt.provider_id, 'RETIRO_COMPLETADO',
                jsonb_build_object('referencia_wompi', $2::text)
         FROM wallet_transactions wt
         WHERE wt.provider_id = $1
           AND wt.tipo = 'DEBITO_RETIRO'
           AND (wt.metadata->>'retiro_id')::uuid = $3`,
        [providerId, referenceToken, retiroId]
      );

      console.log(`✅ [WOMPI PAYOUT RETIRO] Retiro ${retiroId} dispersado con éxito. Ref: ${referenceToken}`);
    } catch (err) {
      console.error(`❌ [WOMPI PAYOUT RETIRO ERROR] Fallo al dispersar retiro ${retiroId}:`, err.message);
      await pool.query(
        `UPDATE retiros 
         SET estado = 'FALLIDO', 
             error_wompi = $2,
             procesado_at = NOW() 
         WHERE id = $1`,
        [retiroId, err.message]
      );
      // Registrar el desenlace fallido como evento append-only
      await pool.query(
        `INSERT INTO wallet_ledger_events (tx_id, provider_id, evento, detalle)
         SELECT wt.id, wt.provider_id, 'RETIRO_FALLIDO',
                jsonb_build_object('error', $3::text)
         FROM wallet_transactions wt
         WHERE wt.provider_id = $1
           AND wt.tipo = 'DEBITO_RETIRO'
           AND (wt.metadata->>'retiro_id')::uuid = $2`,
        [providerId, retiroId, err.message]
      );
    }
  }, 1000);
};

