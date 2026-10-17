/**
 * Contrato de `storeWebhook` (eventos de Wompi para pedidos de tienda).
 *
 * El handler leia el tipo de evento como `event.event.type`. Wompi manda
 * `"event": "transaction.updated"` como STRING (docs.wompi.co -> Eventos ->
 * Cuerpo de un evento), asi que `eventType` quedaba `undefined` y el handler
 * respondia 400 a TODO evento real: Wompi reintenta 3 veces (30 min, 3 h, 24 h)
 * y el pedido no se cerraba nunca. Se detecto probando el endpoint desplegado
 * con un evento firmado, no leyendo el codigo.
 */

jest.mock('../src/config/db', () => ({
  pool: { query: jest.fn() }
}));

jest.mock('../src/services/wompiClient', () => ({
  verifyEventChecksum: jest.fn(() => ({ valid: true }))
}));

jest.mock('../src/services/precioService', () => ({ resolverPrecio: jest.fn() }));
jest.mock('../src/services/shippingService', () => ({ cotizarEnvio: jest.fn() }));
jest.mock('../src/services/dianInvoiceClient', () => ({
  isConfigured: jest.fn(() => false),
  generarFactura: jest.fn()
}));

const express = require('express');
const request = require('supertest');
const { pool } = require('../src/config/db');
const wompiClient = require('../src/services/wompiClient');
const orderController = require('../src/controllers/orderController');

function app() {
  const a = express();
  a.use(express.json());
  a.post('/wh', orderController.storeWebhook);
  return a;
}

/** Evento con la forma EXACTA que documenta Wompi. */
function eventoWompi({ status = 'APPROVED', id = 'TX-1' } = {}) {
  return {
    event: 'transaction.updated',
    data: {
      transaction: {
        id,
        reference: 'wompi_order_8f14e45f-ceea-467f-a1c0-000000000001_1750000000000',
        status,
        amount_in_cents: 1815000,
        payment_method_type: 'DAVIPLATA'
      }
    },
    environment: 'test',
    signature: {
      properties: ['transaction.id', 'transaction.status', 'transaction.amount_in_cents'],
      checksum: 'cualquiera-lo-valida-el-mock'
    },
    timestamp: 1750000000
  };
}

beforeEach(() => {
  jest.clearAllMocks();
  pool.query.mockReset();
  pool.query.mockResolvedValue({ rows: [] });
  wompiClient.verifyEventChecksum.mockReturnValue({ valid: true });
});

describe('storeWebhook — formato real de los eventos de Wompi', () => {
  test('acepta el evento con `event` como STRING (200, no 400)', async () => {
    const res = await request(app()).post('/wh').send(eventoWompi());

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ success: true });
    // llego hasta la busqueda de la transaccion: el tipo de evento se reconocio
    const select = pool.query.mock.calls.find(([sql]) => /SELECT \* FROM transactions/i.test(sql));
    expect(select).toBeDefined();
    expect(select[1]).toEqual(['TX-1']);
  });

  test('tolera tambien el objeto {type} (compatibilidad)', async () => {
    const evento = eventoWompi();
    evento.event = { type: 'transaction.updated' };
    const res = await request(app()).post('/wh').send(evento);
    expect(res.status).toBe(200);
  });

  test('un cuerpo sin tipo de evento sigue respondiendo 400', async () => {
    const res = await request(app()).post('/wh').send({ data: { transaction: { id: 'X' } } });
    expect(res.status).toBe(400);
  });

  test('firma invalida responde 401 y no toca la base', async () => {
    wompiClient.verifyEventChecksum.mockReturnValue({ valid: false, reason: 'checksum no coincide' });
    const res = await request(app()).post('/wh').send(eventoWompi());
    expect(res.status).toBe(401);
    expect(pool.query).not.toHaveBeenCalled();
  });

  test('APPROVED marca el pedido PAGADO (busca por metadata->>wompi_external_id)', async () => {
    pool.query.mockImplementation((sql) => {
      if (/SELECT \* FROM transactions/i.test(sql)) {
        return Promise.resolve({ rows: [{ id: 'tx-local', status: 'pending', monto_total: 18150 }] });
      }
      if (/SELECT \* FROM pedidos_tienda/i.test(sql)) {
        return Promise.resolve({ rows: [{ id: 'order-1' }] });
      }
      return Promise.resolve({ rows: [] });
    });

    const res = await request(app()).post('/wh').send(eventoWompi());

    expect(res.status).toBe(200);
    const updatePedido = pool.query.mock.calls.find(
      ([sql]) => /UPDATE pedidos_tienda SET estado = 'PAGADO'/i.test(sql)
    );
    expect(updatePedido).toBeDefined();
    expect(updatePedido[1]).toEqual(['order-1']);

    const lookup = pool.query.mock.calls.find(([sql]) => /metadata->>'wompi_external_id'/i.test(sql));
    expect(lookup).toBeDefined();
    expect(lookup[1]).toEqual(['TX-1']);
  });

  test('DECLINED no marca el pedido como pagado', async () => {
    const res = await request(app()).post('/wh').send(eventoWompi({ status: 'DECLINED' }));
    expect(res.status).toBe(200);
    const update = pool.query.mock.calls.find(([sql]) => /UPDATE pedidos_tienda SET estado = 'PAGADO'/i.test(sql));
    expect(update).toBeUndefined();
  });
});
