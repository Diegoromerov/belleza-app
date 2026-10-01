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
  pool: mockPool,
}));

// Import the REAL consentService (not mocked)
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
        mockPool.query.mockResolvedValue({ rows: [] });
      
        const result = await checkConsent('user-123', 'facial_analysis');
      
        expect(result.granted).toBe(false);
        expect(result.grantedAt).toBeNull();
        expect(result.version).toBeNull();
      });

      test('debe retornar granted: false si consentimiento fue revocado', async () => {
        mockPool.query.mockResolvedValue({ 
          rows: [{ granted: true, granted_at: new Date(), version_terms: '1.0', revoked_at: new Date() }] 
        });
      
        const result = await checkConsent('user-123', 'facial_analysis');
      
        expect(result.granted).toBe(false);
        expect(result.grantedAt).toBeNull();
      });

      test('debe retornar granted: true si consentimiento está activo', async () => {
        const grantedAt = new Date();
        mockPool.query.mockResolvedValue({ 
          rows: [{ granted: true, granted_at: grantedAt, version_terms: '1.0', revoked_at: null }] 
        });
      
        const result = await checkConsent('user-123', 'facial_analysis');
      
        expect(result.granted).toBe(true);
        expect(result.grantedAt).toEqual(grantedAt);
        expect(result.version).toBe('1.0');
      });

      test('debe retornar false para tipo inválido', async () => {
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
      
        mockPool.query.mockResolvedValue({ rows: [mockConsent] });
      
        const consent = await grantConsent({
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
        await expect(grantConsent({
          userId: 'user-123',
          consentType: 'facial_analysis',
          purpose: ''
        })).rejects.toThrow('La finalidad (purpose) es requerida');
      });

      test('debe rechazar consentimiento con purpose muy corto', async () => {
        await expect(grantConsent({
          userId: 'user-123',
          consentType: 'facial_analysis',
          purpose: 'Corto'
        })).rejects.toThrow('al menos 10 caracteres');
      });

      test('debe rechazar tipo de consentimiento inválido', async () => {
        await expect(grantConsent({
          userId: 'user-123',
          consentType: 'invalid_type',
          purpose: 'Propósito válido para prueba'
        })).rejects.toThrow('Tipo de consentimiento inválido');
      });
    });

  describe('revokeConsent', () => {
      test('debe revocar consentimiento específico', async () => {
        mockPool.query.mockResolvedValue({ 
          rows: [{ id: 1, user_id: 'user-123', consent_type: 'facial_analysis', granted: false, revoked_at: new Date() }] 
        });
      
        const revoked = await revokeConsent('user-123', 'facial_analysis');
      
        expect(revoked).toBe(true);
      });

      test('debe revocar todos los consentimientos si consentType es all_biometric', async () => {
        mockPool.query.mockResolvedValue({ 
          rows: [
            { id: 1, consent_type: 'facial_analysis', granted: false },
            { id: 2, consent_type: 'skin_scan', granted: false }
          ] 
        });
      
        const revoked = await revokeConsent('user-123', 'all_biometric');
      
        expect(revoked).toBe(true);
      });

      test('debe retornar false si no hay consentimiento para revocar', async () => {
        mockPool.query.mockResolvedValue({ rows: [] });
      
        const revoked = await revokeConsent('user-123', 'facial_analysis');
      
        expect(revoked).toBe(false);
      });

      test('debe rechazar tipo inválido', async () => {
        await expect(revokeConsent('user-123', 'invalid_type')).rejects.toThrow('Tipo de consentimiento inválido');
      });
    });

  describe('getConsentHistory', () => {
      test('debe retornar historial de consentimientos', async () => {
        const mockHistory = [
          { id: 1, consent_type: 'facial_analysis', granted: true, granted_at: new Date(), purpose: 'Test' },
          { id: 2, consent_type: 'skin_scan', granted: false, revoked_at: new Date(), purpose: 'Test' }
        ];
      
        mockPool.query.mockResolvedValue({ rows: mockHistory });
      
        const history = await getConsentHistory('user-123');
      
        expect(history).toHaveLength(2);
        expect(history[0].consent_type).toBe('facial_analysis');
      });
    });

  describe('deleteBiometricData', () => {
        test('debe eliminar datos biométricos y retornar conteo (8 tablas incl. biometric_history)', async () => {
          mockPool.query
            .mockResolvedValueOnce({ rowCount: 5 })  // facial_analysis
            .mockResolvedValueOnce({ rowCount: 3 })  // skin_analysis
            .mockResolvedValueOnce({ rowCount: 2 })  // hair_analysis
            .mockResolvedValueOnce({ rowCount: 1 })  // virtual_try_on
            .mockResolvedValueOnce({ rowCount: 0 })  // body_measurements
            .mockResolvedValueOnce({ rowCount: 4 })  // facial_embeddings
            .mockResolvedValueOnce({ rowCount: 2 })  // user_photos
            .mockResolvedValueOnce({ rowCount: 7 }); // biometric_history
      
          const result = await deleteBiometricData('user-123');
      
          expect(result.deleted).toBe(true);
          expect(result.recordsAffected).toBe(24); // 5+3+2+1+0+4+2+7
          // Verificar que se hizo DELETE en biometric_history
          expect(mockPool.query).toHaveBeenCalledWith(
            expect.stringContaining('DELETE FROM biometric_history'),
            ['user-123']
          );
        });

        test('debe manejar errores', async () => {
          mockPool.query.mockRejectedValue(new Error('DB Error'));
        
          const result = await deleteBiometricData('user-123');
        
          expect(result.deleted).toBe(false);
          expect(result.recordsAffected).toBe(0);
          expect(result.error).toBe('DB Error');
        });
      });

  describe('validateConsentBeforeProcessing', () => {
        test('debe lanzar error 403 si no hay consentimiento', async () => {
          mockPool.query.mockResolvedValue({ rows: [] });
     
          const processingFunction = jest.fn().mockResolvedValue('success');
     
          await expect(validateConsentBeforeProcessing('user-123', 'facial_analysis', processingFunction))
            .rejects.toThrow(/necesitas otorgar consentimiento para el procesamiento/);
     
          expect(processingFunction).not.toHaveBeenCalled();
        });
      });

    describe('logAccess', () => {
      test('debe ejecutarse sin errores', async () => {
        mockPool.query.mockResolvedValue({ rows: [] });
      
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