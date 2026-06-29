'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import { User } from '../types/user';
import axios from 'axios';

interface AuthContextType {
  user: User | null;
  loading: boolean;
  login: (email: string, password_hash: string) => Promise<any>;
  register: (data: { email: string; nombre: string; phone?: string; rol: 'CLIENTE' | 'PRESTADOR'; password_hash: string }) => Promise<any>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Cargar sesión del localStorage
    if (typeof window !== 'undefined') {
      const token = localStorage.getItem('glow_token');
      const storedUser = localStorage.getItem('glow_user');
      if (token && storedUser) {
        try {
          setUser(JSON.parse(storedUser));
        } catch (e) {
          localStorage.removeItem('glow_token');
          localStorage.removeItem('glow_user');
        }
      }
      setLoading(false);
    }
  }, []);

  const login = async (email: string, password_hash: string) => {
    setLoading(true);
    try {
      const response = await axios.post(`${API_URL}/api/auth/login`, {
        email,
        password_hash,
      });

      const { token, usuario } = response.data;
      if (token && usuario) {
        localStorage.setItem('glow_token', token);
        localStorage.setItem('glow_user', JSON.stringify(usuario));
        setUser(usuario);
      }
      setLoading(false);
      return response.data;
    } catch (error) {
      setLoading(false);
      throw error;
    }
  };

  const register = async (data: { email: string; nombre: string; phone?: string; rol: 'CLIENTE' | 'PRESTADOR'; password_hash: string }) => {
    setLoading(true);
    try {
      const response = await axios.post(`${API_URL}/api/auth/register`, data);
      const { token, usuario } = response.data;
      if (token && usuario) {
        localStorage.setItem('glow_token', token);
        localStorage.setItem('glow_user', JSON.stringify(usuario));
        setUser(usuario);
      }
      setLoading(false);
      return response.data;
    } catch (error) {
      setLoading(false);
      throw error;
    }
  };

  const logout = () => {
    localStorage.removeItem('glow_token');
    localStorage.removeItem('glow_user');
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
