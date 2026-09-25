const http = require('http');
const fs = require('fs');
const path = require('path');
const { DEGRADED_ALLOWLIST } = require('../src/middleware/degradedLock');

const PORT = process.env.PORT || 8080;
const BASE_URL = `http://127.0.0.1:${PORT}`;

function makeRequest(method, urlPath, headers = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(urlPath, BASE_URL);
    const req = http.request(url, { method, headers, timeout: 5000 }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        let parsed = null;
        try {
          parsed = JSON.parse(body);
        } catch (e) {
          parsed = body;
        }
        resolve({
          status: res.statusCode,
          headers: res.headers,
          body: parsed,
          rawBody: body
        });
      });
    });

    req.on('error', (err) => resolve({ error: err.message, status: 0 }));
    req.on('timeout', () => {
      req.destroy();
      resolve({ error: 'TIMEOUT', status: 0 });
    });
    req.end();
  });
}

async function runSmoke() {
  console.log('🔥 Ejecutando Smoke Test por Superficie (Fase A - Ronda 3)...');
  const routesFile = path.resolve(__dirname, '../../docs/audit/routes-2026-09-24.json');
  
  if (!fs.existsSync(routesFile)) {
    console.error('❌ No se encontró docs/audit/routes-2026-09-24.json. Ejecute node scripts/listRoutes.js primero.');
    process.exit(1);
  }

  const routes = JSON.parse(fs.readFileSync(routesFile, 'utf-8'));
  const safeRoutes = routes.filter(r => ['GET', 'HEAD', 'OPTIONS'].includes(r.method));

  let fakedSuccessCount = 0;
  const results = [];

  // Capturar estado degradado del servidor una sola vez al inicio mediante probes directos
  const healthRes = await makeRequest('GET', '/api/health');
  const testDbRes = await makeRequest('GET', '/api/test-db');

  const isServerDegraded = 
    healthRes.status === 503 ||
    healthRes.headers['x-glowapp-degraded'] === 'memory-fallback' ||
    (healthRes.body && healthRes.body.status === 'DEGRADED') ||
    (healthRes.body && healthRes.body.database && healthRes.body.database.pgAvailable === false) ||
    (testDbRes.body && testDbRes.body.status === 'error');

  console.log(`📊 Estado del servidor detectado (probes inicio): IsDegraded=${isServerDegraded}, HealthStatus=${healthRes.status}`);

  for (const r of safeRoutes) {
    let testPath = r.path
      .replace(':id', '1')
      .replace(':userId', '1')
      .replace(':code', 'GLW-TEST')
      .replace(/:\w+/g, '1');

    if (testPath.includes('*') || testPath.includes('^')) continue;

    const res = await makeRequest(r.method, testPath);
    
    const hasDegradedHeader = !!res.headers['x-glowapp-degraded'];
    const isEmptyLike = Array.isArray(res.body?.data) && res.body.data.length === 0;
    const cleanPath = testPath.split('?')[0];

    let fakedSuccess = false;

    if (isServerDegraded) {
      if (testPath.startsWith('/api/')) {
        if (DEGRADED_ALLOWLIST.has(cleanPath)) {
          // Rutas con allowlist motivada: verificar que no respondan 200 engañoso si la base cayó
          if (res.status >= 200 && res.status < 300) {
            if (cleanPath === '/api/health' && (res.body?.status === 'OK' || !hasDegradedHeader)) {
              fakedSuccess = true;
            } else if (cleanPath === '/api/providers' && res.body?.success === true) {
              fakedSuccess = true;
            }
          }
        } else {
          // REGLA DE CLASE (Cargo 2 / S4):
          // Cualquier superficie de datos bajo /api no en allowlist que responda HTTP 2xx (200-299) estando degradada es FAKED SUCCESS.
          if (res.status >= 200 && res.status < 300) {
            fakedSuccess = true;
          }
        }
      }
    }

    if (fakedSuccess) {
      fakedSuccessCount++;
      console.error(`❌ FAKED SUCCESS detectado en ${r.method} ${testPath} -> HTTP ${res.status} (respuesta 2xx engañosa en estado degradado)`);
    }

    results.push({
      method: r.method,
      path: testPath,
      status: res.status,
      empty_like: isEmptyLike,
      degraded_header: hasDegradedHeader,
      faked_success: fakedSuccess
    });
  }

  // Generar informe de auditoría en docs/audit/smoke-<fecha>.json
  const todayDate = new Date().toISOString().split('T')[0];
  const reportDir = path.resolve(__dirname, '../../docs/audit');
  if (!fs.existsSync(reportDir)) {
    fs.mkdirSync(reportDir, { recursive: true });
  }
  const reportFile = path.join(reportDir, `smoke-${todayDate}.json`);

  const reportData = {
    timestamp: new Date().toISOString(),
    server_degraded: isServerDegraded,
    total_surfaces_tested: results.length,
    faked_success_count: fakedSuccessCount,
    results: results
  };

  fs.writeFileSync(reportFile, JSON.stringify(reportData, null, 2), 'utf-8');
  console.log(`📄 Informe de auditoría del guardián guardado en: ${reportFile}`);

  console.log(`\n📋 Resumen de Smoke Test (${results.length} superficies probadas):`);
  console.log(`- Faked Success Totales: ${fakedSuccessCount}`);

  if (fakedSuccessCount > 0) {
    console.error('❌ SMOKE TEST FALLIDO: Se detectaron respuestas de éxito falso (faked_success).');
    process.exit(1);
  } else {
    console.log('✅ SMOKE TEST EXITOSO: Ninguna superficie fingió éxito.');
    process.exit(0);
  }
}

runSmoke();
