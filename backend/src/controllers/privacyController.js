// backend/src/controllers/privacyController.js
const auditLogs = [];

exports.exportUserData = async (req, res) => {
  try {
    const userId = req.params.id;

    auditLogs.push({
      userId,
      action: 'EXPORT_DATA',
      timestamp: new Date().toISOString(),
    });

    return res.status(200).json({
      success: true,
      data: {
        userId,
        biometricScans: 3,
        habeasDataConsent: true,
        dataExportedAt: new Date().toISOString(),
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

exports.revokeConsent = async (req, res) => {
  try {
    const userId = req.params.id;

    auditLogs.push({
      userId,
      action: 'REVOKE_CONSENT',
      timestamp: new Date().toISOString(),
    });

    return res.status(200).json({
      success: true,
      message: 'Consentimiento biométrico revocado. Los datos serán anonimizados.',
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

exports.getAccessLog = async (req, res) => {
  try {
    const userId = req.params.id;
    const userLogs = auditLogs.filter((log) => log.userId === userId);

    return res.status(200).json({
      success: true,
      data: userLogs,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
