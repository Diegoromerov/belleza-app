const crypto = require('crypto');

const ALGORITHM = 'aes-256-gcm';

let SECRET_KEY;

function initializeKey() {
  const keyEnv = process.env.BIOMETRIC_ENCRYPTION_KEY;
  if (!keyEnv || typeof keyEnv !== 'string') {
    throw new Error('BIOMETRIC_ENCRYPTION_KEY is required and must be a string');
  }
  // Key must be 32 bytes for AES-256 (accepts utf8 string; we'll check byte length)
  const keyBuffer = Buffer.from(keyEnv, 'hex');
  if (keyBuffer.length !== 32) {
    throw new Error('BIOMETRIC_ENCRYPTION_KEY must be 32 bytes long');
  }
  SECRET_KEY = keyBuffer;
}

// Initialize on module load
initializeKey();

class BiometricCryptoService {
  encrypt(data) {
    if (!data) return null;
    const text = typeof data === 'object' ? JSON.stringify(data) : String(data);

    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv(ALGORITHM, SECRET_KEY, iv);

    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');

    const authTag = cipher.getAuthTag().toString('hex');

    return `${iv.toString('hex')}:${authTag}:${encrypted}`;
  }

  decrypt(encryptedString) {
    if (!encryptedString || typeof encryptedString !== 'string') {
      return null;
    }
    const parts = encryptedString.split(':');
    if (parts.length !== 3) {
      throw new Error('Invalid ciphertext format');
    }
    const [ivHex, authTagHex, encryptedText] = parts;
    const iv = Buffer.from(ivHex, 'hex');
    const authTag = Buffer.from(authTagHex, 'hex');
    const decipher = crypto.createDecipheriv(ALGORITHM, SECRET_KEY, iv);
    decipher.setAuthTag(authTag);

    let decrypted;
    try {
      decrypted = decipher.update(encryptedText, 'hex', 'utf8');
      decrypted += decipher.final('utf8');
    } catch (err) {
      throw new Error('Decryption failed');
    }

    try {
      return JSON.parse(decrypted);
    } catch (_) {
      return decrypted;
    }
  }
}

module.exports = new BiometricCryptoService();