/**
 * Contratos estáticos de src/middleware.ts (guardia de sesión del panel admin).
 *
 * Verifica: rutas públicas, lectura de cookies de sesión, exigencia de rol
 * ADMIN y redirección a /login con parámetro `redirect`. Estático: no requiere
 * `next/server` instalado.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const src = join(import.meta.dirname, '..', 'src');
const mwPath = join(src, 'middleware.ts');
const mw = readFileSync(mwPath, 'utf8').replace(/\r\n/g, '\n');

test('existe src/middleware.ts y exporta middleware + config', () => {
  assert.ok(existsSync(mwPath));
  assert.match(mw, /export function middleware\(request: NextRequest\)/);
  assert.match(mw, /export const config = \{/);
});

test('/login y /register son rutas públicas', () => {
  assert.match(mw, /const PUBLIC_PATHS = \['\/login', '\/register'\]/);
});

test('las cookies de sesión reconocidas son glow_token y adminToken', () => {
  assert.match(mw, /const SESSION_COOKIES = \['glow_token', 'adminToken'\]/);
});

test('getSessionToken recorre SESSION_COOKIES y devuelve null si no hay token', () => {
  assert.match(mw, /for \(const name of SESSION_COOKIES\)/);
  assert.match(mw, /request\.cookies\.get\(name\)\?\.value/);
  assert.match(mw, /return null/);
});

test('el rol se normaliza a mayúsculas (rol o role)', () => {
  assert.match(mw, /payload\?\.rol \?\? payload\?\.role/);
  assert.match(mw, /\.trim\(\)\.toUpperCase\(\)/);
});

test('el panel es exclusivo de ADMIN: cualquier otro rol se rechaza', () => {
  assert.match(mw, /getTokenRole\(token\) !== 'ADMIN'/);
  assert.match(mw, /return redirectToLogin\(request, pathname\)/);
});

test('sin sesión en ruta protegida redirige a /login', () => {
  assert.match(mw, /if \(!token\) \{\s*\n\s*return redirectToLogin\(request, pathname\)/);
});

test('redirectToLogin conserva la ruta original en el parámetro redirect', () => {
  assert.match(mw, /new URL\('\/login', request\.url\)/);
  assert.match(mw, /loginUrl\.searchParams\.set\('redirect', pathname\)/);
});

test('las rutas /api/auth son públicas y los archivos estáticos no exigen sesión', () => {
  assert.match(mw, /pathname\.startsWith\('\/api\/auth'\)/);
  assert.match(mw, /\/\\\.\[a-zA-Z0-9\]\+\$\/\.test\(pathname\)/);
});

test('el matcher excluye _next/static, _next/image, favicon.ico y api', () => {
  assert.match(mw, /_next\/static/);
  assert.match(mw, /_next\/image/);
  assert.match(mw, /favicon\.ico/);
});
