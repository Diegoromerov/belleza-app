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
          className="sidebar-overlay visible"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside className={`sidebar ${sidebarOpen ? 'open' : ''}`}>
        <div className="sidebar-brand">
          <Link href="/" className="sidebar-logo" aria-label="GlowAdmin Home">
            <div className="sidebar-logo-icon">
              <Scissors size={22} />
            </div>
            <div>
              <h1 className="sidebar-logo-text">GlowAdmin</h1>
              <p className="caption">Panel de Control</p>
            </div>
          </Link>
        </div>

        <nav className="sidebar-nav" role="navigation" aria-label="Navegación principal">
          {links.map((link) => {
            const Icon = link.icon;
            const isActive = pathname === link.href;
            return (
              <Link
                key={link.href}
                href={link.href}
                onClick={() => setSidebarOpen(false)}
                className={`nav-link ${isActive ? 'active' : ''}`}
                aria-current={isActive ? 'page' : undefined}
              >
                <Icon className="icon" size={20} aria-hidden="true" />
                <span>{link.label}</span>
              </Link>
            );
          })}
        </nav>

        <div className="p-4 border-t border-subtle mt-auto">
          {user && (
            <div className="flex items-center gap-3 mb-4">
              <div className="user-avatar">
                {user.nombre[0].toUpperCase()}
              </div>
              <div className="overflow-hidden min-w-0">
                <p className="body-sm text-primary truncate">{user.nombre}</p>
                <p className="micro text-gold font-medium uppercase tracking-wide">{user.rol}</p>
              </div>
            </div>
          )}
          <button
            onClick={logout}
            className="btn btn-secondary w-full justify-start"
          >
            <LogOut size={20} className="icon" aria-hidden="true" />
            <span>Cerrar Sesión</span>
          </button>
        </div>
      </aside>
    </>
  );
}
