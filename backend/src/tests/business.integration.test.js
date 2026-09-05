/**
 * GLOWAPP BUSINESS INTEGRATION TEST SUITE
 * Tests Business Engine REST API endpoints, diagnostic engine, and document generator.
 */

const request = require('supertest');
const { app } = require('../startup/app');

describe('GlowApp Business Engine Integration Tests', () => {
  let demoProviderId = 'demo-provider-test-100';

  test('GET /api/v1/business/verticals - Debería retornar el catálogo de verticales de belleza', async () => {
    const res = await request(app).get('/api/v1/business/verticals');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data.length).toBeGreaterThan(0);
    expect(res.body.data[0]).toHaveProperty('code');
  });

  test('POST /api/v1/business/diagnostic - Debería ejecutar el diagnóstico de Puerta 1 (NEGOCIO NUEVO)', async () => {
    const res = await request(app)
      .post('/api/v1/business/diagnostic')
      .send({
        provider_id: demoProviderId,
        name: 'Peluquería Test 100',
        onboarding_mode: 'NEW_BUSINESS',
        vertical_code: 'BEAUTY_SALON',
        city: 'Bogotá'
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.profile.onboarding_mode).toBe('NEW_BUSINESS');
    expect(res.body.data.profile.lifecycle_stage).toBe('CONSTITUTION');
    expect(Array.isArray(res.body.data.tasks)).toBe(true);
  });

  test('POST /api/v1/business/diagnostic - Debería ejecutar el diagnóstico de Puerta 2 (NEGOCIO EXISTENTE)', async () => {
    const res = await request(app)
      .post('/api/v1/business/diagnostic')
      .send({
        provider_id: 'existing-provider-200',
        name: 'Barbería Ya Existente',
        onboarding_mode: 'EXISTING_BUSINESS',
        vertical_code: 'BARBERSHOP',
        city: 'Medellín'
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.profile.onboarding_mode).toBe('EXISTING_BUSINESS');
    expect(res.body.data.profile.lifecycle_stage).toBe('AUDIT');
    expect(res.body.data.findings.length).toBeGreaterThan(0);
  });

  test('GET /api/v1/business/summary - Debería retornar el resumen de cumplimiento del negocio', async () => {
    const res = await request(app)
      .get('/api/v1/business/summary')
      .query({ provider_id: demoProviderId });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('compliance_score');
  });

  test('POST /api/v1/business/documents/generate - Debería generar un borrador documental con advertencia legal', async () => {
    const res = await request(app)
      .post('/api/v1/business/documents/generate')
      .send({
        template_code: 'TPL_LABOR_CONTRACT_BEAUTY',
        variables: {
          employer_name: 'Salón Éxito SAS',
          employee_name: 'Ana Pérez',
          job_title: 'Estilista Profesional',
          salary: '$ 2.000.000 COP'
        }
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.renderedBody).toContain('Salón Éxito SAS');
    expect(res.body.data.renderedBody).toContain('Ana Pérez');
    expect(res.body.data.disclaimer).toContain('ADVERTENCIA LEGAL');
  });
});
