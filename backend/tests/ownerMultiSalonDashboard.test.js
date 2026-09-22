const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');

const JWT_SECRET = 'test_secret_key_2026_at_least_32_chars_long';
process.env.JWT_SECRET = JWT_SECRET;

const { pool } = require('../src/config/db');
const ownerRoutes = require('../src/routes/ownerRoutes');
const ownerController = require('../src/controllers/ownerController');

const app = express();
app.use(express.json());
app.use('/api/v1/owner', ownerRoutes);

describe('Fase 3: Multi-Sede OWNER Dashboard & Endpoints Integration Tests', () => {
  let originalQuery;

  beforeAll(() => {
    originalQuery = pool.query;
  });

  afterEach(() => {
    pool.query = originalQuery;
  });

  test('GET /api/v1/owner/salones debe retornar las sedes del propietario con total de colaboradores', async () => {
    const ownerToken = jwt.sign({ id: 10, role: 'SALON', email: 'owner@salonglow.com' }, JWT_SECRET);

    pool.query = jest.fn().mockImplementation((text, params) => {
      if (/SELECT rol, tenant_id FROM usuarios/i.test(text)) {
        return Promise.resolve({ rows: [{ rol: 'SALON', tenant_id: 1 }] });
      }
      if (/SELECT DISTINCT s\.id[\s\S]*FROM salones s/i.test(text)) {
        return Promise.resolve({ rows: [{ id: 1 }, { id: 2 }] });
      }
      if (/SELECT s\.id, s\.nombre_salon[\s\S]*FROM salones s/i.test(text)) {
        return Promise.resolve({
          rows: [
            {
              id: 1,
              nombre_salon: 'Sede Norte',
              id_dueno: 10,
              total_colaboradores: '3',
            },
            {
              id: 2,
              nombre_salon: 'Sede Sur',
              id_dueno: 10,
              total_colaboradores: '2',
            },
          ],
        });
      }
      return Promise.resolve({ rows: [] });
    });

    const res = await request(app)
      .get('/api/v1/owner/salones')
      .set('Authorization', `Bearer ${ownerToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.salones).toHaveLength(2);
    expect(res.body.salones[0].total_colaboradores).toBe(3);
    expect(res.body.salones[1].nombre_salon).toBe('Sede Sur');
  });

  test('GET /api/v1/owner/salones debe rebotar 403 a usuarios que no poseen ninguna sede', async () => {
    const userToken = jwt.sign({ id: 99, role: 'CLIENTE', email: 'cliente@gmail.com' }, JWT_SECRET);

    pool.query = jest.fn().mockImplementation((text, params) => {
      if (/SELECT rol, tenant_id FROM usuarios/i.test(text)) {
        return Promise.resolve({ rows: [{ rol: 'CLIENTE', tenant_id: null }] });
      }
      if (/SELECT DISTINCT s\.id[\s\S]*FROM salones s/i.test(text)) {
        return Promise.resolve({ rows: [] });
      }
      return Promise.resolve({ rows: [] });
    });

    const res = await request(app)
      .get('/api/v1/owner/salones')
      .set('Authorization', `Bearer ${userToken}`);

    expect(res.statusCode).toBe(403);
    expect(res.body.error).toContain('No tienes sedes registradas');
  });

  test('POST /api/v1/owner/switch-salon debe autorizar sedes propias y responder active_salon_id pasando por query, body o cabecera x-active-salon-id', async () => {
    const ownerToken = jwt.sign({ id: 10, role: 'SALON', email: 'owner@salonglow.com' }, JWT_SECRET);

    pool.query = jest.fn().mockImplementation((text, params) => {
      if (/SELECT rol, tenant_id FROM usuarios/i.test(text)) {
        return Promise.resolve({ rows: [{ rol: 'SALON', tenant_id: 1 }] });
      }
      if (/SELECT sub_rol[\s\S]*FROM salon_miembros/i.test(text)) {
        return Promise.resolve({ rows: [{ sub_rol: 'DUEÑO' }] });
      }
      return Promise.resolve({ rows: [] });
    });

    // Prueba 1: Vía body
    const resBody = await request(app)
      .post('/api/v1/owner/switch-salon')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ salon_id: 2 });

    expect(resBody.statusCode).toBe(200);
    expect(resBody.body.success).toBe(true);
    expect(resBody.body.active_salon_id).toBe(2);

    // Prueba 2: Vía cabecera x-active-salon-id
    const resHeader = await request(app)
      .post('/api/v1/owner/switch-salon')
      .set('Authorization', `Bearer ${ownerToken}`)
      .set('x-active-salon-id', '2');

    expect(resHeader.statusCode).toBe(200);
    expect(resHeader.body.active_salon_id).toBe(2);
  });

  test('GET /api/v1/owner/dashboard-metrics debe consultar columnas reales SQL, detectar prestadores cross-tenant y emitir advertencia', async () => {
    const ownerToken = jwt.sign({ id: 10, role: 'SALON', email: 'owner@salonglow.com' }, JWT_SECRET);
    let executedBookingsQuery = null;

    pool.query = jest.fn().mockImplementation((text, params) => {
      if (/SELECT rol, tenant_id FROM usuarios/i.test(text)) {
        return Promise.resolve({ rows: [{ rol: 'SALON', tenant_id: 1 }] });
      }
      if (/SELECT DISTINCT s\.id[\s\S]*FROM salones s/i.test(text)) {
        return Promise.resolve({ rows: [{ id: 1 }, { id: 2 }] });
      }
      if (/JOIN usuarios u/i.test(text)) {
        return Promise.resolve({
          rows: [
            { provider_id: 50, salon_id: 1, nombre_prestador: 'Carlos Mendoza' },
            { provider_id: 50, salon_id: 2, nombre_prestador: 'Carlos Mendoza' },
            { provider_id: 60, salon_id: 2, nombre_prestador: 'Sofía López' },
          ],
        });
      }
      if (/SELECT DISTINCT sm\.user_id AS provider_id/i.test(text)) {
        return Promise.resolve({ rows: [{ provider_id: 50 }, { provider_id: 60 }] });
      }
      // Detección cross-tenant
      if (/NOT\s*\(\s*sm\.salon_id\s*=\s*ANY/i.test(text)) {
        return Promise.resolve({
          rows: [{ provider_id: 50, salon_id: 99 }], // Prestador 50 tiene sede 99 en otro dueño
        });
      }
      if (/FROM bookings/i.test(text)) {
        executedBookingsQuery = text;
        return Promise.resolve({
          rows: [
            {
              id: 'b-101',
              provider_id: 50,
              valor_bruto: 100000,
              comision_plataforma: 20000,
              impuestos_estado: 8000,
              pago_neto_prestador: 72000,
              scheduled_at: '2026-09-20T10:00:00Z',
            },
            {
              id: 'b-102',
              provider_id: 60,
              valor_bruto: 50000,
              comision_plataforma: 10000,
              impuestos_estado: 4000,
              pago_neto_prestador: 36000,
              scheduled_at: '2026-09-21T14:00:00Z',
            },
          ],
        });
      }
      return Promise.resolve({ rows: [] });
    });

    const res = await request(app)
      .get('/api/v1/owner/dashboard-metrics')
      .set('Authorization', `Bearer ${ownerToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);

    expect(executedBookingsQuery).toBeDefined();
    expect(executedBookingsQuery).toContain('scheduled_at');
    expect(executedBookingsQuery).toContain('estado IN');

    const metrics = res.body.metrics;
    expect(metrics.ingresos_brutos).toBe(150000);
    expect(metrics.comision_plataforma).toBe(30000);
    expect(metrics.impuestos_estado).toBe(12000);
    expect(metrics.ingresos_netos_negocio).toBe(108000);
    expect(metrics.pago_neto_prestadores).toBe(108000);
    expect(metrics.total_citas).toBe(2);
    expect(metrics.sedes_compartidas).toBe(true);
    expect(metrics.prestadores_multinegocio).toBe(true);
    expect(metrics.prestadores_externos).toHaveLength(1);
    expect(metrics.advertencia).toContain('Los totales pueden incluir reservas de salones ajenos');
  });

  test('Test de Contrato de Esquema Estricto: aplica whitelist validBookingsColumns sobre el SELECT de bookings', async () => {
    const validBookingsColumns = [
      'id',
      'client_id',
      'provider_id',
      'service_id',
      'scheduled_at',
      'valor_bruto',
      'comision_plataforma',
      'impuestos_estado',
      'pago_neto_prestador',
      'estado',
      'pin_verificacion',
      'payment_status',
      'service_address',
      'tipo_via',
      'numero_via',
      'numero_placa',
      'numero_complemento',
      'complemento_interior',
      'barrio',
      'localidad',
      'notes',
      'created_at',
    ];

    let queryCaptured = '';
    pool.query = jest.fn().mockImplementation((text) => {
      if (/FROM salon_miembros/i.test(text)) {
        return Promise.resolve({
          rows: [{ provider_id: 50, salon_id: 1, nombre_prestador: 'Carlos Mendoza' }],
        });
      }
      if (/FROM bookings/i.test(text)) {
        queryCaptured = text;
        return Promise.resolve({ rows: [] });
      }
      return Promise.resolve({ rows: [] });
    });

    const req = {
      user: { id: 10 },
      ownedSalonIds: [1],
      query: { startDate: '2026-01-01', endDate: '2026-12-31' },
    };
    const res = { json: jest.fn(), status: jest.fn().mockReturnThis() };

    await ownerController.getDashboardMetrics(req, res);

    expect(queryCaptured).toBeDefined();

    // 1. Guardas rápidas contra nombres de columnas erróneas legadas
    expect(queryCaptured).not.toContain('fecha');
    expect(queryCaptured).not.toContain('estado_cita');
    expect(queryCaptured).not.toContain('monto_proveedor');

    // 2. Extracción y verificación activa de la whitelist en la cláusula SELECT
    const selectMatch = queryCaptured.match(/SELECT\s+([\s\S]+?)\s+FROM\s+bookings/i);
    expect(selectMatch).not.toBeNull();

    const selectClause = selectMatch[1];
    const selectedColumns = selectClause
      .split(',')
      .map((col) => col.trim().split(/\s+/)[0])
      .filter(Boolean);

    expect(selectedColumns.length).toBeGreaterThan(0);
    const isSelectSubset = selectedColumns.every((col) => validBookingsColumns.includes(col));
    expect(isSelectSubset).toBe(true);

    // 3. Extracción dinámica y verificación activa de la whitelist en la cláusula WHERE (sin lista hardcodeada)
    const whereMatch = queryCaptured.match(/WHERE\s+([\s\S]+?)$/i);
    expect(whereMatch).not.toBeNull();
    const cleanWhereText = whereMatch[1]
      .replace(/'[^']*'/g, '')
      .replace(/::[a-z0-9_]+/gi, '');

    const sqlKeywords = new Set(['and', 'or', 'any', 'in', 'not', 'is', 'null', 'select', 'from', 'where']);
    const rawTokens = cleanWhereText.match(/\b([a-z_][a-z0-9_]*)\b/gi) || [];
    const extractedWhereCols = Array.from(
      new Set(
        rawTokens
          .map((t) => t.toLowerCase())
          .filter((t) => !sqlKeywords.has(t) && isNaN(Number(t)))
      )
    );

    expect(extractedWhereCols.length).toBeGreaterThan(0);
    const unknownWhereCols = extractedWhereCols.filter((col) => !validBookingsColumns.includes(col));
    expect(unknownWhereCols).toEqual([]);
  });
});

// Test de Integración Gated con PostgreSQL real (se activa únicamente si TEST_DATABASE_URL está definida)
const runRealDbTests = process.env.TEST_DATABASE_URL ? describe : describe.skip;
runRealDbTests('Prueba de Integración SQL Real contra PostgreSQL (Gated)', () => {
  let testPool;

  beforeAll(async () => {
    const { Pool } = require('pg');
    testPool = new Pool({
      connectionString: process.env.TEST_DATABASE_URL,
      connectionTimeoutMillis: 3000,
    });
    // Intentar conexión real a PostgreSQL: falla si el host/puerto es inalcanzable
    await testPool.query('SELECT 1');
  });

  afterAll(async () => {
    if (testPool) {
      await testPool.end();
    }
  });

  test('Ejecuta consulta SQL real contra PostgreSQL y valida que las columnas del controlador existen en el esquema real de bookings', async () => {
    // 1. Obtener la consulta real generada por el controlador
    let queryCaptured = '';
    const tempReq = { user: { id: 10 }, ownedSalonIds: [1], query: {} };
    const tempRes = { json: jest.fn(), status: jest.fn().mockReturnThis() };

    const mockPool = {
      query: jest.fn().mockImplementation((text) => {
        if (/FROM salon_miembros/i.test(text)) {
          return Promise.resolve({ rows: [{ provider_id: 50, salon_id: 1, nombre_prestador: 'Carlos Mendoza' }] });
        }
        if (/FROM bookings/i.test(text)) {
          queryCaptured = text;
          return Promise.resolve({ rows: [] });
        }
        return Promise.resolve({ rows: [] });
      }),
    };

    const originalPoolQuery = pool.query;
    pool.query = mockPool.query;
    await ownerController.getDashboardMetrics(tempReq, tempRes);
    pool.query = originalPoolQuery;

    expect(queryCaptured).toBeDefined();

    // Extraer columnas de SELECT y WHERE
    const selectMatch = queryCaptured.match(/SELECT\s+([\s\S]+?)\s+FROM\s+bookings/i);
    const selectedCols = selectMatch[1].split(',').map((c) => c.trim().split(/\s+/)[0]);

    const whereMatch = queryCaptured.match(/WHERE\s+([\s\S]+?)$/i);
    const cleanWhereText = whereMatch[1]
      .replace(/'[^']*'/g, '')
      .replace(/::[a-z0-9_]+/gi, '');

    const sqlKeywords = new Set(['and', 'or', 'any', 'in', 'not', 'is', 'null']);
    const rawTokens = cleanWhereText.match(/\b([a-z_][a-z0-9_]*)\b/gi) || [];
    const whereCols = Array.from(new Set(rawTokens.map((t) => t.toLowerCase()).filter((t) => !sqlKeywords.has(t) && isNaN(Number(t)))));

    const allUsedCols = Array.from(new Set([...selectedCols, ...whereCols]));

    // 2. Consultar el esquema real de PostgreSQL
    const dbRes = await testPool.query(`
      SELECT column_name
        FROM information_schema.columns
       WHERE table_name = 'bookings'
    `);
    expect(dbRes.rows.length).toBeGreaterThan(0);
    const dbColumns = dbRes.rows.map((r) => r.column_name);

    // 3. Toda columna referenciada en la SQL del controlador debe existir en el esquema real de PostgreSQL
    const columnasDesconocidas = allUsedCols.filter((col) => !dbColumns.includes(col));
    expect(columnasDesconocidas).toEqual([]);
  });
});
