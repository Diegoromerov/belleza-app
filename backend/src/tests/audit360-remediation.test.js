/**
 * audit360-remediation.test.js
 * Guardas de regresión de la remediación A360-2026-09-22.
 * No necesitan base de datos: son unidades puras + el escáner de credenciales.
 */
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const BACKEND = path.resolve(__dirname, '../..');
const leer = (rel) => fs.readFileSync(path.join(BACKEND, rel), 'utf8');
// Los comentarios citan el código viejo para explicar el arreglo: al buscar
// fabricaciones hay que mirar el CÓDIGO, no los comentarios.
const soloCodigo = (src) => src
  .split('\n')
  .filter((l) => !/^\s*(\/\/|\*|\/\*)/.test(l))
  .join('\n');

describe('A360 C-01 — el runner de migraciones no ejecuta rollbacks', () => {
  const { esMigracionAplicable } = require('../config/migrationRunner');

  test('excluye .down.sql y acepta el resto', () => {
    expect(esMigracionAplicable('035_fix_embedding_dimension_and_hnsw_index.down.sql')).toBe(false);
    expect(esMigracionAplicable('035_fix_embedding_dimension_and_hnsw_index.sql')).toBe(true);
    expect(esMigracionAplicable('001_init.sql')).toBe(true);
  });

  test('ningún rollback vivo dentro del directorio que escanea el arranque', () => {
    const enDirectorio = fs.readdirSync(path.join(BACKEND, 'migrations'))
      .filter((f) => f.endsWith('.down.sql'));
    expect(enDirectorio).toEqual([]);
  });

  test('los 6 runners excluyen explícitamente los rollbacks', () => {
    const runners = [
      'index.js',
      'check_and_migrate.js',
      'run_all_migrations.js',
      'run_migrations_ordered.js',
      'run_migrations_until_ready.js',
      'src/config/migrationRunner.js',
    ];
    for (const r of runners) {
      // Cada runner debe excluir .down.sql en su propio filtro.
      expect(leer(r)).toMatch(/endsWith\('\.down\.sql'\)/);
    }
  });
});

describe('A360 C-03 — la capa de datos no fabrica filas en silencio', () => {
  const db = require('../config/db');

  test('expone el estado degradado para /health', () => {
    const status = db.getDbStatus();
    expect(status).toHaveProperty('servingFabricatedData');
    expect(status).toHaveProperty('memoryFallbackAllowed');
    expect(status).toHaveProperty('pgAvailable');
  });

  test('sin opt-in, el fallback en memoria no está permitido', () => {
    const anterior = { ...process.env };
    delete process.env.ALLOW_MEMORY_FALLBACK;
    process.env.NODE_ENV = 'production';
    try {
      // Se re-evalúa el módulo con el entorno de producción.
      jest.isolateModules(() => {
        const dbProd = require('../config/db');
        expect(dbProd.getDbStatus().memoryFallbackAllowed).toBe(false);
      });
    } finally {
      process.env = anterior;
    }
  });

  test('en producción la consulta real no se sustituye por datos inventados', async () => {
    const src = leer('src/config/db.js');
    // El corto-circuito que dejaba el proceso en modo fixtures para siempre ya no existe.
    expect(src).not.toMatch(/if \(isPgAvailable === false\) \{\s*return handleMemoryQuery/);
    // Y `testConnection` no miente cuando no puede fallback.
    expect(src).toMatch(/console\.error\('❌ PostgreSQL no disponible:'/);
  });
});

describe('A360 C-04 — el WebSocket exige token', () => {
  const src = soloCodigo(leer('src/services/websocketService.js'));

  test('no existe registro por id plano', () => {
    expect(src).not.toMatch(/data\.userId/);
    expect(src).not.toMatch(/No token verification/);
  });

  test('valida pertenencia a la reserva y no confía en el providerId del payload', () => {
    expect(src).toMatch(/client_id = \$2 OR provider_id = \$2/);
    expect(src).not.toMatch(/data\.providerId/);
    expect(src).toMatch(/ws\.authenticatedUserId/);
  });
});

describe('A360 C-05 — no hay cobros fabricados', () => {
  test('el pago de cita devuelve 501 en producción', () => {
    const src = leer('src/controllers/bookingController.js');
    expect(src).toMatch(/PAYMENT_GATEWAY_NOT_INTEGRATED/);
  });

  test('los payouts simulados se rechazan en producción', () => {
    const src = leer('src/services/wompiService.js');
    expect(src).toMatch(/simuladorPermitido/);
    expect(src).toMatch(/rechazarSimulacion/);
  });

  test('la validación médica no afirma un pago verificado por Wompi', () => {
    const src = soloCodigo(leer('src/controllers/designsController.js'));
    expect(src).not.toMatch(/Pago de \$15\.000 COP verificado por Wompi/);
    expect(src).toMatch(/PAYMENT_GATEWAY_NOT_INTEGRATED/);
  });

  test('wompiService no llama a ninguna API real: por eso no puede marcar paid', () => {
    const src = leer('src/services/wompiService.js');
    const urls = src.match(/https?:\/\//g) || [];
    expect(urls.length).toBe(0);
  });
});

describe('A360 C-06 — nada de credenciales en logs', () => {
  test('authController no imprime la contraseña', () => {
    const src = leer('src/controllers/authController.js');
    expect(src).not.toMatch(/"Password:", password/);
  });

  test('el seed no imprime la clave ni la hardcodea', () => {
    const src = leer('../seed_glowapp_kb.js');
    expect(src).not.toMatch(/CLAVE REAL LEIDA/);
    expect(src).not.toMatch(/nvapi-[A-Za-z0-9_-]{10,}/);
  });

  test('el OTP no se registra ni se devuelve salvo opt-in explícito', () => {
    const src = leer('src/routes/paymentRoutes.js');
    expect(src).not.toMatch(/OTP para reserva/);
    expect(src).toMatch(/EXPOSE_DEV_OTP/);
  });
});

describe('A360 C-11 — clave biométrica fail-closed', () => {
  test('en producción sin clave, el módulo no arranca', () => {
    const anterior = { ...process.env };
    delete process.env.BIOMETRIC_ENCRYPTION_KEY;
    delete process.env.ENCRYPTION_KEY;
    process.env.NODE_ENV = 'production';
    try {
      jest.isolateModules(() => {
        expect(() => require('../services/biometricCryptoService')).toThrow(/BIOMETRIC_ENCRYPTION_KEY no está configurada/);
      });
    } finally {
      process.env = anterior;
    }
  });

  test('puede descifrar con la clave legada (necesario para migrar datos)', () => {
    const crypto = require('crypto');
    const service = require('../services/biometricCryptoService');
    expect(typeof service.decryptWithLegacyKey).toBe('function');
    // Cifrado con la derivación antigua (sha256 del JWT_SECRET de desarrollo).
    const claveLegada = crypto.createHash('sha256')
      .update(process.env.JWT_SECRET || 'glowapp_biometric_fallback_key_32_bytes!')
      .digest();
    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv('aes-256-gcm', claveLegada, iv);
    let ct = cipher.update(JSON.stringify({ glowScore: 81 }), 'utf8', 'hex');
    ct += cipher.final('hex');
    const payload = `${iv.toString('hex')}:${cipher.getAuthTag().toString('hex')}:${ct}`;
    expect(service.decryptWithLegacyKey(payload)).toEqual({ glowScore: 81 });
  });
});

describe('A360 C-12 — el caché semántico está aislado por identidad', () => {
  test('la clave depende de la identidad y hay índice por identidad', () => {
    const src = leer('src/services/semanticCache.js');
    expect(src).toMatch(/generateCacheKey\(embedding, identity/);
    expect(src).toMatch(/semantic:index:\$\{scope\}/);
    expect(src).toMatch(/entry\.identity !== identity/);
  });
});

describe('A360 A-17 — el orquestador está cerrado y su guard acota de verdad', () => {
  test('/api/ai/orchestrate exige autenticación y rol admin', () => {
    const router = require('../routes/aiOrchestratorRoutes');
    const capa = router.stack.find((l) => l.route && l.route.path === '/orchestrate');
    expect(capa).toBeDefined();
    expect(capa.route.stack.length).toBeGreaterThanOrEqual(3); // auth + admin + handler
  });

  test('el guard de rutas ya no resuelve a la raíz del sistema', () => {
    const src = soloCodigo(leer('src/services/ai/orchestrator.service.js'));
    expect(src).not.toMatch(/path\.resolve\(process\.cwd\(\), '\.\.\/\.\.\/'\)/);
    expect(src).toMatch(/repoRoot/);
  });
});

describe('A360 C-02 — escáner de credenciales versionadas', () => {
  test('no hay credenciales en archivos trackeados', () => {
    execFileSync('node', [path.join('scripts', 'verifyNoVersionedSecrets.js')], {
      cwd: BACKEND,
      stdio: 'pipe',
    });
  });
});
