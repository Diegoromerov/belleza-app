const crypto = require('crypto');

const ALGORITHM = 'aes-256-gcm';

/** Entornos donde NO se admite ninguna derivación de conveniencia. */
const esEntornoProductivo = () =>
  process.env.NODE_ENV === 'production' ||
  process.env.NODE_ENV === 'staging' ||
  !!process.env.RAILWAY_ENVIRONMENT;

/**
 * Clave LEGADA (anterior a C-11): se derivaba de JWT_SECRET. Solo existe para poder
 * descifrar y re-cifrar los datos que ya están en la base con ella.
 * Ver backend/scripts/reencryptBiometricData.js
 */
const CLAVE_LEGADA = () =>
  crypto.createHash('sha256')
    .update(process.env.JWT_SECRET || 'glowapp_biometric_fallback_key_32_bytes!')
    .digest();

let SECRET_KEY;

function initializeKey() {
  // La clave biométrica puede venir de su propia variable o, transitoriamente, de
  // ENCRYPTION_KEY (que ya existe en producción). Lo que NO puede es derivarse del
  // JWT_SECRET: con un solo secreto comprometido caían sesiones Y biometría
  // (A360-2026-09-22/C-11).
  const keyEnv = process.env.BIOMETRIC_ENCRYPTION_KEY || process.env.ENCRYPTION_KEY;
  if (!keyEnv || typeof keyEnv !== 'string') {
<<<<<<< HEAD
    if (process.env.NODE_ENV === 'production' || process.env.NODE_ENV === 'staging') {
      throw new Error('CRITICAL SECURITY ERROR: BIOMETRIC_ENCRYPTION_KEY no está configurada en el entorno.');
    }
    // En desarrollo local o testing se deriva desde un secreto de pruebas controlado
=======
    if (esEntornoProductivo()) {
      throw new Error(
        'CRITICAL SECURITY ERROR: BIOMETRIC_ENCRYPTION_KEY no está configurada. ' +
        'El cifrado de datos biométricos no puede derivar del JWT_SECRET. ' +
        'Provisiona la clave (o ENCRYPTION_KEY) antes de arrancar; ver scripts/reencryptBiometricData.js.'
      );
    }
    console.warn('⚠️  [SECURITY WARNING] BIOMETRIC_ENCRYPTION_KEY no configurada: usando derivación SOLO para desarrollo local.');
>>>>>>> origin/main
    const baseSecret = process.env.JWT_SECRET || 'dev_test_biometric_fallback_key_32_bytes!';
    SECRET_KEY = crypto.createHash('sha256').update(baseSecret).digest();
    return;
  }

  // Key must be 32 bytes for AES-256 (supports 64-char hex or 32-char utf8)
  let keyBuffer;
  if (/^[0-9a-fA-F]{64}$/.test(keyEnv.trim())) {
    keyBuffer = Buffer.from(keyEnv.trim(), 'hex');
  } else if (Buffer.byteLength(keyEnv, 'utf8') === 32) {
    keyBuffer = Buffer.from(keyEnv, 'utf8');
  } else {
    if (process.env.NODE_ENV === 'test') {
      throw new Error('BIOMETRIC_ENCRYPTION_KEY must be 32 bytes long');
    }
    keyBuffer = crypto.createHash('sha256').update(keyEnv).digest();
  }

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
    return crypto.createHash('sha256').update(SECRET_KEY).digest('hex').slice(0, 8);
  }
}

module.exports = new BiometricCryptoService();