// admin-dashboard/src/middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { jwtVerify } from 'jose';
import { SECURITY_HEADERS } from './lib/security';

const PUBLIC_PATHS = ['/login', '/register'];
const JWT_SECRET = process.env.JWT_SECRET;

function getJwtSecretKey() {
  if (!JWT_SECRET || JWT_SECRET.trim().length < 32) {
    return null;
  }
  return new TextEncoder().encode(JWT_SECRET);
}

function redirectToLogin(request: NextRequest, pathname: string) {
  const loginUrl = new URL('/login', request.url);
  loginUrl.searchParams.set('redirect', pathname);
  return NextResponse.redirect(loginUrl);
}

function withSecurityHeaders(response: NextResponse): NextResponse {
  for (const { key, value } of SECURITY_HEADERS) {
    response.headers.set(key, value);
  }
  return response;
}

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // 1. Rutas públicas
  const isPublicPath = PUBLIC_PATHS.some(
    (path) => pathname === path || pathname.startsWith(`${path}/`)
  );
  if (isPublicPath) {
    return withSecurityHeaders(NextResponse.next());
  }

  // 2. API routes de Next.js son gestionadas por sus controladores / BFF proxy
  if (pathname.startsWith('/api')) {
    return withSecurityHeaders(NextResponse.next());
  }

  // 3. Archivos estáticos
  if (/\.[a-zA-Z0-9]+$/.test(pathname)) {
    return withSecurityHeaders(NextResponse.next());
  }

  // 4. Obtener cookie HttpOnly de acceso
  const token = request.cookies.get('glow_access_token')?.value || request.cookies.get('glow_token')?.value;

  if (!token) {
    return withSecurityHeaders(redirectToLogin(request, pathname));
  }

  // 5. Verificar firma del JWT con `jose` y validar el rol 'ADMIN'
  const secretKey = getJwtSecretKey();
  if (!secretKey) {
    // JWT_SECRET no configurado: no podemos validar la sesión de forma segura.
    // Devolvemos 500 en lugar de redirigir silenciosamente para evitar loops y ocultar fallos de despliegue.
    return new NextResponse('Configuración de autenticación incompleta en el servidor (JWT_SECRET faltante o inválido).', { status: 500 });
  }
  try {
    const { payload } = await jwtVerify(token, secretKey);
    const role = (payload.rol || payload.role || '').toString().trim().toUpperCase();

    if (role !== 'ADMIN') {
      return withSecurityHeaders(redirectToLogin(request, pathname));
    }
  } catch (err) {
    // Si la firma falla o el token expiró, redirigir a login
    return withSecurityHeaders(redirectToLogin(request, pathname));
  }

  return withSecurityHeaders(NextResponse.next());
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
