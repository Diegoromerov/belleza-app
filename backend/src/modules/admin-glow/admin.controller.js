const adminModel = require('./admin.model');
const financialHelper = require('./financial.helper');

/**
 * Obtener todas las alertas SOS en estado 'ACTIVO'.
 */
async function getAllActiveAlerts(req, res) {
  try {
    const alerts = await adminModel.getActiveSOSAlerts();
    
    return res.status(200).json({
      success: true,
      count: alerts.length,
      data: alerts
    });
  } catch (error) {
    console.error('Error al obtener alertas SOS activas:', error);
    return res.status(500).json({
      success: false,
      error: 'Error interno al obtener las alertas de pánico activas.'
    });
  }
}

/**
 * Resolver una alerta SOS marcándola como 'ATENDIDA' y registrando la acción del operador.
 */
async function resolveSOSAlert(req, res) {
  try {
    const { id } = req.params;
    const adminId = req.admin.id; // Obtenido del middleware authAdmin

    if (!id) {
      return res.status(400).json({
        success: false,
        error: 'El identificador (ID) de la alerta es requerido.'
      });
    }

    // 1. Actualizar el estado de la alerta en sos_alerts
    await adminModel.updateSOSAlertStatus(id, 'ATENDIDO');

    // 2. Registrar la acción en la bitácora admin_actions
    await adminModel.logAdminAction(
      adminId,
      'RESOLVER_SOS',
      `Alerta SOS ID ${id} marcada como ATENDIDA por operador`
    );

    return res.status(200).json({
      success: true,
      message: `Alerta SOS #${id} resuelta exitosamente.`
    });
  } catch (error) {
    console.error('Error al resolver alerta SOS:', error);
    return res.status(500).json({
      success: false,
      error: 'Error interno al marcar la alerta como atendida.'
    });
  }
}

/**
 * Activar la verificación del perfil de un prestador para habilitar su etiqueta verde.
 */
async function verifyProvider(req, res) {
  try {
    const { providerId } = req.body;
    const adminId = req.admin.id;

    if (!providerId) {
      return res.status(400).json({
        success: false,
        error: 'El ID del prestador es obligatorio para realizar la verificación.'
      });
    }

    // 1. Actualizar estado a 'VERIFICADO' en perfiles_prestador
    await adminModel.setProviderVerifiedStatus(providerId, true);

    // 2. Registrar auditoría de la acción
    await adminModel.logAdminAction(
      adminId,
      'VERIFICAR_PRESTADOR',
      `Prestador ID ${providerId} marcado como VERIFICADO`
    );

    return res.status(200).json({
      success: true,
      message: `El prestador #${providerId} ha sido verificado con éxito.`
    });
  } catch (error) {
    console.error('Error al verificar prestador:', error);
    return res.status(500).json({
      success: false,
      error: 'Error interno al actualizar la verificación del prestador.'
    });
  }
}

/**
 * Aprueba una solicitud de retiro (Payout) si cumple con el saldo disponible y no hay disputas activas.
 */
async function approvePayout(req, res) {
  try {
    const { providerId, amount } = req.body;
    const adminId = req.admin.id;

    if (!providerId || !amount || parseFloat(amount) <= 0) {
      return res.status(400).json({
        success: false,
        error: 'El ID del prestador y un monto de retiro válido son obligatorios.'
      });
    }

    const withdrawAmount = parseFloat(amount);

    // 1. Validar disputas activas relacionadas con el prestador
    const hasDisputes = await adminModel.hasActiveDisputes(providerId);
    if (hasDisputes) {
      return res.status(400).json({
        success: false,
        error: 'Retiro retenido. El prestador posee disputas activas pendientes de resolución.'
      });
    }

    // 2. Validar que el saldo de la billetera sea suficiente
    const availableBalance = await adminModel.getProviderWalletBalance(providerId);
    if (availableBalance < withdrawAmount) {
      return res.status(400).json({
        success: false,
        error: `Saldo insuficiente. Saldo disponible actual: $${availableBalance}`
      });
    }

    // 3. Procesar el retiro debitando el saldo
    const newBalance = availableBalance - withdrawAmount;
    await adminModel.processWalletWithdrawal(providerId, withdrawAmount, newBalance);

    // 4. Registrar logs administrativos
    await adminModel.logAdminAction(
      adminId,
      'APROBAR_RETIRO',
      `Aprobado retiro de $${withdrawAmount} para prestador ID ${providerId}. Nuevo saldo: $${newBalance}`
    );

    return res.status(200).json({
      success: true,
      message: 'Retiro aprobado con éxito. Los fondos serán liberados en una ventana de 24 a 48 horas.',
      data: {
        providerId,
        montoRetirado: withdrawAmount,
        saldoRestante: newBalance,
        tiempoLiberacionEstimado: '24-48 horas'
      }
    });
  } catch (error) {
    console.error('Error al aprobar retiro de fondos:', error);
    return res.status(500).json({
      success: false,
      error: 'Error interno al procesar y aprobar el retiro del prestador.'
    });
  }
}

/**
 * Obtener todos los prestadores pendientes de verificación.
 */
async function getPendingProvidersList(req, res) {
  try {
    const list = await adminModel.getPendingProviders();
    return res.status(200).json({
      success: true,
      count: list.length,
      data: list
    });
  } catch (error) {
    console.error('Error al obtener prestadores pendientes:', error);
    return res.status(500).json({
      success: false,
      error: 'Error interno al obtener los prestadores pendientes.'
    });
  }
}

/**
 * Aprobar la verificación del perfil de un prestador.
 */
async function approveProvider(req, res) {
  try {
    const { providerId } = req.body;
    const adminId = req.admin.id;

    if (!providerId) {
      return res.status(400).json({
        success: false,
        error: 'El ID del prestador es obligatorio para realizar la aprobación.'
      });
    }

    await adminModel.setProviderVerifiedStatus(providerId, true);
    await adminModel.logAdminAction(
      adminId,
      'APROBAR_PRESTADOR',
      `Prestador ID ${providerId} verificado y APROBADO`
    );

    return res.status(200).json({
      success: true,
      message: `El prestador #${providerId} ha sido aprobado exitosamente.`
    });
  } catch (error) {
    console.error('Error al aprobar prestador:', error);
    return res.status(500).json({
      success: false,
      error: 'Error interno al aprobar prestador.'
    });
  }
}

/**
 * Rechazar la verificación del perfil de un prestador.
 */
async function rejectProvider(req, res) {
  try {
    const { providerId } = req.body;
    const adminId = req.admin.id;

    if (!providerId) {
      return res.status(400).json({
        success: false,
        error: 'El ID del prestador es obligatorio para realizar el rechazo.'
      });
    }

    await adminModel.setProviderVerifiedStatus(providerId, false);
    await adminModel.logAdminAction(
      adminId,
      'RECHAZAR_PRESTADOR',
      `Prestador ID ${providerId} RECHAZADO`
    );

    return res.status(200).json({
      success: true,
      message: `El prestador #${providerId} ha sido rechazado.`
    });
  } catch (error) {
    console.error('Error al rechazar prestador:', error);
    return res.status(500).json({
      success: false,
      error: 'Error interno al rechazar prestador.'
    });
  }
}

/**
 * Automatización de KYC (Mock): Aprueba y verifica inmediatamente un prestador.
 */
async function verifyProviderAuto(req, res) {
  try {
    const { providerId, documentType, documentNumber } = req.body;
    const adminId = req.admin ? req.admin.id : null; // Podría llamarse por un sistema automatizado/webhook

    if (!providerId) {
      return res.status(400).json({
        success: false,
        error: 'El ID del prestador es obligatorio para la verificación KYC.'
      });
    }

    // Simulamos que el mock KYC/OCR valida el documento
    if (documentNumber && documentNumber.trim() === 'INVALIDO') {
      await adminModel.setProviderVerifiedStatus(providerId, false);
      return res.status(422).json({
        success: false,
        error: 'El documento falló la validación KYC.'
      });
    }

    // 1. Aprobar y Verificar el prestador
    await adminModel.setProviderVerifiedStatus(providerId, true);

    // 2. Registrar auditoría si hay admin
    if (adminId) {
      await adminModel.logAdminAction(
        adminId,
        'KYC_AUTO_VERIFICACION',
        `Prestador ID ${providerId} aprobado automáticamente por KYC Mock`
      );
    }

    return res.status(200).json({
      success: true,
      message: `El prestador #${providerId} ha sido verificado automáticamente mediante KYC Mock.`
    });
  } catch (error) {
    console.error('Error al realizar auto-verificación KYC:', error);
    return res.status(500).json({
      success: false,
      error: 'Error interno al procesar auto-verificación KYC.'
    });
  }
}

module.exports = {
  getAllActiveAlerts,
  resolveSOSAlert,
  verifyProvider,
  approvePayout,
  getPendingProvidersList,
  approveProvider,
  rejectProvider,
  verifyProviderAuto
};
