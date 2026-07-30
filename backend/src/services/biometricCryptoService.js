// backend/src/services/biometricCryptoService.js
/**
 * Servicio de Cifrado Transparente para Datos Biométricos Sensibles (ADR-001 / GDPR Art. 9)
 * Implementa cifrado simétrico AES-256-GCM para proteger PII y métricas faciales 3D en reposo.
 */
const crypto = require('crypto');

const ALGORITHM = 'aes-256-gcm';
const SECRET_KEY = process.env.BIOMETRIC_ENCRYPTION_KEY || '12345678901234567890123456789012'; // 32 bytes key

class BiometricCryptoService {
  /**
   * Cifra un objeto o string biométrico sensible
   * @param {Object|string} data 
   * @returns {string} Payload cifrado en formato iv:authTag:encryptedData
   */
  encrypt(data) {
    if (!data) return null;
    const text = typeof data === 'object' ? JSON.stringify(data) : String(data);

    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv(ALGORITHM, Buffer.from(SECRET_KEY), iv);

    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');

    const authTag = cipher.getAuthTag().toString('hex');

    return `${iv.toString('hex')}:${authTag}:${encrypted}`;
  }

  /**
   * Descifra un payload biométrico cifrado
   * @param {string} encryptedString 
   * @returns {Object|string}
   */
  decrypt(encryptedString) {
    if (!encryptedString || typeof encryptedString !== 'string') return null;

    const parts = encryptedString.split(':');
    if (parts.length !== 3) return encryptedString; // Si no está cifrado, retornar como está

    const [ivHex, authTagHex, encryptedText] = parts;

    const iv = Buffer.from(ivHex, 'hex');
    const authTag = Buffer.from(authTagHex, 'hex');
    const decipher = crypto.createDecipheriv(ALGORITHM, Buffer.from(SECRET_KEY), iv);

    decipher.setAuthTag(authTag);

    let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
    decrypted += decipher.final('utf8');

    try {
      return JSON.parse(decrypted);
    } catch (_) {
      return decrypted;
    }
  }
}

module.exports = new BiometricCryptoService();
