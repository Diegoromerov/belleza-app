import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Rutas públicas
  const publicPaths = ['/login', '/register'];
  const isPublicPath = publicPaths.some((path) => pathname === path);

  // API routes de auth son públicas
  if (pathname.startsWith('/api/auth')) {
    return NextResponse.next();
  }

  // Si es la raíz y no tiene sesión redirigir
  if (pathname === '/') {
    // Redirigir a login, la protección del lado del cliente decidirá
    return NextResponse.next();
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|api).*)'],
};
