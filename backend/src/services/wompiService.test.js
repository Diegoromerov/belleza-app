/**
 * wompiService.test.js
 * Tests for idempotent reference token generation in Wompi service.
 * FASE C - Fix P0 DINERO: Referencias Wompi con Math.random() no son idempotentes.
 */

const wompiService = require('./wompiService');

// Mock the pool to avoid DB connections
jest.mock('../config/db', () => ({
  pool: {
    query: jest.fn().mockResolvedValue({ rows: [] })
  }
}));

describe('FASE C - Fix P0 DINERO: Idempotent reference token generation', () => {
  
  beforeEach(() => {
    jest.clearAllMocks();
    // Allow simulator in test environment
    process.env.NODE_ENV = 'test';
    process.env.ALLOW_PAYMENT_SIMULATOR = 'true';
  });

  afterEach(() => {
    delete process.env.ALLOW_PAYMENT_SIMULATOR;
    delete process.env.NODE_ENV;
  });

  describe('disbursePayout - idempotent reference tokens', () => {
    const testParams = {
      bookingId: 'booking-123',
      amount: 50000,
      nequiNumber: '3001234567',
      documentId: '1234567890'
    };

    test('should generate deterministic referenceToken for same inputs (TEST ROJO - expects Math.random issue)', async () => {
      // Call the function twice with same inputs
      await wompiService.disbursePayout(testParams.bookingId, testParams.amount, testParams.nequiNumber, testParams.documentId);
      await wompiService.disbursePayout(testParams.bookingId, testParams.amount, testParams.nequiNumber, testParams.documentId);

      // Wait for async operations to complete
      await new Promise(resolve => setTimeout(resolve, 1600));

      // Get the calls made to pool.query
      const calls = require('../config/db').pool.query.mock.calls;
      
      // Find INSERT calls with reference tokens
      const insertCalls = calls.filter(call => 
        call[0].includes('INSERT INTO transactions')
      );

      expect(insertCalls.length).toBeGreaterThanOrEqual(2);
      
      // Check if reference tokens are the same (idempotent)
      // pool.query(text, values) -> external_id es values[2]
      const ref1 = insertCalls[0][1][2];
      const ref2 = insertCalls[1][1][2];

      expect(typeof ref1).toBe('string');
      expect(ref1).toBeTruthy();
      
      // TEST ROJO: This will FAIL with Math.random() - tokens are different
      expect(ref1).toBe(ref2);
    });

    test('should generate different referenceTokens for different bookingIds', async () => {
      await wompiService.disbursePayout('booking-111', 50000, '3001234567', '1234567890');
      await wompiService.disbursePayout('booking-222', 50000, '3001234567', '1234567890');

      await new Promise(resolve => setTimeout(resolve, 1600));

      const calls = require('../config/db').pool.query.mock.calls;
      const insertCalls = calls.filter(call => 
        call[0].includes('INSERT INTO transactions')
      );

      expect(insertCalls.length).toBeGreaterThanOrEqual(2);
      
      const ref1 = insertCalls[0][1][2];
      const ref2 = insertCalls[1][1][2];
      
      // Different bookingIds should produce different reference tokens
      expect(typeof ref1).toBe('string');
      expect(typeof ref2).toBe('string');
      expect(ref1).not.toBe(ref2);
    });

    test('should generate different referenceTokens for different amounts', async () => {
      await wompiService.disbursePayout('booking-123', 50000, '3001234567', '1234567890');
      await wompiService.disbursePayout('booking-123', 75000, '3001234567', '1234567890');

      await new Promise(resolve => setTimeout(resolve, 1600));

      const calls = require('../config/db').pool.query.mock.calls;
      const insertCalls = calls.filter(call => 
        call[0].includes('INSERT INTO transactions')
      );

      expect(insertCalls.length).toBeGreaterThanOrEqual(2);
      
      const ref1 = insertCalls[0][1][2];
      const ref2 = insertCalls[1][1][2];
      
      // Different amounts should produce different reference tokens
      expect(typeof ref1).toBe('string');
      expect(typeof ref2).toBe('string');
      expect(ref1).not.toBe(ref2);
    });
  });

  describe('crearPayout - idempotent reference tokens', () => {
    const testParams = {
      retiroId: 'retiro-123',
      providerId: 'prov-456',
      amount: 100000,
      numeroCuenta: '123456789',
      banco: 'NEQUI',
      automatico: true
    };

    test('should generate deterministic referenceToken for same inputs (TEST ROJO - expects Math.random issue)', async () => {
      await wompiService.crearPayout(testParams);
      await wompiService.crearPayout(testParams);

      await new Promise(resolve => setTimeout(resolve, 1100));

      const calls = require('../config/db').pool.query.mock.calls;
      
      // Find UPDATE calls with reference tokens
      const updateCalls = calls.filter(call => 
        call[0].includes('UPDATE retiros') && call[0].includes('referencia_wompi')
      );

      expect(updateCalls.length).toBeGreaterThanOrEqual(2);
      
      // pool.query(text, values) -> referencia_wompi es values[1]
      const ref1 = updateCalls[0][1][1];
      const ref2 = updateCalls[1][1][1];

      expect(typeof ref1).toBe('string');
      expect(ref1).toBeTruthy();
      
      // TEST ROJO: This will FAIL with Math.random() - tokens are different
      expect(ref1).toBe(ref2);
    });

    test('should generate different referenceTokens for different retiroIds', async () => {
      await wompiService.crearPayout({ ...testParams, retiroId: 'retiro-111' });
      await wompiService.crearPayout({ ...testParams, retiroId: 'retiro-222' });

      await new Promise(resolve => setTimeout(resolve, 1100));

      const calls = require('../config/db').pool.query.mock.calls;
      const updateCalls = calls.filter(call => 
        call[0].includes('UPDATE retiros') && call[0].includes('referencia_wompi')
      );

      expect(updateCalls.length).toBeGreaterThanOrEqual(2);
      
      const ref1 = updateCalls[0][1][1];
      const ref2 = updateCalls[1][1][1];
      
      // Different retiroIds should produce different reference tokens
      expect(typeof ref1).toBe('string');
      expect(typeof ref2).toBe('string');
      expect(ref1).not.toBe(ref2);
    });

    test('should generate different referenceTokens for different amounts', async () => {
      await wompiService.crearPayout({ ...testParams, amount: 50000 });
      await wompiService.crearPayout({ ...testParams, amount: 75000 });

      await new Promise(resolve => setTimeout(resolve, 1100));

      const calls = require('../config/db').pool.query.mock.calls;
      const updateCalls = calls.filter(call => 
        call[0].includes('UPDATE retiros') && call[0].includes('referencia_wompi')
      );

      expect(updateCalls.length).toBeGreaterThanOrEqual(2);
      
      const ref1 = updateCalls[0][1][1];
      const ref2 = updateCalls[1][1][1];
      
      // Different amounts should produce different reference tokens
      expect(typeof ref1).toBe('string');
      expect(typeof ref2).toBe('string');
      expect(ref1).not.toBe(ref2);
    });
  });
});