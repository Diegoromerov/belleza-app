'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuth } from '../../contexts/AuthContext';
import { 
  Home, 
  Calendar, 
  Settings, 
  MessageSquare, 
  LogOut, 
  User as UserIcon,
  Scissors
} from 'lucide-react';

export default function Sidebar() {
  const pathname = usePathname();
  const { user, logout } = useAuth();

  const links = [
    {
      href: user?.rol === 'PRESTADOR' ? '/prestador' : '/cliente',
      label: 'Panel Principal',
      icon: Home,
    },
    {
      href: user?.rol === 'PRESTADOR' ? '/prestador/citas' : '/cliente/citas',
      label: 'Mis Citas',
      icon: Calendar,
    },
    {
      href: '/chat',
      label: 'Mensajes',
      icon: MessageSquare,
    },
    {
      href: '/perfil',
      label: 'Mi Perfil',
      icon: UserIcon,
    },
  ];

  return (
    <aside className="w-64 bg-slate-900 text-white min-h-screen flex flex-col justify-between border-r border-slate-800">
      <div className="p-6">
        <div className="flex items-center gap-3 mb-8">
          <div className="bg-rose-500 p-2 rounded-xl text-white">
            <Scissors size={24} />
          </div>
          <div>
            <h1 className="font-bold text-xl tracking-wide bg-gradient-to-r from-rose-400 to-pink-500 bg-clip-text text-transparent">GlowApp</h1>
            <p className="text-xs text-slate-400">Portal de Belleza</p>
          </div>
        </div>

        <nav className="space-y-1">
          {links.map((link) => {
            const Icon = link.icon;
            const isActive = pathname === link.href;
            return (
              <Link
                key={link.href}
                href={link.href}
                className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 ${
                  isActive
                    ? 'bg-rose-500 text-white shadow-lg shadow-rose-500/20 font-medium'
                    : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                }`}
              >
                <Icon size={20} />
                <span>{link.label}</span>
              </Link>
            );
          })}
        </nav>
      </div>

      <div className="p-6 border-t border-slate-800">
        {user && (
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 rounded-full bg-slate-700 flex items-center justify-center font-bold text-rose-400">
              {user.nombre[0].toUpperCase()}
            </div>
            <div className="overflow-hidden">
              <p className="text-sm font-semibold truncate">{user.nombre}</p>
              <p className="text-xs text-slate-400 truncate">{user.rol}</p>
            </div>
          </div>
        )}
        <button
          onClick={logout}
          className="flex items-center gap-3 px-4 py-3 rounded-xl w-full text-slate-400 hover:bg-red-500/10 hover:text-red-400 transition-all duration-200"
        >
          <LogOut size={20} />
          <span>Cerrar Sesión</span>
        </button>
      </div>
    </aside>
  );
}
