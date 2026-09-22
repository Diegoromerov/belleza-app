'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import axios from 'axios';

/** Usuario de sesión tal como lo persiste el panel (subconjunto estable de la respuesta del backend). */
export interface SessionUser {
  id: number;
  email: string;
  nombre: string;
  rol: 'CLIENTE' | 'PRESTADOR' | 'ADMIN' | 'SALON';
  onboarding_completo?: boolean;
}

interface ApiUser {
  id?: string | number;
  email?: string;
  nombre?: string;
  full_name?: string;
  rol?: string;
  role?: string;
  onboarding_completo?: boolean;
}

export interface AuthResponse {
  token?: string;
  user?: ApiUser;
  usuario?: ApiUser;
  [key: string]: unknown;
}

interface AuthContextType {
  user: SessionUser | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<AuthResponse>;
  register: (data: { email: string; nombre: string; phone?: string; rol: 'CLIENTE' | 'PRESTADOR'; password: string }) => Promise<AuthResponse>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const API_URL = process.env.NEXT_PUBLIC_API_URL || (typeof window !== 'undefined' && window.location.hostname.includes('railway.app') ? 'https://beauty-app-production-bfd4.up.railway.app' : 'http://localhost:3000');

// La sesión se guarda en localStorage (la usa el cliente) y se refleja en cookies
// para que el middleware del servidor pueda decidir si renderiza el panel.
// El backend (authAdmin) es quien valida la firma del JWT en cada endpoint.
const SESSION_COOKIE = 'glow_token';
const ADMIN_COOKIE = 'adminToken';
const COOKIE_MAX_AGE = 60 * 60 * 24 * 7; // 7 días

export function setSessionCookie(name: string, value: string) {
  if (typeof document === 'undefined') return;
  document.cookie = `${name}=${value}; path=/; max-age=${COOKIE_MAX_AGE}; SameSite=Lax`;
}

export function clearSessionCookies() {
  if (typeof document === 'undefined') return;
  document.cookie = `${SESSION_COOKIE}=; path=/; max-age=0; SameSite=Lax`;
  document.cookie = `${ADMIN_COOKIE}=; path=/; max-age=0; SameSite=Lax`;
}

function normalizeRole(raw?: string, fallbackRole?: string): SessionUser['rol'] {
  const value = (raw || '').toUpperCase();
  if (value === 'ADMIN' || fallbackRole === 'admin') return 'ADMIN';
  if (value === 'PRESTADOR' || value === 'PROVIDER' || fallbackRole === 'provider') return 'PRESTADOR';
  if (value === 'SALON' || fallbackRole === 'salon') return 'SALON';
  return 'CLIENTE';
}

function buildSessionUser(apiUser: ApiUser): SessionUser {
  return {
    id: typeof apiUser.id === 'number' ? apiUser.id : parseInt(String(apiUser.id), 10) || 0,
    email: apiUser.email || '',
    nombre: apiUser.full_name || apiUser.nombre || '',
    rol: normalizeRole(apiUser.rol, apiUser.role),
    onboarding_completo: apiUser.onboarding_completo,
  };
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<SessionUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Cargar sesión del localStorage
    if (typeof window !== 'undefined') {
      const token = localStorage.getItem('glow_token');
      const storedUser = localStorage.getItem('glow_user');
      if (token && storedUser) {
        try {
          const parsed = JSON.parse(storedUser) as SessionUser;
          setUser(parsed);
          // Mantener sincronizada la cookie que consume el middleware.
          setSessionCookie(SESSION_COOKIE, token);
          if (parsed.rol === 'ADMIN') setSessionCookie(ADMIN_COOKIE, token);
        } catch {
          localStorage.removeItem('glow_token');
          localStorage.removeItem('glow_user');
          localStorage.removeItem('adminToken');
          clearSessionCookies();
        }
      }
      setLoading(false);
    }
  }, []);

  const persistSession = (token: string, sessionUser: SessionUser) => {
    localStorage.setItem('glow_token', token);
    localStorage.setItem('glow_user', JSON.stringify(sessionUser));
    setSessionCookie(SESSION_COOKIE, token);
    if (sessionUser.rol === 'ADMIN') {
      localStorage.setItem('adminToken', token);
      setSessionCookie(ADMIN_COOKIE, token);
    } else {
      localStorage.removeItem('adminToken');
    }
    setUser(sessionUser);
  };

  const login = async (email: string, password: string): Promise<AuthResponse> => {
    setLoading(true);
    try {
      const response = await axios.post(`${API_URL}/api/auth/login`, {
        email,
        password,
      });

      const data = response.data as AuthResponse;
      const apiUser = data.user || data.usuario;
      if (data.token && apiUser) {
        persistSession(data.token, buildSessionUser(apiUser));
      }
      setLoading(false);
      return data;
    } catch (error) {
      setLoading(false);
      throw error;
    }
  };

  const register = async (data: { email: string; nombre: string; phone?: string; rol: 'CLIENTE' | 'PRESTADOR'; password: string }): Promise<AuthResponse> => {
    setLoading(true);
    try {
      const payload = {
        full_name: data.nombre,
        nombre: data.nombre,
        email: data.email,
        password: data.password,
        phone: data.phone || null,
        role: data.rol,
        rol: data.rol
      };
      const response = await axios.post(`${API_URL}/api/auth/register`, payload);
      const body = response.data as AuthResponse;
      const apiUser = body.user || body.usuario;
      if (body.token && apiUser) {
        persistSession(body.token, buildSessionUser(apiUser));
      }
      setLoading(false);
      return body;
    } catch (error) {
      setLoading(false);
      throw error;
    }
  };

  const logout = () => {
    localStorage.removeItem('glow_token');
    localStorage.removeItem('glow_user');
    localStorage.removeItem('adminToken');
    clearSessionCookies();
    setUser(null);
    if (typeof window !== 'undefined') {
      window.location.href = '/login';
    }
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, register, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
