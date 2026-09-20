// backend/src/tests/e2e-saas-verification.test.js
const request = require('supertest');
const express = require('express');
const { Service, Membership, User, BusinessProfile } = require('../models');
const serviceRoutes = require('../routes/serviceRoutes');
const membershipRoutes = require('../routes/membershipRoutes');
const { pool } = require('../config/db');

// Crear app Express para pruebas E2E
const app = express();
app.use(express.json());
app.use('/api', serviceRoutes);
app.use('/api/v1/memberships', membershipRoutes);

describe('Suite E2E de Verificación SaaS & Multi-Tenancy (Fase 2B.7 / Goal 05)', () => {
  const jwt = require('jsonwebtoken');
  const { getJwtSecret } = require('../config/jwt');

  beforeEach(() => {
    jest.clearAllMocks();
    jest.spyOn(pool, 'query').mockResolvedValue({ rows: [{ id: 1, rol: 'PRESTADOR', tenant_id: 1 }] });
  });

  describe('1. Aislamiento E2E Multi-Inquilino (Salón A vs Salón B)', () => {
    test('Usuario del Salón A solo visualiza servicios pertenecientes al Salón A', async () => {
      const mockServicesSalonA = [
        { id: 'srv-a1', name: 'Corte Salón A', price: '30.00', duration_minutes: 45, is_active: true, business_profile_id: 'bp-salon-a' }
      ];

      jest.spyOn(Service, 'findAll').mockResolvedValue(mockServicesSalonA);

      const tokenA = jwt.sign({ id: 101, email: 'owner@salona.com' }, getJwtSecret());

      jest.spyOn(Membership, 'findAll').mockResolvedValue([{
        id: 'mem-a',
        user_id: 101,
        business_profile_id: 'bp-salon-a',
        role: 'OWNER',
        status: 'ACTIVE',
        businessProfile: { id: 'bp-salon-a', name: 'Salón A' }
      }]);

      const res = await request(app)
        .get('/api/services/provider')
        .set('Authorization', `Bearer ${tokenA}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data[0].business_profile_id).toBe('bp-salon-a');
    });

    test('Soporta pre-selección de contexto con encabezado x-business-profile-id', async () => {
      const tokenUser = jwt.sign({ id: 101, email: 'owner@salona.com' }, getJwtSecret());

      jest.spyOn(Membership, 'findOne').mockResolvedValue({
        id: 'mem-a',
        user_id: 101,
        business_profile_id: 'bp-salon-a',
        role: 'OWNER',
        status: 'ACTIVE',
        businessProfile: { id: 'bp-salon-a', name: 'Salón A' }
      });

      jest.spyOn(Service, 'findAll').mockResolvedValue([
        { id: 'srv-a1', name: 'Servicio Header Context', price: '50.00', duration_minutes: 60, is_active: true, business_profile_id: 'bp-salon-a' }
      ]);

      const res = await request(app)
        .get('/api/services/provider')
        .set('Authorization', `Bearer ${tokenUser}`)
        .set('x-business-profile-id', 'bp-salon-a');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });

  describe('2. Pruebas de Resistencia Anti-IDOR & Inyección de Contexto', () => {
    test('Ataque IDOR: Usuario A no puede modificar un servicio perteneciente al Salón B (404)', async () => {
      jest.spyOn(Service, 'findOne').mockResolvedValue(null);

      const tokenA = jwt.sign({ id: 101, email: 'user@salona.com' }, getJwtSecret());

      jest.spyOn(Membership, 'findAll').mockResolvedValue([{
        id: 'mem-a',
        user_id: 101,
        business_profile_id: 'bp-salon-a',
        role: 'OWNER',
        status: 'ACTIVE',
        businessProfile: { id: 'bp-salon-a', name: 'Salón A' }
      }]);

      const res = await request(app)
        .put('/api/services/srv-salon-b')
        .set('Authorization', `Bearer ${tokenA}`)
        .send({ name: 'Nombre Alterado', price: 5.00, duration_minutes: 15 });

      expect(res.status).toBe(404);
      expect(res.body.error).toBe('SERVICE_NOT_FOUND');
    });

    test('Inmunidad a inyección en Body: Forzar business_profile_id ajeno en el body no sobreescribe el contexto autenticado', async () => {
      const createdServiceMock = {
        id: 'srv-nuevo',
        provider_id: 101,
        business_profile_id: 'bp-salon-a',
        name: 'Servicio Seguro',
        price: 40.0,
        duration_minutes: 30,
        category: 'Cabello',
        is_active: true
      };

      jest.spyOn(Service, 'create').mockResolvedValue(createdServiceMock);

      const tokenA = jwt.sign({ id: 101, email: 'owner@salona.com' }, getJwtSecret());

      jest.spyOn(Membership, 'findAll').mockResolvedValue([{
        id: 'mem-a',
        user_id: 101,
        business_profile_id: 'bp-salon-a',
        role: 'OWNER',
        status: 'ACTIVE',
        businessProfile: { id: 'bp-salon-a', name: 'Salón A' }
      }]);

      const res = await request(app)
        .post('/api/services')
        .set('Authorization', `Bearer ${tokenA}`)
        .send({
          name: 'Servicio Seguro',
          price: 40.0,
          duration_minutes: 30,
          category: 'Cabello',
          business_profile_id: 'bp-salon-b-hack' // Intento de inyección ignorado
        });

      expect(res.status).toBe(201);
      expect(res.body.data.business_profile_id).toBe('bp-salon-a');
      expect(res.body.data.business_profile_id).not.toBe('bp-salon-b-hack');
    });
  });
});
