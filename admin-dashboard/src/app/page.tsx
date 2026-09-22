"use client";

import React, { useState, useEffect } from 'react';
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
  PlusCircle
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

/**
 * Token de la sesión real de administrador.
 * NUNCA se debe leer de una variable NEXT_PUBLIC_*: todo lo que empieza por
 * NEXT_PUBLIC_ se inlinea en el bundle público y el JWT quedaría expuesto.
 */
function getAdminSessionToken(): string | null {
  if (typeof window === 'undefined') return null;
  return window.localStorage.getItem('adminToken') || window.localStorage.getItem('glow_token');
}

/** Valor monetario o marca de "sin datos" (nunca un número inventado). */
function formatCOPSafe(val: number | null | undefined) {
  if (val === null || val === undefined || Number.isNaN(Number(val))) return 'Sin datos';
  return new Intl.NumberFormat('es-CO', {
    style: 'currency',
    currency: 'COP',
    minimumFractionDigits: 0
  }).format(Number(val));
}

export default function Dashboard() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [loading, setLoading] = useState(true);
  const [backendStatus, setBackendStatus] = useState('Comprobando conexión...');
  // Sin datos simulados: los estados arrancan vacíos/sin datos hasta que responda el backend.
  const [metrics, setMetrics] = useState<FinancialMetrics | null>(null);
  const [dailyHistory, setDailyHistory] = useState<DailyHistoryPoint[]>([]);
  const [categoryData, setCategoryData] = useState<CategoryPoint[]>([]);
  const [sosAlerts, setSosAlerts] = useState<SosAlert[]>([]);
  const [pendingProviders, setPendingProviders] = useState<PendingProvider[]>([]);
  const [dataError, setDataError] = useState<string | null>(null);
  const [failedSections, setFailedSections] = useState<string[]>([]);
  const [actionMessage, setActionMessage] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  // board meeting state
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

  // Datos reales del backend. Sin sesión o sin backend NO se muestra ningún dato simulado.
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

  // Endpoints reales en backend/src/modules/admin-glow/admin.routes.js
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

  // Alarma acústica para emergencias SOS
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

  return (
    <div className="flex h-screen w-full bg-[#0b0f19] text-slate-100 font-sans overflow-hidden">
      {/* Sidebar Menu */}
      <aside className="w-64 bg-slate-900/60 backdrop-blur-xl border-r border-slate-800 flex flex-col justify-between p-6">
        <div>
          {/* Logo */}
          <div className="flex items-center gap-3 mb-10">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-rose-500 to-pink-500 flex items-center justify-center font-bold text-white shadow-lg shadow-pink-500/20">
              G
            </div>
            <div>
              <h1 className="font-extrabold text-lg tracking-tight bg-gradient-to-r from-white via-slate-200 to-slate-400 bg-clip-text text-transparent">GlowAdmin</h1>
              <span className="text-[10px] text-slate-500 font-semibold uppercase tracking-widest">Enterprise Panel</span>
            </div>
          </div>

          {/* Menú Links */}
          <nav className="space-y-2">
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
                  onClick={() => setActiveTab(tab.id)}
                  className={`w-full flex items-center justify-between px-4 py-3 rounded-xl transition-all duration-300 font-medium ${
                    isActive 
                      ? 'bg-gradient-to-r from-rose-500/10 to-pink-500/10 border border-pink-500/20 text-rose-400 shadow-lg shadow-rose-500/5' 
                      : 'text-slate-400 hover:text-white hover:bg-slate-800/40 border border-transparent'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <Icon className={`w-5 h-5 ${isActive ? 'text-rose-400' : 'text-slate-400'}`} />
                    <span>{tab.label}</span>
                  </div>
                  {tab.badge !== undefined && tab.badge > 0 && (
                    <span className={`px-2 py-0.5 rounded-full text-xs font-bold ${
                      tab.isAlert 
                        ? 'bg-rose-500 text-white animate-pulse' 
                        : 'bg-slate-800 text-slate-300'
                    }`}>
                      {tab.badge}
                    </span>
                  )}
                </button>
              );
            })}
          </nav>
        </div>

        {/* Footer info */}
        <div className="bg-slate-800/40 border border-slate-850 p-4 rounded-2xl flex flex-col gap-1.5">
          <div className="flex items-center gap-2">
            <span className={`w-2 h-2 rounded-full ${backendStatus.includes('Conectado') ? 'bg-emerald-500' : 'bg-amber-500'}`} />
            <span className="text-xs font-medium text-slate-300">{backendStatus}</span>
          </div>
          <p className="text-[10px] text-slate-500">v1.2.0 • SSL Activado</p>
        </div>
      </aside>

      {/* Main Panel Area */}
      <main className="flex-1 flex flex-col overflow-y-auto bg-slate-950/40">
        {/* Header bar */}
        <header className="h-20 border-b border-slate-900 flex items-center justify-between px-8 bg-slate-950/20 backdrop-blur-md sticky top-0 z-50">
          <div>
            <h2 className="text-xl font-bold text-white capitalize">
              {activeTab === 'dashboard' ? 'Resumen de Negocio' : activeTab === 'board' ? 'Reunión Directiva' : activeTab}
            </h2>
            <p className="text-xs text-slate-400">Monitoreo operativo y financiero en tiempo real</p>
          </div>

          <div className="flex items-center gap-4">
            {/* Notificaciones */}
            <div className="relative cursor-pointer w-10 h-10 rounded-xl bg-slate-900 border border-slate-800 flex items-center justify-center text-slate-400 hover:text-white hover:border-slate-700 transition-all duration-300">
              <Bell className="w-5 h-5" />
              {sosAlerts.length > 0 && (
                <span className="absolute top-1.5 right-1.5 w-2.5 h-2.5 bg-rose-500 rounded-full border border-slate-900 animate-ping" />
              )}
            </div>

            {/* Perfil Admin */}
            <div className="flex items-center gap-3 pl-4 border-l border-slate-800">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-rose-400 via-pink-500 to-indigo-600 p-0.5 shadow-md">
                <div className="w-full h-full rounded-[10px] bg-slate-950 flex items-center justify-center text-white text-xs font-bold">
                  AD
                </div>
              </div>
              <div>
                <p className="text-xs font-bold text-white">Administrador Glow</p>
                <span className="text-[10px] text-rose-400 font-semibold tracking-wider uppercase">Super Admin</span>
              </div>
            </div>
          </div>
        </header>

        {/* Tab contents */}
        <div className="p-8 space-y-8 flex-1">
          {/* Estado real de los datos: errores de carga y resultado de acciones */}
          {dataError && (
            <div className="flex items-start justify-between gap-4 rounded-2xl border border-rose-500/40 bg-rose-500/10 px-5 py-4">
              <div className="flex items-start gap-3">
                <ShieldAlert className="w-4 h-4 mt-0.5 shrink-0 text-rose-400" />
                <span className="text-xs font-semibold text-rose-300">{dataError}</span>
              </div>
              <button
                onClick={() => fetchDashboardData()}
                className="shrink-0 px-3 py-1.5 rounded-xl border border-rose-500/40 text-[11px] font-bold text-rose-300 hover:bg-rose-500/10 transition-all"
              >
                Reintentar
              </button>
            </div>
          )}
          {actionError && (
            <div className="rounded-2xl border border-amber-500/40 bg-amber-500/10 px-5 py-4 text-xs font-semibold text-amber-300">
              {actionError}
            </div>
          )}
          {actionMessage && (
            <div className="rounded-2xl border border-emerald-500/40 bg-emerald-500/10 px-5 py-4 text-xs font-semibold text-emerald-300">
              {actionMessage}
            </div>
          )}
          {/* TAB 1: DASHBOARD METRICS */}
          {activeTab === 'dashboard' && (
            <>
              {/* Financial KPI Cards */}
              <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                {[
                  { title: 'GMV Facturado', value: loading ? 'Cargando...' : formatCOP(metrics?.gmv), sub: 'Total de reservas completadas', icon: DollarSign, color: 'from-emerald-500 to-teal-500 bg-emerald-500/10 border-emerald-500/20 text-emerald-400' },
                  { title: 'Comisión Plataforma (12%)', value: loading ? 'Cargando...' : formatCOP(metrics?.total_commission), sub: 'Neto de GlowApp', icon: Percent, color: 'from-pink-500 to-rose-500 bg-pink-500/10 border-pink-500/20 text-pink-400' },
                  { title: 'Impuesto Recaudado (8%)', value: loading ? 'Cargando...' : formatCOP(metrics?.total_taxes), sub: 'Retenciones tributarias', icon: Activity, color: 'from-amber-500 to-orange-500 bg-amber-500/10 border-amber-500/20 text-amber-400' },
                  { title: 'Dispersión Prestadores', value: loading ? 'Cargando...' : formatCOP(metrics?.total_provider_payouts), sub: 'Transferido a profesionales', icon: Users, color: 'from-indigo-500 to-cyan-500 bg-indigo-500/10 border-indigo-500/20 text-indigo-400' }
                ].map((kpi, idx) => {
                  const Icon = kpi.icon;
                  return (
                    <div 
                      key={idx} 
                      className={`relative overflow-hidden p-6 rounded-3xl border backdrop-blur-md transition-all duration-300 hover:scale-[1.02] flex flex-col justify-between h-40 ${kpi.color}`}
                    >
                      <div className="flex justify-between items-start">
                        <div>
                          <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">{kpi.title}</span>
                          <p className="text-2xl font-black text-white mt-2 tracking-tight">{kpi.value}</p>
                        </div>
                        <div className="p-3 rounded-2xl bg-white/5 backdrop-blur-md">
                          <Icon className="w-5 h-5" />
                        </div>
                      </div>
                      <span className="text-[11px] text-slate-400">{kpi.sub}</span>
                    </div>
                  );
                })}
              </section>

              {/* Graphic Charts Analysis */}
              <section className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* 30-Day Area Chart */}
                <div className="lg:col-span-2 bg-slate-900/40 border border-slate-900 p-6 rounded-3xl backdrop-blur-md">
                  <div className="flex justify-between items-center mb-6">
                    <div>
                      <h3 className="text-base font-bold text-white">Evolución Semanal de Facturación</h3>
                      <p className="text-xs text-slate-400">Comparativa diaria de volumen de ventas e ingresos</p>
                    </div>
                  </div>
                  {dailyHistory.length === 0 ? (
                    <div className="h-80 w-full flex items-center justify-center rounded-2xl border border-dashed border-slate-800 text-xs text-slate-400">
                      Sin datos de facturación registrados en el backend.
                    </div>
                  ) : (
                  <div className="h-80 w-full">
                    <ResponsiveContainer width="100%" height="100%">
                      <AreaChart data={dailyHistory}>
                        <defs>
                          <linearGradient id="colorGmv" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="5%" stopColor="#ec4899" stopOpacity={0.2}/>
                            <stop offset="95%" stopColor="#ec4899" stopOpacity={0}/>
                          </linearGradient>
                          <linearGradient id="colorIncome" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="5%" stopColor="#f43f5e" stopOpacity={0.2}/>
                            <stop offset="95%" stopColor="#f43f5e" stopOpacity={0}/>
                          </linearGradient>
                        </defs>
                        <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" />
                        <XAxis dataKey="date" stroke="#64748b" fontSize={11} />
                        <YAxis stroke="#64748b" fontSize={11} />
                        <Tooltip contentStyle={{ backgroundColor: '#0f172a', borderColor: '#334155', borderRadius: '12px' }} />
                        <Area type="monotone" dataKey="gmv" stroke="#ec4899" strokeWidth={2.5} fillOpacity={1} fill="url(#colorGmv)" name="GMV Reserva" />
                        <Area type="monotone" dataKey="income" stroke="#f43f5e" strokeWidth={2.5} fillOpacity={1} fill="url(#colorIncome)" name="Ingreso Plataforma" />
                      </AreaChart>
                    </ResponsiveContainer>
                  </div>
                  )}
                </div>

                {/* Bar Category Popularity */}
                <div className="bg-slate-900/40 border border-slate-900 p-6 rounded-3xl backdrop-blur-md">
                  <div>
                    <h3 className="text-base font-bold text-white">Participación por Categoría</h3>
                    <p className="text-xs text-slate-400 mb-6">Desglose analítico de los servicios estéticos más solicitados</p>
                  </div>
                  {categoryData.length === 0 ? (
                    <div className="h-80 w-full flex items-center justify-center rounded-2xl border border-dashed border-slate-800 text-xs text-slate-400">
                      Sin datos de categorías registrados en el backend.
                    </div>
                  ) : (
                  <div className="h-80 w-full flex items-center justify-center">
                    <ResponsiveContainer width="100%" height="100%">
                      <BarChart data={categoryData} layout="vertical">
                        <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" horizontal={false} />
                        <XAxis type="number" stroke="#64748b" fontSize={11} />
                        <YAxis dataKey="category" type="category" stroke="#64748b" fontSize={11} width={80} />
                        <Tooltip contentStyle={{ backgroundColor: '#0f172a', borderColor: '#334155', borderRadius: '12px' }} />
                        <Bar dataKey="total_revenue" radius={[0, 8, 8, 0]} barSize={20} name="Ingresos Totales">
                          {categoryData.map((entry, idx) => (
                            <Cell key={`cell-${idx}`} fill={entry.color} />
                          ))}
                        </Bar>
                      </BarChart>
                    </ResponsiveContainer>
                  </div>
                  )}
                </div>
              </section>
            </>
          )}

          {/* TAB 1.5: BOARD MEETING (Reunión Directiva) */}
          {activeTab === 'board' && (
            <div className="space-y-8">
              {/* Maqueta local: el backend no expone ningún endpoint de reunión directiva. */}
              <div className="rounded-2xl border border-amber-500/40 bg-amber-500/10 px-5 py-4 text-xs font-semibold text-amber-300">
                Esta pestaña usa datos de demostración locales (checklist, minutas y KPIs de ejemplo): no los respalda ningún endpoint del backend y no se persisten.
              </div>
              {/* KPIs Híbridos Interdependientes */}
              <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                {[
                  { title: 'LTV / CAC Ratio', value: '4.2x', sub: 'Salud de Adquisición (>3.5x)', desc: 'Costo amortizado en 6 meses', icon: Award, color: 'from-purple-500 to-indigo-500 bg-purple-500/10 border-purple-500/20 text-purple-400' },
                  { title: 'SLA Respuesta SOS', value: '3m 45s', sub: 'Objetivo: < 5m 00s', desc: 'Despacho y reporte policial', icon: ShieldAlert, color: 'from-rose-500 to-red-500 bg-rose-500/10 border-rose-500/20 text-rose-400' },
                  { title: 'Latencia PostGIS', value: '28 ms', sub: 'Tiempo de Geo-query', desc: 'Carga de prestadores en mapa', icon: Zap, color: 'from-amber-500 to-yellow-500 bg-amber-500/10 border-amber-500/20 text-amber-400' },
                  { title: 'Tasa Error Splits', value: '0.002%', sub: 'Errores de conciliación', desc: 'Desviaciones en transferencias', icon: Activity, color: 'from-emerald-500 to-teal-500 bg-emerald-500/10 border-emerald-500/20 text-emerald-400' }
                ].map((kpi, idx) => {
                  const Icon = kpi.icon;
                  return (
                    <div 
                      key={idx} 
                      className={`relative overflow-hidden p-6 rounded-3xl border backdrop-blur-md transition-all duration-300 hover:scale-[1.02] flex flex-col justify-between h-44 ${kpi.color}`}
                    >
                      <div className="flex justify-between items-start">
                        <div>
                          <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">{kpi.title}</span>
                          <p className="text-3xl font-black text-white mt-2 tracking-tight">{kpi.value}</p>
                          <span className="text-[10px] text-slate-300 font-medium block mt-1">{kpi.sub}</span>
                        </div>
                        <div className="p-3 rounded-2xl bg-white/5 backdrop-blur-md">
                          <Icon className="w-5 h-5" />
                        </div>
                      </div>
                      <span className="text-[10px] text-slate-500 italic mt-2">{kpi.desc}</span>
                    </div>
                  );
                })}
              </section>

              {/* Panel Dinámico de Directores y Checklists */}
              <section className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                <div className="lg:col-span-1 bg-slate-900/40 border border-slate-900 p-6 rounded-3xl backdrop-blur-md flex flex-col justify-between">
                  <div>
                    <h3 className="text-base font-bold text-white mb-2">Panel de Auditoría de Directores</h3>
                    <p className="text-xs text-slate-400 mb-6">Seleccione un directivo para revisar y gestionar sus objetivos pendientes de la junta.</p>
                    
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
                          className={`p-3 rounded-2xl border text-left transition-all duration-300 flex flex-col justify-between ${
                            selectedDirector === dir.id 
                              ? 'bg-rose-500/10 border-rose-500/40 text-rose-400 shadow-md shadow-rose-500/5' 
                              : 'bg-slate-950/40 border-slate-850 hover:bg-slate-800/40 text-slate-300'
                          }`}
                        >
                          <span className="text-xs font-bold">{dir.label}</span>
                          <span className="text-[10px] text-slate-500 mt-1">{dir.desc}</span>
                        </button>
                      ))}
                    </div>
                  </div>

                  <div className="mt-6 pt-6 border-t border-slate-900/60 text-xs text-slate-500 flex items-center gap-2">
                    <CheckSquare className="w-4 h-4 text-rose-400" />
                    <span>Haga clic en un ítem de la checklist de la derecha para cambiar su estado.</span>
                  </div>
                </div>

                {/* Checklist Panel */}
                <div className="lg:col-span-2 bg-slate-900/40 border border-slate-900 p-6 rounded-3xl backdrop-blur-md">
                  <div className="flex justify-between items-center mb-6">
                    <div>
                      <h3 className="text-base font-bold text-white">Cola de Objetivos Directivos • {selectedDirector}</h3>
                      <p className="text-xs text-slate-400">Checklist operativa para seguimiento de sinergia institucional</p>
                    </div>
                    <span className="px-3 py-1 bg-slate-950 text-slate-400 border border-slate-850 rounded-full text-xs font-bold uppercase tracking-wider">
                      {checklists[selectedDirector as keyof typeof checklists].filter(x => x.completed).length} / {checklists[selectedDirector as keyof typeof checklists].length} Completado
                    </span>
                  </div>

                  <div className="space-y-3">
                    {checklists[selectedDirector as keyof typeof checklists].map(item => (
                      <div 
                        key={item.id}
                        onClick={() => toggleChecklist(selectedDirector, item.id)}
                        className={`p-4 rounded-2xl border cursor-pointer transition-all duration-300 flex items-center justify-between ${
                          item.completed 
                            ? 'bg-slate-900/20 border-slate-850/30 opacity-60 text-slate-500 line-through' 
                            : 'bg-slate-950/40 border-slate-850 hover:border-slate-800 text-slate-300'
                        }`}
                      >
                        <div className="flex items-center gap-3">
                          <div className={`w-5 h-5 rounded-lg border flex items-center justify-center transition-all ${
                            item.completed 
                              ? 'bg-emerald-500/20 border-emerald-500 text-emerald-400' 
                              : 'border-slate-700'
                          }`}>
                            {item.completed && <CheckCircle className="w-3.5 h-3.5" />}
                          </div>
                          <span className="text-xs font-semibold">{item.text}</span>
                        </div>
                        <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                          item.completed 
                            ? 'bg-emerald-500/10 text-emerald-400' 
                            : 'bg-amber-500/10 text-amber-400 animate-pulse'
                        }`}>
                          {item.completed ? 'Hecho' : 'Pendiente'}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              </section>

              {/* Matriz de Sinergia y Flujo de Impacto */}
              <section className="bg-slate-900/40 border border-slate-900 p-6 rounded-3xl backdrop-blur-md">
                <div className="mb-6">
                  <h3 className="text-base font-bold text-white">Matriz de Sinergia y Flujo de Impacto</h3>
                  <p className="text-xs text-slate-400">Audite cómo influye cada vector tecnológico y de marketing en el rendimiento transaccional general</p>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                  {[
                    { area: 'Tecnología (CTO)', target: 'Operaciones (COO)', impact: 'La optimización de latencia PostGIS a <30ms permite un despacho y agendamiento 20% más rápido en zonas críticas.' },
                    { area: 'Operaciones (COO)', target: 'Finanzas (CFO)', impact: 'La reducción del SLA SOS disminuye las cancelaciones de reservas y retiene el flujo bruto facturado.' },
                    { area: 'Finanzas (CFO)', target: 'Marketing (CMO)', impact: 'La conciliación de splits al 100% de efectividad permite liberar bonos de referidos para capturar nuevos usuarios a menor CAC.' },
                    { area: 'Marketing (CMO)', target: 'Tecnología (CTO)', impact: 'El aumento de reservas en categorías específicas (ej. Uñas) exige clusters de Geo-query eficientes en la base de datos.' }
                  ].map((sinergia, idx) => (
                    <div key={idx} className="p-5 rounded-2xl bg-slate-950/40 border border-slate-850 hover:border-pink-500/20 hover:bg-slate-900/20 transition-all duration-300 flex flex-col justify-between">
                      <div>
                        <div className="flex items-center justify-between mb-3">
                          <span className="text-[10px] text-pink-400 font-bold uppercase tracking-wider">{sinergia.area}</span>
                          <span className="text-[10px] text-slate-500">Afecta a</span>
                        </div>
                        <h4 className="text-xs font-black text-white mb-2">{sinergia.target}</h4>
                        <p className="text-[11px] text-slate-400 leading-relaxed">{sinergia.impact}</p>
                      </div>
                      <div className="mt-4 pt-3 border-t border-slate-900/60 flex items-center gap-1.5 text-[10px] text-rose-400 font-bold">
                        <Layers className="w-3.5 h-3.5" />
                        <span>Flujo de Impacto Activo</span>
                      </div>
                    </div>
                  ))}
                </div>
              </section>

              {/* Bitácora de Decisiones Activas */}
              <section className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Decision List */}
                <div className="lg:col-span-2 bg-slate-900/40 border border-slate-900 p-6 rounded-3xl backdrop-blur-md">
                  <div className="mb-6">
                    <h3 className="text-base font-bold text-white">Bitácora de Decisiones Directivas</h3>
                    <p className="text-xs text-slate-400">Historial activo de minutas de junta y decisiones estratégicas</p>
                  </div>

                  <div className="space-y-4">
                    {decisions.map(dec => (
                      <div key={dec.id} className="p-5 rounded-2xl bg-slate-950/40 border border-slate-850 flex flex-col md:flex-row md:items-center justify-between gap-4">
                        <div className="space-y-1.5 flex-1">
                          <div className="flex items-center gap-3">
                            <span className={`px-2 py-0.5 rounded-full text-[10px] font-black uppercase tracking-wider ${
                              dec.status === 'Aprobado' 
                                ? 'bg-emerald-500/10 text-emerald-400' 
                                : dec.status === 'Rechazado' 
                                  ? 'bg-rose-500/10 text-rose-450' 
                                  : 'bg-amber-500/10 text-amber-400'
                            }`}>
                              {dec.status}
                            </span>
                            <span className="text-[10px] text-slate-500 font-semibold">{dec.date}</span>
                          </div>
                          <h4 className="text-xs font-bold text-white">{dec.title}</h4>
                          <p className="text-[11px] text-slate-400">{dec.desc}</p>
                        </div>

                        {/* Controles de Estado */}
                        <div className="flex gap-2">
                          {['Aprobado', 'En Discusión', 'Rechazado'].map(st => (
                            <button
                              key={st}
                              onClick={() => handleStatusChange(dec.id, st)}
                              className={`px-2.5 py-1.5 rounded-xl text-[10px] font-bold transition-all duration-300 ${
                                dec.status === st 
                                  ? st === 'Aprobado' 
                                    ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30' 
                                    : st === 'Rechazado' 
                                      ? 'bg-rose-500/20 text-rose-400 border border-rose-500/30' 
                                      : 'bg-amber-500/20 text-amber-400 border border-amber-500/30'
                                  : 'bg-slate-900 border border-slate-800 text-slate-400 hover:text-slate-200'
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

                {/* Form to add decision */}
                <div className="bg-slate-900/40 border border-slate-900 p-6 rounded-3xl backdrop-blur-md flex flex-col justify-between">
                  <div>
                    <h3 className="text-base font-bold text-white mb-2">Registrar Nueva Minuta</h3>
                    <p className="text-xs text-slate-400 mb-6">Añada una decisión acordada por la junta directiva en tiempo real.</p>

                    <form onSubmit={handleAddDecision} className="space-y-4">
                      <div>
                        <label className="text-[11px] font-bold text-slate-400 uppercase tracking-wider block mb-2">Título de la Decisión</label>
                        <input
                          type="text"
                          required
                          value={newDecisionTitle}
                          onChange={(e) => setNewDecisionTitle(e.target.value)}
                          placeholder="Ej. Reducir comisión de onboarding"
                          className="w-full px-4 py-3 bg-slate-950/60 border border-slate-850 focus:border-rose-500/30 focus:outline-none text-slate-300 text-xs rounded-xl"
                        />
                      </div>
                      <div>
                        <label className="text-[11px] font-bold text-slate-400 uppercase tracking-wider block mb-2">Detalle o Minuta</label>
                        <textarea
                          required
                          value={newDecisionDesc}
                          onChange={(e) => setNewDecisionDesc(e.target.value)}
                          rows={4}
                          placeholder="Detalle los directivos involucrados y el plan de ejecución..."
                          className="w-full px-4 py-3 bg-slate-950/60 border border-slate-850 focus:border-rose-500/30 focus:outline-none text-slate-300 text-xs rounded-xl resize-none"
                        />
                      </div>
                      <button
                        type="submit"
                        className="w-full flex items-center justify-center gap-2 px-5 py-3 bg-gradient-to-r from-rose-500 to-pink-500 hover:from-rose-600 hover:to-pink-600 text-white font-bold text-xs rounded-2xl shadow-lg shadow-rose-500/10 active:scale-95 transition-all duration-300"
                      >
                        <PlusCircle className="w-4 h-4" />
                        <span>Publicar Decisión</span>
                      </button>
                    </form>
                  </div>
                </div>
              </section>
            </div>
          )}

          {/* TAB 2: KYC PROVIDERS VALIDATION */}
          {activeTab === 'kyc' && (
            <section className="space-y-6">
              <div className="flex justify-between items-center">
                <div>
                  <h3 className="text-lg font-bold text-white">Verificación de Perfiles de Prestadores (KYC)</h3>
                  <p className="text-xs text-slate-400">Verifique los documentos legales y apruebe perfiles para activar su insignia verificada verde.</p>
                </div>
              </div>

              {pendingProviders.length === 0 ? (
                <div className="bg-slate-900/20 border border-slate-900 rounded-3xl p-12 text-center flex flex-col items-center justify-center">
                  {failedSections.includes('kyc') ? (
                    <>
                      <ShieldAlert className="w-12 h-12 text-rose-500 mb-4" />
                      <h4 className="text-base font-bold text-white">No se pudo consultar la cola de KYC</h4>
                      <p className="text-xs text-slate-400 max-w-sm mt-1">La petición al backend falló: no se puede afirmar que no haya verificaciones pendientes.</p>
                    </>
                  ) : (
                    <>
                      <CheckCircle className="w-12 h-12 text-emerald-500 mb-4" />
                      <h4 className="text-base font-bold text-white">¡Todo al día!</h4>
                      <p className="text-xs text-slate-400 max-w-sm mt-1">No quedan solicitudes de verificación de prestadores pendientes en la cola.</p>
                    </>
                  )}
                </div>
              ) : (
                <div className="grid grid-cols-1 gap-6">
                  {pendingProviders.map((prov) => (
                    <div key={prov.id} className="bg-slate-900/30 border border-slate-900 rounded-3xl p-6 backdrop-blur-md flex flex-col lg:flex-row justify-between gap-6 hover:border-slate-800 transition-all duration-300">
                      <div className="space-y-4 flex-1">
                        <div className="flex items-center gap-3">
                          <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-rose-500 to-pink-500 p-0.5 flex items-center justify-center font-bold text-white text-base">
                            {prov.nombre[0]}
                          </div>
                          <div>
                            <h4 className="text-base font-bold text-white">{prov.nombre}</h4>
                            <p className="text-xs text-slate-400">{prov.business_name} • <span className="text-rose-400">{prov.email}</span></p>
                          </div>
                        </div>

                        <p className="text-xs text-slate-300 bg-slate-950/40 p-4 rounded-2xl border border-slate-900/60 leading-relaxed">
                          {prov.description}
                        </p>

                        {/* Documentos */}
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
                              className="px-4 py-2 bg-slate-950/60 border border-slate-850 hover:border-slate-700 hover:bg-slate-900 text-slate-300 text-xs font-semibold rounded-xl flex items-center gap-2 transition-all duration-300"
                            >
                              <FileText className="w-4 h-4 text-pink-400" />
                              <span>{doc.label}</span>
                              <ExternalLink className="w-3.5 h-3.5 text-slate-500" />
                            </a>
                          ))}
                        </div>
                      </div>

                      {/* Botones de acción */}
                      <div className="flex lg:flex-col justify-end items-end gap-3 lg:w-48">
                        <button
                          onClick={() => handleApproveProvider(prov.id)}
                          className="w-full flex items-center justify-center gap-2 px-5 py-3 bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-600 hover:to-teal-600 text-white font-bold text-xs rounded-2xl shadow-lg shadow-emerald-500/10 hover:shadow-emerald-500/20 active:scale-95 transition-all duration-300"
                        >
                          <CheckCircle className="w-4 h-4" />
                          <span>Aprobar KYC</span>
                        </button>
                        <button
                          onClick={() => handleRejectProvider(prov.id)}
                          className="w-full flex items-center justify-center gap-2 px-5 py-3 bg-slate-900 border border-slate-800 hover:border-rose-500/30 hover:bg-rose-500/5 text-slate-300 hover:text-rose-400 font-bold text-xs rounded-2xl transition-all duration-300"
                        >
                          <XCircle className="w-4 h-4" />
                          <span>Rechazar</span>
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </section>
          )}

          {/* TAB 3: SOS ALERTS */}
          {activeTab === 'sos' && (
            <section className="space-y-6">
              <div>
                <h3 className="text-lg font-bold text-rose-500 flex items-center gap-2.5">
                  <ShieldAlert className="w-6 h-6 animate-pulse" />
                  <span>Monitoreo de Emergencias SOS</span>
                </h3>
                <p className="text-xs text-slate-400">Atienda y coordine asistencia policial para alertas SOS emitidas por clientes o conductores durante trayectos.</p>
              </div>

              {sosAlerts.length === 0 ? (
                <div className="bg-slate-900/20 border border-slate-900 rounded-3xl p-12 text-center flex flex-col items-center justify-center">
                  {failedSections.includes('sos') ? (
                    <>
                      <ShieldAlert className="w-12 h-12 text-rose-500 mb-4" />
                      <h4 className="text-base font-bold text-white">No se pudieron consultar las alertas SOS</h4>
                      <p className="text-xs text-slate-400 max-w-sm mt-1">La petición al backend falló: no se puede afirmar que no haya emergencias activas.</p>
                    </>
                  ) : (
                    <>
                      <CheckCircle className="w-12 h-12 text-emerald-500 mb-4" />
                      <h4 className="text-base font-bold text-white">¡No hay emergencias!</h4>
                      <p className="text-xs text-slate-400 max-w-sm mt-1">El backend no reporta alertas SOS pendientes.</p>
                    </>
                  )}
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  {sosAlerts.map((alert) => (
                    <div key={alert.id} className="relative overflow-hidden bg-slate-900/20 border border-rose-500/30 rounded-3xl p-6 backdrop-blur-md flex flex-col justify-between gap-6">
                      <div className="absolute top-0 right-0 px-4 py-1.5 bg-rose-500/20 border-b border-l border-rose-500/30 text-rose-400 text-[10px] font-black tracking-widest uppercase rounded-bl-2xl">
                        Alta Prioridad
                      </div>

                      <div className="space-y-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-xl bg-rose-500/10 border border-rose-500/20 flex items-center justify-center text-rose-400">
                            <ShieldAlert className="w-5 h-5 animate-bounce" />
                          </div>
                          <div>
                            <h4 className="text-base font-black text-white">Alerta de Pánico #{alert.id}</h4>
                            <span className="text-[10px] text-slate-500 font-bold flex items-center gap-1">
                              <Clock className="w-3.5 h-3.5" />
                              {alert.fecha_creacion ? new Date(alert.fecha_creacion).toLocaleString('es-CO') : 'Fecha no disponible'}
                            </span>
                          </div>
                        </div>

                        <div className="space-y-2 text-xs">
                          <div className="flex justify-between items-center border-b border-slate-900/50 pb-2">
                            <span className="text-slate-400 font-semibold">Cliente:</span>
                            <span className="text-white font-bold">{alert.client_name || 'No informado'} ({alert.client_phone || 'sin teléfono'})</span>
                          </div>
                          <div className="flex justify-between items-center border-b border-slate-900/50 pb-2">
                            <span className="text-slate-400 font-semibold">Prestador:</span>
                            <span className="text-white font-bold">{alert.provider_name || 'No informado'} ({alert.provider_phone || 'sin teléfono'})</span>
                          </div>
                          <div className="flex justify-between items-center border-b border-slate-900/50 pb-2">
                            <span className="text-slate-400 font-semibold">Ubicación GPS:</span>
                            <span className="text-rose-400 font-bold flex items-center gap-1">
                              <MapPin className="w-4 h-4" />
                              {alert.latitude}, {alert.longitude}
                            </span>
                          </div>
                        </div>
                      </div>

                      {/* Mapa Interactivo de Emergencia */}
                      <div className="w-full h-36 rounded-2xl overflow-hidden border border-rose-500/20 relative shadow-inner">
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

                      <div className="flex gap-4">
                        <a 
                          href={`https://www.google.com/maps?q=${alert.latitude},${alert.longitude}`}
                          target="_blank"
                          rel="noreferrer"
                          className="flex-1 flex items-center justify-center gap-2 px-4 py-3 bg-slate-900 hover:bg-slate-800 text-slate-300 font-bold text-xs rounded-2xl border border-slate-800 transition-all duration-300"
                        >
                          <ExternalLink className="w-4 h-4" />
                          <span>Ver en Maps</span>
                        </a>
                        <button
                          onClick={() => handleResolveSOS(alert.id)}
                          className="flex-1 flex items-center justify-center gap-2 px-4 py-3 bg-rose-500 hover:bg-rose-600 text-white font-bold text-xs rounded-2xl shadow-lg shadow-rose-500/10 active:scale-95 transition-all duration-300"
                        >
                          <CheckCircle className="w-4 h-4" />
                          <span>Resolver Alerta</span>
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </section>
          )}
        </div>
      </main>
    </div>
  );
}
