'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '../../../contexts/AuthContext';
import Link from 'next/link';
import { Scissors, Mail, Lock, User as UserIcon, Phone, UserCheck } from 'lucide-react';

export default function RegisterPage() {
  const { register } = useAuth();
  const router = useRouter();
  const [nombre, setNombre] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [rol, setRol] = useState<'CLIENTE' | 'PRESTADOR'>('CLIENTE');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSubmitting(true);

    try {
      const res = await register({
        nombre,
        email,
        phone,
        rol,
        password_hash: password
      });
      if (res.usuario?.rol === 'PRESTADOR') {
        router.push('/prestador');
      } else {
        router.push('/cliente');
      }
    } catch (err: any) {
      setError(err.response?.data?.error || 'Error al registrarse. Inténtalo de nuevo.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="w-full">
      <div className="flex flex-col items-center mb-8">
        <div className="bg-rose-500 text-white p-3 rounded-2xl mb-4 shadow-lg shadow-rose-500/20">
          <Scissors size={28} />
        </div>
        <h2 className="text-3xl font-extrabold text-gray-900 tracking-tight">Crea tu cuenta</h2>
        <p className="text-sm text-gray-500 mt-1">Únete a la red de belleza a domicilio</p>
      </div>

      {error && (
        <div className="bg-red-50 text-red-600 px-4 py-3 rounded-xl text-sm border border-red-100 mb-6 text-center">
          {error}
        </div>
      )}

      <form className="space-y-5" onSubmit={handleSubmit}>
        <div>
          <label className="block text-xs font-semibold text-gray-600 uppercase tracking-wider mb-2">Nombre Completo</label>
          <div className="relative">
            <span className="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-400">
              <UserIcon size={18} />
            </span>
            <input
              type="text"
              required
              value={nombre}
              onChange={(e) => setNombre(e.target.value)}
              className="pl-10 pr-4 py-3 w-full border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500 text-sm transition-all duration-200 text-gray-900"
              placeholder="Tu nombre y apellido"
            />
          </div>
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-600 uppercase tracking-wider mb-2">Correo Electrónico</label>
          <div className="relative">
            <span className="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-400">
              <Mail size={18} />
            </span>
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="pl-10 pr-4 py-3 w-full border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500 text-sm transition-all duration-200 text-gray-900"
              placeholder="nombre@ejemplo.com"
            />
          </div>
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-600 uppercase tracking-wider mb-2">Teléfono</label>
          <div className="relative">
            <span className="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-400">
              <Phone size={18} />
            </span>
            <input
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              className="pl-10 pr-4 py-3 w-full border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500 text-sm transition-all duration-200 text-gray-900"
              placeholder="+57 300 000 0000"
            />
          </div>
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-600 uppercase tracking-wider mb-2">Quiero registrarme como</label>
          <div className="grid grid-cols-2 gap-4 mt-2">
            <button
              type="button"
              onClick={() => setRol('CLIENTE')}
              className={`py-3 px-4 rounded-xl border text-sm font-semibold transition-all duration-200 ${
                rol === 'CLIENTE'
                  ? 'border-rose-500 bg-rose-50 text-rose-600 shadow-sm'
                  : 'border-gray-200 text-gray-600 hover:bg-gray-50'
              }`}
            >
              Cliente
            </button>
            <button
              type="button"
              onClick={() => setRol('PRESTADOR')}
              className={`py-3 px-4 rounded-xl border text-sm font-semibold transition-all duration-200 ${
                rol === 'PRESTADOR'
                  ? 'border-rose-500 bg-rose-50 text-rose-600 shadow-sm'
                  : 'border-gray-200 text-gray-600 hover:bg-gray-50'
              }`}
            >
              Prestador
            </button>
          </div>
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-600 uppercase tracking-wider mb-2">Contraseña</label>
          <div className="relative">
            <span className="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-400">
              <Lock size={18} />
            </span>
            <input
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="pl-10 pr-4 py-3 w-full border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500 text-sm transition-all duration-200 text-gray-900"
              placeholder="••••••••"
            />
          </div>
        </div>

        <button
          type="submit"
          disabled={submitting}
          className="w-full bg-rose-500 text-white py-3 rounded-xl font-semibold shadow-lg shadow-rose-500/20 hover:bg-rose-600 hover:shadow-rose-600/30 active:scale-[0.98] disabled:opacity-50 disabled:pointer-events-none transition-all duration-200"
        >
          {submitting ? 'Creando cuenta...' : 'Crear Cuenta'}
        </button>
      </form>

      <div className="mt-8 text-center border-t border-gray-100 pt-6">
        <p className="text-sm text-gray-500">
          ¿Ya tienes una cuenta?{' '}
          <Link href="/login" className="font-semibold text-rose-500 hover:text-rose-600 transition-colors">
            Inicia sesión aquí
          </Link>
        </p>
      </div>
    </div>
  );
}
