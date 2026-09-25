const request = require('supertest');
const app = require('../../index');
const db = require('../config/db');

describe('Cargo 1 / C6 — Comportamiento de Bloqueo por Degradación en la Capa de Datos', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  test('C6: Superficie de datos (/api/products) responde 503 + X-GlowApp-Degraded cuando la base está degradada', async () => {
    jest.spyOn(db, 'getDbStatus').mockReturnValue({
      pgAvailable: false,
      servingFabricatedData: true,
      memoryFallbackAllowed: true
    });

    const res = await request(app).get('/api/products');

    expect(res.status).toBe(503);
    expect(res.headers['x-glowapp-degraded']).toBe('memory-fallback');
    expect(res.body).toHaveProperty('error', 'DATA_LAYER_DEGRADED');
  });

  test('C6: Ruta exenta (/api/health) responde 503 con estado DEGRADED propio cuando la base está degradada', async () => {
    jest.spyOn(db, 'getDbStatus').mockReturnValue({
      pgAvailable: false,
      servingFabricatedData: true,
      memoryFallbackAllowed: true
    });

    const res = await request(app).get('/api/health');

    expect(res.status).toBe(503);
    expect(res.body).toHaveProperty('status', 'DEGRADED');
  });

  test('C6: Ruta exenta (/api/providers) responde 503 con PROVIDER_SEARCH_DEGRADED propio cuando la base está degradada', async () => {
    jest.spyOn(db, 'getDbStatus').mockReturnValue({
      pgAvailable: false,
      servingFabricatedData: true,
      memoryFallbackAllowed: true
    });

    const res = await request(app).get('/api/providers');

    expect(res.status).toBe(503);
    expect(res.body).toHaveProperty('error', 'PROVIDER_SEARCH_DEGRADED');
  });

  test('C6: Superficie de datos responde normalmente sin 503 (DATA_LAYER_DEGRADED) cuando la capa de datos no está degradada', async () => {
    jest.spyOn(db, 'getDbStatus').mockReturnValue({
      pgAvailable: true,
      servingFabricatedData: false,
      memoryFallbackAllowed: false
    });

    const res = await request(app).get('/api/products');

    expect(res.status).not.toBe(503);
    if (res.body) {
      expect(res.body.error).not.toBe('DATA_LAYER_DEGRADED');
    }
  });
});
