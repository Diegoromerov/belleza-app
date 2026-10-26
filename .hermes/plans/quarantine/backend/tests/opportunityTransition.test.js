const request = require('supertest');
const app = require('../src/app'); // Ajusta la ruta si es necesario
const { Opportunity } = require('../src/models');

describe('POST /api/saas/opportunities/:id/transition', () => {
  it('debe actualizar el stage de la oportunidad', async () => {
    // Crear una oportunidad de prueba
    const opp = await Opportunity.create({
      title: 'Prueba',
      amount: 1000,
      stage: 'new',
    });
    const res = await request(app)
      .post(`/api/saas/opportunities/${opp.id}/transition`)
      .send({ stage: 'closed-won' })
      .expect(200);
    expect(res.body.stage).toBe('closed-won');
  });
});
