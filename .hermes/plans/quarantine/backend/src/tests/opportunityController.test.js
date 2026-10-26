// Jest tests for Opportunity controller
const request = require('supertest');
const app = require('../../index'); // Assuming index.js exports the Express app

// Mock auth middleware to inject req.user
jest.mock('../../src/middleware/auth', () => ({
  authMiddleware: (req, res, next) => {
    req.user = { id: 1, name: 'Test User' };
    next();
  },
}));

describe('Opportunity Controller', () => {
  it('should create an opportunity', async () => {
    const res = await request(app)
      .post('/api/saas/opportunities')
      .send({ title: 'Demo', leadId: 1, salonId: 1 })
      .expect(201);
    expect(res.body).toHaveProperty('id');
    expect(res.body.title).toBe('Demo');
  });

  it('should list opportunities', async () => {
    const res = await request(app)
      .get('/api/saas/opportunities')
      .expect(200);
    expect(res.body).toHaveProperty('total');
    expect(Array.isArray(res.body.data)).toBe(true);
  });
});
