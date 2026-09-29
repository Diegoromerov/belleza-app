const crypto = require('crypto');
const { getJwtSecret } = require('../config/jwt');

const ALGORITHM = 'aes-256-gcm';

/** Entornos donde NO se admite ninguna derivación de conveniencia. */
const esEntornoProductivo = () =>
  process.env.NODE_ENV === 'production' ||
  process.env.NODE_ENV === 'staging' ||
  !!process.env.RAILWAY_ENVIRONMENT;

/**
 * Clave LEGADA (anterior a C-11): clave fija para descifrar datos históricos cifrados
 * con la derivación legacy (sha256 del secret legacy). NO deriva de JWT_SECRET actual
 * para mantener aislamiento criptográfico (A360-2026-09-22/C-11, TEC-53/CI-14).
 * Ver backend/scripts/reencryptBiometricData.js
 */
const CLAVE_LEGADA = () => {
  const legacyKeyEnv = process.env.LEGACY_BIOMETRIC_KEY;
  if (!legacyKeyEnv) {
    throw new Error('LEGACY_BIOMETRIC_KEY no configurada para descifrado legacy');
  }
  // Soporta 64-char hex (32 bytes) o 32-char utf8
  if (/^[0-9a-fA-F]{64}$/.test(legacyKeyEnv.trim())) {
    return Buffer.from(legacyKeyEnv.trim(), 'hex');
  }
  if (Buffer.byteLength(legacyKeyEnv, 'utf8') === 32) {
    return Buffer.from(legacyKeyEnv, 'utf8');
  }
  throw new Error('LEGACY_BIOMETRIC_KEY debe ser 32 bytes (64 hex o 32 utf8)');
};

let activeCipherBuffer;

function initializeKey() {
  // La clave biométrica puede venir de su propia variable o, transitoriamente, de
  // ENCRYPTION_KEY (que ya existe en producción). Lo que NO puede es derivarse del
  // JWT_SECRET: con un solo secreto comprometido caían sesiones Y biometría
  // (A360-2026-09-22/C-11).
  const keyEnv = process.env.BIOMETRIC_ENCRYPTION_KEY || process.env.ENCRYPTION_KEY;
  if (!keyEnv || typeof keyEnv !== 'string') {
    if (esEntornoProductivo()) {
      throw new Error(
        'CRITICAL SECURITY ERROR: BIOMETRIC_ENCRYPTION_KEY no está configurada. ' +
        'El cifrado de datos biométricos no puede derivar del JWT_SECRET. ' +
        'Provisiona la clave (o ENCRYPTION_KEY) antes de arrancar; ver scripts/reencryptBiometricData.js.'
      );
    }
    console.warn('⚠️  [SECURITY WARNING] BIOMETRIC_ENCRYPTION_KEY desconfigurada — usando derivación solo para dev local.');
    const baseSecret = getJwtSecret();
    activeCipherBuffer = crypto.createHash('sha256').update(baseSecret).digest();
    return;
  }

  // Key must be 32 bytes for AES-256 (supports 64-char hex or 32-char utf8)
    let keyBuffer;
    if (/^[0-9a-fA-F]{64}$/.test(keyEnv.trim())) {
      keyBuffer = Buffer.from(keyEnv.trim(), 'hex');
    } else if (Buffer.byteLength(keyEnv, 'utf8') === 32) {
      keyBuffer = Buffer.from(keyEnv, 'utf8');
    } else {
      throw new Error('La clave biométrica debe ser de 32 bytes (64 hex o 32 utf8)');
    }

  if (keyBuffer.length !== 32) {
    throw new Error('La clave biométrica debe ser de 32 bytes');
  }
  activeCipherBuffer = keyBuffer;
}

// Initialize on module load
initializeKey();

class BiometricCryptoService {
  encrypt(data) {
    if (!data) return null;
    const text = typeof data === 'object' ? JSON.stringify(data) : String(data);

    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv(ALGORITHM, activeCipherBuffer, iv);

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
    const decipher = crypto.createDecipheriv(ALGORITHM, activeCipherBuffer, iv);
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

  /**
   * Descifra con la clave LEGADA (la que se derivaba de JWT_SECRET). Existe solo para
   * migrar los datos ya cifrados con ella antes de cambiar el origen de la clave.
   * Uso: backend/scripts/reencryptBiometricData.js (A360-2026-09-22/C-11).
   */
  decryptWithLegacyKey(encryptedString) {
    if (!encryptedString || typeof encryptedString !== 'string') return null;
    const parts = encryptedString.split(':');
    if (parts.length !== 3) throw new Error('Invalid ciphertext format');
    const [ivHex, authTagHex, encryptedText] = parts;
    const decipher = crypto.createDecipheriv(ALGORITHM, CLAVE_LEGADA(), Buffer.from(ivHex, 'hex'));
    decipher.setAuthTag(Buffer.from(authTagHex, 'hex'));
    let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    try {
      return JSON.parse(decrypted);
    } catch (_) {
      return decrypted;
    }
  }

  /** Huella de la clave activa: sirve para auditar con cuál se cifró cada registro. */
  keyFingerprint() {
    return crypto.createHash('sha256').update(activeCipherBuffer).digest('hex').slice(0, 8);
  }
}

module.exports = new BiometricCryptoService();