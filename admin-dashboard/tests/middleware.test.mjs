/**
 * Contratos estáticos de src/middleware.ts (guardia de sesión del panel admin T-A1).
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
  assert.match(mw, /export async function middleware\(request: NextRequest\)/);
  assert.match(mw, /export const config = \{/);
});

test('/login y /register son rutas públicas', () => {
  assert.match(mw, /const PUBLIC_PATHS = \['\/login', '\/register'\]/);
});

test('las cookies de sesión reconocidas incluyen glow_access_token', () => {
  assert.match(mw, /glow_access_token/);
});

test('obtiene token de cookies HttpOnly', () => {
  assert.match(mw, /request\.cookies\.get\('glow_access_token'\)\?\.value/);
});

test('la firma JWT se verifica con jose jwtVerify', () => {
  assert.match(mw, /const secretKey = getJwtSecretKey\(\)/);
  assert.match(mw, /if \(!secretKey\) \{/);
  assert.match(mw, /jwtVerify\(token, secretKey\)/);
});

test('el panel es exclusivo de ADMIN: cualquier otro rol o token inválido se rechaza', () => {
  assert.match(mw, /role !== 'ADMIN'/);
  assert.match(mw, /return withSecurityHeaders\(redirectToLogin\(request, pathname\)\)/);
});

test('sin sesión en ruta protegida redirige a /login', () => {
  assert.match(mw, /if \(!token\) \{\s*\n\s*return withSecurityHeaders\(redirectToLogin\(request, pathname\)\)/);
});

test('redirectToLogin conserva la ruta original en el parámetro redirect', () => {
  assert.match(mw, /new URL\('\/login', request\.url\)/);
  assert.match(mw, /loginUrl\.searchParams\.set\('redirect', pathname\)/);
});

test('las rutas /api son gestionadas por sus controladores / BFF proxy', () => {
  assert.match(mw, /pathname\.startsWith\('\/api'\)/);
  assert.match(mw, /\/\\\.\[a-zA-Z0-9\]\+\$\/\.test\(pathname\)/);
});

test('el matcher excluye _next/static, _next/image, favicon.ico', () => {
  assert.match(mw, /_next\/static/);
  assert.match(mw, /_next\/image/);
  assert.match(mw, /favicon\.ico/);
});
