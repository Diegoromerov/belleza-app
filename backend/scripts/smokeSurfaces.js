const http = require('http');
const fs = require('fs');
const path = require('path');

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
  console.log('🔥 Ejecutando Smoke Test por Superficie (Fase A)...');
  const routesFile = path.resolve(__dirname, '../../docs/audit/routes-2026-09-24.json');
  
  if (!fs.existsSync(routesFile)) {
    console.error('❌ No se encontró docs/audit/routes-2026-09-24.json. Ejecute node scripts/listRoutes.js primero.');
    process.exit(1);
  }

  const routes = JSON.parse(fs.readFileSync(routesFile, 'utf-8'));
  const safeRoutes = routes.filter(r => ['GET', 'HEAD', 'OPTIONS'].includes(r.method));

  let fakedSuccessCount = 0;
  const results = [];

  // Verificar primero si la base de datos o el backend están en modo degradado llamando a /api/health
  const healthRes = await makeRequest('GET', '/api/health');
  const isServerDegraded = healthRes.status === 503 || (healthRes.body && healthRes.body.status === 'DEGRADED') || (healthRes.body && healthRes.body.database && healthRes.body.database.pgAvailable === false);

  console.log(`📊 Estado del servidor detectado vía /api/health: HTTP ${healthRes.status}, IsDegraded=${isServerDegraded}`);

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

    let fakedSuccess = false;

    // Detección de faked_success en /api/providers:
    // Si la base está degradada (o servida por memoria) y /api/providers responde HTTP 200 con datos de prestadores
    if (r.path.includes('/api/providers') && res.status === 200 && isServerDegraded) {
      if (res.body && res.body.success === true && Array.isArray(res.body.data) && res.body.data.length > 0) {
        fakedSuccess = true;
      }
    }

    // Detección de faked_success en /api/health si respondiera 200 OK estado degradado sin reflejar el fallo
    if (r.path.includes('/api/health') && res.status === 200 && isServerDegraded) {
      fakedSuccess = true;
    }

    if (fakedSuccess) {
      fakedSuccessCount++;
      console.error(`❌ FAKED SUCCESS detectado en ${r.method} ${testPath} -> HTTP ${res.status} (servidos datos fabricados sin degradación visible)`);
    }

    results.push({
      method: r.method,
      path: testPath,
      status: res.status,
      empty_like: isEmptyLike,
      degraded_header: hasDegradedHeader,
      wrote_to_db: false,
      faked_success: fakedSuccess
    });
  }

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
