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
  PlusCircle,
  HelpCircle
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

export default function Dashboard() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [loading, setLoading] = useState(true);
  const [backendStatus, setBackendStatus] = useState('Checking...');
  const [metrics, setMetrics] = useState({
    gmv: 1845000,
    total_commission: 221400,
    total_taxes: 147600,
    platform_gross_income: 369000,
    total_provider_payouts: 1476000,
    total_bookings: 112
  });
  const [dailyHistory, setDailyHistory] = useState([
    { date: '01 Jun', gmv: 350000, income: 70000 },
    { date: '02 Jun', gmv: 420000, income: 84000 },
    { date: '03 Jun', gmv: 290000, income: 58000 },
    { date: '04 Jun', gmv: 510000, income: 102000 },
    { date: '05 Jun', gmv: 620000, income: 124000 },
    { date: '06 Jun', gmv: 480000, income: 96000 },
    { date: '07 Jun', gmv: 590000, income: 118000 }
  ]);
  const [categoryData, setCategoryData] = useState([
    { category: 'Uñas', booking_count: 54, total_revenue: 810000, color: '#f43f5e' },
    { category: 'Cabello', booking_count: 35, total_revenue: 700000, color: '#ec4899' },
    { category: 'Maquillaje', booking_count: 15, total_revenue: 225000, color: '#a855f7' },
    { category: 'Otros', booking_count: 8, total_revenue: 110000, color: '#6366f1' }
  ]);
  const [sosAlerts, setSosAlerts] = useState([
    { 
      id: 1, 
      client_name: 'Camila Rojas', 
      client_phone: '+57 312 456 7890',
      provider_name: 'Daniela Gómez',
      provider_phone: '+57 300 987 6543',
      latitude: '4.60971', 
      longitude: '-74.08175', 
      fecha_creacion: 'Hace 5 minutos' 
    },
    { 
      id: 2, 
      client_name: 'Mateo Restrepo', 
      client_phone: '+57 321 654 0987',
      provider_name: 'Carlos Ospina',
      provider_phone: '+57 315 321 6789',
      latitude: '6.25184', 
      longitude: '-75.56359', 
      fecha_creacion: 'Hace 12 minutos' 
    }
  ]);
  const [pendingProviders, setPendingProviders] = useState([
    {
      id: 12,
      nombre: 'Lucía Fernández',
      email: 'lucia.f@example.com',
      business_name: 'Fernández Estilistas',
      description: 'Especialista en colorimetría y tratamientos capilares avanzados en Bogotá.',
      documento_id_url: '#',
      rut_url: '#',
      certificacion_url: '#',
      estatus_verificacion: 'PENDIENTE'
    },
    {
      id: 15,
      nombre: 'Mateo Salazar',
      email: 'mateo.salon@example.com',
      business_name: 'Barbería Golden',
      description: 'Barbería profesional y cortes modernos a domicilio.',
      documento_id_url: '#',
      rut_url: '#',
      certificacion_url: '#',
      estatus_verificacion: 'PENDIENTE'
    }
  ]);

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

  // Fetch from actual backend when loaded
  useEffect(() => {
    async function fetchDashboardData() {
      try {
        const apiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000';
        const adminToken =
          window.localStorage.getItem('adminToken') ||
          process.env.NEXT_PUBLIC_ADMIN_TOKEN;

        if (!adminToken) {
          setBackendStatus('Modo SimulaciÃ³n (sin token admin)');
          return;
        }

        const response = await fetch(`${apiBaseUrl}/api/glow-admin/dashboard/financial-summary`, {
          headers: {
            'Authorization': `Bearer ${adminToken}`
          }
        });
        if (response.ok) {
          const resJson = await response.json();
          if (resJson.success && resJson.data) {
            if (resJson.data.consolidated) setMetrics(resJson.data.consolidated);
            if (resJson.data.dailyHistory && resJson.data.dailyHistory.length > 0) setDailyHistory(resJson.data.dailyHistory);
            if (resJson.data.categoryPopularity && resJson.data.categoryPopularity.length > 0) setCategoryData(resJson.data.categoryPopularity);
            setBackendStatus('Conectado a PostgreSQL');
          }
        } else {
          setBackendStatus('Modo Simulación (Backend Offline)');
        }
      } catch (err) {
        setBackendStatus('Modo Simulación (Backend Offline)');
      } finally {
        setLoading(false);
      }
    }
    fetchDashboardData();
  }, []);

  const handleResolveSOS = (alertId: number) => {
    setSosAlerts(prev => prev.filter(alert => alert.id !== alertId));
    alert(`Alerta SOS #${alertId} resuelta e informada a las autoridades.`);
  };

  const handleApproveProvider = (providerId: number) => {
    setPendingProviders(prev => prev.filter(prov => prov.id !== providerId));
    alert(`El prestador #${providerId} ha sido APROBADO. Su etiqueta de verificación verde ha sido activada.`);
  };

  const handleRejectProvider = (providerId: number) => {
    setPendingProviders(prev => prev.filter(prov => prov.id !== providerId));
    alert(`El prestador #${providerId} ha sido RECHAZADO.`);
  };

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

  const formatCOP = (val: number) => {
    return new Intl.NumberFormat('es-CO', {
      style: 'currency',
      currency: 'COP',
      minimumFractionDigits: 0
    }).format(val);
  };

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
          {/* TAB 1: DASHBOARD METRICS */}
          {activeTab === 'dashboard' && (
            <>
              {/* Financial KPI Cards */}
              <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                {[
                  { title: 'GMV Facturado', value: formatCOP(metrics.gmv), sub: 'Total de reservas completadas', icon: DollarSign, color: 'from-emerald-500 to-teal-500 bg-emerald-500/10 border-emerald-500/20 text-emerald-400' },
                  { title: 'Comisión Plataforma (12%)', value: formatCOP(metrics.total_commission), sub: 'Neto de GlowApp', icon: Percent, color: 'from-pink-500 to-rose-500 bg-pink-500/10 border-pink-500/20 text-pink-400' },
                  { title: 'Impuesto Recaudado (8%)', value: formatCOP(metrics.total_taxes), sub: 'Retenciones tributarias', icon: Activity, color: 'from-amber-500 to-orange-500 bg-amber-500/10 border-amber-500/20 text-amber-400' },
                  { title: 'Dispersión Prestadores', value: formatCOP(metrics.total_provider_payouts), sub: 'Transferido a profesionales', icon: Users, color: 'from-indigo-500 to-cyan-500 bg-indigo-500/10 border-indigo-500/20 text-indigo-400' }
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
                </div>

                {/* Bar Category Popularity */}
                <div className="bg-slate-900/40 border border-slate-900 p-6 rounded-3xl backdrop-blur-md">
                  <div>
                    <h3 className="text-base font-bold text-white">Participación por Categoría</h3>
                    <p className="text-xs text-slate-400 mb-6">Desglose analítico de los servicios estéticos más solicitados</p>
                  </div>
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
                </div>
              </section>
            </>
          )}

          {/* TAB 1.5: BOARD MEETING (Reunión Directiva) */}
          {activeTab === 'board' && (
            <div className="space-y-8">
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
                  <CheckCircle className="w-12 h-12 text-emerald-500 mb-4" />
                  <h4 className="text-base font-bold text-white">¡Todo al día!</h4>
                  <p className="text-xs text-slate-400 max-w-sm mt-1">No quedan solicitudes de verificación de prestadores pendientes en la cola.</p>
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
                              href={doc.url} 
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
                  <CheckCircle className="w-12 h-12 text-emerald-500 mb-4" />
                  <h4 className="text-base font-bold text-white">¡No hay emergencias!</h4>
                  <p className="text-xs text-slate-400 max-w-sm mt-1">El estado de seguridad general en Bogotá y Medellín es normal. Cero alertas SOS pendientes.</p>
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
                              {alert.fecha_creacion}
                            </span>
                          </div>
                        </div>

                        <div className="space-y-2 text-xs">
                          <div className="flex justify-between items-center border-b border-slate-900/50 pb-2">
                            <span className="text-slate-400 font-semibold">Cliente:</span>
                            <span className="text-white font-bold">{alert.client_name} ({alert.client_phone})</span>
                          </div>
                          <div className="flex justify-between items-center border-b border-slate-900/50 pb-2">
                            <span className="text-slate-400 font-semibold">Prestador:</span>
                            <span className="text-white font-bold">{alert.provider_name} ({alert.provider_phone})</span>
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
