// Jest tests for Lead controller
const request = require('supertest');
const app = require('../../index'); // Assuming index.js exports the Express app

// Mock auth middleware to inject req.user
jest.mock('../../src/middleware/auth', () => ({
  authMiddleware: (req, res, next) => {
    req.user = { id: 1, name: 'Test User' };
    next();
  },
}));

describe('Lead Controller', () => {
  it('should create a lead', async () => {
    const res = await request(app)
      .post('/api/saas/leads')
      .send({ name: 'Cliente', email: 'test@example.com', salonId: 1 })
      .expect(201);
    expect(res.body).toHaveProperty('id');
    expect(res.body.name).toBe('Cliente');
  });

  it('should list leads', async () => {
    const res = await request(app)
      .get('/api/saas/leads')
      .expect(200);
    expect(res.body).toHaveProperty('total');
    expect(Array.isArray(res.body.data)).toBe(true);
  });
});
