// backend/src/tests/tenantContext.test.js
//
// Prueba el CICLO DE VIDA de la transacción por petición sin necesidad de una
// base de datos real: se inyecta un pool falso que registra la secuencia de
// sentencias. Verifica lo que no se puede verificar por lectura:
//   - que se hace BEGIN y sobre todo COMMIT (no solo ROLLBACK),
//   - que set_config se llama con is_local = true,
//   - que la conexión SIEMPRE se libera, también en error,
//   - que con el flag desactivado no se abre ninguna conexión,
//   - que un error de la CADENA no se enmascara con un 500 del middleware.
//
// Las variables referenciadas dentro de jest.mock() deben llevar prefijo `mock`
// por la restricción de hoisting de jest (babel-plugin-jest-hoist).

const EventEmitter = require('events');

const mockLlamadas = [];
let mockFalloAlConectar = false;

const mockCliente = {
  query: async (text, params) => {
    mockLlamadas.push(params === undefined ? text : `${text} :: ${JSON.stringify(params)}`);
    return { rows: [] };
  },
  release: () => mockLlamadas.push('RELEASE'),
};

jest.mock('../config/db', () => ({
  pool: {
    connect: async () => {
      if (mockFalloAlConectar) throw new Error('sin conexión a la base de datos');
      return mockCliente;
    },
  },
}));

const tenantContext = require('../middleware/tenantContext');

function fakeRes() {
  const res = new EventEmitter();
  res.headersSent = false;
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

function activarFlag(valor) {
  if (valor === undefined) delete process.env.TENANT_TRANSACTION_PER_REQUEST;
  else process.env.TENANT_TRANSACTION_PER_REQUEST = valor;
}

describe('tenantContext — ciclo de vida de la transacción por petición', () => {
  beforeEach(() => {
    mockLlamadas.length = 0;
    mockFalloAlConectar = false;
    activarFlag(undefined);
  });

  afterAll(() => activarFlag(undefined));

  test('flag desactivado: passthrough, sin conexión ni transacción', async () => {
    const next = jest.fn();
    await tenantContext({ user: { id: 1, tenant_id: 7 } }, fakeRes(), next);

    expect(next).toHaveBeenCalledTimes(1);
    expect(mockLlamadas).toEqual([]);
  });

  test('sin req.user: passthrough aunque el flag esté activo', async () => {
    activarFlag('true');
    const next = jest.fn();
    await tenantContext({}, fakeRes(), next);

    expect(next).toHaveBeenCalledTimes(1);
    expect(mockLlamadas).toEqual([]);
  });

  test('sin tenant_id: passthrough aunque el flag esté activo', async () => {
    activarFlag('true');
    const next = jest.fn();
    await tenantContext({ user: { id: 1, tenant_id: null } }, fakeRes(), next);

    expect(next).toHaveBeenCalledTimes(1);
    expect(mockLlamadas).toEqual([]);
  });

  test('flag activo: BEGIN -> set_config(local) -> COMMIT -> RELEASE', async () => {
    activarFlag('true');
    const res = fakeRes();
    const next = jest.fn();

    const pendiente = tenantContext({ user: { id: 1, tenant_id: 7 } }, res, next);

    // El middleware queda esperando a que termine la respuesta.
    await new Promise((r) => setImmediate(r));
    expect(next).toHaveBeenCalledTimes(1);
    expect(mockLlamadas).toContain('BEGIN');

    res.emit('finish');
    await pendiente;

    expect(mockLlamadas[0]).toBe('BEGIN');
    expect(mockLlamadas[1]).toBe('SELECT set_config($1, $2, true) :: ["app.tenant_id","7"]');
    expect(mockLlamadas).toContain('COMMIT');
    expect(mockLlamadas[mockLlamadas.length - 1]).toBe('RELEASE');
    expect(mockLlamadas).not.toContain('ROLLBACK');
  });

  test('is_local es true (nunca false): el contexto no debe persistir en la conexión', async () => {
    activarFlag('true');
    const res = fakeRes();
    const pendiente = tenantContext({ user: { id: 1, tenant_id: 99 } }, res, jest.fn());
    await new Promise((r) => setImmediate(r));
    res.emit('finish');
    await pendiente;

    const setConfig = mockLlamadas.find((l) => l.startsWith('SELECT set_config'));
    expect(setConfig).toContain('true');
    expect(setConfig).not.toMatch(/, false\]/);
  });

  test('error en la cadena: ROLLBACK y RELEASE igualmente', async () => {
    activarFlag('true');
    const res = fakeRes();
    const error = new Error('fallo del controlador');

    // Modela Express con fidelidad: la PRIMERA llamada a next() entra en la
    // cadena y revienta; la segunda (next(error)) reenvía al manejador de
    // errores y por tanto NO lanza. Si el doble lanzara siempre, reproduciría
    // un fallo inexistente.
    let invocaciones = 0;
    const next = jest.fn(() => {
      invocaciones += 1;
      if (invocaciones === 1) throw error;
    });

    await tenantContext({ user: { id: 1, tenant_id: 3 } }, res, next);

    expect(mockLlamadas[0]).toBe('BEGIN');
    expect(mockLlamadas).toContain('ROLLBACK');
    expect(mockLlamadas[mockLlamadas.length - 1]).toBe('RELEASE');
    expect(mockLlamadas).not.toContain('COMMIT');
    // El error de la cadena NO debe convertirse en un 500 genérico del
    // middleware: debe reenviarse a Express con el error original.
    expect(res.status).not.toHaveBeenCalled();
    expect(next).toHaveBeenLastCalledWith(error);
  });

  test('fallo AL MONTAR la transacción: 500 (no se puede servir la petición)', async () => {
    activarFlag('true');
    mockFalloAlConectar = true;
    const res = fakeRes();
    const next = jest.fn();

    await tenantContext({ user: { id: 1, tenant_id: 4 } }, res, next);

    // No se cedió el control a la cadena...
    expect(next).not.toHaveBeenCalled();
    // ...y el fallo es del propio middleware, así que sí responde 500.
    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.json).toHaveBeenCalled();
  });

  test('desconexión del cliente (close): la transacción se cierra y se libera', async () => {
    activarFlag('true');
    const res = fakeRes();
    const pendiente = tenantContext({ user: { id: 1, tenant_id: 5 } }, res, jest.fn());

    await new Promise((r) => setImmediate(r));
    res.emit('close');
    await pendiente;

    expect(mockLlamadas[0]).toBe('BEGIN');
    expect(mockLlamadas).toContain('COMMIT');
    expect(mockLlamadas[mockLlamadas.length - 1]).toBe('RELEASE');
  });
});
