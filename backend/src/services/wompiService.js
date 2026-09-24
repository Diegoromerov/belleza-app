const { pool } = require('../config/db');

/**
 * Realiza la dispersión de fondos simulada de forma asíncrona usando Nequi a través de Wompi.
 * @param {string} bookingId ID de la cita.
 * @param {number} amount Monto neto a transferir al prestador.
 * @param {string} nequiNumber Número telefónico / Nequi del prestador.
 * @param {string} documentId Cédula / Identidad del titular.
 */
exports.disbursePayout = async (bookingId, amount, nequiNumber, documentId) => {
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

      // Simular llamada exitosa de Wompi y generar una referencia aleatoria
      const referenceToken = 'wompi_ref_' + Math.random().toString(36).substring(2, 11).toUpperCase();

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
  // Simular la llamada de Wompi con latencia
  setTimeout(async () => {
    try {
      console.log(`\n💸 [WOMPI PAYOUT RETIRO] Procesando dispersión de retiro (${automatico ? 'AUTOMÁTICO' : 'DEMANDA'}):`);
      console.log(`   - Retiro ID: ${retiroId}`);
      console.log(`   - Prestador ID: ${providerId}`);
      console.log(`   - Monto: $${amount} COP`);
      console.log(`   - Banco/Método: ${banco}`);
      console.log(`   - Cuenta: ${numeroCuenta}`);

      const referenceToken = 'wompi_ret_' + Math.random().toString(36).substring(2, 11).toUpperCase();

      // Actualizar el estado del retiro a COMPLETADO y guardar el ID externo
      await pool.query(
        `UPDATE retiros 
         SET estado = 'COMPLETADO', 
             referencia_wompi = $2,
             procesado_at = NOW() 
         WHERE id = $1`,
        [retiroId, referenceToken]
      );

      // Actualizar el estado de la transacción en ledger a COMPLETADO
      await pool.query(
        `UPDATE wallet_transactions 
         SET estado = 'COMPLETADO', 
             metadata = metadata || $2::jsonb 
         WHERE provider_id = $1 
           AND tipo = 'DEBITO_RETIRO' 
           AND (metadata->>'retiro_id')::uuid = $3`,
        [providerId, JSON.stringify({ referencia_wompi: referenceToken }), retiroId]
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
      await pool.query(
        `UPDATE wallet_transactions 
         SET estado = 'FALLIDO' 
         WHERE provider_id = $1 
           AND tipo = 'DEBITO_RETIRO' 
           AND (metadata->>'retiro_id')::uuid = $2`,
        [providerId, retiroId]
      );
    }
  }, 1000);
};

/**
 * Ejecuta la reversión o reembolso de una transacción contra Wompi de forma idempotente.
 * @param {object} params Datos de la reversión
 * @returns {Promise<{success: boolean, status: string, external_refund_id?: string, is_idempotent?: boolean}>}
 */
exports.executeRefund = async ({ bookingId, transactionId, amount }) => {
  const privateKey = process.env.WOMPI_PRIVATE_KEY;
  const isSimulated = !privateKey || process.env.NODE_ENV === 'test' || process.env.NODE_ENV === 'development' || !transactionId || transactionId.startsWith('wompi_sim_');

  if (isSimulated) {
    // Simulación determinista local para tests y desarrollo
    if (transactionId === 'FORCE_TIMEOUT') {
      const err = new Error('Gateway Timeout');
      err.code = 'ETIMEDOUT';
      err.status = 504;
      throw err;
    }
    if (transactionId === 'FORCE_500') {
      const err = new Error('Internal Wompi Server Error');
      err.status = 500;
      throw err;
    }
    if (transactionId === 'FORCE_400') {
      const err = new Error('Invalid Request to Wompi');
      err.status = 400;
      err.isFatal = true;
      throw err;
    }
    if (transactionId === 'FORCE_ALREADY_VOIDED') {
      return {
        success: true,
        status: 'ALREADY_VOIDED',
        external_refund_id: 'void_sim_already_done',
        is_idempotent: true
      };
    }

    const mockRef = 'wompi_void_' + Math.random().toString(36).substring(2, 11).toUpperCase();
    return {
      success: true,
      status: 'APPROVED',
      external_refund_id: mockRef,
      is_idempotent: false
    };
  }

  // Integración HTTP real con Wompi API
  try {
    const https = require('https');
    const endpoint = `https://production.wompi.co/v1/transactions/${transactionId}/void`;

    return await new Promise((resolve, reject) => {
      const req = https.request(endpoint, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${privateKey}`,
          'Content-Type': 'application/json'
        },
        timeout: 10000
      }, (res) => {
        let body = '';
        res.on('data', chunk => body += chunk);
        res.on('end', () => {
          try {
            const parsed = JSON.parse(body || '{}');
            if (res.statusCode >= 200 && res.statusCode < 300) {
              resolve({
                success: true,
                status: 'APPROVED',
                external_refund_id: parsed.data ? parsed.data.id : transactionId
              });
            } else if (res.statusCode === 422 && parsed.error && (parsed.error.type === 'TRANSACTION_ALREADY_VOIDED' || parsed.error.type === 'ALREADY_REFUNDED')) {
              // Manejo de idempotencia: Si ya estaba reversada, se considera éxito
              resolve({
                success: true,
                status: parsed.error.type,
                external_refund_id: transactionId,
                is_idempotent: true
              });
            } else {
              const err = new Error(`Wompi Refund Error: ${res.statusCode} ${body}`);
              err.status = res.statusCode;
              err.isFatal = res.statusCode >= 400 && res.statusCode < 500 && res.statusCode !== 422;
              reject(err);
            }
          } catch (jsonErr) {
            reject(new Error(`Invalid JSON response from Wompi: ${body}`));
          }
        });
      });

      req.on('timeout', () => {
        req.destroy();
        const err = new Error('Wompi request timeout');
        err.code = 'ETIMEDOUT';
        err.status = 504;
        reject(err);
      });

      req.on('error', (err) => reject(err));
      req.end();
    });
  } catch (error) {
    throw error;
  }
};


