/**
 * Contratos estáticos de src/lib/api-client.ts.
 *
 * Se verifican contratos con el backend que ya han causado bugs reales
 * (rutas inexistentes, verbo HTTP incorrecto, sesión no limpiada ante 401).
 * Los tests son estáticos: leen la fuente y verifican el contrato sin
 * necesitar axios/red instalados.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const src = join(import.meta.dirname, '..', 'src');
const apiPath = join(src, 'lib', 'api-client.ts');
const api = readFileSync(apiPath, 'utf8').replace(/\r\n/g, '\n');

test('existe src/lib/api-client.ts', () => {
  assert.ok(existsSync(apiPath));
});

test('el baseURL por defecto apunta al backend en el puerto 3000', () => {
  assert.match(api, /process\.env\.NEXT_PUBLIC_API_URL/);
  assert.match(api, /'http:\/\/localhost:3000'/);
});

test('getBookings enruta a /api/bookings/provider solo para prestador', () => {
  assert.match(
    api,
    /rol\s*===\s*'prestador'\s*\?\s*'\/api\/bookings\/provider'\s*:\s*'\/api\/bookings\/client'/,
    'la ruta de citas debe depender del rol (provider vs client)'
  );
});

test('getBookings NO llama al endpoint inexistente GET /api/bookings', () => {
  assert.doesNotMatch(
    api,
    /\.get\(\s*['"`]\/api\/bookings['"`]\s*\)/,
    'el backend no expone GET /api/bookings (solo /provider y /client)'
  );
});

test('getBookings normaliza respuestas { data: [] }, arrays y nulos a array', () => {
  assert.match(api, /Array\.isArray\(payload\)/);
  assert.match(api, /payload\.data/);
  assert.match(api, /return \[\]/);
});

test('cancelBooking usa PATCH /api/bookings/:id/cancel', () => {
  assert.match(api, /this\.client\.patch\(`\/api\/bookings\/\$\{id\}\/cancel`/);
});

test('updateProfile usa PATCH /api/users/profile (no PUT)', () => {
  assert.match(
    api,
    /this\.client\.patch\('\/api\/users\/profile',\s*data\)/,
    'el backend expone PATCH /api/users/profile'
  );
  assert.doesNotMatch(api, /this\.client\.put\(\s*['"`]\/api\/users\/profile/);
});

test('el interceptor de request adjunta Bearer desde glow_token', () => {
  assert.match(api, /localStorage\.getItem\('glow_token'\)/);
  assert.match(api, /config\.headers\.Authorization\s*=\s*`Bearer \$\{token\}`/);
});

test('el interceptor de respuesta limpia sesión y redirige a /login ante 401', () => {
  assert.match(api, /error\.response\?\.status\s*===\s*401/);
  assert.match(api, /clearClientSession\(\)/);
  assert.match(api, /window\.location\.href\s*=\s*'\/login'/);
});

test('clearClientSession borra glow_token, glow_user y adminToken, y sus cookies', () => {
  assert.match(api, /localStorage\.removeItem\('glow_token'\)/);
  assert.match(api, /localStorage\.removeItem\('glow_user'\)/);
  assert.match(api, /localStorage\.removeItem\('adminToken'\)/);
  assert.match(api, /document\.cookie = 'glow_token=;[\s\S]*max-age=0/);
  assert.match(api, /document\.cookie = 'adminToken=;[\s\S]*max-age=0/);
});

test('clearClientSession es no-op fuera del navegador', () => {
  assert.match(api, /typeof window === 'undefined'\s*\)?\s*return/);
});

test('exporta una instancia singleton apiClient', () => {
  assert.match(api, /export const apiClient = new ApiClient\(\)/);
});
