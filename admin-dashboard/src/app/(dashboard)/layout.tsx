'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import ProtectedRoute from '@/components/auth/ProtectedRoute';
import Header from '@/components/dashboard/Header';
import { Building2, Tag, Package, GraduationCap, LayoutDashboard, ChevronRight, MessageSquare, User } from 'lucide-react';

const adminNavLinks = [
  { href: '/', label: 'Resumen Ejecutivo', icon: LayoutDashboard },
  { href: '/admin/business', label: 'Cumplimiento Business', icon: Building2 },
  { href: '/admin/precios', label: 'Gestión de Precios', icon: Tag },
  { href: '/admin/productos', label: 'Catálogo Productos', icon: Package },
  { href: '/admin/academia', label: 'Academia Glow', icon: GraduationCap },
  { href: '/admin/vto', label: 'VTO', icon: LayoutDashboard },
];

const commonLinks = [
  { href: '/chat', label: 'Mensajes', icon: MessageSquare },
  { href: '/perfil', label: 'Mi Perfil', icon: User },
];

// Scissors icon as inline SVG
const ScissorsIcon = () => (
  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
    <path d="M6 4 3.5 7.5a2.5 2.5 0 0 0 0 3.5l2.5 2.5" />
    <path d="M18 4l2.5 3.5a2.5 2.5 0 0 1 0 3.5l-2.5 2.5" />
    <path d="M6 20l-2.5-2.5a2.5 2.5 0 0 1 0-3.5L6 10" />
    <path d="M18 20l2.5-2.5a2.5 2.5 0 0 0 0-3.5L18 14" />
  </svg>
);

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const pathname = usePathname();

  return (
    <ProtectedRoute allowedRoles={['ADMIN']}>
      <div className="dashboard-layout">
        {/* Sidebar Overlay (Mobile) */}
        {sidebarOpen && (
          <div className="sidebar-overlay visible" onClick={() => setSidebarOpen(false)} />
        )}

        {/* Sidebar */}
        <aside className={`sidebar ${sidebarOpen ? 'open' : ''}`} role="navigation" aria-label="Navegación principal">
          <div className="sidebar-brand">
            <Link href="/" className="sidebar-logo" aria-label="GlowAdmin Home">
              <div className="sidebar-logo-icon">
                <ScissorsIcon />
              </div>
              <div>
                <h1 className="sidebar-logo-text">GlowAdmin</h1>
                <p className="caption">Panel de Control</p>
              </div>
            </Link>
          </div>

          <nav className="sidebar-nav">
            {/* Admin Navigation Section */}
            <div className="nav-section">
              <h3 className="nav-section-title">Administración</h3>
              {adminNavLinks.map((link) => {
                const Icon = link.icon;
                const isActive = pathname === link.href || (link.href !== '/' && pathname.startsWith(link.href));
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
                    {isActive && <ChevronRight size={16} className="ml-auto text-gold" aria-hidden="true" />}
                  </Link>
                );
              })}
            </div>

            {/* Common links for all admin pages */}
            <div className="nav-section mt-4">
              <h3 className="nav-section-title">Comunes</h3>
              {commonLinks.map((link) => {
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
                    {isActive && <ChevronRight size={16} className="ml-auto text-gold" aria-hidden="true" />}
                  </Link>
                );
              })}
            </div>
          </nav>

          <div className="p-4 border-t border-subtle mt-auto">
            <div className="flex items-center gap-3 mb-4">
              <div className="user-avatar">AD</div>
              <div className="overflow-hidden min-w-0">
                <p className="body-sm text-primary truncate">Administrador Glow</p>
                <p className="micro text-gold font-medium uppercase tracking-wide">Super Admin</p>
              </div>
            </div>
          </div>
        </aside>

        {/* Main Content */}
        <main className="main-content">
          <Header onMenuClick={() => setSidebarOpen(true)} />
          <div className="content-area">
            {children}
          </div>
        </main>
      </div>
    </ProtectedRoute>
  );
}
