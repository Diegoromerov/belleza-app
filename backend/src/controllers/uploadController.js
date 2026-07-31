// backend/src/controllers/uploadController.js
const crypto = require('crypto');

const activeUploads = new Map();

exports.getSignedUploadUrl = async (req, res) => {
  try {
    const uploadId = `upl_${crypto.randomBytes(12).toString('hex')}`;
    const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minutos de validez

    const signedUrl = `https://storage.glowapp.com/temp-upload/${uploadId}?expires=${expiresAt}`;

    activeUploads.set(uploadId, {
      userId: req.user?.id || 'anonymous',
      createdAt: Date.now(),
      status: 'pending',
    });

    return res.status(200).json({
      success: true,
      data: {
        uploadId,
        signedUrl,
        expiresAt,
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

exports.processUpload = async (req, res) => {
  try {
    const { uploadId } = req.body;

    if (!uploadId || !activeUploads.has(uploadId)) {
      return res.status(404).json({ success: false, message: 'Upload ID inválido o expirado' });
    }

    // Simulación de procesamiento biométrico y purga efímera inmediata
    activeUploads.delete(uploadId);

    return res.status(200).json({
      success: true,
      message: 'Imagen procesada y purgada exitosamente del almacenamiento temporal.',
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
