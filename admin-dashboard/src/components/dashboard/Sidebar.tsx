'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { 
  Home, 
  Calendar, 
  Settings, 
  MessageSquare, 
  LogOut, 
  User as UserIcon,
  Scissors,
  GraduationCap,
  LayoutDashboard,
  Tag,
  Menu,
  X,
  Building2
} from 'lucide-react';

export default function Sidebar() {
  const pathname = usePathname();
  const { user, logout } = useAuth();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  // Links based on role
  const getLinks = () => {
    if (user?.rol === 'PRESTADOR') {
      return [
        { href: '/prestador', label: 'Panel Principal', icon: LayoutDashboard },
        { href: '/prestador/citas', label: 'Mis Citas', icon: Calendar },
        { href: '/chat', label: 'Mensajes', icon: MessageSquare },
        { href: '/perfil', label: 'Mi Perfil', icon: UserIcon },
      ];
    }
    
    if (user?.rol === 'ADMIN') {
      return [
        { href: '/admin/business', label: 'Cumplimiento Business', icon: Building2 },
        { href: '/admin/precios', label: 'Gestión de Precios', icon: Tag },
        { href: '/admin/academia', label: 'Academia Glow', icon: GraduationCap },
        { href: '/chat', label: 'Mensajes', icon: MessageSquare },
        { href: '/perfil', label: 'Mi Perfil', icon: UserIcon },
      ];
    }
    
    // CLIENTE
    return [
      { href: '/cliente', label: 'Panel Principal', icon: Home },
      { href: '/cliente/citas', label: 'Mis Citas', icon: Calendar },
      { href: '/chat', label: 'Mensajes', icon: MessageSquare },
      { href: '/perfil', label: 'Mi Perfil', icon: UserIcon },
    ];
  };

  const links = getLinks();

  return (
    <>
      {/* Mobile sidebar overlay */}
      {sidebarOpen && (
        <div 
          className="fixed inset-0 bg-black/50 z-40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside className={`fixed lg:static inset-y-0 left-0 z-50 w-64 bg-[#FAF8F5] text-[#2B2420] min-h-screen flex flex-col justify-between border-r border-[#C5A052]/25 transform transition-transform duration-300 lg:translate-x-0 ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'}`}>
        <div className="p-6">
          <div className="flex items-center gap-3 mb-8">
            <div className="bg-[#2B2420] p-2.5 rounded-xl text-[#C5A052] border border-[#C5A052]/40 shadow-sm">
              <Scissors size={22} />
            </div>
            <div>
              <h1 className="font-bold text-xl tracking-tight text-[#2B2420] font-serif">GlowAdmin</h1>
              <p className="text-xs text-[#8C6F65] font-sans">Panel de Control Día</p>
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
                  onClick={() => setSidebarOpen(false)}
                  className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 ${
                    isActive
                      ? 'bg-[#2B2420] text-[#FCF8F6] shadow-md shadow-[#2B2420]/10 border border-[#C5A052]/40 font-medium'
                      : 'text-[#8C6F65] hover:bg-[#FCF8F6] hover:text-[#2B2420] hover:border hover:border-[#C5A052]/20'
                  }`}
                >
                  <Icon size={20} className={isActive ? 'text-[#C5A052]' : 'text-[#8C6F65]'} />
                  <span>{link.label}</span>
                </Link>
              );
            })}
          </nav>
        </div>

        <div className="p-6 border-t border-[#C5A052]/20">
          {user && (
            <div className="flex items-center gap-3 mb-6">
              <div className="w-10 h-10 rounded-full bg-[#2B2420] text-[#C5A052] border border-[#C5A052]/40 flex items-center justify-center font-bold font-serif">
                {user.nombre[0].toUpperCase()}
              </div>
              <div className="overflow-hidden">
                <p className="text-sm font-semibold truncate text-[#2B2420]">{user.nombre}</p>
                <p className="text-xs text-[#8C6F65] truncate font-mono">{user.rol}</p>
              </div>
            </div>
          )}
          <button
            onClick={logout}
            className="flex items-center gap-3 px-4 py-3 rounded-xl w-full text-[#8C6F65] hover:bg-[#FDF2F4] hover:text-[#881337] transition-all duration-200"
          >
            <LogOut size={20} />
            <span>Cerrar Sesión</span>
          </button>
        </div>
      </aside>
    </>
  );
}