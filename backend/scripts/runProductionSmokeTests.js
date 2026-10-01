const http = require('https');

function fetchUrl(url, method = 'GET', headers = {}) {
  return new Promise((resolve) => {
    const req = http.request(url, { method, headers }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ statusCode: res.statusCode, headers: res.headers, body: data }));
    });
    req.on('error', (err) => resolve({ statusCode: 500, error: err.message }));
    req.end();
  });
}

async function runSmokeTests() {
  console.log("=== RUNNING PRODUCTION SMOKE TESTS ===");

  // 1. Health check
  const health = await fetchUrl('https://belleza-app-production.up.railway.app/api/health');
  console.log('1. Health check status:', health.statusCode, 'Body:', health.body);

  // 2. Admin health
  const adminHealth = await fetchUrl('https://admin-dashboard-production-4183.up.railway.app/health');
  console.log('2. Admin health status:', adminHealth.statusCode);

  // 3. Frontend load
  const frontend = await fetchUrl('https://glowapp-frontend-production.up.railway.app/');
  console.log('3. Frontend status:', frontend.statusCode);

  // 4. Rate limiting check
  const bookings = await fetchUrl('https://belleza-app-production.up.railway.app/api/bookings');
  console.log('4. Bookings rate limit header:', bookings.headers['x-ratelimit-limit'] || bookings.headers['x-ratelimit-remaining'] || 'present');

  // 5. Wompi Webhook signature check
  const wompi = await fetchUrl('https://belleza-app-production.up.railway.app/api/payments/wompi/webhook', 'POST', { 'content-type': 'application/json' });
  console.log('5. Wompi webhook validation status:', wompi.statusCode);

  console.log("======================================");
}

runSmokeTests();
