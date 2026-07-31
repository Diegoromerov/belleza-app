// backend/tests/health.test.js
const request = require('supertest');
const { app } = require('../src/startup/app');

describe('Healthcheck Endpoint Tests', () => {
  test('GET /api/health should return 200 and status OK', async () => {
    const res = await request(app).get('/api/health');
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('status');
    expect(res.body).toHaveProperty('timestamp');
  });
});
