const crypto = require('crypto');
const path = require('path');
const ALGORITHM = 'aes-256-gcm';

describe('BiometricCryptoService - Hardening', () => {
  const validKey = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'; // 32 bytes

  beforeEach(() => {
    // Clean up environment variable
    delete process.env.BIOMETRIC_ENCRYPTION_KEY;
    jest.resetModules();
  });

  describe('encrypt() and decrypt() with valid key', () => {
    test('should encrypt and decrypt an object correctly', () => {
      process.env.BIOMETRIC_ENCRYPTION_KEY = validKey;
      const BiometricCryptoService = require(path.join(__dirname, 'biometricCryptoService.js'));
      const bcs = new BiometricCryptoService();
      const original = { hydration: 80, wrinkles: 10 };
      const encrypted = bcs.encrypt(original);
      expect(typeof encrypted).toBe('string');
      expect(encrypted.split(':').length).toBe(3);
      const decrypted = bcs.decrypt(encrypted);
      expect(decrypted).toEqual(original);
    });

    test('should encrypt and decrypt a string correctly', () => {
      process.env.BIOMETRIC_ENCRYPTION_KEY = validKey;
      const BiometricCryptoService = require(path.join(__dirname, 'biometricCryptoService.js'));
      const bcs = new BiometricCryptoService();
      const original = 'some string';
      const encrypted = bcs.encrypt(original);
      const decrypted = bcs.decrypt(encrypted);
      expect(decrypted).toBe(original);
    });

    test('should return null for null input', () => {
      process.env.BIOMETRIC_ENCRYPTION_KEY = validKey;
      const BiometricCryptoService = require(path.join(__dirname, 'biometricCryptoService.js'));
      const bcs = new BiometricCryptoService();
      expect(bcs.encrypt(null)).toBeNull();
      expect(bcs.decrypt(null)).toBeNull();
    });

    test('should return null for undefined input', () => {
      process.env.BIOMETRIC_ENCRYPTION_KEY = validKey;
      const BiometricCryptoService = require(path.join(__dirname, 'biometricCryptoService.js'));
      const bcs = new BiometricCryptoService();
      expect(bcs.encrypt(undefined)).toBeNull();
      expect(bcs.decrypt(undefined)).toBeNull();
    });

    test('should return null for empty string', () => {
      process.env.BIOMETRIC_ENCRYPTION_KEY = validKey;
      const BiometricCryptoService = require(path.join(__dirname, 'biometricCryptoService.js'));
      const bcs = new BiometricCryptoService();
      expect(bcs.encrypt('')).toBeNull();
      expect(bcs.decrypt('')).toBeNull();
    });
  });

  describe('Key validation', () => {
    test('should throw when BIOMETRIC_ENCRYPTION_KEY is missing', () => {
      delete process.env.BIOMETRIC_ENCRYPTION_KEY;
      expect(() => {
        require(path.join(__dirname, 'biometricCryptoService.js'));
      }).toThrow('BIOMETRIC_ENCRYPTION_KEY is required and must be a string');
    });

    test('should throw when BIOMETRIC_ENCRYPTION_KEY is not a string', () => {
      process.env.BIOMETRIC_ENCRYPTION_KEY = 123;
      expect(() => {
        require(path.join(__dirname, 'biometricCryptoService.js'));
      }).toThrow('BIOMETRIC_ENCRYPTION_KEY is required and must be a string');
    });

    test('should throw when BIOMETRIC_ENCRYPTION_KEY is not 32 bytes', () => {
      process.env.BIOMETRIC_ENCRYPTION_KEY = 'short'; // 5 bytes
      expect(() => {
        require(path.join(__dirname, 'biometricCryptoService.js'));
      }).toThrow('BIOMETRIC_ENCRYPTION_KEY must be 32 bytes long');
    });

    test('should throw when BIOMETRIC_ENCRYPTION_KEY is too long', () => {
      process.env.BIOMETRIC_ENCRYPTION_KEY = 'a'.repeat(33); // 33 bytes
      expect(() => {
        require(path.join(__dirname, 'biometricCryptoService.js'));
      }).toThrow('BIOMETRIC_ENCRYPTION_KEY must be 32 bytes long');
    });
  });

  describe('decrypt() error handling', () => {
    // Use a valid key for these tests
    beforeEach(() => {
      process.env.BIOMETRIC_ENCRYPTION_KEY = validKey;
      jest.resetModules();
    });

    test('should throw for invalid format (not three parts)', () => {
      const BiometricCryptoService = require(path.join(__dirname, 'biometricCryptoService.js'));
      const bcs = new BiometricCryptoService();
      expect(() => bcs.decrypt('invalid')).toThrow('Invalid ciphertext format');
      expect(() => bcs.decrypt('part1:part2')).toThrow('Invalid ciphertext format');
      expect(() => bcs.decrypt('part1:part2:part3:part4')).toThrow('Invalid ciphertext format');
    });

    test('should throw for invalid hex in iv', () => {
      const BiometricCryptoService = require(path.join(__dirname, 'biometricCryptoService.js'));
      const bcs = new BiometricCryptoService();
      // Create a valid ciphertext first to then tamper with the iv part
      const original = { test: 1 };
      const encrypted = bcs.encrypt(original);
      const [ivHex, authTagHex, encryptedText] = encrypted.split(':');
      // Change one character in the ivHex to non-hex
      const badIv = ivHex.slice(0, -1) + 'g'; // last char to 'g'
      const badEncrypted = `${badIv}:${authTagHex}:${encryptedText}`;
      expect(() => bcs.decrypt(badEncrypted)).toThrow();
    });

    test('should throw for invalid hex in authTag', () => {
      const BiometricCryptoService = require(path.join(__dirname, 'biometricCryptoService.js'));
      const bcs = new BiometricCryptoService();
      const original = { test: 1 };
      const encrypted = bcs.encrypt(original);
      const [ivHex, authTagHex, encryptedText] = encrypted.split(':');
      const badTag = authTagHex.slice(0, -1) + 'g';
      const badEncrypted = `${ivHex}:${badTag}:${encryptedText}`;
      expect(() => bcs.decrypt(badEncrypted)).toThrow();
    });

    test('should throw for corrupted ciphertext (auth tag mismatch)', () => {
      const BiometricCryptoService = require(path.join(__dirname, 'biometricCryptoService.js'));
      const bcs = new BiometricCryptoService();
      const original = { test: 1 };
      const encrypted = bcs.encrypt(original);
      const [ivHex, authTagHex, encryptedText] = encrypted.split(':');
      // Flip a bit in the encryptedText (change a hex digit)
      const corrupted = encryptedText.slice(0, -1) + (parseInt(encryptedText.slice(-1), 16) ^ 1).toString(16);
      const badEncrypted = `${ivHex}:${authTagHex}:${corrupted}`;
      expect(() => bcs.decrypt(badEncrypted)).toThrow();
    });

    test('should throw for invalid authentication tag (tampered)', () => {
      const BiometricCryptoService = require(path.join(__dirname, 'biometricCryptoService.js'));
      const bcs = new BiometricCryptoService();
      const original = { test: 1 };
      const encrypted = bcs.encrypt(original);
      const [ivHex, authTagHex, encryptedText] = encrypted.split(':');
      // Change the authTag
      const badTag = (parseInt(authTagHex, 16) ^ 1).toString(16).padStart(authTagHex.length, '0');
      const badEncrypted = `${ivHex}:${badTag}:${encryptedText}`;
      expect(() => bcs.decrypt(badEncrypted)).toThrow();
    });

    test('should not return the original ciphertext on decryption failure', () => {
      const BiometricCryptoService = require(path.join(__dirname, 'biometricCryptoService.js'));
      const bcs = new BiometricCryptoService();
      const original = { test: 1 };
      const encrypted = bcs.encrypt(original);
      // Tamper with the encrypted string
      const tampered = encrypted.slice(0, -1) + 'x';
      // Expect that decrypt throws, not returns the tampered string
      expect(() => bcs.decrypt(tampered)).toThrow();
      // Also, we can catch and ensure it doesn't return the tampered string
      try {
        bcs.decrypt(tampered);
        fail('Expected decrypt to throw');
      } catch (e) {
        expect(e).toBeInstanceOf(Error);
        // Ensure the error message is not the tampered string
        expect(e.message).not.toBe(tampered);
      }
    });
  });

  describe('Compatibility with existing data', () => {
    test('should produce ciphertext in the expected iv:authTag:encryptedData format', () => {
      process.env.BIOMETRIC_ENCRYPTION_KEY = validKey;
      const BiometricCryptoService = require(path.join(__dirname, 'biometricCryptoService.js'));
      const bcs = new BiometricCryptoService();
      const original = { test: 1 };
      const encrypted = bcs.encrypt(original);
      const parts = encrypted.split(':');
      expect(parts).toHaveLength(3);
      // Each part should be a hex string (only 0-9a-f)
      const hexRegex = /^[0-9a-f]+$/;
      expect(parts[0]).toMatch(hexRegex); // iv
      expect(parts[1]).toMatch(hexRegex); // authTag
      expect(parts[2]).toMatch(hexRegex); // encryptedData
      // Additionally, iv should be 24 hex chars (12 bytes), authTag 32 hex chars (16 bytes)
      expect(parts[0].length).toBe(24); // 12 bytes * 2
      expect(parts[1].length).toBe(32); // 16 bytes * 2
    });
  });
});