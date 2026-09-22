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

      // NO se fabrica un pago. Antes se escribía status = 'paid' con una
      // referencia generada con Math.random() y SIN llamar a Wompi: el dinero
      // constaba como transferido sin haberse transferido, y la única prueba
      // era un número inventado en la base de datos.
      // La dispersión real necesita la API de pagos de Wompi o la confirmación
      // manual del operador. Hasta entonces la fila queda 'pending' y el
      // external_id no se toca (no hay identificador real que guardar).
      // DO NOTHING en conflicto para NO degradar una transacción ya pagada.
      const query = `
        INSERT INTO transactions (booking_id, amount, status, payment_method)
        VALUES ($1, $2, 'pending', 'NEQUI')
        ON CONFLICT (booking_id) DO NOTHING;
      `;
      await pool.query(query, [bookingId, amount]);

      console.log(`⏳ [WOMPI PAYOUT] Dispersión registrada como PENDIENTE para el operador (cita ${bookingId}). No se ha transferido nada todavía.`);
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
  try {
    console.log(`\n💸 [WOMPI PAYOUT RETIRO] Registrando retiro para verificación manual (${automatico ? 'AUTOMÁTICO' : 'DEMANDA'}):`);
    console.log(`   - Retiro ID: ${retiroId}`);
    console.log(`   - Prestador ID: ${providerId}`);
    console.log(`   - Monto: $${amount} COP`);
    console.log(`   - Banco/Método: ${banco}`);
    console.log(`   - Cuenta: ${numeroCuenta}`);

    // Los retiros requieren integración directa con la API de dispersión de Wompi o procesamiento manual por el operador
    await pool.query(
      `UPDATE retiros 
       SET estado = 'PENDIENTE_MANUAL', 
           notas = 'Pendiente de dispersión bancaria manual o confirmación de pasarela',
           procesado_at = NOW() 
       WHERE id = $1`,
      [retiroId]
    );

    console.log(`⏳ [WOMPI PAYOUT RETIRO] Retiro ${retiroId} registrado como PENDIENTE_MANUAL para procesamiento bancario.`);
  } catch (err) {
    console.error(`❌ [WOMPI PAYOUT RETIRO ERROR] Fallo al registrar retiro ${retiroId}:`, err.message);
  }
};

