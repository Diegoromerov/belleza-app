'use client';

import React, { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { 
  TrendingUp, 
  Users, 
  ShieldAlert, 
  DollarSign, 
  Activity, 
  Briefcase, 
  CheckCircle, 
  XCircle, 
  Bell, 
  MapPin, 
  Clock, 
  ExternalLink, 
  Percent, 
  FileText,
  Layers,
  Award,
  Zap,
  CheckSquare,
  ClipboardList,
  PlusCircle,
  LayoutDashboard,
  Building2,
  GraduationCap,
  Tag,
  Menu,
  X,
  Search,
  ChevronDown,
  LogOut,
  User as UserIcon,
  MessageSquare,
  Calendar,
  Settings,
  Scissors,
} from 'lucide-react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  Cell
} from 'recharts';

interface FinancialMetrics {
  gmv: number;
  total_commission: number;
  total_taxes: number;
  platform_gross_income: number;
  total_provider_payouts: number;
  total_bookings: number;
}

interface DailyHistoryPoint {
  date: string;
  gmv: number;
  income: number;
}

interface CategoryPoint {
  category: string;
  booking_count: number;
  total_revenue: number;
  color: string;
}

interface SosAlert {
  id: number;
  client_name?: string | null;
  client_phone?: string | null;
  provider_name?: string | null;
  provider_phone?: string | null;
  latitude: string | number;
  longitude: string | number;
  fecha_creacion?: string | null;
}

interface PendingProvider {
  id: number;
  nombre: string;
  email: string;
  business_name?: string | null;
  description?: string | null;
  documento_id_url?: string | null;
  rut_url?: string | null;
  certificacion_url?: string | null;
  estatus_verificacion?: string | null;
}

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000';

const CATEGORY_COLORS = ['#f43f5e', '#ec4899', '#a855f7', '#6366f1', '#0ea5e9', '#f59e0b'];

function getAdminSessionToken(): string | null {
  if (typeof window === 'undefined') return null;
  return window.localStorage.getItem('adminToken') || window.localStorage.getItem('glow_token');
}

function formatCOPSafe(val: number | null | undefined) {
  if (val === null || val === undefined || Number.isNaN(Number(val))) return 'Sin datos';
  return new Intl.NumberFormat('es-CO', {
    style: 'currency',
    currency: 'COP',
    minimumFractionDigits: 0
  }).format(Number(val));
}

export default function Dashboard() {
  const pathname = usePathname();
  const [activeTab, setActiveTab] = useState('dashboard');
  const [loading, setLoading] = useState(true);
  const [backendStatus, setBackendStatus] = useState('Comprobando conexión...');
  const [metrics, setMetrics] = useState<FinancialMetrics | null>(null);
  const [dailyHistory, setDailyHistory] = useState<DailyHistoryPoint[]>([]);
  const [categoryData, setCategoryData] = useState<CategoryPoint[]>([]);
  const [sosAlerts, setSosAlerts] = useState<SosAlert[]>([]);
  const [pendingProviders, setPendingProviders] = useState<PendingProvider[]>([]);
  const [dataError, setDataError] = useState<string | null>(null);
  const [failedSections, setFailedSections] = useState<string[]>([]);
  const [actionMessage, setActionMessage] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  const [selectedDirector, setSelectedDirector] = useState('COO');
  const [checklists, setChecklists] = useState({
    COO: [
      { id: 1, text: 'Revisión de tiempo de despacho en Bogotá Norte', completed: true },
      { id: 2, text: 'Auditoría de conductores activos en horas pico', completed: false },
      { id: 3, text: 'Evaluación del protocolo de seguridad física SOS', completed: false }
    ],
    CTO: [
      { id: 4, text: 'Optimizar índices PostGIS en base de datos de réplica', completed: true },
      { id: 5, text: 'Implementar validación criptográfica en webhook de Wompi', completed: false },
      { id: 6, text: 'Actualizar dependencias de seguridad del servidor Node.js', completed: true }
    ],
    CFO: [
      { id: 7, text: 'Conciliar splits tributarios (12% plataforma / 8% impuestos)', completed: true },
      { id: 8, text: 'Procesar lotes de liquidación semanal para prestadores', completed: false },
      { id: 9, text: 'Proyectar LTV/CAC en la categoría de maquillaje profesional', completed: false }
    ],
    CMO: [
      { id: 10, text: 'Analizar conversión de campañas de referidos en Bogotá', completed: true },
      { id: 11, text: 'Lanzar promoción especial para servicios de Uñas', completed: true },
      { id: 12, text: 'Ajustar segmentación de pauta para maximizar LTV', completed: false }
    ]
  });

  const [decisions, setDecisions] = useState([
    { id: 1, title: 'Migración a réplica de lectura en caliente para analítica', date: '2026-06-09', status: 'Aprobado', desc: 'CTO aprueba migración para evitar bloqueos transaccionales por queries de BI.' },
    { id: 2, title: 'Ajuste de comisión en servicios premium a 22%', date: '2026-06-09', status: 'En Discusión', desc: 'CFO y CMO evalúan impacto en la retención de profesionales.' },
    { id: 3, title: 'Alianza con aseguradora local para incidentes SOS', date: '2026-06-09', status: 'En Discusión', desc: 'COO negocia póliza contra incidentes reportados a través del botón SOS.' }
  ]);
  const [newDecisionTitle, setNewDecisionTitle] = useState('');
  const [newDecisionDesc, setNewDecisionDesc] = useState('');

  const fetchDashboardData = async () => {
    const adminToken = getAdminSessionToken();

    if (!adminToken) {
      setBackendStatus('Sin sesión de administrador');
      setDataError('No hay sesión de administrador activa. Inicia sesión con una cuenta ADMIN para ver datos reales.');
      setMetrics(null);
      setDailyHistory([]);
      setCategoryData([]);
      setSosAlerts([]);
      setPendingProviders([]);
      setFailedSections(['financial', 'sos', 'kyc']);
      setLoading(false);
      return;
    }

    setLoading(true);
    setDataError(null);
    try {
      const headers = { Authorization: `Bearer ${adminToken}` };
      const [summaryRes, sosRes, providersRes] = await Promise.all([
        fetch(`${API_BASE_URL}/api/glow-admin/dashboard/financial-summary`, { headers }),
        fetch(`${API_BASE_URL}/api/glow-admin/sos/active`, { headers }),
        fetch(`${API_BASE_URL}/api/glow-admin/provider/pending`, { headers })
      ]);

      const failures: string[] = [];
      const failed: string[] = [];

      if (summaryRes.ok) {
        const resJson = await summaryRes.json();
        const data = resJson?.data;
        setMetrics(data?.consolidated ?? null);
        setDailyHistory(Array.isArray(data?.dailyHistory) ? data.dailyHistory : []);
        setCategoryData(
          Array.isArray(data?.categoryPopularity)
            ? (data.categoryPopularity as Array<{ category: string; booking_count: number; total_revenue: number }>).map(
                (item, index) => ({ ...item, color: CATEGORY_COLORS[index % CATEGORY_COLORS.length] })
              )
            : []
        );
      } else {
        setMetrics(null);
        setDailyHistory([]);
        setCategoryData([]);
        failures.push(`resumen financiero (HTTP ${summaryRes.status})`);
        failed.push('financial');
      }

      if (sosRes.ok) {
        const sosJson = await sosRes.json();
        setSosAlerts(Array.isArray(sosJson?.data) ? (sosJson.data as SosAlert[]) : []);
      } else {
        setSosAlerts([]);
        failures.push(`alertas SOS (HTTP ${sosRes.status})`);
        failed.push('sos');
      }

      if (providersRes.ok) {
        const providersJson = await providersRes.json();
        setPendingProviders(Array.isArray(providersJson?.data) ? (providersJson.data as PendingProvider[]) : []);
      } else {
        setPendingProviders([]);
        failures.push(`verificaciones KYC (HTTP ${providersRes.status})`);
        failed.push('kyc');
      }

      setFailedSections(failed);

      if (failures.length > 0) {
        setBackendStatus('Backend con errores');
        setDataError(`No se pudieron cargar: ${failures.join(', ')}.`);
      } else {
        setBackendStatus('Conectado a PostgreSQL');
      }
    } catch (err) {
      setMetrics(null);
      setDailyHistory([]);
      setCategoryData([]);
      setSosAlerts([]);
      setPendingProviders([]);
      setFailedSections(['financial', 'sos', 'kyc']);
      setBackendStatus('Backend no disponible');
      setDataError(
        `No se pudo contactar al backend: ${err instanceof Error ? err.message : 'error desconocido'}.`
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const handleResolveSOS = async (alertId: number) => {
    setActionError(null);
    setActionMessage(null);
    const adminToken = getAdminSessionToken();
    if (!adminToken) {
      setActionError('No hay sesión de administrador activa: no se puede resolver la alerta.');
      return;
    }
    try {
      const response = await fetch(`${API_BASE_URL}/api/glow-admin/sos/resolve/${alertId}`, {
        method: 'PATCH',
        headers: { Authorization: `Bearer ${adminToken}` }
      });
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      setSosAlerts(prev => prev.filter(alert => alert.id !== alertId));
      setActionMessage(`Alerta SOS #${alertId} marcada como ATENDIDA en el backend.`);
    } catch (err) {
      setActionError(
        `No se pudo resolver la alerta SOS #${alertId}: ${err instanceof Error ? err.message : 'error desconocido'}.`
      );
    }
  };

  const handleProviderReview = async (providerId: number, action: 'approve' | 'reject') => {
    setActionError(null);
    setActionMessage(null);
    const adminToken = getAdminSessionToken();
    if (!adminToken) {
      setActionError('No hay sesión de administrador activa: no se puede actualizar la verificación.');
      return;
    }
    const label = action === 'approve' ? 'APROBADO' : 'RECHAZADO';
    try {
      const response = await fetch(`${API_BASE_URL}/api/glow-admin/provider/${action}`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${adminToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ providerId })
      });
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      setPendingProviders(prev => prev.filter(prov => prov.id !== providerId));
      setActionMessage(`El prestador #${providerId} ha sido ${label} en el backend.`);
    } catch (err) {
      setActionError(
        `No se pudo marcar al prestador #${providerId} como ${label}: ${err instanceof Error ? err.message : 'error desconocido'}.`
      );
    }
  };

  const handleApproveProvider = (providerId: number) => handleProviderReview(providerId, 'approve');
  const handleRejectProvider = (providerId: number) => handleProviderReview(providerId, 'reject');

  useEffect(() => {
    let audio: HTMLAudioElement | null = null;
    if (sosAlerts.length > 0) {
      audio = new Audio('https://assets.mixkit.co/active_storage/sfx/951/951-84.wav');
      audio.loop = true;
      const playAlarm = () => {
        audio?.play().catch(() => {});
      };
      playAlarm();
      window.addEventListener('click', playAlarm);
      return () => {
        audio?.pause();
        window.removeEventListener('click', playAlarm);
      };
    }
  }, [sosAlerts]);

  const toggleChecklist = (director: string, itemId: number) => {
    setChecklists(prev => {
      const updated = prev[director as keyof typeof prev].map(item => {
        if (item.id === itemId) {
          return { ...item, completed: !item.completed };
        }
        return item;
      });
      return { ...prev, [director]: updated };
    });
  };

  const handleStatusChange = (decisionId: number, newStatus: string) => {
    setDecisions(prev => prev.map(dec => {
      if (dec.id === decisionId) {
        return { ...dec, status: newStatus };
      }
      return dec;
    }));
  };

  const handleAddDecision = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newDecisionTitle.trim()) return;
    const newDec = {
      id: Date.now(),
      title: newDecisionTitle,
      date: new Date().toISOString().split('T')[0],
      status: 'En Discusión',
      desc: newDecisionDesc
    };
    setDecisions(prev => [newDec, ...prev]);
    setNewDecisionTitle('');
    setNewDecisionDesc('');
  };

  const formatCOP = (val: number | null | undefined) => formatCOPSafe(val);

  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [userMenuOpen, setUserMenuOpen] = useState(false);
  const [notificationsOpen, setNotificationsOpen] = useState(false);
  const userMenuButtonRef = useRef<HTMLButtonElement>(null);
  const userMenuDropdownRef = useRef<HTMLDivElement>(null);
  const notificationsRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (userMenuButtonRef.current && !userMenuButtonRef.current.contains(event.target as Node) &&
          userMenuDropdownRef.current && !userMenuDropdownRef.current.contains(event.target as Node)) {
        setUserMenuOpen(false);
      }
      if (notificationsRef.current && !notificationsRef.current.contains(event.target as Node)) {
        setNotificationsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const adminNavLinks = [
    { href: '/admin/business', label: 'Cumplimiento Business', icon: Building2 },
    { href: '/admin/precios', label: 'Gestión de Precios', icon: Tag },
    { href: '/admin/academia', label: 'Academia Glow', icon: GraduationCap },
    { href: '/admin/vto', label: 'VTO', icon: LayoutDashboard },
  ];

  return (
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
              <Scissors size={22} />
            </div>
            <div>
              <h1 className="sidebar-logo-text">GlowAdmin</h1>
              <p className="caption">Panel de Control</p>
            </div>
          </Link>
        </div>

        <nav className="sidebar-nav">
          {[
            { id: 'dashboard', label: 'Métricas Financieras', icon: TrendingUp },
            { id: 'board', label: 'Reunión Directiva', icon: ClipboardList },
            { id: 'kyc', label: 'Verificaciones KYC', icon: Briefcase, badge: pendingProviders.length },
            { id: 'sos', label: 'Alertas SOS de Pánico', icon: ShieldAlert, badge: sosAlerts.length, isAlert: true }
          ].map(tab => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => { setActiveTab(tab.id); setSidebarOpen(false); }}
                className={`nav-link ${isActive ? 'active' : ''}`}
                aria-current={isActive ? 'page' : undefined}
              >
                <Icon className="icon" size={20} aria-hidden="true" />
                <span>{tab.label}</span>
                {tab.badge !== undefined && tab.badge > 0 && (
                  <span className={`chip ${tab.isAlert ? 'danger' : 'active'} chip-sm`}>
                    {tab.badge}
                  </span>
                )}
              </button>
            );
          })}

          {/* Admin Navigation Section */}
          <div className="nav-section">
            <h3 className="nav-section-title">Administración</h3>
            {adminNavLinks.map(link => {
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
          </div>
        </nav>

        <div className="p-4 border-t border-subtle mt-auto">
          <button
            onClick={() => { setUserMenuOpen(!userMenuOpen); setNotificationsOpen(false); }}
            className="user-menu w-full justify-start"
            aria-label="Menú de usuario"
            aria-expanded={userMenuOpen}
            ref={userMenuButtonRef}
          >
            <div className="user-avatar">AD</div>
            <div className="user-info min-w-0">
              <p className="user-name">Administrador Glow</p>
              <p className="user-role">Super Admin</p>
            </div>
            <ChevronDown size={16} className={`transition-transform ${userMenuOpen ? 'rotate-180' : ''}`} />
          </button>

          {userMenuOpen && (
            <div className="dropdown-menu mt-2" role="menu">
              <Link href="/perfil" className="dropdown-item" role="menuitem">
                <UserIcon size={16} />
                <span>Mi Perfil</span>
              </Link>
              <Link href="/settings" className="dropdown-item" role="menuitem">
                <Settings size={16} />
                <span>Configuración</span>
              </Link>
              <div className="dropdown-divider" />
              <button 
                onClick={() => { setUserMenuOpen(false); }}
                className="dropdown-item danger" 
                role="menuitem"
              >
                <LogOut size={16} />
                <span>Cerrar Sesión</span>
              </button>
            </div>
          )}
        </div>
      </aside>

      {/* Main Content */}
      <main className="main-content" style={{ marginLeft: '260px' }}>
        {/* Header */}
        <header className="header" role="banner">
          <div className="header-left">
            <button 
              className="mobile-menu-btn"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              aria-label={mobileMenuOpen ? 'Cerrar menú' : 'Abrir menú'}
              aria-expanded={mobileMenuOpen}
            >
              {mobileMenuOpen ? <X size={20} /> : <Menu size={20} />}
            </button>
            
            <div className="relative max-w-md w-full hidden md:block">
              <span className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none text-muted">
                <Search size={18} />
              </span>
              <input
                type="text"
                placeholder="Buscar servicios, precios, auditoría..."
                className="form-input pl-10 pr-4"
                aria-label="Buscar"
              />
            </div>
            
            <h1 className="page-title hidden sm:block">
              {activeTab === 'dashboard' ? 'Resumen de Negocio' : 
               activeTab === 'board' ? 'Reunión Directiva' : 
               activeTab === 'kyc' ? 'Verificaciones KYC' : 'Alertas SOS'}
            </h1>
          </div>

          <div className="header-right">
            {/* Notifications */}
            <div className="dropdown" ref={notificationsRef}>
              <button
                className="btn-icon relative"
                onClick={() => { setNotificationsOpen(!notificationsOpen); setUserMenuOpen(false); }}
                aria-label="Notificaciones"
                aria-expanded={notificationsOpen}
              >
                <Bell size={20} />
                {sosAlerts.length > 0 && (
                  <span className="dot" aria-hidden="true" />
                )}
              </button>
              
              {notificationsOpen && (
                <div className="dropdown-menu" role="menu">
                  <div className="p-3 border-b border-subtle">
                    <h3 className="caption text-primary">Notificaciones</h3>
                  </div>
                  {sosAlerts.length > 0 ? (
                    sosAlerts.slice(0, 5).map(alert => (
                      <button key={alert.id} className="dropdown-item" role="menuitem">
                        <ShieldAlert size={16} className="text-danger" />
                        <span>SOS #{alert.id} - {alert.client_name || 'Cliente'}</span>
                      </button>
                    ))
                  ) : (
                    <button className="dropdown-item" role="menuitem">
                      <span>No hay notificaciones nuevas</span>
                    </button>
                  )}
                </div>
              )}
            </div>

            {/* User Menu (Desktop) */}
            <div className="dropdown" ref={userMenuDropdownRef}>
              <button
                className="user-menu"
                onClick={() => { setUserMenuOpen(!userMenuOpen); setNotificationsOpen(false); }}
                aria-label="Menú de usuario"
                aria-expanded={userMenuOpen}
              >
                <div className="user-avatar">AD</div>
                <div className="user-info">
                  <p className="user-name">Administrador Glow</p>
                  <p className="user-role">Super Admin</p>
                </div>
                <ChevronDown size={16} className={`transition-transform ${userMenuOpen ? 'rotate-180' : ''}`} />
              </button>
              
              {userMenuOpen && (
                <div className="dropdown-menu" role="menu">
                  <div className="p-3 border-b border-subtle">
                    <p className="body-sm text-primary">Administrador Glow</p>
                    <p className="caption text-gold">Super Admin</p>
                  </div>
                  <Link href="/perfil" className="dropdown-item" role="menuitem">
                    <UserIcon size={16} />
                    <span>Mi Perfil</span>
                  </Link>
                  <Link href="/settings" className="dropdown-item" role="menuitem">
                    <Settings size={16} />
                    <span>Configuración</span>
                  </Link>
                  <div className="dropdown-divider" />
                  <button 
                    onClick={() => { setUserMenuOpen(false); }}
                    className="dropdown-item danger" 
                    role="menuitem"
                  >
                    <LogOut size={16} />
                    <span>Cerrar Sesión</span>
                  </button>
                </div>
              )}
            </div>
          </div>
        </header>

        {/* Content Area */}
        <div className="content-area">
          {/* Status Bar */}
          {(dataError || actionError || actionMessage) && (
            <div className="mb-6 space-y-3">
              {dataError && (
                <div className="card border-danger bg-danger-bg/50">
                  <div className="card-content flex items-start justify-between gap-4">
                    <div className="flex items-start gap-3">
                      <ShieldAlert className="icon text-danger shrink-0" size={20} />
                      <span className="body-sm text-danger">{dataError}</span>
                    </div>
                    <button
                      onClick={() => fetchDashboardData()}
                      className="btn btn-secondary btn-sm shrink-0"
                    >
                      Reintentar
                    </button>
                  </div>
                </div>
              )}
              {actionError && (
                <div className="card border-warning bg-warning-bg/50">
                  <div className="card-content flex items-center gap-3">
                    <ShieldAlert className="icon text-warning shrink-0" size={20} />
                    <span className="body-sm text-warning">{actionError}</span>
                  </div>
                </div>
              )}
              {actionMessage && (
                <div className="card border-success bg-success-bg/50">
                  <div className="card-content flex items-center gap-3">
                    <CheckCircle className="icon text-success shrink-0" size={20} />
                    <span className="body-sm text-success">{actionMessage}</span>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* TAB CONTENTS */}
          {activeTab === 'dashboard' && (
            <DashboardTab 
              loading={loading}
              metrics={metrics}
              dailyHistory={dailyHistory}
              categoryData={categoryData}
              formatCOP={formatCOP}
            />
          )}

          {activeTab === 'board' && (
            <BoardTab 
              selectedDirector={selectedDirector}
              setSelectedDirector={setSelectedDirector}
              checklists={checklists}
              toggleChecklist={toggleChecklist}
              decisions={decisions}
              handleStatusChange={handleStatusChange}
              newDecisionTitle={newDecisionTitle}
              setNewDecisionTitle={setNewDecisionTitle}
              newDecisionDesc={newDecisionDesc}
              setNewDecisionDesc={setNewDecisionDesc}
              handleAddDecision={handleAddDecision}
            />
          )}

          {activeTab === 'kyc' && (
            <KycTab 
              pendingProviders={pendingProviders}
              failedSections={failedSections}
              handleApproveProvider={handleApproveProvider}
              handleRejectProvider={handleRejectProvider}
            />
          )}

          {activeTab === 'sos' && (
            <SosTab 
              sosAlerts={sosAlerts}
              failedSections={failedSections}
              handleResolveSOS={handleResolveSOS}
            />
          )}
        </div>
      </main>
    </div>
  );
}

// ===== SUB-COMPONENTS =====

function DashboardTab({ 
  loading, 
  metrics, 
  dailyHistory, 
  categoryData, 
  formatCOP 
}: {
  loading: boolean;
  metrics: FinancialMetrics | null;
  dailyHistory: DailyHistoryPoint[];
  categoryData: CategoryPoint[];
  formatCOP: (val: number | null | undefined) => string;
}) {
  return (
    <>
      {/* Financial KPI Cards */}
      <section className="kpi-grid">
        {[
          { title: 'GMV Facturado', value: loading ? 'Cargando...' : formatCOP(metrics?.gmv), sub: 'Total de reservas completadas', icon: DollarSign, color: 'gold' },
          { title: 'Comisión Plataforma (12%)', value: loading ? 'Cargando...' : formatCOP(metrics?.total_commission), sub: 'Neto de GlowApp', icon: Percent, color: 'rose' },
          { title: 'Impuesto Recaudado (8%)', value: loading ? 'Cargando...' : formatCOP(metrics?.total_taxes), sub: 'Retenciones tributarias', icon: Activity, color: 'warning' },
          { title: 'Dispersión Prestadores', value: loading ? 'Cargando...' : formatCOP(metrics?.total_provider_payouts), sub: 'Transferido a profesionales', icon: Users, color: 'info' }
        ].map((kpi, idx) => {
          const Icon = kpi.icon;
          return (
            <div key={idx} className="kpi-card">
              <div className="kpi-header">
                <span className="kpi-title">{kpi.title}</span>
                <div className={`kpi-icon ${kpi.color}`}>
                  <Icon size={22} />
                </div>
              </div>
              <p className="kpi-value">{kpi.value}</p>
              <span className="kpi-label">{kpi.sub}</span>
            </div>
          );
        })}
      </section>

      {/* Graphic Charts Analysis */}
      <section className="card-grid">
        {/* 30-Day Area Chart */}
        <div className="card">
          <div className="card-header">
            <div>
              <h3 className="card-title">Evolución Semanal de Facturación</h3>
              <p className="card-subtitle">Comparativa diaria de volumen de ventas e ingresos</p>
            </div>
          </div>
          <div className="card-content" style={{ height: '320px' }}>
            {dailyHistory.length === 0 ? (
              <div className="flex items-center justify-center h-full text-muted">
                Sin datos de facturación registrados en el backend.
              </div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={dailyHistory}>
                  <defs>
                    <linearGradient id="colorGmv" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#ec4899" stopOpacity={0.2} />
                      <stop offset="95%" stopColor="#ec4899" stopOpacity={0} />
                    </linearGradient>
                    <linearGradient id="colorIncome" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#f43f5e" stopOpacity={0.2} />
                      <stop offset="95%" stopColor="#f43f5e" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--border-subtle)" />
                  <XAxis dataKey="date" stroke="var(--text-muted)" fontSize={11} />
                  <YAxis stroke="var(--text-muted)" fontSize={11} />
                  <Tooltip contentStyle={{ backgroundColor: 'var(--bg-modal)', borderColor: 'var(--border-standard)', borderRadius: '12px' }} />
                  <Area type="monotone" dataKey="gmv" stroke="#ec4899" strokeWidth={2.5} fillOpacity={1} fill="url(#colorGmv)" name="GMV Reserva" />
                  <Area type="monotone" dataKey="income" stroke="#f43f5e" strokeWidth={2.5} fillOpacity={1} fill="url(#colorIncome)" name="Ingreso Plataforma" />
                </AreaChart>
              </ResponsiveContainer>
            )}
          </div>
        </div>

        {/* Bar Category Popularity */}
        <div className="card">
          <div className="card-header">
            <div>
              <h3 className="card-title">Participación por Categoría</h3>
              <p className="card-subtitle">Desglose analítico de los servicios estéticos más solicitados</p>
            </div>
          </div>
          <div className="card-content" style={{ height: '320px' }}>
            {categoryData.length === 0 ? (
              <div className="flex items-center justify-center h-full text-muted">
                Sin datos de categorías registrados en el backend.
              </div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={categoryData} layout="vertical">
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--border-subtle)" horizontal={false} />
                  <XAxis type="number" stroke="var(--text-muted)" fontSize={11} />
                  <YAxis dataKey="category" type="category" stroke="var(--text-muted)" fontSize={11} width={80} />
                  <Tooltip contentStyle={{ backgroundColor: 'var(--bg-modal)', borderColor: 'var(--border-standard)', borderRadius: '12px' }} />
                  <Bar dataKey="total_revenue" radius={[0, 8, 8, 0]} barSize={20} name="Ingresos Totales">
                    {categoryData.map((entry, idx) => (
                      <Cell key={`cell-${idx}`} fill={entry.color} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            )}
          </div>
        </div>
      </section>
    </>
  );
}

function BoardTab({
  selectedDirector,
  setSelectedDirector,
  checklists,
  toggleChecklist,
  decisions,
  handleStatusChange,
  newDecisionTitle,
  setNewDecisionTitle,
  newDecisionDesc,
  setNewDecisionDesc,
  handleAddDecision
}: any) {
  return (
    <div className="space-y-6">
      <div className="card border-warning bg-warning-bg/30">
        <div className="card-content">
          <p className="body-sm text-warning">
            Esta pestaña usa datos de demostración locales (checklist, minutas y KPIs de ejemplo): no los respalda ningún endpoint del backend y no se persisten.
          </p>
        </div>
      </div>

      {/* Hybrid KPIs */}
      <section className="kpi-grid">
        {[
          { title: 'LTV / CAC Ratio', value: '4.2x', sub: 'Salud de Adquisición (>3.5x)', desc: 'Costo amortizado en 6 meses', icon: Award, color: 'info' },
          { title: 'SLA Respuesta SOS', value: '3m 45s', sub: 'Objetivo: < 5m 00s', desc: 'Despacho y reporte policial', icon: ShieldAlert, color: 'danger' },
          { title: 'Latencia PostGIS', value: '28 ms', sub: 'Tiempo de Geo-query', desc: 'Carga de prestadores en mapa', icon: Zap, color: 'warning' },
          { title: 'Tasa Error Splits', value: '0.002%', sub: 'Errores de conciliación', desc: 'Desviaciones en transferencias', icon: Activity, color: 'success' }
        ].map((kpi, idx) => {
          const Icon = kpi.icon;
          return (
            <div key={idx} className="kpi-card" style={{ minHeight: '176px' }}>
              <div className="kpi-header">
                <span className="kpi-title">{kpi.title}</span>
                <div className={`kpi-icon ${kpi.color}`}>
                  <Icon size={22} />
                </div>
              </div>
              <p className="kpi-value" style={{ fontSize: '3rem' }}>{kpi.value}</p>
              <span className="caption text-muted" style={{ display: 'block', marginBottom: '4px' }}>{kpi.sub}</span>
              <span className="micro text-subtle" style={{ fontStyle: 'italic' }}>{kpi.desc}</span>
            </div>
          );
        })}
      </section>

      {/* Director Panel & Checklists */}
      <section className="card-grid">
        <div className="card">
          <div className="card-content" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
            <div className="mb-6">
              <h3 className="card-title mb-2">Panel de Auditoría de Directores</h3>
              <p className="card-subtitle mb-6">Seleccione un directivo para revisar y gestionar sus objetivos pendientes de la junta.</p>
              
              <div className="grid grid-cols-2 gap-3">
                {[
                  { id: 'COO', label: 'COO • Operaciones', desc: 'Despacho & SLA' },
                  { id: 'CTO', label: 'CTO • Tecnología', desc: 'PostGIS & SSL' },
                  { id: 'CFO', label: 'CFO • Finanzas', desc: 'Splits & Wompi' },
                  { id: 'CMO', label: 'CMO • Mercadeo', desc: 'CAC & Promos' }
                ].map(dir => (
                  <button
                    key={dir.id}
                    onClick={() => setSelectedDirector(dir.id)}
                    className={`p-3 rounded-xl border text-left transition-fast flex flex-col justify-between ${
                      selectedDirector === dir.id
                        ? 'bg-brand-gold-bg border-brand-gold-border text-brand-gold shadow-md'
                        : 'bg-bg-panel border-border-subtle hover:bg-bg-elevated text-text-secondary'
                    }`}
                  >
                    <span className="caption font-bold">{dir.label}</span>
                    <span className="micro text-muted mt-1">{dir.desc}</span>
                  </button>
                ))}
              </div>
            </div>

            <div className="mt-auto pt-4 border-t border-subtle text-xs text-muted flex items-center gap-2">
              <CheckSquare className="icon text-gold" size={16} />
              <span>Haga clic en un ítem de la checklist para cambiar su estado.</span>
            </div>
          </div>
        </div>

        {/* Checklist Panel */}
        <div className="card lg:col-span-2">
          <div className="card-header">
            <div>
              <h3 className="card-title">Cola de Objetivos Directivos • {selectedDirector}</h3>
              <p className="card-subtitle">Checklist operativa para seguimiento de sinergia institucional</p>
            </div>
            <span className="chip chip-sm">
              {checklists[selectedDirector].filter((x: { completed: boolean }) => x.completed).length} / {checklists[selectedDirector].length} Completado
            </span>
          </div>
          <div className="card-content space-y-3">
            {checklists[selectedDirector].map((item: { id: number; text: string; completed: boolean }) => (
              <div
                key={item.id}
                onClick={() => toggleChecklist(selectedDirector, item.id)}
                className={`p-4 rounded-xl border cursor-pointer transition-fast flex items-center justify-between ${
                  item.completed
                    ? 'bg-bg-panel border-border-subtle opacity-60 text-muted line-through'
                    : 'bg-bg-surface border-border-standard hover:border-brand text-text-secondary'
                }`}
              >
                <div className="flex items-center gap-3">
                  <div className={`w-5 h-5 rounded-lg border flex items-center justify-center transition-fast ${
                    item.completed
                      ? 'bg-success-bg border-success text-success'
                      : 'border-border-standard'
                  }`}>
                    {item.completed && <CheckCircle className="w-3.5 h-3.5" />}
                  </div>
                  <span className="body-sm font-medium">{item.text}</span>
                </div>
                <span className={`chip chip-sm ${item.completed ? 'success' : 'warning'}`}>
                  {item.completed ? 'Hecho' : 'Pendiente'}
                </span>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Synergy Matrix */}
      <section className="card">
        <div className="card-header">
          <div>
            <h3 className="card-title">Matriz de Sinergia y Flujo de Impacto</h3>
            <p className="card-subtitle">Audite cómo influye cada vector tecnológico y de marketing en el rendimiento transaccional general</p>
          </div>
        </div>
        <div className="card-content">
          <div className="card-grid">
            {[
              { area: 'Tecnología (CTO)', target: 'Operaciones (COO)', impact: 'La optimización de latencia PostGIS a <30ms permite un despacho y agendamiento 20% más rápido en zonas críticas.' },
              { area: 'Operaciones (COO)', target: 'Finanzas (CFO)', impact: 'La reducción del SLA SOS disminuye las cancelaciones de reservas y retiene el flujo bruto facturado.' },
              { area: 'Finanzas (CFO)', target: 'Marketing (CMO)', impact: 'La conciliación de splits al 100% de efectividad permite liberar bonos de referidos para capturar nuevos usuarios a menor CAC.' },
              { area: 'Marketing (CMO)', target: 'Tecnología (CTO)', impact: 'El aumento de reservas en categorías específicas (ej. Uñas) exige clusters de Geo-query eficientes en la base de datos.' }
            ].map((sinergia, idx) => (
              <div key={idx} className="card card-interactive">
                <div className="card-content">
                  <div>
                    <div className="flex items-center justify-between mb-3">
                      <span className="label text-gold">{sinergia.area}</span>
                      <span className="micro text-muted">Afecta a</span>
                    </div>
                    <h4 className="body-sm font-semibold text-primary mb-2">{sinergia.target}</h4>
                    <p className="body-sm text-muted leading-relaxed">{sinergia.impact}</p>
                  </div>
                  <div className="mt-4 pt-3 border-t border-subtle flex items-center gap-1.5 label text-gold">
                    <Layers className="icon" size={14} />
                    <span>Flujo de Impacto Activo</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Decisions Log */}
      <section className="card-grid">
        <div className="card lg:col-span-2">
          <div className="card-header">
            <div>
              <h3 className="card-title">Bitácora de Decisiones Directivas</h3>
              <p className="card-subtitle">Historial activo de minutas de junta y decisiones estratégicas</p>
            </div>
          </div>
          <div className="card-content space-y-4">
            {decisions.map((dec: { id: number; title: string; date: string; status: string; desc: string }) => (
              <div key={dec.id} className="p-4 rounded-xl border border-border-standard bg-bg-panel flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div className="space-y-1.5 flex-1">
                  <div className="flex items-center gap-3">
                    <span className={`chip chip-sm ${dec.status === 'Aprobado' ? 'success' : dec.status === 'Rechazado' ? 'danger' : 'warning'}`}>
                      {dec.status}
                    </span>
                    <span className="micro text-muted">{dec.date}</span>
                  </div>
                  <h4 className="body-sm font-bold text-primary">{dec.title}</h4>
                  <p className="body-sm text-muted">{dec.desc}</p>
                </div>

                <div className="flex gap-2">
                  {['Aprobado', 'En Discusión', 'Rechazado'].map(st => (
                    <button
                      key={st}
                      onClick={() => handleStatusChange(dec.id, st)}
                      className={`btn btn-tertiary btn-sm ${
                        dec.status === st
                          ? st === 'Aprobado' ? 'bg-success-bg text-success border-success-border'
                          : st === 'Rechazado' ? 'bg-danger-bg text-danger border-danger-border'
                          : 'bg-warning-bg text-warning'
                          : ''
                      }`}
                    >
                      {st}
                    </button>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Add Decision Form */}
        <div className="card">
          <div className="card-header">
            <h3 className="card-title">Registrar Nueva Minuta</h3>
            <p className="card-subtitle">Añada una decisión acordada por la junta directiva en tiempo real.</p>
          </div>
          <div className="card-content">
            <form onSubmit={handleAddDecision} className="space-y-4">
              <div>
                <label className="form-label">Título de la Decisión</label>
                <input
                  type="text"
                  required
                  value={newDecisionTitle}
                  onChange={(e) => setNewDecisionTitle(e.target.value)}
                  placeholder="Ej. Reducir comisión de onboarding"
                  className="form-input"
                />
              </div>
              <div>
                <label className="form-label">Detalle o Minuta</label>
                <textarea
                  required
                  value={newDecisionDesc}
                  onChange={(e) => setNewDecisionDesc(e.target.value)}
                  rows={4}
                  placeholder="Detalle los directivos involucrados y el plan de ejecución..."
                  className="form-input form-textarea"
                />
              </div>
              <button type="submit" className="btn btn-primary w-full">
                <PlusCircle className="icon" size={16} />
                <span>Publicar Decisión</span>
              </button>
            </form>
          </div>
        </div>
      </section>
    </div>
  );
}

function KycTab({
  pendingProviders,
  failedSections,
  handleApproveProvider,
  handleRejectProvider
}: any) {
  return (
    <section className="space-y-6">
      <div className="section-header">
        <div>
          <h3 className="section-title">Verificación de Perfiles de Prestadores (KYC)</h3>
          <p className="section-subtitle">Verifique los documentos legales y apruebe perfiles para activar su insignia verificada verde.</p>
        </div>
      </div>

      {pendingProviders.length === 0 ? (
        <div className="card p-8 text-center">
          {failedSections.includes('kyc') ? (
            <>
              <ShieldAlert className="icon text-danger mx-auto mb-4" size={48} />
              <h4 className="h3 text-primary mb-2">No se pudo consultar la cola de KYC</h4>
              <p className="body-sm text-muted max-w-sm mx-auto">La petición al backend falló: no se puede afirmar que no haya verificaciones pendientes.</p>
            </>
          ) : (
            <>
              <CheckCircle className="icon text-success mx-auto mb-4" size={48} />
              <h4 className="h3 text-primary mb-2">¡Todo al día!</h4>
              <p className="body-sm text-muted max-w-sm mx-auto">No quedan solicitudes de verificación de prestadores pendientes en la cola.</p>
            </>
          )}
        </div>
      ) : (
        <div className="card">
          <div className="card-content space-y-6">
            {pendingProviders.map((prov: PendingProvider) => (
              <div key={prov.id} className="card card-interactive">
                <div className="card-content flex flex-col lg:flex-row justify-between gap-6">
                  <div className="space-y-4 flex-1">
                    <div className="flex items-center gap-3">
                      <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-rose-500 to-pink-500 p-0.5 flex items-center justify-center font-bold text-white text-base">
                        {prov.nombre[0]}
                      </div>
                      <div>
                        <h4 className="body font-bold text-primary">{prov.nombre}</h4>
                        <p className="caption text-muted">{prov.business_name} • <span className="text-rose">{prov.email}</span></p>
                      </div>
                    </div>

                    <p className="body-sm text-secondary bg-bg-panel p-4 rounded-xl border border-border-subtle leading-relaxed">
                      {prov.description}
                    </p>

                    {/* Documents */}
                    <div className="flex flex-wrap gap-4">
                      {[
                        { label: 'Documento ID / Cédula', url: prov.documento_id_url },
                        { label: 'Registro Único Tributario (RUT)', url: prov.rut_url },
                        { label: 'Certificación de Bioseguridad', url: prov.certificacion_url }
                      ].map((doc, idx) => (
                        <a
                          key={idx}
                          href={doc.url ?? undefined}
                          target="_blank"
                          rel="noreferrer"
                          className="btn btn-tertiary flex items-center gap-2"
                        >
                          <FileText className="icon text-rose" size={16} />
                          <span className="body-sm">{doc.label}</span>
                          <ExternalLink className="icon text-muted" size={14} />
                        </a>
                      ))}
                    </div>
                  </div>

                  {/* Action Buttons */}
                  <div className="flex lg:flex-col justify-end items-end gap-3 lg:w-48 shrink-0">
                    <button
                      onClick={() => handleApproveProvider(prov.id)}
                      className="btn btn-primary w-full"
                    >
                      <CheckCircle className="icon" size={16} />
                      <span>Aprobar KYC</span>
                    </button>
                    <button
                      onClick={() => handleRejectProvider(prov.id)}
                      className="btn btn-danger w-full"
                    >
                      <XCircle className="icon" size={16} />
                      <span>Rechazar</span>
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </section>
  );
}

function SosTab({
  sosAlerts,
  failedSections,
  handleResolveSOS
}: any) {
  return (
    <section className="space-y-6">
      <div className="section-header">
        <div>
          <h3 className="section-title flex items-center gap-2.5">
            <ShieldAlert className="icon text-danger animate-pulse" size={24} />
            <span>Monitoreo de Emergencias SOS</span>
          </h3>
          <p className="section-subtitle">Atienda y coordine asistencia policial para alertas SOS emitidas por clientes o conductores durante trayectos.</p>
        </div>
      </div>

      {sosAlerts.length === 0 ? (
        <div className="card p-8 text-center">
          {failedSections.includes('sos') ? (
            <>
              <ShieldAlert className="icon text-danger mx-auto mb-4" size={48} />
              <h4 className="h3 text-primary mb-2">No se pudieron consultar las alertas SOS</h4>
              <p className="body-sm text-muted max-w-sm mx-auto">La petición al backend falló: no se puede afirmar que no haya emergencias activas.</p>
            </>
          ) : (
            <>
              <CheckCircle className="icon text-success mx-auto mb-4" size={48} />
              <h4 className="h3 text-primary mb-2">¡No hay emergencias!</h4>
              <p className="body-sm text-muted max-w-sm mx-auto">El backend no reporta alertas SOS pendientes.</p>
            </>
          )}
        </div>
      ) : (
        <div className="card-grid">
          {sosAlerts.map((alert: SosAlert) => (
            <div key={alert.id} className="card border-danger bg-danger-bg/30">
              <div className="relative">
                <div className="absolute top-0 right-0 px-4 py-1.5 bg-danger-bg border-b border-l border-danger-border text-danger text-label font-bold uppercase rounded-bl-xl">
                  Alta Prioridad
                </div>

                <div className="card-content space-y-6">
                  <div className="space-y-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-danger-bg border border-danger-border flex items-center justify-center text-danger">
                        <ShieldAlert className="icon animate-bounce" size={24} />
                      </div>
                      <div>
                        <h4 className="body font-bold text-primary">Alerta de Pánico #{alert.id}</h4>
                        <span className="caption text-muted flex items-center gap-1">
                          <Clock className="icon" size={14} />
                          {alert.fecha_creacion ? new Date(alert.fecha_creacion).toLocaleString('es-CO') : 'Fecha no disponible'}
                        </span>
                      </div>
                    </div>

                    <div className="space-y-2 caption">
                      <div className="flex justify-between items-center border-b border-subtle pb-2">
                        <span className="text-muted font-medium">Cliente:</span>
                        <span className="text-primary font-bold">{alert.client_name || 'No informado'} ({alert.client_phone || 'sin teléfono'})</span>
                      </div>
                      <div className="flex justify-between items-center border-b border-subtle pb-2">
                        <span className="text-muted font-medium">Prestador:</span>
                        <span className="text-primary font-bold">{alert.provider_name || 'No informado'} ({alert.provider_phone || 'sin teléfono'})</span>
                      </div>
                      <div className="flex justify-between items-center border-b border-subtle pb-2">
                        <span className="text-muted font-medium">Ubicación GPS:</span>
                        <span className="text-danger font-bold flex items-center gap-1">
                          <MapPin className="icon" size={14} />
                          {alert.latitude}, {alert.longitude}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Emergency Map */}
                  <div className="w-full h-36 rounded-xl overflow-hidden border border-danger-border relative">
                    <iframe
                      width="100%"
                      height="100%"
                      frameBorder="0"
                      scrolling="no"
                      marginHeight={0}
                      marginWidth={0}
                      title={`Mapa Alerta ${alert.id}`}
                      src={`https://maps.google.com/maps?q=${alert.latitude},${alert.longitude}&z=14&output=embed`}
                    />
                  </div>

                  <div className="flex gap-4 pt-2">
                    <a
                      href={`https://www.google.com/maps?q=${alert.latitude},${alert.longitude}`}
                      target="_blank"
                      rel="noreferrer"
                      className="btn btn-secondary flex-1"
                    >
                      <ExternalLink className="icon" size={16} />
                      <span>Ver en Maps</span>
                    </a>
                    <button
                      onClick={() => handleResolveSOS(alert.id)}
                      className="btn btn-danger flex-1"
                    >
                      <CheckCircle className="icon" size={16} />
                      <span>Resolver Alerta</span>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </section>
  );
}