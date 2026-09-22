import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// Rutas públicas: accesibles sin sesión.
const PUBLIC_PATHS = ['/login', '/register'];

// Cookies donde la sesión real deja el JWT (ver src/contexts/AuthContext.tsx).
const SESSION_COOKIES = ['glow_token', 'adminToken'];

function getSessionToken(request: NextRequest): string | null {
  for (const name of SESSION_COOKIES) {
    const value = request.cookies.get(name)?.value;
    if (value) return value;
  }
  return null;
}

/**
 * Lee el claim de rol del JWT sin verificar la firma.
 * La firma se valida en el backend (authAdmin) en cada endpoint; aquí solo se
 * decide si se renderiza o no el panel de administración.
 */
function getTokenRole(token: string): string | null {
  const parts = token.split('.');
  if (parts.length < 2) return null;
  try {
    const base64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const payload = JSON.parse(atob(base64));
    const role = payload?.rol ?? payload?.role;
    return typeof role === 'string' ? role.trim().toUpperCase() : null;
  } catch {
    return null;
  }
}

function redirectToLogin(request: NextRequest, pathname: string) {
  const loginUrl = new URL('/login', request.url);
  loginUrl.searchParams.set('redirect', pathname);
  return NextResponse.redirect(loginUrl);
}

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Rutas públicas
  const isPublicPath = PUBLIC_PATHS.some(
    (path) => pathname === path || pathname.startsWith(`${path}/`)
  );
  if (isPublicPath) {
    return NextResponse.next();
  }

  // API routes de auth son públicas (las valida el backend)
  if (pathname.startsWith('/api/auth')) {
    return NextResponse.next();
  }

  // Archivos estáticos de /public (imágenes, iconos, etc.) no requieren sesión.
  if (/\.[a-zA-Z0-9]+$/.test(pathname)) {
    return NextResponse.next();
  }

  // Sin sesión en una ruta protegida: redirigir a /login.
  const token = getSessionToken(request);
  if (!token) {
    return redirectToLogin(request, pathname);
  }

  // El panel es exclusivamente de administración.
  if (getTokenRole(token) !== 'ADMIN') {
    return redirectToLogin(request, pathname);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|api).*)'],
};
