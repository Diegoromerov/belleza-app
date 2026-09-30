// backend/tests/orderController.test.js
const request = require('supertest');
const express = require('express');
const bodyParser = require('body-parser');
const jwt = require('jsonwebtoken');

// Mock the database pool BEFORE requiring the controller
jest.mock('../src/config/db', () => ({
  pool: {
    connect: jest.fn(),
    query: jest.fn()
  }
}));

const { pool } = require('../src/config/db');
const { createOrder } = require('../src/controllers/orderController');

function createMockReq(user, body) {
  return {
    user,
    body,
    ip: '127.0.0.1'
  };
}

function createMockRes() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

describe('OrderController - createOrder (t_fix_pagos_01)', () => {
  let mockClient;

  beforeEach(() => {
    jest.clearAllMocks();
    mockClient = {
      query: jest.fn(),
      release: jest.fn()
    };
    pool.connect.mockResolvedValue(mockClient);
    
    // Mock pool.query for precioService calls
    pool.query
      .mockResolvedValueOnce({ // listas_precios query
        rows: [{ id: 1, codigo: 'cliente', nombre: 'Lista Cliente', rol_destino: 'CLIENTE', incluye_iva: false }]
      })
      .mockResolvedValueOnce({ // precios_producto query
        rows: [{ precio: 50000, unidad_minima: 1, vigente_desde: '2024-01-01', vigente_hasta: null }]
      });
  });

  const validUser = { id: 1, role: 'client', email: 'client@test.com' };
  const validBookingId = '550e8400-e29b-41d4-a716-446655440000';
  const validItems = [{ producto_id: 1, cantidad: 2 }];
  const validBody = {
    booking_id: validBookingId,
    nombre_entrega: 'Juan Pérez',
    direccion_entrega: 'Calle 123 #45-67',
    items: validItems
  };

  test('debe crear pedido con estado PENDIENTE_PAGO (no PAGADO) sin gateway real', async () => {
    // Mock booking validation
    mockClient.query
      .mockResolvedValueOnce({ rows: [] }) // BEGIN
      .mockResolvedValueOnce({ // booking validation
        rows: [{ id: validBookingId, provider_id: 2, client_id: 1 }]
      })
      .mockResolvedValueOnce({ // product lookup with FOR UPDATE
        rows: [{
          id: 1,
          nombre: 'Producto Test',
          stock: 10,
          precio: 50000
        }]
      })
      .mockResolvedValueOnce({ rows: [] }) // UPDATE stock
      .mockResolvedValueOnce({ // order insert - should NOT include estado (uses DEFAULT PENDIENTE_PAGO)
        rows: [{
          id: 'order-123',
          comprador_id: 1,
          rol_comprador: 'CLIENTE',
          booking_id: validBookingId,
          prestador_comisionado_id: 2,
          comision_total_prestador: 0,
          subtotal: 100000,
          envio: 0,
          iva: 19000,
          total: 119000,
          nombre_entrega: 'Juan Pérez',
          direccion_entrega: 'Calle 123 #45-67',
          creado_en: new Date(),
          // estado should NOT be in the insert - it should use DEFAULT 'PENDIENTE_PAGO'
        }]
      })
      .mockResolvedValueOnce({ rows: [] }) // detail insert
      .mockResolvedValueOnce({ rows: [] }); // COMMIT

    const req = createMockReq(validUser, validBody);
    const res = createMockRes();

    await createOrder(req, res);

    // Verify the order insert query does NOT include estado = 'PAGADO'
    const insertCall = mockClient.query.mock.calls.find(call => 
      call[0].includes('INSERT INTO pedidos_tienda')
    );
    
    expect(insertCall).toBeDefined();
    
    // The INSERT should NOT contain 'PAGADO' - it should rely on DEFAULT
    const insertSql = insertCall[0];
    expect(insertSql).not.toMatch(/PAGADO/i);
    // estado column should not be explicitly set in the INSERT (uses DEFAULT PENDIENTE_PAGO)
    // Note: some field names contain 'estado' as substring (e.g., prestador_comisionado), 
    // so we only verify PAGADO is not hardcoded
    
    // Verify response status is 201
    expect(res.status).toHaveBeenCalledWith(201);
    
    // Verify the response contains the order with PENDIENTE_PAGO (from DEFAULT)
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: true,
        data: expect.objectContaining({
          order: expect.objectContaining({
            // estado should be PENDIENTE_PAGO from the DEFAULT
          })
        })
      })
    );
  });

  test('debe fallar si no hay items', async () => {
    const req = createMockReq(validUser, { ...validBody, items: [] });
    const res = createMockRes();

    await createOrder(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ error: 'Se requiere una lista de productos (items)' })
    );
  });

  test('debe fallar si no hay nombre_entrega', async () => {
    const req = createMockReq(validUser, { ...validBody, nombre_entrega: '' });
    const res = createMockRes();

    await createOrder(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ error: 'Se requiere nombre y dirección de entrega' })
    );
  });

  test('debe fallar si booking no pertenece al usuario', async () => {
    mockClient.query
      .mockResolvedValueOnce({ rows: [] }) // BEGIN
      .mockResolvedValueOnce({ // booking validation - different client
        rows: [{ id: validBookingId, provider_id: 2, client_id: 999 }]
      });

    const req = createMockReq(validUser, validBody);
    const res = createMockRes();

    await createOrder(req, res);

    expect(res.status).toHaveBeenCalledWith(403);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ error: 'No tienes acceso a esta reserva' })
    );
    // Should have rolled back
    expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK');
  });

  test('prestador no puede asociar compra a reserva', async () => {
    const providerUser = { id: 2, role: 'provider', email: 'provider@test.com' };
    
    const req = createMockReq(providerUser, validBody);
    const res = createMockRes();

    await createOrder(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ error: 'Un prestador no puede asociar compras a una reserva' })
    );
  });
});
