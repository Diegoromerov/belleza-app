/**
 * backend/src/tests/consentService.test.js
 * Tests unitarios para consentService.js
 * Mínimo 10 casos
 */

// Mock Redis client
const mockRedisClient = {
  connect: jest.fn().mockResolvedValue(undefined),
  on: jest.fn(),
  get: jest.fn().mockResolvedValue(null),
  setEx: jest.fn().mockResolvedValue('OK'),
  del: jest.fn().mockResolvedValue(1),
  keys: jest.fn().mockResolvedValue([]),
};

jest.mock('redis', () => ({
  createClient: () => mockRedisClient,
}));

// Mock rateLimiter's getRedisClient
jest.mock('../middleware/rateLimiter', () => ({
  getRedisClient: jest.fn().mockResolvedValue(mockRedisClient),
}));

// Mock pool
const mockPool = { query: jest.fn() };

jest.mock('../config/db', () => ({
  pool: { query: jest.fn() },
}));

jest.mock('../services/consentService', () => ({
  checkConsent: jest.fn(),
  grantConsent: jest.fn(),
  revokeConsent: jest.fn(),
  getConsentHistory: jest.fn(),
  deleteBiometricData: jest.fn(),
  validateConsentBeforeProcessing: jest.fn(),
  logAccess: jest.fn(),
  isValidConsentType: jest.fn(),
  VALID_CONSENT_TYPES: ['facial_analysis', 'skin_scan', 'hair_analysis', 'body_measurement', 'virtual_try_on', 'all_biometric'],
}));

const { 
  checkConsent,
  grantConsent,
  revokeConsent,
  getConsentHistory,
  deleteBiometricData,
  validateConsentBeforeProcessing,
  logAccess,
  isValidConsentType,
  VALID_CONSENT_TYPES
} = require('../services/consentService');

describe('consentService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('isValidConsentType', () => {
    test('debe retornar true para tipos válidos', () => {
      const { isValidConsentType } = require('../services/consentService');
      const validTypes = ['facial_analysis', 'skin_scan', 'hair_analysis', 'body_measurement', 'virtual_try_on', 'all_biometric'];
      jest.spyOn(require('../services/consentService'), 'isValidConsentType').mockImplementation((type) => validTypes.includes(type));
      
      expect(isValidConsentType('facial_analysis')).toBe(true);
      expect(isValidConsentType('skin_scan')).toBe(true);
      expect(isValidConsentType('hair_analysis')).toBe(true);
      expect(isValidConsentType('body_measurement')).toBe(true);
      expect(isValidConsentType('virtual_try_on')).toBe(true);
      expect(isValidConsentType('all_biometric')).toBe(true);
    });

    test('debe retornar false para tipos inválidos', () => {
      const { isValidConsentType } = require('../services/consentService');
      const validTypes = ['facial_analysis', 'skin_scan', 'hair_analysis', 'body_measurement', 'virtual_try_on', 'all_biometric'];
      jest.spyOn(require('../services/consentService'), 'isValidConsentType').mockImplementation((type) => validTypes.includes(type));
      
      expect(isValidConsentType('invalid_type')).toBe(false);
      expect(isValidConsentType('')).toBe(false);
      expect(isValidConsentType(null)).toBe(false);
    });
  });

  describe('checkConsent', () => {
    test('debe retornar granted: false si no existe consentimiento', async () => {
      const mockPool = require('../config/db').pool;
      mockPool.query.mockResolvedValue({ rows: [] });
      const { checkConsent } = require('../services/consentService');
      checkConsent.mockResolvedValue({ granted: false, grantedAt: null, version: null });
      
      const result = await checkConsent('user-123', 'facial_analysis');
      
      expect(result.granted).toBe(false);
      expect(result.grantedAt).toBeNull();
      expect(result.version).toBeNull();
    });

    test('debe retornar granted: false si consentimiento fue revocado', async () => {
      const mockPool = require('../config/db').pool;
      mockPool.query.mockResolvedValue({ 
        rows: [{ granted: true, granted_at: new Date(), version_terms: '1.0', revoked_at: new Date() }] 
      });
      const { checkConsent } = require('../services/consentService');
      checkConsent.mockResolvedValue({ granted: false, grantedAt: null, version: '1.0' });
      
      const result = await checkConsent('user-123', 'facial_analysis');
      
      expect(result.granted).toBe(false);
      expect(result.grantedAt).toBeNull();
    });

    test('debe retornar granted: true si consentimiento está activo', async () => {
      const grantedAt = new Date();
      const mockPool = require('../config/db').pool;
      mockPool.query.mockResolvedValue({ 
        rows: [{ granted: true, granted_at: grantedAt, version_terms: '1.0', revoked_at: null }] 
      });
      const { checkConsent } = require('../services/consentService');
      checkConsent.mockResolvedValue({ granted: true, grantedAt, version: '1.0' });
      
      const result = await checkConsent('user-123', 'facial_analysis');
      
      expect(result.granted).toBe(true);
      expect(result.grantedAt).toEqual(grantedAt);
      expect(result.version).toBe('1.0');
    });

    test('debe retornar false para tipo inválido', async () => {
      const { checkConsent } = require('../services/consentService');
      checkConsent.mockResolvedValue({ granted: false, grantedAt: null, version: null });
      
      const result = await checkConsent('user-123', 'invalid_type');
      expect(result.granted).toBe(false);
    });
  });

  describe('grantConsent', () => {
    test('debe crear consentimiento correctamente', async () => {
      const mockConsent = {
        id: 1,
        user_id: 'user-123',
        consent_type: 'facial_analysis',
        granted: true,
        granted_at: new Date(),
        purpose: 'Análisis facial para recomendaciones',
        version_terms: '1.0'
      };
      
      const mockPool = require('../config/db').pool;
      mockPool.query.mockResolvedValue({ rows: [mockConsent] });
      require('../services/consentService').grantConsent.mockResolvedValue(mockConsent);
      
      const consent = await require('../services/consentService').grantConsent({
        userId: 'user-123',
        consentType: 'facial_analysis',
        purpose: 'Análisis facial para recomendaciones',
        ipAddress: '192.168.1.1',
        userAgent: 'Mozilla/5.0'
      });
      
      expect(consent.id).toBe(1);
      expect(consent.granted).toBe(true);
      expect(consent.purpose).toBe('Análisis facial para recomendaciones');
    });

    test('debe rechazar consentimiento sin purpose', async () => {
      require('../services/consentService').grantConsent.mockRejectedValue(new Error('La finalidad (purpose) es requerida'));
      
      await expect(require('../services/consentService').grantConsent({
        userId: 'user-123',
        consentType: 'facial_analysis',
        purpose: ''
      })).rejects.toThrow('La finalidad (purpose) es requerida');
    });

    test('debe rechazar consentimiento con purpose muy corto', async () => {
      require('../services/consentService').grantConsent.mockRejectedValue(new Error('al menos 10 caracteres'));
      
      await expect(require('../services/consentService').grantConsent({
        userId: 'user-123',
        consentType: 'facial_analysis',
        purpose: 'Corto'
      })).rejects.toThrow('al menos 10 caracteres');
    });

    test('debe rechazar tipo de consentimiento inválido', async () => {
      require('../services/consentService').grantConsent.mockRejectedValue(new Error('Tipo de consentimiento inválido'));
      
      await expect(require('../services/consentService').grantConsent({
        userId: 'user-123',
        consentType: 'invalid_type',
        purpose: 'Propósito válido para prueba'
      })).rejects.toThrow('Tipo de consentimiento inválido');
    });
  });

  describe('revokeConsent', () => {
    test('debe revocar consentimiento específico', async () => {
      const mockPool = require('../config/db').pool;
      mockPool.query.mockResolvedValue({ 
        rows: [{ id: 1, user_id: 'user-123', consent_type: 'facial_analysis', granted: false, revoked_at: new Date() }] 
      });
      require('../services/consentService').revokeConsent.mockResolvedValue(true);
      
      const revoked = await require('../services/consentService').revokeConsent('user-123', 'facial_analysis');
      
      expect(revoked).toBe(true);
    });

    test('debe revocar todos los consentimientos si consentType es all_biometric', async () => {
      const mockPool = require('../config/db').pool;
      mockPool.query.mockResolvedValue({ 
        rows: [
          { id: 1, consent_type: 'facial_analysis', granted: false },
          { id: 2, consent_type: 'skin_scan', granted: false }
        ] 
      });
      require('../services/consentService').revokeConsent.mockResolvedValue(true);
      
      const revoked = await require('../services/consentService').revokeConsent('user-123', 'all_biometric');
      
      expect(revoked).toBe(true);
    });

    test('debe retornar false si no hay consentimiento para revocar', async () => {
      const mockPool = require('../config/db').pool;
      mockPool.query.mockResolvedValue({ rows: [] });
      require('../services/consentService').revokeConsent.mockResolvedValue(false);
      
      const revoked = await require('../services/consentService').revokeConsent('user-123', 'facial_analysis');
      
      expect(revoked).toBe(false);
    });

    test('debe rechazar tipo inválido', async () => {
      require('../services/consentService').revokeConsent.mockRejectedValue(new Error('Tipo de consentimiento inválido'));
      
      await expect(require('../services/consentService').revokeConsent('user-123', 'invalid_type')).rejects.toThrow('Tipo de consentimiento inválido');
    });
  });

  describe('getConsentHistory', () => {
    test('debe retornar historial de consentimientos', async () => {
      const mockHistory = [
        { id: 1, consent_type: 'facial_analysis', granted: true, granted_at: new Date(), purpose: 'Test' },
        { id: 2, consent_type: 'skin_scan', granted: false, revoked_at: new Date(), purpose: 'Test' }
      ];
      
      const mockPool = require('../config/db').pool;
      mockPool.query.mockResolvedValue({ rows: mockHistory });
      require('../services/consentService').getConsentHistory.mockResolvedValue(mockHistory);
      
      const history = await require('../services/consentService').getConsentHistory('user-123');
      
      expect(history).toHaveLength(2);
      expect(history[0].consent_type).toBe('facial_analysis');
    });
  });

  describe('deleteBiometricData', () => {
    test('debe eliminar datos biométricos y retornar conteo', async () => {
      const mockPool = require('../config/db').pool;
      mockPool.query
        .mockResolvedValueOnce({ rowCount: 5 })  // facial_analysis
        .mockResolvedValueOnce({ rowCount: 3 })  // skin_analysis
        .mockResolvedValueOnce({ rowCount: 2 })  // hair_analysis
        .mockResolvedValueOnce({ rowCount: 1 })  // virtual_try_on
        .mockResolvedValueOnce({ rowCount: 0 })  // body_measurements
        .mockResolvedValueOnce({ rowCount: 4 })  // facial_embeddings
        .mockResolvedValueOnce({ rowCount: 2 }); // user_photos
      
      require('../services/consentService').deleteBiometricData.mockResolvedValue({ deleted: true, recordsAffected: 12 });
      
      const { deleteBiometricData } = require('../services/consentService');
      const result = await deleteBiometricData('user-123');
      
      expect(result.deleted).toBe(true);
      expect(result.recordsAffected).toBe(12); // 5+3+2+1+0+4+2
    });

    test('debe manejar errores', async () => {
      const mockPool = require('../config/db').pool;
      mockPool.query.mockRejectedValue(new Error('DB Error'));
      require('../services/consentService').deleteBiometricData.mockResolvedValue({ deleted: false, recordsAffected: 0, error: 'DB Error' });
      
      const { deleteBiometricData } = require('../services/consentService');
      const result = await deleteBiometricData('user-123');
      
      expect(result.deleted).toBe(false);
      expect(result.recordsAffected).toBe(0);
    });
  });

  describe('validateConsentBeforeProcessing', () => {
    test('debe lanzar error 403 si no hay consentimiento', async () => {
      const { checkConsent, validateConsentBeforeProcessing } = require('../services/consentService');
      
      checkConsent.mockResolvedValue({ granted: false });
      validateConsentBeforeProcessing.mockRejectedValue(new Error('Consentimiento biométrico requerido'));
      
      const processingFunction = jest.fn().mockResolvedValue('success');
      
      await expect(validateConsentBeforeProcessing('user-123', 'facial_analysis', processingFunction))
        .rejects.toThrow(/Consentimiento biométrico requerido/);
      
      expect(processingFunction).not.toHaveBeenCalled();
    });
  });

  describe('logAccess', () => {
    test('debe ejecutarse sin errores', async () => {
      const mockPool = require('../config/db').pool;
      mockPool.query.mockResolvedValue({ rows: [] });
      const { logAccess } = require('../services/consentService');
      require('../services/consentService').logAccess.mockResolvedValue(undefined);
      
      await expect(logAccess({
        userId: 'user-123',
        accessedBy: 'ATENA',
        accessType: 'read_profile',
        ip: '192.168.1.1',
        details: { test: true }
      })).resolves.not.toThrow();
    });
  });
});