'use client';

import React, { useState, useEffect } from 'react';
import { 
  TrendingUp, 
  Users, 
  ShieldAlert, 
  DollarSign, 
  Activity, 
  Percent,
  Bell,
  FileText,
  ExternalLink,
  Clock,
  MapPin,
  CheckCircle,
  XCircle,
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

export default function DashboardPage() {
  const [loading, setLoading] = useState(true);
  const [backendStatus, setBackendStatus] = useState('Comprobando conexión...');
  const [metrics, setMetrics] = useState<FinancialMetrics | null>(null);
  const [dailyHistory, setDailyHistory] = useState<DailyHistoryPoint[]>([]);
  const [categoryData, setCategoryData] = useState<CategoryPoint[]>([]);
  const [sosAlerts, setSosAlerts] = useState<SosAlert[]>([]);
  const [pendingProviders, setPendingProviders] = useState<PendingProvider[]>([]);
  const [dataError, setDataError] = useState<string | null>(null);
  const [failedSections, setFailedSections] = useState<string[]>([]);

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
            ? data.categoryPopularity.map((c: any, i: number) => ({
                ...c,
                color: CATEGORY_COLORS[i % CATEGORY_COLORS.length],
              }))
            : []
        );
      } else {
        failures.push('financial');
      }

      if (sosRes.ok) {
        const resJson = await sosRes.json();
        const alerts = resJson?.data?.alerts ?? [];
        setSosAlerts(alerts);
      } else {
        failures.push('sos');
      }

      if (providersRes.ok) {
        const resJson = await providersRes.json();
        setPendingProviders(resJson?.data?.pending ?? []);
      } else {
        failures.push('kyc');
      }

      setFailedSections(failures);
      setBackendStatus(failures.length ? `Parcial: ${failures.join(', ')} fallaron` : 'Conectado');
    } catch (err) {
      console.error('[Dashboard] error:', err);
      setDataError('Error de red o CORS al contactar el backend.');
      setBackendStatus('Error de conexión');
      setFailedSections(['financial', 'sos', 'kyc']);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
    const interval = setInterval(fetchDashboardData, 60000);
    return () => clearInterval(interval);
  }, []);

  // KPI cards
  const kpis = [
    { title: 'GMV Facturado', value: loading ? 'Cargando...' : formatCOPSafe(metrics?.gmv), sub: 'Total de reservas completadas', icon: DollarSign, color: 'gold' },
    { title: 'Comisión Plataforma (12%)', value: loading ? 'Cargando...' : formatCOPSafe(metrics?.total_commission), sub: 'Neto de GlowApp', icon: Percent, color: 'rose' },
    { title: 'Impuesto Recaudado (8%)', value: loading ? 'Cargando...' : formatCOPSafe(metrics?.total_taxes), sub: 'Retenciones tributarias', icon: Activity, color: 'warning' },
    { title: 'Dispersión Prestadores', value: loading ? 'Cargando...' : formatCOPSafe(metrics?.total_provider_payouts), sub: 'Transferido a profesionales', icon: Users, color: 'info' },
  ];

  return (
    <div className="space-y-8">
      {/* Status Bar */}
      {(dataError || backendStatus === 'Sin sesión de administrador') && (
        <div className="card border-danger bg-danger-bg/50">
          <div className="card-content flex items-start justify-between gap-4">
            <div className="flex items-start gap-3">
              <ShieldAlert className="icon text-danger shrink-0" size={20} />
              <span className="body-sm text-danger">{dataError || backendStatus}</span>
            </div>
            <button
              onClick={fetchDashboardData}
              className="btn btn-secondary btn-sm shrink-0"
            >
              Reintentar
            </button>
          </div>
        </div>
      )}

      {/* Financial KPI Cards */}
      <section className="kpi-grid">
        {kpis.map((kpi, idx) => {
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

      {/* Quick Stats */}
      <section className="card-grid">
        <div className="card">
          <div className="card-header">
            <h3 className="card-title">Estado del Sistema</h3>
          </div>
          <div className="card-content space-y-3">
            <div className="flex items-center justify-between">
              <span className="body-sm text-secondary">Backend API</span>
              <span className={`chip chip-sm ${failedSections.includes('financial') ? 'danger' : 'success'}`}>
                {failedSections.includes('financial') ? 'Error' : 'Conectado'}
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="body-sm text-secondary">Alertas SOS</span>
              <span className={`chip chip-sm ${failedSections.includes('sos') ? 'danger' : 'success'}`}>
                {failedSections.includes('sos') ? 'Error' : `${sosAlerts.length} activas`}
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="body-sm text-secondary">KYC Pendientes</span>
              <span className={`chip chip-sm ${failedSections.includes('kyc') ? 'danger' : 'success'}`}>
                {failedSections.includes('kyc') ? 'Error' : `${pendingProviders.length} pendientes`}
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="body-sm text-secondary">Última actualización</span>
              <span className="chip chip-sm info">
                {new Date().toLocaleTimeString('es-CO', { hour: '2-digit', minute: '2-digit' })}
              </span>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="card-header">
            <h3 className="card-title">Accesos Rápidos</h3>
          </div>
          <div className="card-content space-y-2">
            <a href="/admin/business" className="flex items-center gap-3 p-3 rounded-lg border border-border-subtle hover:border-brand-gold-border hover:bg-bg-surface transition-fast">
              <Bell className="icon text-gold" size={20} />
              <div>
                <p className="body-sm font-medium text-primary">Cumplimiento Business</p>
                <p className="micro text-muted">Verificar estado de negocio</p>
              </div>
            </a>
            <a href="/admin/precios" className="flex items-center gap-3 p-3 rounded-lg border border-border-subtle hover:border-brand-gold-border hover:bg-bg-surface transition-fast">
              <DollarSign className="icon text-gold" size={20} />
              <div>
                <p className="body-sm font-medium text-primary">Gestión de Precios</p>
                <p className="micro text-muted">Configurar tarifas y comisiones</p>
              </div>
            </a>
            <a href="/admin/productos" className="flex items-center gap-3 p-3 rounded-lg border border-border-subtle hover:border-brand-gold-border hover:bg-bg-surface transition-fast">
              <TrendingUp className="icon text-gold" size={20} />
              <div>
                <p className="body-sm font-medium text-primary">Catálogo Productos</p>
                <p className="micro text-muted">Gestionar inventario</p>
              </div>
            </a>
            <a href="/admin/academia" className="flex items-center gap-3 p-3 rounded-lg border border-border-subtle hover:border-brand-gold-border hover:bg-bg-surface transition-fast">
              <ShieldAlert className="icon text-gold" size={20} />
              <div>
                <p className="body-sm font-medium text-primary">Academia Glow</p>
                <p className="micro text-muted">Contenido educativo</p>
              </div>
            </a>
          </div>
        </div>
      </section>
    </div>
  );
}
