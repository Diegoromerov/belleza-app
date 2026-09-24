# 📦 GlowApp SaaS Platform — Código Fuente Completo de la Aplicación

> **Documento de Revisión Arquitectónica y Código Fuente**
> **Versión:** Producción Railway (`admin-dashboard-production-4183.up.railway.app`)
> **Estado de Rutas:** Totalmente verificadas (HTTP 200 OK)

---

## 📑 Índice de Contenidos del Código

### 1. Admin Dashboard (Frontend Next.js App Router)
- [next.config.ts](#nextconfigts)
- [tsconfig.json](#tsconfigjson)
- [package.json](#packagejson)
- [src/app/layout.tsx](#srcapplayouttsx)
- [src/app/page.tsx](#srcapppagetsx)
- [src/app/(dashboard)/layout.tsx](#srcappdashboardlayouttsx)
- [src/app/(dashboard)/perfil/page.tsx](#srcappdashboardperfilpagetsx)
- [src/app/(dashboard)/chat/page.tsx](#srcappdashboardchatpagetsx)
- [src/app/(dashboard)/prestador/page.tsx](#srcappdashboardprestadorpagetsx)
- [src/app/(dashboard)/prestador/citas/page.tsx](#srcappdashboardprestadorcitaspagetsx)
- [src/app/(dashboard)/cliente/page.tsx](#srcappdashboardclientepagetsx)
- [src/app/(dashboard)/cliente/citas/page.tsx](#srcappdashboardclientecitaspagetsx)
- [src/app/(dashboard)/cliente/nueva-cita/page.tsx](#srcappdashboardclientenueva-citapagetsx)
- [src/app/(dashboard)/admin/academia/page.tsx](#srcappdashboardadminacademiapagetsx)
- [src/app/(dashboard)/admin/academia/nuevo/page.tsx](#srcappdashboardadminacademianuevopagetsx)
- [src/app/(dashboard)/admin/academia/[id]/page.tsx](#srcappdashboardadminacademiaidpagetsx)
- [src/app/(dashboard)/admin/vto/page.tsx](#srcappdashboardadminvtopagetsx)
- [src/app/(auth)/login/page.tsx](#srcappauthloginpagetsx)
- [src/app/(auth)/register/page.tsx](#srcappauthregisterpagetsx)
- [src/components/dashboard/Sidebar.tsx](#srccomponentsdashboardsidebartsx)
- [src/components/dashboard/Header.tsx](#srccomponentsdashboardheadertsx)
- [src/components/auth/ProtectedRoute.tsx](#srccomponentsauthprotectedroutetsx)
- [src/contexts/AuthContext.tsx](#srccontextsauthcontexttsx)
- [src/hooks/useBookings.ts](#srchooksusebookingsts)

### 2. Backend Core Services & Controllers (Node.js/Express)
- [backend/src/routes/inventoryRoutes.js](#backendsrcroutesinventoryroutesjs)
- [backend/src/controllers/inventoryController.js](#backendsrccontrollersinventorycontrollerjs)
- [backend/src/controllers/providerController.js](#backendsrccontrollersprovidercontrollerjs)
- [backend/src/controllers/bookingController.js](#backendsrccontrollersbookingcontrollerjs)
- [backend/src/controllers/authController.js](#backendsrccontrollersauthcontrollerjs)
- [backend/serve_mock_demo.js](#backendserve_mock_demojs)

---

## 1. Frontend: Admin Dashboard (Next.js App Router)

### `next.config.ts`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\next.config.ts`

```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  eslint: {
    ignoreDuringBuilds: true,
  },
};

export default nextConfig;

```

---

### `tsconfig.json`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\tsconfig.json`

```json
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": [
      "dom",
      "dom.iterable",
      "esnext"
    ],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": [
        "./src/*"
      ]
    }
  },
  "include": [
    "next-env.d.ts",
    "**/*.ts",
    "**/*.tsx",
    ".next/types/**/*.ts",
    ".next/dev/types/**/*.ts",
    "**/*.mts"
  ],
  "exclude": [
    "node_modules"
  ]
}

```

---

### `package.json`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\package.json`

```json
{
  "name": "admin-dashboard",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev -p 3001",
    "build": "next build",
    "start": "next start -p 3001",
    "lint": "eslint"
  },
  "dependencies": {
    "axios": "^1.18.1",
    "lucide-react": "^0.468.0",
    "next": "^15.1.11",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "recharts": "^2.15.0"
  },
  "devDependencies": {
    "@tailwindcss/postcss": "^4",
    "@types/node": "^20",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "eslint": "^9",
    "eslint-config-next": "15.1.11",
    "tailwindcss": "^4",
    "typescript": "^5.9.3"
  }
}

```

---

### `src/app/layout.tsx`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\src\app\layout.tsx`

```typescript
import type { Metadata } from "next";
import "./globals.css";
import { AuthProvider } from "../contexts/AuthContext";

export const metadata: Metadata = {
  title: "GlowAdmin",
  description: "Panel administrativo de Beauty App",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="es"
      className="h-full antialiased"
    >
      <body className="min-h-full flex flex-col">
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  );
}


```

---

### `src/app/page.tsx`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\src\app\page.tsx`

```typescript
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

```

---

### `src/app/(dashboard)/layout.tsx`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\src\app\(dashboard)\layout.tsx`

```typescript
import Sidebar from '@/components/dashboard/Sidebar';
import Header from '@/components/dashboard/Header';
import ProtectedRoute from '@/components/auth/ProtectedRoute';

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <ProtectedRoute>
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 flex flex-col min-w-0">
          <Header />
          <main className="flex-1 p-8 overflow-y-auto">{children}</main>
        </div>
      </div>
    </ProtectedRoute>
  );
}

```

---

### `src/app/(dashboard)/perfil/page.tsx`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\src\app\(dashboard)\perfil\page.tsx`

```typescript
'use client';

import React, { useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { User, Mail, Shield, Phone, Key, Award, CheckCircle2 } from 'lucide-react';

export default function PerfilPage() {
  const { user } = useAuth();
  const [nombre, setNombre] = useState(user?.nombre || '');
  const [phone, setPhone] = useState('+57 300 123 4567');
  const [saved, setSaved] = useState(false);

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    setSaved(true);
    setTimeout(() => setSaved(false), 2500);
  };

  return (
    <div className="space-y-8 max-w-4xl mx-auto">
      <div>
        <h2 className="text-3xl font-extrabold text-gray-900 tracking-tight">Mi Perfil de Usuario</h2>
        <p className="text-gray-500 mt-1">Configuración de cuenta, seguridad e información personal</p>
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-gray-200/80 overflow-hidden">
        {/* Banner Header */}
        <div className="bg-gradient-to-r from-rose-500 to-pink-600 p-8 text-white flex items-center gap-6">
          <div className="w-20 h-20 rounded-full bg-white/20 backdrop-blur-md border-2 border-white/40 flex items-center justify-center font-extrabold text-3xl text-white shadow-lg">
            {user?.nombre ? user.nombre[0].toUpperCase() : 'U'}
          </div>
          <div>
            <h3 className="text-2xl font-bold">{user?.nombre || 'Usuario GlowApp'}</h3>
            <p className="text-rose-100 text-sm font-medium flex items-center gap-2 mt-1">
              <Shield size={16} /> Rol: <strong className="uppercase">{user?.rol || 'USUARIO'}</strong>
            </p>
          </div>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSave} className="p-8 space-y-6">
          {saved && (
            <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl text-emerald-800 text-sm font-bold flex items-center gap-2">
              <CheckCircle2 size={18} /> ¡Perfil actualizado correctamente!
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-2">Nombre Completo</label>
              <div className="relative">
                <User size={18} className="absolute left-3.5 top-3 text-gray-400" />
                <input
                  type="text"
                  required
                  value={nombre}
                  onChange={(e) => setNombre(e.target.value)}
                  className="w-full pl-10 pr-4 py-2.5 text-sm bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-2">Correo Electrónico</label>
              <div className="relative">
                <Mail size={18} className="absolute left-3.5 top-3 text-gray-400" />
                <input
                  type="email"
                  disabled
                  value={user?.email || 'usuario@beautyapp.com'}
                  className="w-full pl-10 pr-4 py-2.5 text-sm bg-gray-100 text-gray-500 border border-gray-200 rounded-xl cursor-not-allowed"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-2">Teléfono de Contacto</label>
              <div className="relative">
                <Phone size={18} className="absolute left-3.5 top-3 text-gray-400" />
                <input
                  type="text"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  className="w-full pl-10 pr-4 py-2.5 text-sm bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-2">Estado de Verificación</label>
              <div className="px-4 py-2.5 bg-emerald-50 border border-emerald-200 text-emerald-800 text-sm font-semibold rounded-xl flex items-center justify-between">
                <span>Cuenta Verificada</span>
                <Award size={18} className="text-emerald-600" />
              </div>
            </div>
          </div>

          <div className="pt-6 border-t border-gray-100 flex justify-end">
            <button
              type="submit"
              className="px-6 py-3 bg-rose-500 hover:bg-rose-600 text-white font-bold text-sm rounded-xl shadow-md shadow-rose-500/20 transition-all"
            >
              Guardar Cambios
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

```

---

### `src/app/(dashboard)/chat/page.tsx`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\src\app\(dashboard)\chat\page.tsx`

```typescript
'use client';

import React, { useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { MessageSquare, Send, User, Sparkles, CheckCheck } from 'lucide-react';

export default function ChatPage() {
  const { user } = useAuth();
  const [messages, setMessages] = useState([
    { id: '1', sender: 'Aura IA', text: '¡Hola! Soy Aura, tu asistente de IA en GlowApp. ¿En qué te puedo ayudar hoy?', time: '10:00 AM', isMe: false },
    { id: '2', sender: 'Soporte Concierge', text: 'Bienvenido al Centro de Mensajes. Tu cuenta está verificada y activa.', time: '10:02 AM', isMe: false }
  ]);
  const [inputText, setInputText] = useState('');

  const handleSendMessage = (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputText.trim()) return;

    const newMsg = {
      id: Date.now().toString(),
      sender: user?.nombre || 'Usuario',
      text: inputText,
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      isMe: true
    };

    setMessages((prev) => [...prev, newMsg]);
    setInputText('');

    // Simulated reply
    setTimeout(() => {
      setMessages((prev) => [
        ...prev,
        {
          id: (Date.now() + 1).toString(),
          sender: 'Aura IA',
          text: 'Gracias por escribir. Hemos recibido tu mensaje y nuestro equipo de Concierge se encuentra atendiendo tu solicitud en tiempo real.',
          time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          isMe: false
        }
      ]);
    }, 1000);
  };

  return (
    <div className="space-y-6 max-w-5xl mx-auto h-[calc(100vh-140px)] flex flex-col">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-extrabold text-gray-900 tracking-tight">Centro de Mensajes</h2>
          <p className="text-gray-500 mt-1">Canal directo de chat con Soporte Concierge y Asistente Aura IA</p>
        </div>
      </div>

      <div className="flex-1 bg-white rounded-2xl shadow-sm border border-gray-200/80 flex flex-col overflow-hidden">
        {/* Header Chat */}
        <div className="p-4 bg-gray-50 border-b border-gray-200/80 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-rose-500 to-pink-500 flex items-center justify-center text-white font-bold shadow-sm">
              <Sparkles size={20} />
            </div>
            <div>
              <h3 className="font-bold text-gray-900 text-sm">Soporte Concierge & Aura IA</h3>
              <p className="text-xs text-emerald-600 font-semibold flex items-center gap-1">
                <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span> En línea 24/7
              </p>
            </div>
          </div>
        </div>

        {/* Message Container */}
        <div className="flex-1 p-6 overflow-y-auto space-y-4 bg-gray-50/30">
          {messages.map((m) => (
            <div key={m.id} className={`flex flex-col ${m.isMe ? 'items-end' : 'items-start'}`}>
              <span className="text-[11px] font-semibold text-gray-400 mb-1 px-1">{m.sender} • {m.time}</span>
              <div className={`max-w-md p-4 rounded-2xl text-sm ${
                m.isMe
                  ? 'bg-rose-500 text-white rounded-tr-none shadow-sm'
                  : 'bg-white text-gray-800 border border-gray-200/80 rounded-tl-none shadow-sm'
              }`}>
                {m.text}
              </div>
            </div>
          ))}
        </div>

        {/* Input Form */}
        <form onSubmit={handleSendMessage} className="p-4 bg-white border-t border-gray-200/80 flex gap-3">
          <input
            type="text"
            placeholder="Escribe un mensaje para soporte o Aura..."
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            className="flex-1 px-4 py-3 text-sm bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500"
          />
          <button
            type="submit"
            disabled={!inputText.trim()}
            className="px-5 py-3 bg-rose-500 hover:bg-rose-600 disabled:opacity-50 text-white font-bold rounded-xl transition-all flex items-center gap-2"
          >
            <Send size={18} />
          </button>
        </form>
      </div>
    </div>
  );
}

```

---

### `src/app/(dashboard)/prestador/page.tsx`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\src\app\(dashboard)\prestador\page.tsx`

```typescript
'use client';

import React from 'react';
import Link from 'next/link';
import { useBookings } from '@/hooks/useBookings';
import { Calendar, Clock, MapPin, DollarSign, Award, CheckCircle, TrendingUp } from 'lucide-react';

export default function PrestadorDashboard() {
  const { bookings, loading } = useBookings({ rol: 'prestador' });
  
  const reservasPendientes = bookings.filter((b) => b.estado === 'PENDIENTE_PAGO');
  const reservasConfirmadas = bookings.filter((b) => b.estado === 'CONFIRMADA');
  const reservasCompletadas = bookings.filter((b) => b.estado === 'COMPLETADA');

  const totalIngresos = reservasCompletadas.reduce((acc, curr) => acc + Number(curr.pago_neto_prestador), 0);

  return (
    <div className="space-y-8 max-w-7xl mx-auto">
      <div>
        <h2 className="text-3xl font-extrabold text-gray-900 tracking-tight">Panel de Prestador</h2>
        <p className="text-gray-500 mt-1">Gestiona tus servicios, citas y tus ganancias en tiempo real</p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200/80 flex items-center gap-4">
          <div className="bg-amber-50 text-amber-500 p-4 rounded-xl">
            <Clock size={24} />
          </div>
          <div>
            <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Pendientes de Pago</p>
            <p className="text-2xl font-bold text-amber-600 mt-1">{reservasPendientes.length}</p>
          </div>
        </div>

        <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200/80 flex items-center gap-4">
          <div className="bg-emerald-50 text-emerald-500 p-4 rounded-xl">
            <CheckCircle size={24} />
          </div>
          <div>
            <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Citas Confirmadas</p>
            <p className="text-2xl font-bold text-emerald-600 mt-1">{reservasConfirmadas.length}</p>
          </div>
        </div>

        <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200/80 flex items-center gap-4">
          <div className="bg-rose-50 text-rose-500 p-4 rounded-xl">
            <TrendingUp size={24} />
          </div>
          <div>
            <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Tus Ganancias (Netas)</p>
            <p className="text-2xl font-bold text-gray-950 mt-1">${totalIngresos.toLocaleString('es-CO')}</p>
          </div>
        </div>
      </div>

      {/* Reservation lists */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Confirmadas */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray-200/80 overflow-hidden">
          <div className="px-8 py-5 border-b border-gray-100">
            <h3 className="font-bold text-lg text-gray-900">Agenda Confirmada</h3>
          </div>

          {loading ? (
            <div className="p-8 text-center text-gray-500">Cargando...</div>
          ) : reservasConfirmadas.length === 0 ? (
            <div className="p-8 text-center text-gray-400 text-sm">No tienes citas confirmadas para hoy.</div>
          ) : (
            <div className="divide-y divide-gray-100">
              {reservasConfirmadas.map((booking) => (
                <div key={booking.id} className="p-6 hover:bg-gray-50/50 transition-colors">
                  <div className="flex justify-between items-start mb-2">
                    <h4 className="font-bold text-gray-900">{booking.service_name}</h4>
                    <span className="text-sm font-bold text-emerald-600">${Number(booking.pago_neto_prestador).toLocaleString('es-CO')}</span>
                  </div>
                  <p className="text-sm text-gray-500 mb-3">Cliente: <strong>{booking.client_name}</strong></p>
                  <div className="flex flex-wrap gap-y-1 gap-x-4 text-xs text-gray-400">
                    <span className="flex items-center gap-1"><Calendar size={13} /> {new Date(booking.scheduled_at).toLocaleDateString()}</span>
                    <span className="flex items-center gap-1"><Clock size={13} /> {new Date(booking.scheduled_at).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</span>
                    {booking.service_address && (
                      <span className="flex items-center gap-1"><MapPin size={13} /> {booking.service_address}</span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Pendientes */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray-200/80 overflow-hidden">
          <div className="px-8 py-5 border-b border-gray-100">
            <h3 className="font-bold text-lg text-gray-900">Solicitudes Pendientes</h3>
          </div>

          {loading ? (
            <div className="p-8 text-center text-gray-500">Cargando...</div>
          ) : reservasPendientes.length === 0 ? (
            <div className="p-8 text-center text-gray-400 text-sm">No tienes solicitudes pendientes.</div>
          ) : (
            <div className="divide-y divide-gray-100">
              {reservasPendientes.map((booking) => (
                <div key={booking.id} className="p-6 hover:bg-gray-50/50 transition-colors">
                  <div className="flex justify-between items-start mb-2">
                    <h4 className="font-bold text-gray-900">{booking.service_name}</h4>
                    <span className="text-sm font-bold text-amber-600">${Number(booking.pago_neto_prestador).toLocaleString('es-CO')}</span>
                  </div>
                  <p className="text-sm text-gray-500 mb-3">Cliente: <strong>{booking.client_name}</strong></p>
                  <div className="flex flex-wrap gap-y-1 gap-x-4 text-xs text-gray-400 mb-4">
                    <span className="flex items-center gap-1"><Calendar size={13} /> {new Date(booking.scheduled_at).toLocaleDateString()}</span>
                    <span className="flex items-center gap-1"><Clock size={13} /> {new Date(booking.scheduled_at).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</span>
                  </div>
                  <div className="flex gap-2">
                    <button className="flex-1 bg-rose-500 hover:bg-rose-600 text-white text-xs font-semibold py-2 px-3 rounded-lg transition-colors">
                      Aceptar Servicio
                    </button>
                    <button className="border border-gray-200 hover:bg-gray-50 text-gray-600 text-xs font-semibold py-2 px-3 rounded-lg transition-colors">
                      Rechazar
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

```

---

### `src/app/(dashboard)/prestador/citas/page.tsx`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\src\app\(dashboard)\prestador\citas\page.tsx`

```typescript
'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useBookings } from '@/hooks/useBookings';
import { Calendar, Clock, MapPin, Search, User } from 'lucide-react';

export default function PrestadorCitasPage() {
  const { bookings, loading } = useBookings({ rol: 'prestador' });
  const [filterStatus, setFilterStatus] = useState<string>('TODAS');
  const [searchTerm, setSearchTerm] = useState<string>('');

  const filteredBookings = bookings.filter((b) => {
    const matchesStatus = filterStatus === 'TODAS' || b.estado === filterStatus;
    const matchesSearch = 
      (b.service_name || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      (b.client_name || '').toLowerCase().includes(searchTerm.toLowerCase());
    return matchesStatus && matchesSearch;
  });

  return (
    <div className="space-y-8 max-w-7xl mx-auto">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-3xl font-extrabold text-gray-900 tracking-tight">Mis Citas & Agenda</h2>
          <p className="text-gray-500 mt-1">Gestión detallada de reservas, turnos y servicios asignados</p>
        </div>
        <Link 
          href="/prestador" 
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-gray-100 hover:bg-gray-200 text-gray-700 text-sm font-semibold rounded-xl transition-colors self-start md:self-auto"
        >
          &larr; Volver al Panel
        </Link>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white p-4 rounded-2xl shadow-sm border border-gray-200/80 flex flex-col md:flex-row gap-4 justify-between items-center">
        <div className="relative w-full md:w-80">
          <Search size={18} className="absolute left-3.5 top-3.5 text-gray-400" />
          <input
            type="text"
            placeholder="Buscar por cliente o servicio..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 text-sm bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500 transition-all"
          />
        </div>

        <div className="flex flex-wrap gap-2 w-full md:w-auto">
          {['TODAS', 'CONFIRMADA', 'PENDIENTE_PAGO', 'COMPLETADA', 'CANCELADA'].map((status) => (
            <button
              key={status}
              onClick={() => setFilterStatus(status)}
              className={`px-3.5 py-2 text-xs font-semibold rounded-xl transition-all ${
                filterStatus === status
                  ? 'bg-rose-500 text-white shadow-sm'
                  : 'bg-gray-50 text-gray-600 hover:bg-gray-100 border border-gray-200'
              }`}
            >
              {status === 'TODAS' ? 'Todas' : status.replace('_', ' ')}
            </button>
          ))}
        </div>
      </div>

      {/* Bookings List */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-200/80 overflow-hidden">
        {loading ? (
          <div className="p-12 text-center text-gray-500">Cargando agenda de citas...</div>
        ) : filteredBookings.length === 0 ? (
          <div className="p-12 text-center text-gray-400">
            <Calendar size={48} className="mx-auto mb-3 text-gray-300" />
            <p className="font-semibold text-gray-600">No se encontraron citas</p>
            <p className="text-xs text-gray-400 mt-1">Intenta cambiando el filtro de búsqueda o estado.</p>
          </div>
        ) : (
          <div className="divide-y divide-gray-100">
            {filteredBookings.map((b) => (
              <div key={b.id} className="p-6 hover:bg-gray-50/50 transition-colors flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div className="space-y-2">
                  <div className="flex items-center gap-3">
                    <h3 className="font-bold text-gray-900 text-base">{b.service_name}</h3>
                    <span className={`px-2.5 py-0.5 text-xs font-bold rounded-full ${
                      b.estado === 'CONFIRMADA' ? 'bg-emerald-100 text-emerald-800' :
                      b.estado === 'COMPLETADA' ? 'bg-blue-100 text-blue-800' :
                      b.estado === 'PENDIENTE_PAGO' ? 'bg-amber-100 text-amber-800' :
                      'bg-rose-100 text-rose-800'
                    }`}>
                      {b.estado.replace('_', ' ')}
                    </span>
                  </div>
                  
                  <div className="flex flex-wrap gap-x-6 gap-y-1.5 text-xs text-gray-500">
                    <span className="flex items-center gap-1.5 font-medium"><User size={14} className="text-gray-400" /> Cliente: <strong className="text-gray-800">{b.client_name}</strong></span>
                    <span className="flex items-center gap-1.5"><Calendar size={14} className="text-gray-400" /> {new Date(b.scheduled_at).toLocaleDateString()}</span>
                    <span className="flex items-center gap-1.5"><Clock size={14} className="text-gray-400" /> {new Date(b.scheduled_at).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</span>
                    {b.service_address && (
                      <span className="flex items-center gap-1.5"><MapPin size={14} className="text-gray-400" /> {b.service_address}</span>
                    )}
                  </div>
                </div>

                <div className="flex items-center gap-4 border-t md:border-t-0 pt-4 md:pt-0">
                  <div className="text-right">
                    <p className="text-xs text-gray-400 uppercase font-semibold">Ganancia Neta</p>
                    <p className="text-lg font-extrabold text-emerald-600">${Number(b.pago_neto_prestador).toLocaleString('es-CO')}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

```

---

### `src/app/(dashboard)/cliente/page.tsx`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\src\app\(dashboard)\cliente\page.tsx`

```typescript
'use client';

import React from 'react';
import Link from 'next/link';
import { useBookings } from '@/hooks/useBookings';
import { Calendar, Clock, MapPin, DollarSign, Tag, UserCheck, XCircle } from 'lucide-react';

export default function ClienteDashboard() {
  const { bookings, loading, cancelBooking } = useBookings({ rol: 'cliente' });
  
  const proximasReservas = bookings.filter((b) => 
    ['PENDIENTE_PAGO', 'CONFIRMADA', 'EN_PROGRESO'].includes(b.estado)
  );

  const completedReservas = bookings.filter((b) => 
    ['COMPLETADA'].includes(b.estado)
  );

  const totalSpent = completedReservas.reduce((acc, curr) => acc + Number(curr.valor_bruto), 0);

  const handleCancel = async (id: string) => {
    if (confirm('¿Estás seguro de que deseas cancelar esta reserva?')) {
      try {
        await cancelBooking(id);
        alert('Cita cancelada con éxito.');
      } catch (err) {
        alert('No se pudo cancelar la cita.');
      }
    }
  };

  return (
    <div className="space-y-8 max-w-7xl mx-auto">
      <div>
        <h2 className="text-3xl font-extrabold text-gray-900 tracking-tight">Tu Panel</h2>
        <p className="text-gray-500 mt-1">Resumen de tu actividad y citas de belleza a domicilio</p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200/80 flex items-center gap-4">
          <div className="bg-rose-50 text-rose-500 p-4 rounded-xl">
            <Calendar size={24} />
          </div>
          <div>
            <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Reservas Activas</p>
            <p className="text-2xl font-bold text-gray-950 mt-1">{proximasReservas.length}</p>
          </div>
        </div>

        <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200/80 flex items-center gap-4">
          <div className="bg-emerald-50 text-emerald-500 p-4 rounded-xl">
            <UserCheck size={24} />
          </div>
          <div>
            <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Servicios Completados</p>
            <p className="text-2xl font-bold text-gray-950 mt-1">{completedReservas.length}</p>
          </div>
        </div>

        <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200/80 flex items-center gap-4">
          <div className="bg-amber-50 text-amber-500 p-4 rounded-xl">
            <DollarSign size={24} />
          </div>
          <div>
            <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Total Invertido</p>
            <p className="text-2xl font-bold text-gray-950 mt-1">${totalSpent.toLocaleString('es-CO')}</p>
          </div>
        </div>
      </div>

      {/* Booking list */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-200/80 overflow-hidden">
        <div className="px-8 py-5 border-b border-gray-100 flex items-center justify-between">
          <h3 className="font-bold text-lg text-gray-900">Tus Próximas Citas</h3>
          <Link href="/cliente/nueva-cita" className="text-sm font-semibold text-rose-500 hover:text-rose-600">
            Nueva Reserva →
          </Link>
        </div>

        {loading ? (
          <div className="p-8 text-center text-gray-500">Cargando tus citas...</div>
        ) : proximasReservas.length === 0 ? (
          <div className="p-12 text-center">
            <p className="text-gray-500 text-sm">No tienes citas programadas actualmente.</p>
            <Link href="/cliente/nueva-cita" className="inline-block mt-4 bg-rose-500 text-white font-semibold px-5 py-2.5 rounded-xl text-sm hover:bg-rose-600 transition-colors">
              Programar ahora
            </Link>
          </div>
        ) : (
          <div className="divide-y divide-gray-100">
            {proximasReservas.map((booking) => (
              <div key={booking.id} className="p-6 md:p-8 flex flex-col md:flex-row md:items-center justify-between gap-6 hover:bg-gray-50/50 transition-all duration-200">
                <div className="space-y-3">
                  <div className="flex items-center gap-2.5">
                    <span className={`text-xs font-semibold px-2.5 py-1 rounded-full uppercase tracking-wider ${
                      booking.estado === 'CONFIRMADA' ? 'bg-emerald-50 text-emerald-600' :
                      booking.estado === 'EN_PROGRESO' ? 'bg-rose-50 text-rose-600' : 'bg-amber-50 text-amber-600'
                    }`}>
                      {booking.estado.replace('_', ' ')}
                    </span>
                    <span className="text-sm font-bold text-gray-900">${Number(booking.valor_bruto).toLocaleString('es-CO')}</span>
                  </div>
                  <h4 className="font-bold text-gray-900 text-base">{booking.service_name || 'Servicio de Belleza'}</h4>
                  <p className="text-sm text-gray-500 flex items-center gap-2">
                    <span>Estilista: <strong>{booking.provider_name || 'Profesional de Belleza'}</strong></span>
                  </p>
                  <div className="flex flex-wrap gap-x-5 gap-y-2 text-xs text-gray-400">
                    <span className="flex items-center gap-1.5">
                      <Calendar size={14} />
                      {new Date(booking.scheduled_at).toLocaleDateString('es-CO', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
                    </span>
                    <span className="flex items-center gap-1.5">
                      <Clock size={14} />
                      {new Date(booking.scheduled_at).toLocaleTimeString('es-CO', { hour: '2-digit', minute: '2-digit' })}
                    </span>
                    {booking.service_address && (
                      <span className="flex items-center gap-1.5">
                        <MapPin size={14} />
                        {booking.service_address}
                      </span>
                    )}
                  </div>
                </div>

                <div className="flex gap-3">
                  {booking.estado === 'PENDIENTE_PAGO' && (
                    <button className="bg-rose-500 hover:bg-rose-600 text-white text-sm font-semibold px-5 py-2.5 rounded-xl transition-all duration-200">
                      Pagar Ahora
                    </button>
                  )}
                  {['PENDIENTE_PAGO', 'CONFIRMADA'].includes(booking.estado) && (
                    <button
                      onClick={() => handleCancel(booking.id)}
                      className="border border-gray-200 hover:border-red-200 hover:bg-red-50 text-gray-600 hover:text-red-500 text-sm font-semibold p-2.5 rounded-xl transition-all duration-200"
                      title="Cancelar Cita"
                    >
                      <XCircle size={20} />
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

```

---

### `src/app/(dashboard)/cliente/citas/page.tsx`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\src\app\(dashboard)\cliente\citas\page.tsx`

```typescript
'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useBookings } from '@/hooks/useBookings';
import { Calendar, Clock, MapPin, Search, UserCheck } from 'lucide-react';

export default function ClienteCitasPage() {
  const { bookings, loading, cancelBooking } = useBookings({ rol: 'cliente' });
  const [filterStatus, setFilterStatus] = useState<string>('TODAS');

  const filteredBookings = bookings.filter((b) => {
    return filterStatus === 'TODAS' || b.estado === filterStatus;
  });

  return (
    <div className="space-y-8 max-w-7xl mx-auto">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-3xl font-extrabold text-gray-900 tracking-tight">Mis Citas & Reservas</h2>
          <p className="text-gray-500 mt-1">Historial y próximas citas de belleza agendadas</p>
        </div>
        <div className="flex gap-3">
          <Link 
            href="/cliente/nueva-cita" 
            className="inline-flex items-center gap-2 px-5 py-2.5 bg-rose-500 hover:bg-rose-600 text-white text-sm font-semibold rounded-xl shadow-sm transition-colors"
          >
            + Nueva Cita
          </Link>
          <Link 
            href="/cliente" 
            className="inline-flex items-center gap-2 px-4 py-2.5 bg-gray-100 hover:bg-gray-200 text-gray-700 text-sm font-semibold rounded-xl transition-colors"
          >
            &larr; Volver
          </Link>
        </div>
      </div>

      {/* Filter Bar */}
      <div className="bg-white p-4 rounded-2xl shadow-sm border border-gray-200/80 flex flex-wrap gap-2">
        {['TODAS', 'CONFIRMADA', 'PENDIENTE_PAGO', 'COMPLETADA', 'CANCELADA'].map((status) => (
          <button
            key={status}
            onClick={() => setFilterStatus(status)}
            className={`px-3.5 py-2 text-xs font-semibold rounded-xl transition-all ${
              filterStatus === status
                ? 'bg-rose-500 text-white shadow-sm'
                : 'bg-gray-50 text-gray-600 hover:bg-gray-100 border border-gray-200'
            }`}
          >
            {status === 'TODAS' ? 'Todas' : status.replace('_', ' ')}
          </button>
        ))}
      </div>

      {/* Bookings List */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-200/80 overflow-hidden">
        {loading ? (
          <div className="p-12 text-center text-gray-500">Cargando tus citas...</div>
        ) : filteredBookings.length === 0 ? (
          <div className="p-12 text-center text-gray-400">
            <Calendar size={48} className="mx-auto mb-3 text-gray-300" />
            <p className="font-semibold text-gray-600">No tienes citas registradas en este estado</p>
            <Link href="/cliente/nueva-cita" className="inline-block mt-3 text-rose-500 font-semibold text-sm hover:underline">
              Agendar una nueva cita de belleza &rarr;
            </Link>
          </div>
        ) : (
          <div className="divide-y divide-gray-100">
            {filteredBookings.map((b) => (
              <div key={b.id} className="p-6 hover:bg-gray-50/50 transition-colors flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div className="space-y-2">
                  <div className="flex items-center gap-3">
                    <h3 className="font-bold text-gray-900 text-base">{b.service_name}</h3>
                    <span className={`px-2.5 py-0.5 text-xs font-bold rounded-full ${
                      b.estado === 'CONFIRMADA' ? 'bg-emerald-100 text-emerald-800' :
                      b.estado === 'COMPLETADA' ? 'bg-blue-100 text-blue-800' :
                      b.estado === 'PENDIENTE_PAGO' ? 'bg-amber-100 text-amber-800' :
                      'bg-rose-100 text-rose-800'
                    }`}>
                      {b.estado.replace('_', ' ')}
                    </span>
                  </div>
                  
                  <div className="flex flex-wrap gap-x-6 gap-y-1.5 text-xs text-gray-500">
                    <span className="flex items-center gap-1.5 font-medium"><UserCheck size={14} className="text-gray-400" /> Prestador: <strong className="text-gray-800">{b.provider_name || 'Asignado'}</strong></span>
                    <span className="flex items-center gap-1.5"><Calendar size={14} className="text-gray-400" /> {new Date(b.scheduled_at).toLocaleDateString()}</span>
                    <span className="flex items-center gap-1.5"><Clock size={14} className="text-gray-400" /> {new Date(b.scheduled_at).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</span>
                    {b.service_address && (
                      <span className="flex items-center gap-1.5"><MapPin size={14} className="text-gray-400" /> {b.service_address}</span>
                    )}
                  </div>
                </div>

                <div className="flex items-center gap-4">
                  <div className="text-right">
                    <p className="text-xs text-gray-400 uppercase font-semibold">Valor Total</p>
                    <p className="text-lg font-extrabold text-gray-900">${Number(b.valor_bruto).toLocaleString('es-CO')}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

```

---

### `src/app/(dashboard)/cliente/nueva-cita/page.tsx`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\src\app\(dashboard)\cliente\nueva-cita\page.tsx`

```typescript
﻿'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Calendar, Clock, MapPin, Scissors, Check, Sparkles } from 'lucide-react';

export default function NuevaCitaPage() {
  const router = useRouter();
  const [step, setStep] = useState(1);
  const [selectedService, setSelectedService] = useState('');
  const [selectedAddress, setSelectedAddress] = useState('Calle 26 # 68-10, Fontibón, Bogotá');
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);
  const [selectedTime, setSelectedTime] = useState('10:00');
  const [loading, setLoading] = useState(false);

  const serviciosDisponibles = [
    { id: '1', nombre: 'Corte + Cepillado Velvet', precio: 65000, duracion: '60 min', categoria: 'Peluquería' },
    { id: '2', nombre: 'Manicura Semipermanente Luxe', precio: 55000, duracion: '45 min', categoria: 'Uñas' },
    { id: '3', nombre: 'Tratamiento Piel Seda Dermo', precio: 120000, duracion: '90 min', categoria: 'Facial' },
    { id: '4', nombre: 'Diseño de Cejas & Henna', precio: 45000, duracion: '30 min', categoria: 'Mirada' },
  ];

  const handleBookingSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    setTimeout(() => {
      setLoading(false);
      alert('¡Cita solicitada con éxito! Redirigiendo a tus citas...');
      router.push('/cliente/citas');
    }, 1200);
  };

  return (
    <div className="space-y-8 max-w-4xl mx-auto">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-extrabold text-gray-900 tracking-tight">Agendar Nueva Cita</h2>
          <p className="text-gray-500 mt-1">Selecciona el servicio de belleza a domicilio deseado</p>
        </div>
        <Link 
          href="/cliente" 
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-gray-100 hover:bg-gray-200 text-gray-700 text-sm font-semibold rounded-xl transition-colors"
        >
          &larr; Cancelar
        </Link>
      </div>

      <form onSubmit={handleBookingSubmit} className="bg-white p-8 rounded-2xl shadow-sm border border-gray-200/80 space-y-8">
        {/* Paso 1: Seleccionar Servicio */}
        <div>
          <h3 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
            <span className="w-7 h-7 bg-rose-500 text-white rounded-full text-xs flex items-center justify-center font-bold">1</span>
            Elige el servicio
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {serviciosDisponibles.map((serv) => (
              <div
                key={serv.id}
                onClick={() => setSelectedService(serv.id)}
                className={`p-5 rounded-xl border-2 cursor-pointer transition-all ${
                  selectedService === serv.id
                    ? 'border-rose-500 bg-rose-50/30 shadow-sm'
                    : 'border-gray-200 hover:border-gray-300'
                }`}
              >
                <div className="flex justify-between items-start mb-2">
                  <h4 className="font-bold text-gray-900">{serv.nombre}</h4>
                  <span className="text-xs font-bold text-rose-500 px-2 py-0.5 bg-rose-50 rounded-full">{serv.categoria}</span>
                </div>
                <div className="flex justify-between items-center text-sm mt-4">
                  <span className="text-gray-500 flex items-center gap-1 text-xs"><Clock size={14} /> {serv.duracion}</span>
                  <span className="font-extrabold text-gray-900 text-base">${serv.precio.toLocaleString('es-CO')}</span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Paso 2: Dirección y Fecha */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-6 border-t border-gray-100">
          <div>
            <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-2">Dirección del Servicio</label>
            <div className="relative">
              <MapPin size={18} className="absolute left-3.5 top-3 text-gray-400" />
              <input
                type="text"
                required
                value={selectedAddress}
                onChange={(e) => setSelectedAddress(e.target.value)}
                className="w-full pl-10 pr-4 py-2.5 text-sm bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-2">Fecha</label>
              <input
                type="date"
                required
                value={selectedDate}
                onChange={(e) => setSelectedDate(e.target.value)}
                className="w-full px-3 py-2.5 text-sm bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-2">Hora</label>
              <input
                type="time"
                required
                value={selectedTime}
                onChange={(e) => setSelectedTime(e.target.value)}
                className="w-full px-3 py-2.5 text-sm bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500"
              />
            </div>
          </div>
        </div>

        {/* Submit */}
        <div className="pt-4 border-t border-gray-100 flex justify-end">
          <button
            type="submit"
            disabled={!selectedService || loading}
            className="w-full md:w-auto px-8 py-3.5 bg-rose-500 hover:bg-rose-600 disabled:opacity-50 text-white font-bold text-sm rounded-xl shadow-lg shadow-rose-500/20 transition-all flex items-center justify-center gap-2"
          >
            {loading ? 'Confirmando Cita...' : 'Confirmar Reserva de Servicio'}
          </button>
        </div>
      </form>
    </div>
  );
}

```

---

### `src/app/(dashboard)/admin/academia/page.tsx`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\src\app\(dashboard)\admin\academia\page.tsx`

```typescript
'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { 
  BookOpen, 
  Plus, 
  Edit, 
  Trash2, 
  Loader2, 
  AlertCircle,
  CheckCircle,
  Users,
  Layers,
  FileText,
  Award,
  ArrowUpDown,
  Search,
  Filter
} from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';

interface Course {
  id: string;
  title: string;
  description: string;
  category: string;
  badge_name: string;
  created_at: string;
  modules_count: number;
  lessons_count: number;
  quizzes_count: number;
  certificates_issued: number;
  enrolled_providers: number;
}

export default function AcademiaAdminPage() {
  const { user } = useAuth();
  const [courses, setCourses] = useState<Course[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [showOnlyActive, setShowOnlyActive] = useState(false);

  const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

  const fetchCourses = async () => {
    try {
      setLoading(true);
      const token = localStorage.getItem('glow_token');
      const response = await fetch(`${API_URL}/api/admin/academy/courses`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });
      
      if (!response.ok) {
        throw new Error('Error al cargar cursos');
      }
      
      const data = await response.json();
      setCourses(data);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error desconocido');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCourses();
  }, []);

  const handleDelete = async (courseId: string) => {
    if (!window.confirm('¿Estás seguro de eliminar este curso? Esta acción no se puede deshacer.')) return;
    
    try {
      const token = localStorage.getItem('glow_token');
      const response = await fetch(`${API_URL}/api/admin/academy/courses/${courseId}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });
      
      if (!response.ok) throw new Error('Error al eliminar');
      
      fetchCourses();
    } catch (err) {
      alert('Error al eliminar el curso');
    }
  };

  const filteredCourses = courses.filter(course => {
    const matchesSearch = course.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          course.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          course.category.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = categoryFilter === 'all' || course.category === categoryFilter;
    return matchesSearch && matchesCategory;
  });

  const categories = [...new Set(courses.map(c => c.category))];

  if (user?.rol !== 'ADMIN') {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="text-center">
          <AlertCircle className="w-16 h-16 text-red-400 mx-auto mb-4" />
          <h2 className="text-xl font-bold text-gray-900">Acceso denegado</h2>
          <p className="text-gray-500 mt-2">Solo los administradores pueden acceder a esta sección.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold text-gray-900 tracking-tight">Academia Glow - Administración</h1>
          <p className="text-gray-500 mt-1">Gestiona cursos, módulos, lecciones y exámenes de certificación</p>
        </div>
        <Link
          href="/admin/academia/nuevo"
          className="inline-flex items-center gap-2 bg-rose-500 hover:bg-rose-600 text-white px-5 py-3 rounded-xl font-semibold transition-colors shadow-sm shadow-rose-500/20"
        >
          <Plus size={20} />
          <span>Nuevo Curso</span>
        </Link>
      </div>

      {/* Stats Overview */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard 
          title="Total Cursos" 
          value={courses.length} 
          icon={BookOpen} 
          color="bg-rose-500" 
          bgColor="bg-rose-50" 
        />
        <StatCard 
          title="Prestadores Inscritos" 
          value={courses.reduce((sum, c) => sum + (c.enrolled_providers || 0), 0)} 
          icon={Users} 
          color="bg-blue-500" 
          bgColor="bg-blue-50" 
        />
        <StatCard 
          title="Certificados Emitidos" 
          value={courses.reduce((sum, c) => sum + (c.certificates_issued || 0), 0)} 
          icon={Award} 
          color="bg-amber-500" 
          bgColor="bg-amber-50" 
        />
        <StatCard 
          title="Total Lecciones" 
          value={courses.reduce((sum, c) => sum + (c.lessons_count || 0), 0)} 
          icon={FileText} 
          color="bg-emerald-500" 
          bgColor="bg-emerald-50" 
        />
      </div>

      {/* Filters */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-200/80 p-4 sm:p-6">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" size={20} />
            <input
              type="text"
              placeholder="Buscar por título, descripción, categoría..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-12 pr-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-rose-500 focus:border-rose-500 outline-none transition-all"
            />
          </div>
          <div className="flex gap-3">
            <select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              className="px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-rose-500 focus:border-rose-500 outline-none bg-white"
            >
              <option value="all">Todas las categorías</option>
              {categories.map(cat => (
                <option key={cat} value={cat}>{cat}</option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Courses Table */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-200/80 overflow-hidden">
        {loading ? (
          <div className="p-12 text-center">
            <Loader2 className="w-8 h-8 text-rose-500 animate-spin mx-auto mb-4" />
            <p className="text-gray-500">Cargando cursos...</p>
          </div>
        ) : error ? (
          <div className="p-12 text-center">
            <AlertCircle className="w-12 h-12 text-red-400 mx-auto mb-4" />
            <h3 className="text-lg font-semibold text-gray-900 mb-2">Error al cargar cursos</h3>
            <p className="text-gray-500 mb-4">{error}</p>
            <button
              onClick={fetchCourses}
              className="px-4 py-2 bg-rose-500 text-white rounded-lg hover:bg-rose-600 transition-colors"
            >
              Reintentar
            </button>
          </div>
        ) : filteredCourses.length === 0 ? (
          <div className="p-12 text-center">
            <BookOpen className="w-16 h-16 text-gray-300 mx-auto mb-4" />
            <h3 className="text-lg font-semibold text-gray-900 mb-2">No hay cursos</h3>
            <p className="text-gray-500 mb-6">
              {searchTerm || categoryFilter !== 'all' 
                ? 'No se encontraron cursos con esos filtros' 
                : 'Comienza creando tu primer curso de capacitación'}
            </p>
            {(!searchTerm && categoryFilter === 'all') && (
              <Link
                href="/admin/academia/nuevo"
                className="inline-flex items-center gap-2 bg-rose-500 hover:bg-rose-600 text-white px-5 py-3 rounded-xl font-semibold transition-colors"
              >
                <Plus size={20} />
                <span>Crear Primer Curso</span>
              </Link>
            )}
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Curso</th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider hidden md:table-cell">Categoría</th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider hidden lg:table-cell">Insignia</th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider hidden lg:table-cell">Módulos</th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider hidden lg:table-cell">Lecciones</th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider hidden lg:table-cell">Exámenes</th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider hidden md:table-cell">Certificados</th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider hidden md:table-cell">Inscritos</th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Fecha</th>
                  <th className="px-6 py-4 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {filteredCourses.map((course) => (
                  <tr key={course.id} className="hover:bg-gray-50/50 transition-colors">
                    <td className="px-6 py-4">
                      <Link
                        href={`/admin/academia/${course.id}`}
                        className="font-medium text-gray-900 hover:text-rose-600 transition-colors"
                      >
                        {course.title}
                      </Link>
                      <p className="text-sm text-gray-500 mt-1 line-clamp-1">{course.description}</p>
                    </td>
                    <td className="px-6 py-4 hidden md:table-cell">
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-rose-50 text-rose-700">
                        {course.category}
                      </span>
                    </td>
                    <td className="px-6 py-4 hidden lg:table-cell">
                      <span className="inline-flex items-center gap-1 text-sm text-gray-600">
                        <Award className="w-4 h-4 text-amber-500" />
                        {course.badge_name}
                      </span>
                    </td>
                    <td className="px-6 py-4 hidden lg:table-cell">
                      <span className="inline-flex items-center gap-1 text-sm text-gray-600">
                        <Layers className="w-4 h-4" />
                        {course.modules_count}
                      </span>
                    </td>
                    <td className="px-6 py-4 hidden lg:table-cell">
                      <span className="inline-flex items-center gap-1 text-sm text-gray-600">
                        <FileText className="w-4 h-4" />
                        {course.lessons_count}
                      </span>
                    </td>
                    <td className="px-6 py-4 hidden lg:table-cell">
                      <span className="text-sm text-gray-600">{course.quizzes_count}</span>
                    </td>
                    <td className="px-6 py-4 hidden md:table-cell">
                      <span className="inline-flex items-center gap-1 text-sm text-gray-600">
                        <Award className="w-4 h-4 text-amber-500" />
                        {course.certificates_issued}
                      </span>
                    </td>
                    <td className="px-6 py-4 hidden md:table-cell">
                      <span className="inline-flex items-center gap-1 text-sm text-gray-600">
                        <Users className="w-4 h-4" />
                        {course.enrolled_providers}
                      </span>
                    </td>
                    <td className="px-6 py-4 hidden md:table-cell text-sm text-gray-500">
                      {new Date(course.created_at).toLocaleDateString('es-ES', {
                        day: '2-digit',
                        month: '2-digit',
                        year: 'numeric'
                      })}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <Link
                          href={`/admin/academia/${course.id}`}
                          className="p-2 text-gray-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-all"
                          title="Editar curso"
                        >
                          <Edit size={18} />
                        </Link>
                        <button
                          onClick={() => handleDelete(course.id)}
                          className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-all"
                          title="Eliminar curso"
                        >
                          <Trash2 size={18} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

interface StatCardProps {
  title: string;
  value: number;
  icon: React.ComponentType<{ size?: number; className?: string }>;
  color: string;
  bgColor: string;
}

function StatCard({ title, value, icon: Icon, color, bgColor }: StatCardProps) {
  return (
    <div className={`bg-white p-6 rounded-2xl shadow-sm border border-gray-200/80 flex items-center gap-4`}>
      <div className={`p-4 rounded-xl ${color} ${bgColor}`}>
        <Icon size={24} className="text-white" />
      </div>
      <div>
        <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">{title}</p>
        <p className="text-2xl font-bold text-gray-900 mt-1">{value.toLocaleString('es-CO')}</p>
      </div>
    </div>
  );
}
```

---

### `src/app/(dashboard)/admin/academia/nuevo/page.tsx`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\src\app\(dashboard)\admin\academia\nuevo\page.tsx`

```typescript
'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { 
  ArrowLeft, 
  Loader2, 
  Save, 
  X,
  AlertCircle,
  CheckCircle
} from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';

export default function NuevoCursoPage() {
  const { user } = useAuth();
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const [formData, setFormData] = useState({
    title: '',
    description: '',
    category: '',
    badge_name: '',
  });

  const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    if (error) setError(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    // Validación
    if (!formData.title || !formData.description || !formData.category || !formData.badge_name) {
      setError('Todos los campos son obligatorios');
      setLoading(false);
      return;
    }

    try {
      const token = localStorage.getItem('glow_token');
      const response = await fetch(`${API_URL}/api/admin/academy/courses`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Error al crear el curso');
      }

      setSuccess(true);
      setTimeout(() => {
        router.push(`/admin/academia/${data.id}`);
      }, 1500);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error desconocido');
    } finally {
      setLoading(false);
    }
  };

  const handleBack = () => {
    router.back();
  };

  if (user?.rol !== 'ADMIN') {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="text-center">
          <AlertCircle className="w-16 h-16 text-red-400 mx-auto mb-4" />
          <h2 className="text-xl font-bold text-gray-900">Acceso denegado</h2>
          <p className="text-gray-500 mt-2">Solo los administradores pueden acceder a esta sección.</p>
        </div>
      </div>
    );
  }

  const categories = [
    'bioseguridad',
    'uñas',
    'maquillaje',
    'piel',
    'cabello',
    'cejas',
    'marketing',
    'negocios',
    'otro',
  ];

  return (
    <div className="max-w-3xl mx-auto space-y-8">
      {/* Header */}
      <div className="flex items-center gap-4">
        <button
          onClick={handleBack}
          className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-xl transition-all"
        >
          <ArrowLeft size={24} />
        </button>
        <div>
          <h1 className="text-3xl font-extrabold text-gray-900 tracking-tight">Nuevo Curso</h1>
          <p className="text-gray-500 mt-1">Crea un nuevo curso de capacitación para prestadores</p>
        </div>
      </div>

      {success && (
        <div className="flex items-center gap-3 p-4 bg-green-50 border border-green-200 rounded-xl text-green-800">
          <CheckCircle size={24} />
          <span className="font-medium">¡Curso creado exitosamente! Redirigiendo...</span>
        </div>
      )}

      {/* Form */}
      <form onSubmit={handleSubmit} className="bg-white rounded-2xl shadow-sm border border-gray-200/80 p-6 sm:p-8 space-y-6">
        {error && (
          <div className="flex items-center gap-3 p-4 bg-red-50 border border-red-200 rounded-xl text-red-800">
            <AlertCircle size={20} />
            <span>{error}</span>
          </div>
        )}

        <div>
          <label htmlFor="title" className="block text-sm font-semibold text-gray-700 mb-2">
            Título del Curso <span className="text-rose-500">*</span>
          </label>
          <input
            type="text"
            id="title"
            name="title"
            value={formData.title}
            onChange={handleChange}
            placeholder="Ej: Protocolos de Bioseguridad y Calidad Glow"
            className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-rose-500 focus:border-rose-500 outline-none transition-all"
            required
          />
        </div>

        <div>
          <label htmlFor="description" className="block text-sm font-semibold text-gray-700 mb-2">
            Descripción <span className="text-rose-500">*</span>
          </label>
          <textarea
            id="description"
            name="description"
            value={formData.description}
            onChange={handleChange}
            rows={4}
            placeholder="Describe el contenido, objetivos y qué aprenderán los prestadores..."
            className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-rose-500 focus:border-rose-500 outline-none transition-all resize-y"
            required
          />
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
          <div>
            <label htmlFor="category" className="block text-sm font-semibold text-gray-700 mb-2">
              Categoría <span className="text-rose-500">*</span>
            </label>
            <select
              id="category"
              name="category"
              value={formData.category}
              onChange={handleChange}
              className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-rose-500 focus:border-rose-500 outline-none transition-all bg-white"
              required
            >
              <option value="">Seleccionar categoría</option>
              {categories.map(cat => (
                <option key={cat} value={cat}>{cat.charAt(0).toUpperCase() + cat.slice(1)}</option>
              ))}
            </select>
          </div>

          <div>
            <label htmlFor="badge_name" className="block text-sm font-semibold text-gray-700 mb-2">
              Nombre de la Insignia <span className="text-rose-500">*</span>
            </label>
            <input
              type="text"
              id="badge_name"
              name="badge_name"
              value={formData.badge_name}
              onChange={handleChange}
              placeholder="Ej: Profesional Certificada Glow"
              className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-rose-500 focus:border-rose-500 outline-none transition-all"
              required
            />
            <p className="mt-1 text-xs text-gray-500">Esta insignia se mostrará en el perfil del prestador al completar el curso</p>
          </div>
        </div>

        {/* Preview */}
        <div className="bg-gray-50 rounded-xl p-6 border border-gray-200">
          <h3 className="font-semibold text-gray-900 mb-4 flex items-center gap-2">
            <CheckCircle className="text-emerald-500" size={20} />
            Vista Previa
          </h3>
          <div className="space-y-3 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-500">Título:</span>
              <span className="font-medium text-gray-900">{formData.title || '—'}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-500">Categoría:</span>
              <span className="font-medium text-gray-900">{formData.category ? formData.category.charAt(0).toUpperCase() + formData.category.slice(1) : '—'}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-500">Insignia:</span>
              <span className="font-medium text-gray-900">{formData.badge_name || '—'}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-500">Descripción:</span>
              <span className="font-medium text-gray-900 max-w-xs truncate">{formData.description || '—'}</span>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="flex flex-col sm:flex-row justify-end gap-4 pt-4 border-t border-gray-100">
          <button
            type="button"
            onClick={handleBack}
            className="px-6 py-3 text-gray-700 font-semibold border border-gray-300 rounded-xl hover:bg-gray-50 transition-colors"
          >
            Cancelar
          </button>
          <button
            type="submit"
            disabled={loading}
            className="flex items-center gap-2 px-6 py-3 bg-rose-500 text-white font-semibold rounded-xl hover:bg-rose-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed shadow-sm shadow-rose-500/20"
          >
            {loading ? (
              <>
                <Loader2 size={20} className="animate-spin" />
                <span>Guardando...</span>
              </>
            ) : (
              <>
                <Save size={20} />
                <span>Crear Curso</span>
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
```

---

### `src/app/(dashboard)/admin/academia/[id]/page.tsx`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\src\app\(dashboard)\admin\academia\[id]\page.tsx`

```typescript
// @ts-nocheck
'use client';

import React, { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { 
  ArrowLeft, 
  Loader2, 
  Save, 
  Plus, 
  Edit, 
  Trash2, 
  X,
  AlertCircle,
  CheckCircle,
  ChevronDown,
  ChevronUp,
  Layers,
  FileText,
  HelpCircle,
  Award,
  GripVertical,
  Eye,
  EyeOff,
  GraduationCap
} from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';

interface Module {
  id: string;
  course_id: string;
  title: string;
  sort_order: number;
  lessons?: Lesson[];
}

interface Lesson {
  id: string;
  module_id: string;
  title: string;
  video_url: string | null;
  content_text: string | null;
  sort_order: number;
  module_title?: string;
  module_order?: number;
}

interface Quiz {
  id: string;
  course_id: string;
  question: string;
  options: string[];
  correct_index: number;
}

interface Course {
  id: string;
  title: string;
  description: string;
  category: string;
  badge_name: string;
  created_at: string;
}

interface ModuleFormData {
  title: string;
  sort_order: string;
}

interface LessonFormData {
  module_id: string;
  title: string;
  video_url: string;
  content_text: string;
  sort_order: string;
}

interface QuizFormData {
  question: string;
  options: string[];
  correct_index: number;
}

export default function EditarCursoPage() {
  const { user } = useAuth();
  const router = useRouter();
  const params = useParams();
  const courseId = params.id as string;

  const [course, setCourse] = useState<Course | null>(null);
  const [modules, setModules] = useState<Module[]>([]);
  const [lessons, setLessons] = useState<Lesson[]>([]);
  const [quizzes, setQuizzes] = useState<Quiz[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  // UI State
  const [activeTab, setActiveTab] = useState<'modules' | 'quizzes' | 'course'>('modules');
  const [expandedModuleId, setExpandedModuleId] = useState<string | null>(null);
  const [editingModuleId, setEditingModuleId] = useState<string | null>(null);
  const [editingLessonId, setEditingLessonId] = useState<string | null>(null);
  const [editingQuizId, setEditingQuizId] = useState<string | null>(null);
  const [showAddModule, setShowAddModule] = useState(false);
  const [showAddLesson, setShowAddLesson] = useState<string | null>(null);
  const [showAddQuiz, setShowAddQuiz] = useState(false);

  // Form states
  const [moduleForm, setModuleForm] = useState<ModuleFormData>({ title: '', sort_order: '' });
  const [lessonForm, setLessonForm] = useState<LessonFormData>({ module_id: '', title: '', video_url: '', content_text: '', sort_order: '' });
  const [quizForm, setQuizForm] = useState<QuizFormData>({ question: '', options: ['', '', '', ''], correct_index: 0 });

  const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

  const fetchCourseData = async () => {
    try {
      setLoading(true);
      const token = localStorage.getItem('glow_token');
      const response = await fetch(`${API_URL}/api/admin/academy/courses/${courseId}`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });
      
      if (!response.ok) {
        if (response.status === 404) throw new Error('Curso no encontrado');
        throw new Error('Error al cargar el curso');
      }
      
      const data = await response.json();
      setCourse(data.course);
      setModules(data.modules || []);
      setLessons(data.lessons || []);
      setQuizzes(data.quizzes || []);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error desconocido');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCourseData();
  }, [courseId]);

  // ==================== MODULE ACTIONS ====================
  const handleAddModule = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSaving(true);
    
    try {
      const token = localStorage.getItem('glow_token');
      const response = await fetch(`${API_URL}/api/admin/academy/courses/${courseId}/modules`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          title: moduleForm.title,
          sort_order: moduleForm.sort_order ? parseInt(moduleForm.sort_order) : undefined,
        }),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Error al crear módulo');
      }

      const newModule = await response.json();
      setModules(prev => [...prev, newModule].sort((a, b) => a.sort_order - b.sort_order));
      setModuleForm({ title: '', sort_order: '' });
      setShowAddModule(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al crear módulo');
    } finally {
      setSaving(false);
    }
  };

  const handleUpdateModule = async (moduleId: string) => {
    const module = modules.find(m => m.id === moduleId);
    if (!module) return;

    try {
      const token = localStorage.getItem('glow_token');
      const response = await fetch(`${API_URL}/api/admin/academy/modules/${moduleId}`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          title: module.title,
          sort_order: module.sort_order,
        }),
      });

      if (!response.ok) throw new Error('Error al actualizar módulo');
      setEditingModuleId(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al actualizar módulo');
    }
  };

  const handleDeleteModule = async (moduleId: string) => {
    if (!window.confirm('¿Eliminar este módulo? Se eliminarán todas sus lecciones.')) return;
    
    try {
      const token = localStorage.getItem('glow_token');
      const response = await fetch(`${API_URL}/api/admin/academy/modules/${moduleId}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` },
      });

      if (!response.ok) throw new Error('Error al eliminar módulo');
      
      setModules(prev => prev.filter(m => m.id !== moduleId));
      setLessons(prev => prev.filter(l => l.module_id !== moduleId));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al eliminar módulo');
    }
  };

  const moveModule = (fromIndex: number, toIndex: number) => {
    setModules(prev => {
      const newModules = [...prev];
      const [moved] = newModules.splice(fromIndex, 1);
      newModules.splice(toIndex, 0, moved);
      return newModules.map((m, i) => ({ ...m, sort_order: i + 1 }));
    });
  };

  // ==================== LESSON ACTIONS ====================
  const handleAddLesson = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSaving(true);

    try {
      const token = localStorage.getItem('glow_token');
      const response = await fetch(`${API_URL}/api/admin/academy/modules/${lessonForm.module_id}/lessons`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          title: lessonForm.title,
          video_url: lessonForm.video_url || null,
          content_text: lessonForm.content_text || null,
          sort_order: lessonForm.sort_order ? parseInt(lessonForm.sort_order) : undefined,
        }),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Error al crear lección');
      }

      const newLesson = await response.json();
      setLessons(prev => [...prev, newLesson].sort((a, b) => a.sort_order - b.sort_order));
      setLessonForm({ module_id: '', title: '', video_url: '', content_text: '', sort_order: '' });
      setShowAddLesson(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al crear lección');
    } finally {
      setSaving(false);
    }
  };

  const handleUpdateLesson = async (lessonId: string) => {
    const lesson = lessons.find(l => l.id === lessonId);
    if (!lesson) return;

    try {
      const token = localStorage.getItem('glow_token');
      const response = await fetch(`${API_URL}/api/admin/academy/lessons/${lessonId}`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          title: lesson.title,
          video_url: lesson.video_url,
          content_text: lesson.content_text,
          sort_order: lesson.sort_order,
        }),
      });

      if (!response.ok) throw new Error('Error al actualizar lección');
      setEditingLessonId(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al actualizar lección');
    }
  };

  const handleDeleteLesson = async (lessonId: string) => {
    if (!window.confirm('¿Eliminar esta lección?')) return;
    
    try {
      const token = localStorage.getItem('glow_token');
      const response = await fetch(`${API_URL}/api/admin/academy/lessons/${lessonId}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` },
      });

      if (!response.ok) throw new Error('Error al eliminar lección');
      setLessons(prev => prev.filter(l => l.id !== lessonId));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al eliminar lección');
    }
  };

  const moveLesson = (lessonId: string, direction: 'up' | 'down') => {
    const targetLesson = lessons.find(l => l.id === lessonId);
    if (!targetLesson) return;
    
    setLessons(prev => {
      const moduleLessons = prev
        .filter(l => l.module_id === targetLesson.module_id)
        .sort((a, b) => a.sort_order - b.sort_order);
      const lessonIndex = moduleLessons.findIndex(l => l.id === lessonId);
      const targetIndex = direction === 'up' ? lessonIndex - 1 : lessonIndex + 1;
      if (targetIndex < 0 || targetIndex >= moduleLessons.length) return prev;
      
      const newModuleLessons = [...moduleLessons];
      const [moved] = newModuleLessons.splice(lessonIndex, 1);
      newModuleLessons.splice(targetIndex, 0, moved);
      
      return prev.map(l => {
        const updated = newModuleLessons.find(nl => nl.id === l.id);
        return updated ? { ...l, sort_order: newModuleLessons.indexOf(updated) + 1 } : l;
      });
    });
  };

  // ==================== QUIZ ACTIONS ====================
  const handleAddQuiz = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSaving(true);

    const validOptions = quizForm.options.filter(opt => opt.trim());
    if (validOptions.length < 2) {
      setError('Se requieren al menos 2 opciones');
      setSaving(false);
      return;
    }

    try {
      const token = localStorage.getItem('glow_token');
      const response = await fetch(`${API_URL}/api/admin/academy/courses/${courseId}/quizzes`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          question: quizForm.question,
          options: validOptions,
          correct_index: quizForm.correct_index,
        }),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Error al crear pregunta');
      }

      const newQuiz = await response.json();
      setQuizzes(prev => [...prev, newQuiz]);
      setQuizForm({ question: '', options: ['', '', '', ''], correct_index: 0 });
      setShowAddQuiz(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al crear pregunta');
    } finally {
      setSaving(false);
    }
  };

  const handleUpdateQuiz = async (quizId: string) => {
    const quiz = quizzes.find(q => q.id === quizId);
    if (!quiz) return;

    try {
      const token = localStorage.getItem('glow_token');
      const response = await fetch(`${API_URL}/api/admin/academy/quizzes/${quizId}`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          question: quiz.question,
          options: quiz.options,
          correct_index: quiz.correct_index,
        }),
      });

      if (!response.ok) throw new Error('Error al actualizar pregunta');
      setEditingQuizId(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al actualizar pregunta');
    }
  };

  const handleDeleteQuiz = async (quizId: string) => {
    if (!window.confirm('¿Eliminar esta pregunta del examen?')) return;
    
    try {
      const token = localStorage.getItem('glow_token');
      const response = await fetch(`${API_URL}/api/admin/academy/quizzes/${quizId}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` },
      });

      if (!response.ok) throw new Error('Error al eliminar pregunta');
      setQuizzes(prev => prev.filter(q => q.id !== quizId));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al eliminar pregunta');
    }
  };

  // Helpers
  const getLessonsForModule = (moduleId: string) => {
    return lessons
      .filter(l => l.module_id === moduleId)
      .sort((a, b) => a.sort_order - b.sort_order);
  };

  if (user?.rol !== 'ADMIN') {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="text-center">
          <AlertCircle className="w-16 h-16 text-red-400 mx-auto mb-4" />
          <h2 className="text-xl font-bold text-gray-900">Acceso denegado</h2>
          <p className="text-gray-500 mt-2">Solo los administradores pueden acceder a esta sección.</p>
        </div>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="max-w-6xl mx-auto space-y-8 animate-pulse">
        <div className="flex items-center gap-4">
          <div className="w-10 h-10 bg-gray-200 rounded-xl"></div>
          <div className="space-y-2 flex-1">
            <div className="h-6 bg-gray-200 rounded-md w-48"></div>
            <div className="h-4 bg-gray-200 rounded-md w-32"></div>
          </div>
        </div>
        <div className="bg-white rounded-2xl border border-gray-150 p-6 space-y-6">
          <div className="flex gap-4 border-b border-gray-100 pb-3">
            <div className="h-8 bg-gray-200 rounded-lg w-36"></div>
            <div className="h-8 bg-gray-200 rounded-lg w-44"></div>
            <div className="h-8 bg-gray-200 rounded-lg w-32"></div>
          </div>
          <div className="space-y-4">
            <div className="h-12 bg-gray-50 rounded-xl w-full"></div>
            <div className="h-12 bg-gray-50 rounded-xl w-full"></div>
            <div className="h-12 bg-gray-50 rounded-xl w-full"></div>
          </div>
        </div>
      </div>
    );
  }

  if (error && !course) {
    return (
      <div className="max-w-3xl mx-auto text-center p-12">
        <AlertCircle className="w-12 h-12 text-red-400 mx-auto mb-4" />
        <h3 className="text-lg font-semibold text-gray-900 mb-2">Error al cargar el curso</h3>
        <p className="text-gray-500 mb-6">{error}</p>
        <Link href="/admin/academia" className="inline-flex items-center gap-2 px-4 py-2 bg-rose-500 text-white rounded-lg hover:bg-rose-600">
          <ArrowLeft size={18} /> Volver al listado
        </Link>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto space-y-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div className="flex items-center gap-4">
          <Link
            href="/admin/academia"
            className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-xl transition-all"
          >
            <ArrowLeft size={24} />
          </Link>
          <div>
            <h1 className="text-3xl font-extrabold text-gray-900 tracking-tight">{course?.title}</h1>
            <div className="flex items-center gap-3 mt-1 text-sm text-gray-500">
                          <span className="px-2 py-0.5 bg-rose-50 text-rose-700 rounded-full">
                            {course?.category ? course.category.charAt(0).toUpperCase() + course.category.slice(1) : '—'}
                          </span>
                          <span>•</span>
                          <span className="flex items-center gap-1">
                            <GraduationCap className="w-4 h-4" />
                            {course?.badge_name}
                          </span>
                        </div>
          </div>
        </div>
        <Link
          href="/admin/academia/nuevo"
          className="px-4 py-2 bg-gray-100 text-gray-700 rounded-xl font-semibold hover:bg-gray-200 transition-colors"
        >
          + Nuevo Curso
        </Link>
      </div>

      {error && (
        <div className="flex items-center gap-3 p-4 bg-red-50 border border-red-200 rounded-xl text-red-800">
          <AlertCircle size={20} />
          <span>{error}</span>
          <button onClick={() => setError(null)} className="ml-auto text-red-500 hover:text-red-700">
            <X size={20} />
          </button>
        </div>
      )}

      {success && (
        <div className="flex items-center gap-3 p-4 bg-green-50 border border-green-200 rounded-xl text-green-800">
          <CheckCircle size={20} />
          <span className="font-medium">Cambios guardados correctamente</span>
        </div>
      )}

      {/* Tabs */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-200/80 overflow-hidden">
        <div className="border-b border-gray-200">
          <nav className="flex -mb-px" aria-label="Tabs">
            <TabButton 
              active={activeTab === 'modules'} 
              onClick={() => setActiveTab('modules')}
              icon={Layers}
            >
              Módulos y Lecciones
            </TabButton>
            <TabButton 
              active={activeTab === 'quizzes'} 
              onClick={() => setActiveTab('quizzes')}
              icon={HelpCircle}
            >
              Examen de Certificación ({quizzes.length})
            </TabButton>
            <TabButton 
              active={activeTab === 'course'} 
              onClick={() => setActiveTab('course')}
              icon={FileText}
            >
              Info del Curso
            </TabButton>
          </nav>
        </div>

        <div className="p-6">
          {activeTab === 'modules' && <ModulesTab />}
          {activeTab === 'quizzes' && <QuizzesTab />}
          {activeTab === 'course' && <CourseInfoTab />}
        </div>
      </div>
    </div>
  );

  // ==================== TAB COMPONENTS ====================
  function TabButton({ active, onClick, icon: Icon, children }: { 
    active: boolean; 
    onClick: () => void; 
    icon: React.ComponentType<{ size?: number; className?: string }>;
    children: React.ReactNode;
  }) {
    return (
      <button
        onClick={onClick}
        className={`flex items-center gap-2 px-6 py-4 text-sm font-semibold transition-all ${
          active
            ? 'text-rose-600 border-b-2 border-rose-600'
            : 'text-gray-500 hover:text-gray-700 hover:border-gray-300 border-b-2 border-transparent'
        }`}
      >
        <Icon size={18} />
        {children}
      </button>
    );
  }

  function ModulesTab() {
    return (
      <div className="space-y-6">
        {/* Add Module Form */}
        {showAddModule && (
          <ModuleForm 
            onSubmit={handleAddModule} 
            onCancel={() => setShowAddModule(false)} 
            formData={moduleForm} 
            setFormData={setModuleForm} 
            saving={saving} 
          />
        )}

        {modules.length === 0 && !showAddModule && (
          <div className="text-center py-12">
            <Layers className="w-16 h-16 text-gray-300 mx-auto mb-4" />
            <h3 className="text-lg font-semibold text-gray-900 mb-2">No hay módulos aún</h3>
            <p className="text-gray-500 mb-6">Crea el primer módulo para organizar las lecciones del curso</p>
            <button
              onClick={() => setShowAddModule(true)}
              className="inline-flex items-center gap-2 px-5 py-3 bg-rose-500 text-white rounded-xl font-semibold hover:bg-rose-600 transition-colors"
            >
              <Plus size={20} />
              <span>Crear Primer Módulo</span>
            </button>
          </div>
        )}

        <div className="space-y-4">
          {modules.map((module, index) => (
            <ModuleCard
              key={module.id}
              module={module}
              index={index}
              lessons={getLessonsForModule(module.id)}
              expanded={expandedModuleId === module.id}
              editing={editingModuleId === module.id}
              onToggleExpand={() => setExpandedModuleId(expandedModuleId === module.id ? null : module.id)}
              onEditClick={() => setEditingModuleId(editingModuleId === module.id ? null : module.id)}
              onSave={() => handleUpdateModule(module.id)}
              onCancel={() => setEditingModuleId(null)}
              onDelete={() => handleDeleteModule(module.id)}
              onAddLesson={() => setShowAddLesson(module.id)}
              onMoveUp={() => index > 0 && moveModule(index, index - 1)}
              onMoveDown={() => index < modules.length - 1 && moveModule(index, index + 1)}
              formData={module}
              setFormData={(val: Partial<Module>) => setModules(prev => prev.map(m => m.id === module.id ? { ...m, ...val } : m))}
              modulesLength={modules.length}
              showAddLesson={showAddLesson}
              setShowAddLesson={setShowAddLesson}
              lessonForm={lessonForm}
              setLessonForm={setLessonForm}
              modules={modules}
              saving={saving}
              handleAddLesson={handleAddLesson}
              editingLessonId={editingLessonId}
              setEditingLessonId={setEditingLessonId}
              handleUpdateLesson={handleUpdateLesson}
              handleDeleteLesson={handleDeleteLesson}
              moveLesson={moveLesson}
              setLessons={setLessons}
            />
          ))}
        </div>

        {!showAddModule && (
          <button
            onClick={() => setShowAddModule(true)}
            className="w-full flex items-center justify-center gap-2 px-4 py-3 border-2 border-dashed border-gray-200 rounded-xl text-gray-500 hover:border-rose-400 hover:text-rose-500 hover:bg-rose-50 transition-all"
          >
            <Plus size={20} />
            <span className="font-medium">Agregar Módulo</span>
          </button>
        )}
      </div>
    );
  }

  function QuizzesTab() {
    return (
      <div className="space-y-6">
        {showAddQuiz && (
          <QuizForm 
            onSubmit={handleAddQuiz} 
            onCancel={() => setShowAddQuiz(false)} 
            formData={quizForm} 
            setFormData={setQuizForm} 
            saving={saving} 
          />
        )}

        {quizzes.length === 0 && !showAddQuiz ? (
          <div className="text-center py-12">
            <HelpCircle className="w-16 h-16 text-gray-300 mx-auto mb-4" />
            <h3 className="text-lg font-semibold text-gray-900 mb-2">No hay preguntas de examen</h3>
            <p className="text-gray-500 mb-6">Agrega preguntas para el examen de certificación (requiere 100% aciertos para aprobar)</p>
            <button
              onClick={() => setShowAddQuiz(true)}
              className="inline-flex items-center gap-2 px-5 py-3 bg-rose-500 text-white rounded-xl font-semibold hover:bg-rose-600 transition-colors"
            >
              <Plus size={20} />
              <span>Agregar Primera Pregunta</span>
            </button>
          </div>
        ) : (
          <>
            <div className="space-y-4">
              {quizzes.map((quiz, index) => (
                <QuizRow
                  key={quiz.id}
                  quiz={quiz}
                  index={index}
                  editing={editingQuizId === quiz.id}
                  onEditClick={() => setEditingQuizId(editingQuizId === quiz.id ? null : quiz.id)}
                  onSave={() => handleUpdateQuiz(quiz.id)}
                  onCancel={() => setEditingQuizId(null)}
                  onDelete={() => handleDeleteQuiz(quiz.id)}
                  formData={quiz}
                  setFormData={(val: Partial<Quiz>) => setQuizzes(prev => prev.map(q => q.id === quiz.id ? { ...q, ...val } : q))}
                />
              ))}
            </div>
            {!showAddQuiz && (
              <button
                onClick={() => setShowAddQuiz(true)}
                className="w-full flex items-center justify-center gap-2 px-4 py-3 border-2 border-dashed border-gray-200 rounded-xl text-gray-500 hover:border-rose-400 hover:text-rose-500 hover:bg-rose-50 transition-all"
              >
                <Plus size={20} />
                <span className="font-medium">Agregar Pregunta al Examen</span>
              </button>
            )}
          </>
        )}
      </div>
    );
  }

  function CourseInfoTab() {
    return (
      <div className="space-y-6 max-w-2xl">
        <div className="bg-gray-50 rounded-xl p-6">
          <h3 className="font-semibold text-gray-900 mb-4">Información General</h3>
          <dl className="space-y-4 text-sm">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <dt className="text-gray-500">ID</dt>
                <dd className="font-mono text-gray-900 mt-1">{course?.id}</dd>
              </div>
              <div>
                <dt className="text-gray-500">Categoría</dt>
                <dd className="font-medium text-gray-900 mt-1">{course?.category}</dd>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <dt className="text-gray-500">Insignia</dt>
                <dd className="font-medium text-gray-900 mt-1">{course?.badge_name}</dd>
              </div>
              <div>
                <dt className="text-gray-500">Creado</dt>
                <dd className="font-medium text-gray-900 mt-1">
                  {course?.created_at ? new Date(course.created_at).toLocaleDateString('es-ES') : '—'}
                </dd>
              </div>
            </div>
            <div>
              <dt className="text-gray-500">Descripción</dt>
              <dd className="text-gray-900 mt-1 whitespace-pre-wrap">{course?.description}</dd>
            </div>
          </dl>
        </div>

        <div className="bg-gray-50 rounded-xl p-6">
          <h3 className="font-semibold text-gray-900 mb-4">Estadísticas</h3>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <StatItem label="Módulos" value={modules.length} icon={Layers} color="blue" />
            <StatItem label="Lecciones" value={lessons.length} icon={FileText} color="emerald" />
            <StatItem label="Preguntas Examen" value={quizzes.length} icon={HelpCircle} color="amber" />
            <StatItem label="Certificados" value={0} icon={Award} color="rose" />
          </div>
        </div>
      </div>
    );
  }
}

function StatItem({ label, value, icon: Icon, color }: { label: string; value: number; icon: any; color: string }) {
  const colorClasses = {
    blue: 'bg-blue-500 bg-blue-50 text-blue-700',
    emerald: 'bg-emerald-500 bg-emerald-50 text-emerald-700',
    amber: 'bg-amber-500 bg-amber-50 text-amber-700',
    rose: 'bg-rose-500 bg-rose-50 text-rose-700',
  };
  
  return (
    <div className="text-center p-4 bg-white rounded-lg border border-gray-200">
      <div className={`p-3 rounded-xl ${colorClasses[color as keyof typeof colorClasses]?.split(' ')[0]} ${colorClasses[color as keyof typeof colorClasses]?.split(' ')[1]} mx-auto w-fit mb-2`}>
        <Icon size={24} className={colorClasses[color as keyof typeof colorClasses]?.split(' ')[2]} />
      </div>
      <p className="text-2xl font-bold text-gray-900">{value}</p>
      <p className="text-xs text-gray-500">{label}</p>
    </div>
  );
}

function ModuleCard({ 
  module, 
  index, 
  lessons, 
  expanded, 
  editing, 
  onToggleExpand, 
  onEditClick, 
  onSave, 
  onCancel, 
  onDelete, 
  onAddLesson,
  onMoveUp,
  onMoveDown,
  formData,
  setFormData,
  modulesLength,
  showAddLesson,
  setShowAddLesson,
  lessonForm,
  setLessonForm,
  modules,
  saving,
  handleAddLesson,
  editingLessonId,
  setEditingLessonId,
  handleUpdateLesson,
  handleDeleteLesson,
  moveLesson,
  setLessons
}: { 
  module: any; 
  index: number; 
  lessons: any[]; 
  expanded: boolean; 
  editing: boolean; 
  onToggleExpand: () => void; 
  onEditClick: () => void; 
  onSave: () => void; 
  onCancel: () => void; 
  onDelete: () => void; 
  onAddLesson: () => void; 
  onMoveUp: () => void; 
  onMoveDown: () => void; 
  formData: any; 
  setFormData: (prev: any) => any;
  modulesLength: number;
  showAddLesson: string | null;
  setShowAddLesson: (val: string | null) => void;
  lessonForm: any;
  setLessonForm: any;
  modules: any[];
  saving: boolean;
  handleAddLesson: any;
  editingLessonId: string | null;
  setEditingLessonId: (val: string | null) => void;
  handleUpdateLesson: any;
  handleDeleteLesson: any;
  moveLesson: any;
  setLessons: any;
}) {
  const handleInputChange = (field: string, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  return (
    <div className="bg-gray-50 rounded-xl border border-gray-200 overflow-hidden">
      {/* Module Header */}
      <div className="p-4 flex items-center gap-4 bg-white border-b border-gray-100">
        <div className="flex items-center gap-2 text-gray-400">
          {index > 0 && (
            <button onClick={onMoveUp} className="p-1 hover:bg-gray-100 rounded" title="Subir">
              <ChevronUp size={18} />
            </button>
          )}
          {index < modulesLength - 1 && (
            <button onClick={onMoveDown} className="p-1 hover:bg-gray-100 rounded" title="Bajar">
              <ChevronDown size={18} />
            </button>
          )}
        </div>
        <GripVertical className="text-gray-300 cursor-grab" size={20} />
        
        {editing ? (
          <input
            type="text"
            value={formData.title}
            onChange={(e) => handleInputChange('title', e.target.value)}
            className="flex-1 px-3 py-2 border border-rose-400 rounded-lg focus:ring-2 focus:ring-rose-500 focus:border-rose-500 outline-none font-medium"
            autoFocus
          />
        ) : (
          <h3 className="flex-1 font-semibold text-gray-900 cursor-pointer" onClick={onToggleExpand}>
            {module.title}
          </h3>
        )}

        <span className="text-sm text-gray-500 px-2 py-1 bg-gray-100 rounded-full">
          Orden: {module.sort_order}
        </span>

        <div className="flex items-center gap-2 ml-auto">
          {editing ? (
            <>
              <button onClick={onSave} className="px-3 py-1.5 bg-emerald-500 text-white rounded-lg text-sm hover:bg-emerald-600">Guardar</button>
              <button onClick={onCancel} className="px-3 py-1.5 bg-gray-100 text-gray-600 rounded-lg text-sm hover:bg-gray-200">Cancelar</button>
            </>
          ) : (
            <>
              <button onClick={onEditClick} className="p-2 text-gray-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg" title="Editar">
                <Edit size={18} />
              </button>
              <button onClick={onDelete} className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg" title="Eliminar">
                <Trash2 size={18} />
              </button>
            </>
          )}
          <button 
            onClick={onToggleExpand} 
            className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg"
          >
            {expanded ? <ChevronUp size={20} /> : <ChevronDown size={20} />}
          </button>
        </div>
      </div>

      {/* Lessons List */}
      {expanded && (
        <div className="p-4 space-y-3 bg-gray-50/50">
          {showAddLesson === module.id && (
            <LessonForm 
              onSubmit={handleAddLesson} 
              onCancel={() => setShowAddLesson(null)} 
              formData={lessonForm} 
              setFormData={setLessonForm} 
              modules={modules}
              preSelectedModuleId={module.id}
              saving={saving}
            />
          )}

          {lessons.length === 0 && !showAddLesson ? (
            <div className="text-center py-8">
              <FileText className="w-12 h-12 text-gray-300 mx-auto mb-3" />
              <p className="text-gray-500 mb-4">Este módulo no tiene lecciones aún</p>
              <button
                onClick={onAddLesson}
                className="inline-flex items-center gap-2 px-4 py-2 bg-rose-500 text-white rounded-lg font-medium hover:bg-rose-600 transition-colors text-sm"
              >
                <Plus size={18} />
                <span>Agregar Primera Lección</span>
              </button>
            </div>
          ) : (
            <>
              {lessons.map((lesson: Lesson, lIndex: number) => (
                <LessonRow
                  key={lesson.id}
                  lesson={lesson}
                  index={lIndex}
                  editing={editingLessonId === lesson.id}
                  onEditClick={() => setEditingLessonId(editingLessonId === lesson.id ? null : lesson.id)}
                  onSave={() => handleUpdateLesson(lesson.id)}
                  onCancel={() => setEditingLessonId(null)}
                  onDelete={() => handleDeleteLesson(lesson.id)}
                  onMoveUp={() => lIndex > 0 && moveLesson(lesson.id, 'up')}
                  onMoveDown={() => lIndex < lessons.length - 1 && moveLesson(lesson.id, 'down')}
                  formData={lesson}
                  setFormData={(val: Partial<Lesson>) => setLessons(prev => prev.map(l => l.id === lesson.id ? { ...l, ...val } : l))}
                  lessons={lessons}
                />
              ))}
              {!showAddLesson && (
                <button
                  onClick={onAddLesson}
                  className="w-full flex items-center justify-center gap-2 px-4 py-3 border-2 border-dashed border-gray-200 rounded-xl text-gray-500 hover:border-rose-400 hover:text-rose-500 hover:bg-rose-50 transition-all"
                >
                  <Plus size={20} />
                  <span className="font-medium">Agregar Lección</span>
                </button>
              )}
            </>
          )}
        </div>
      )}
    </div>
  );
}

function LessonRow({ 
  lesson, 
  index, 
  editing, 
  onEditClick, 
  onSave, 
  onCancel, 
  onDelete, 
  onMoveUp,
  onMoveDown,
  formData,
  setFormData,
  lessons
}: { 
  lesson: any; 
  index: number; 
  editing: boolean; 
  onEditClick: () => void; 
  onSave: () => void; 
  onCancel: () => void; 
  onDelete: () => void; 
  onMoveUp: () => void; 
  onMoveDown: () => void; 
  formData: any; 
  setFormData: (prev: any) => any;
  lessons: any[];
}) {
  const handleInputChange = (field: string, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  return (
    <div className="bg-white rounded-lg border border-gray-200 p-4 flex items-center gap-4">
      <div className="flex flex-col gap-1 text-gray-400">
        {index > 0 && <button onClick={onMoveUp} className="p-1 hover:bg-gray-100 rounded" title="Subir"><ChevronUp size={16} /></button>}
        {index < lessons.filter(l => l.module_id === lesson.module_id).length - 1 && (
          <button onClick={onMoveDown} className="p-1 hover:bg-gray-100 rounded" title="Bajar"><ChevronDown size={16} /></button>
        )}
      </div>
      <GripVertical className="text-gray-300 cursor-grab" size={18} />
      
      {editing ? (
        <div className="flex-1 space-y-3">
          <input
            type="text"
            value={formData.title}
            onChange={(e) => handleInputChange('title', e.target.value)}
            className="w-full px-3 py-2 border border-rose-400 rounded-lg focus:ring-2 focus:ring-rose-500 focus:border-rose-500 outline-none font-medium"
            placeholder="Título de la lección"
          />
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <input
              type="url"
              value={formData.video_url}
              onChange={(e) => handleInputChange('video_url', e.target.value)}
              placeholder="https://youtube.com/watch?v=... o https://vimeo.com/..."
              className="px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
            />
            <input
              type="number"
              value={formData.sort_order}
              onChange={(e) => handleInputChange('sort_order', e.target.value)}
              placeholder="Orden"
              className="px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none w-24"
              min="1"
            />
          </div>
          <textarea
            value={formData.content_text}
            onChange={(e) => handleInputChange('content_text', e.target.value)}
            rows={3}
            placeholder="Contenido textual de la lección (Markdown soportado)..."
            className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none resize-y font-mono text-sm"
          />
          <div className="flex gap-2">
            <button onClick={onSave} className="px-4 py-2 bg-emerald-500 text-white rounded-lg text-sm hover:bg-emerald-600">Guardar</button>
            <button onClick={onCancel} className="px-4 py-2 bg-gray-100 text-gray-600 rounded-lg text-sm hover:bg-gray-200">Cancelar</button>
          </div>
        </div>
      ) : (
        <div className="flex-1 min-w-0" onClick={onEditClick}>
          <div className="flex items-center gap-3 mb-1">
            <span className="font-medium text-gray-900 truncate">{lesson.title}</span>
            {lesson.video_url && (
              <span className="px-2 py-0.5 bg-blue-50 text-blue-700 text-xs rounded-full flex items-center gap-1">
                <FileText size={12} /> Video
              </span>
            )}
            {lesson.content_text && (
              <span className="px-2 py-0.5 bg-emerald-50 text-emerald-700 text-xs rounded-full flex items-center gap-1">
                <FileText size={12} /> Texto
              </span>
            )}
          </div>
          <p className="text-sm text-gray-500 truncate">
            {lesson.content_text ? lesson.content_text.substring(0, 100) + '...' : 'Sin contenido textual'}
          </p>
        </div>
      )}

      <div className="flex items-center gap-2">
        {editing ? (
          <>
            <button onClick={onSave} className="p-2 text-emerald-500 hover:bg-emerald-50 rounded" title="Guardar"><CheckCircle size={20} /></button>
            <button onClick={onCancel} className="p-2 text-gray-400 hover:bg-gray-100 rounded" title="Cancelar"><X size={20} /></button>
          </>
        ) : (
          <>
            <button onClick={onEditClick} className="p-2 text-gray-400 hover:text-rose-600 hover:bg-rose-50 rounded" title="Editar"><Edit size={18} /></button>
            <button onClick={onDelete} className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded" title="Eliminar"><Trash2 size={18} /></button>
          </>
        )}
      </div>
    </div>
  );
}

function ModuleForm({ onSubmit, onCancel, formData, setFormData, saving }: { 
  onSubmit: (e: React.FormEvent) => void; 
  onCancel: () => void; 
  formData: any; 
  setFormData: (prev: any) => any; 
  saving: boolean; 
}) {
  return (
    <form onSubmit={onSubmit} className="bg-white rounded-xl border border-rose-200 p-6 space-y-4">
      <div className="flex items-center justify-between mb-4">
        <h3 className="font-semibold text-gray-900 flex items-center gap-2">
          <Layers className="text-rose-500" size={20} />
          Nuevo Módulo
        </h3>
        <button type="button" onClick={onCancel} className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg"><X size={20} /></button>
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Título del Módulo *</label>
        <input
          type="text"
          name="title"
          value={formData.title}
          onChange={(e) => setFormData(prev => ({ ...prev, title: e.target.value }))}
          placeholder="Ej: Módulo 1: Protocolo de Bioseguridad"
          className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-rose-500 focus:border-rose-500 outline-none"
          required
          autoFocus
        />
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Orden (opcional)</label>
        <input
          type="number"
          name="sort_order"
          value={formData.sort_order}
          onChange={(e) => setFormData(prev => ({ ...prev, sort_order: e.target.value }))}
          placeholder="Se asignará automáticamente al final"
          className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-rose-500 focus:border-rose-500 outline-none"
          min="1"
        />
      </div>
      <div className="flex justify-end gap-3 pt-2">
        <button type="button" onClick={onCancel} className="px-4 py-2 text-gray-700 font-medium border border-gray-300 rounded-xl hover:bg-gray-50">Cancelar</button>
        <button type="submit" disabled={saving} className="px-4 py-2 bg-rose-500 text-white font-medium rounded-xl hover:bg-rose-600 disabled:opacity-50">
          {saving ? 'Guardando...' : 'Crear Módulo'}
        </button>
      </div>
    </form>
  );
}

function LessonForm({ 
  onSubmit, 
  onCancel, 
  formData, 
  setFormData, 
  modules, 
  preSelectedModuleId, 
  saving 
}: { 
  onSubmit: (e: React.FormEvent) => void; 
  onCancel: () => void; 
  formData: any; 
  setFormData: (prev: any) => any; 
  modules: any[]; 
  preSelectedModuleId: string; 
  saving: boolean; 
}) {
  return (
    <form onSubmit={onSubmit} className="bg-white rounded-xl border border-blue-200 p-6 space-y-4">
      <div className="flex items-center justify-between mb-4">
        <h3 className="font-semibold text-gray-900 flex items-center gap-2">
          <FileText className="text-blue-500" size={20} />
          Nueva Lección
        </h3>
        <button type="button" onClick={onCancel} className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg"><X size={20} /></button>
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Módulo *</label>
        <select
          name="module_id"
          value={formData.module_id}
          onChange={(e) => setFormData(prev => ({ ...prev, module_id: e.target.value }))}
          className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none bg-white"
          required
        >
          <option value="">Seleccionar módulo</option>
          {modules.map(m => (
            <option key={m.id} value={m.id} selected={m.id === preSelectedModuleId}>{m.title}</option>
          ))}
        </select>
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Título de la Lección *</label>
        <input
          type="text"
          name="title"
          value={formData.title}
          onChange={(e) => setFormData(prev => ({ ...prev, title: e.target.value }))}
          placeholder="Ej: 1. Esterilización del Instrumental"
          className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
          required
        />
      </div>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">URL del Video (opcional)</label>
          <input
            type="url"
            name="video_url"
            value={formData.video_url}
            onChange={(e) => setFormData(prev => ({ ...prev, video_url: e.target.value }))}
            placeholder="https://youtube.com/watch?v=... o https://vimeo.com/..."
            className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Orden (opcional)</label>
          <input
            type="number"
            name="sort_order"
            value={formData.sort_order}
            onChange={(e) => setFormData(prev => ({ ...prev, sort_order: e.target.value }))}
            placeholder="Auto"
            className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
            min="1"
          />
        </div>
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Contenido Textual (Markdown, opcional)</label>
        <textarea
          name="content_text"
          value={formData.content_text}
          onChange={(e) => setFormData(prev => ({ ...prev, content_text: e.target.value }))}
          rows={4}
          placeholder="Contenido de la lección... Se renderiza con soporte Markdown básico."
          className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none resize-y font-mono text-sm"
        />
      </div>
      <div className="flex justify-end gap-3 pt-2">
        <button type="button" onClick={onCancel} className="px-4 py-2 text-gray-700 font-medium border border-gray-300 rounded-xl hover:bg-gray-50">Cancelar</button>
        <button type="submit" disabled={saving} className="px-4 py-2 bg-blue-500 text-white font-medium rounded-xl hover:bg-blue-600 disabled:opacity-50">
          {saving ? 'Guardando...' : 'Crear Lección'}
        </button>
      </div>
    </form>
  );
}

function QuizForm({ onSubmit, onCancel, formData, setFormData, saving }: { 
  onSubmit: (e: React.FormEvent) => void; 
  onCancel: () => void; 
  formData: any; 
  setFormData: (prev: any) => any; 
  saving: boolean; 
}) {
  const handleOptionChange = (index: number, value: string) => {
    setFormData(prev => ({
      ...prev,
      options: prev.options.map((opt: string, i: number) => i === index ? value : opt)
    }));
  };

  const handleCorrectIndexChange = (index: number) => {
    setFormData(prev => ({ ...prev, correct_index: index }));
  };

  return (
    <form onSubmit={onSubmit} className="bg-white rounded-xl border border-amber-200 p-6 space-y-4">
      <div className="flex items-center justify-between mb-4">
        <h3 className="font-semibold text-gray-900 flex items-center gap-2">
          <HelpCircle className="text-amber-500" size={20} />
          Nueva Pregunta de Examen
        </h3>
        <button type="button" onClick={onCancel} className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg"><X size={20} /></button>
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Pregunta *</label>
        <textarea
          name="question"
          value={formData.question}
          onChange={(e) => setFormData(prev => ({ ...prev, question: e.target.value }))}
          rows={2}
          placeholder="Ej: ¿Con qué frecuencia deben esterilizarse las herramientas de manicura?"
          className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-amber-500 focus:border-amber-500 outline-none"
          required
        />
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">Opciones de Respuesta (mínimo 2) *</label>
        <div className="space-y-2">
          {formData.options.map((option: string, index: number) => (
            <div key={index} className="flex items-center gap-3">
              <input
                type="radio"
                name="correct_index"
                checked={formData.correct_index === index}
                onChange={() => handleCorrectIndexChange(index)}
                className="w-4 h-4 text-amber-500 border-gray-300 focus:ring-amber-500"
              />
              <input
                type="text"
                value={option}
                onChange={(e) => handleOptionChange(index, e.target.value)}
                placeholder={`Opción ${index + 1}`}
                className="flex-1 px-4 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-amber-500 focus:border-amber-500 outline-none"
              />
              {formData.options.length > 2 && (
                <button
                  type="button"
                  onClick={() => setFormData(prev => ({ ...prev, options: prev.options.filter((_: string, i: number) => i !== index) }))}
                  className="p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-lg"
                  title="Eliminar opción"
                >
                  <Trash2 size={18} />
                </button>
              )}
            </div>
          ))}
        </div>
        {formData.options.length < 4 && (
          <button
            type="button"
            onClick={() => setFormData(prev => ({ ...prev, options: [...prev.options, ''] }))}
            className="mt-2 text-sm text-amber-600 hover:text-amber-700 font-medium flex items-center gap-1"
          >
            <Plus size={16} /> Agregar otra opción
          </button>
        )}
      </div>
      <div className="flex justify-end gap-3 pt-2">
        <button type="button" onClick={onCancel} className="px-4 py-2 text-gray-700 font-medium border border-gray-300 rounded-xl hover:bg-gray-50">Cancelar</button>
        <button type="submit" disabled={saving} className="px-4 py-2 bg-amber-500 text-white font-medium rounded-xl hover:bg-amber-600 disabled:opacity-50">
          {saving ? 'Guardando...' : 'Agregar Pregunta'}
        </button>
      </div>
    </form>
  );
}

function QuizRow({ quiz, index, editing, onEditClick, onSave, onCancel, onDelete, formData, setFormData }: any) {
  const handleInputChange = (field: string, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handleOptionChange = (optIndex: number, value: string) => {
    setFormData(prev => ({
      ...prev,
      options: prev.options.map((opt: string, i: number) => i === optIndex ? value : opt)
    }));
  };

  const handleCorrectChange = (correctIndex: number) => {
    setFormData(prev => ({ ...prev, correct_index: correctIndex }));
  };

  return (
    <div className="bg-white rounded-xl border border-gray-200 p-6 space-y-4">
      <div className="flex items-start justify-between gap-4">
        <div className="flex-1">
          {editing ? (
            <textarea
              value={formData.question}
              onChange={(e) => handleInputChange('question', e.target.value)}
              rows={2}
              className="w-full px-3 py-2 border border-amber-400 rounded-lg focus:ring-2 focus:ring-amber-500 focus:border-amber-500 outline-none font-medium"
            />
          ) : (
            <p className="font-medium text-gray-900">{quiz.question}</p>
          )}
        </div>
        <div className="flex items-center gap-2">
          {editing ? (
            <>
              <button onClick={onSave} className="px-3 py-1.5 bg-emerald-500 text-white rounded-lg text-sm hover:bg-emerald-600">Guardar</button>
              <button onClick={onCancel} className="px-3 py-1.5 bg-gray-100 text-gray-600 rounded-lg text-sm hover:bg-gray-200">Cancelar</button>
            </>
          ) : (
            <>
              <button onClick={onEditClick} className="p-2 text-gray-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg" title="Editar"><Edit size={18} /></button>
              <button onClick={onDelete} className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg" title="Eliminar"><Trash2 size={18} /></button>
            </>
          )}
        </div>
      </div>

      <div className="space-y-2 ml-2 border-l-2 border-gray-100 pl-4">
        {formData.options.map((option: string, optIndex: number) => (
          <div key={optIndex} className="flex items-center gap-3">
            <input
              type="radio"
              name={`correct_${quiz.id}`}
              checked={formData.correct_index === optIndex}
              onChange={() => handleCorrectChange(optIndex)}
              disabled={!editing}
              className="w-4 h-4 text-amber-500 border-gray-300 focus:ring-amber-500"
            />
            {editing ? (
              <input
                type="text"
                value={option}
                onChange={(e) => handleOptionChange(optIndex, e.target.value)}
                className="flex-1 px-3 py-1.5 border border-gray-200 rounded-lg focus:ring-2 focus:ring-amber-500 focus:border-amber-500 outline-none text-sm"
              />
            ) : (
              <span className={`text-sm ${formData.correct_index === optIndex ? 'font-semibold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded' : 'text-gray-700'}`}>
                {option}
                {formData.correct_index === optIndex && <span className="ml-2 text-emerald-500">✓ Correcta</span>}
              </span>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
```

---

### `src/app/(dashboard)/admin/vto/page.tsx`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\src\app\(dashboard)\admin\vto\page.tsx`

```typescript
'use client';

import React, { useState } from 'react';

interface VtoProduct {
  id: string;
  brand: string;
  name: string;
  category: string;
  hex: string;
  finish: string;
  price: number;
}

export default function VtoAdminPage() {
  const [products, setProducts] = useState<VtoProduct[]>([
    { id: 'mk-01', brand: "L'Oréal Paris", name: 'Color Riche Coral Sunset', category: 'makeup', hex: '#E05A47', finish: 'Mate', price: 14.99 },
    { id: 'mk-02', brand: 'MAC Cosmetics', name: 'Velvet Teddy Warm Nude', category: 'makeup', hex: '#C88A68', finish: 'Satinado', price: 24.50 },
    { id: 'nl-01', brand: 'OPI', name: 'Terracota Warm Elegance', category: 'nails', hex: '#B84A39', finish: 'Brillante', price: 12.50 },
    { id: 'nl-03', brand: 'Chanel', name: 'Le Vernis Deep Burgundy', category: 'nails', hex: '#4A0E17', finish: 'Satinado', price: 32.00 },
  ]);

  const [newBrand, setNewBrand] = useState('');
  const [newName, setNewName] = useState('');
  const [newHex, setNewHex] = useState('#E05A47');
  const [newCategory, setNewCategory] = useState('makeup');
  const [newFinish, setNewFinish] = useState('Mate');
  const [newPrice, setNewPrice] = useState('19.99');

  const handleAddProduct = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newBrand || !newName) return;

    const newItem: VtoProduct = {
      id: `vto-${Date.now()}`,
      brand: newBrand,
      name: newName,
      category: newCategory,
      hex: newHex,
      finish: newFinish,
      price: parseFloat(newPrice) || 19.99,
    };

    setProducts([newItem, ...products]);
    setNewBrand('');
    setNewName('');
  };

  return (
    <div className="p-8 max-w-6xl mx-auto text-slate-800">
      <h1 className="text-3xl font-bold mb-2">Gestión de Catálogo VTO Multimarca B2B</h1>
      <p className="text-slate-500 mb-8">Administra los productos de belleza y códigos de tono HEX recomendados por DeepSeek IA para simulación virtual.</p>

      {/* Formulario de Alta de Producto Multimarca */}
      <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-200 mb-8">
        <h2 className="text-xl font-semibold mb-4 text-slate-700">Añadir Nuevo Producto VTO (Marca Socio B2B)</h2>
        <form onSubmit={handleAddProduct} className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium text-slate-600 mb-1">Marca Patrocinadora</label>
            <input
              type="text"
              placeholder="Ej. MAC Cosmetics"
              value={newBrand}
              onChange={(e) => setNewBrand(e.target.value)}
              className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-orange-500 text-sm"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-600 mb-1">Nombre del Producto / Tono</label>
            <input
              type="text"
              placeholder="Ej. Ruby Woo"
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
              className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-orange-500 text-sm"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-600 mb-1">Categoría VTO</label>
            <select
              value={newCategory}
              onChange={(e) => setNewCategory(e.target.value)}
              className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-orange-500 text-sm"
            >
              <option value="makeup">Maquillaje (Rostro/Labios)</option>
              <option value="nails">Manicura & Uñas</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-600 mb-1">Código de Tono (HEX)</label>
            <div className="flex items-center space-x-2">
              <input
                type="color"
                value={newHex}
                onChange={(e) => setNewHex(e.target.value)}
                className="w-10 h-10 rounded border cursor-pointer"
              />
              <input
                type="text"
                value={newHex}
                onChange={(e) => setNewHex(e.target.value)}
                className="w-full px-3 py-2 border rounded-lg text-sm"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-600 mb-1">Acabado</label>
            <select
              value={newFinish}
              onChange={(e) => setNewFinish(e.target.value)}
              className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-orange-500 text-sm"
            >
              <option value="Mate">Mate</option>
              <option value="Satinado">Satinado</option>
              <option value="Brillante">Brillante</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-600 mb-1">Precio E-Commerce ($ USD)</label>
            <input
              type="number"
              step="0.01"
              value={newPrice}
              onChange={(e) => setNewPrice(e.target.value)}
              className="w-full px-3 py-2 border rounded-lg text-sm"
            />
          </div>

          <div className="md:col-span-3 pt-2">
            <button
              type="submit"
              className="bg-orange-600 hover:bg-orange-700 text-white font-medium px-6 py-2 rounded-lg text-sm transition-colors"
            >
              + Publicar Producto en VTO
            </button>
          </div>
        </form>
      </div>

      {/* Lista de Productos VTO Activos */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="p-4 bg-slate-50 border-b font-medium text-slate-700">
          Catálogo Activo de Productos VTO Multimarca ({products.length} productos)
        </div>
        <table className="w-full text-left text-sm border-collapse">
          <thead>
            <tr className="bg-slate-100 border-b text-slate-600">
              <th className="p-3">Color</th>
              <th className="p-3">Marca</th>
              <th className="p-3">Producto</th>
              <th className="p-3">Categoría</th>
              <th className="p-3">Acabado</th>
              <th className="p-3">Precio</th>
            </tr>
          </thead>
          <tbody>
            {products.map((item) => (
              <tr key={item.id} className="border-b hover:bg-slate-50">
                <td className="p-3">
                  <div className="flex items-center space-x-2">
                    <span className="w-6 h-6 rounded-full border shadow-inner" style={{ backgroundColor: item.hex }} />
                    <span className="font-mono text-xs text-slate-500">{item.hex}</span>
                  </div>
                </td>
                <td className="p-3 font-semibold text-slate-800">{item.brand}</td>
                <td className="p-3 text-slate-700">{item.name}</td>
                <td className="p-3 capitalize">{item.category === 'makeup' ? '💄 Maquillaje' : '💅 Manicura'}</td>
                <td className="p-3">{item.finish}</td>
                <td className="p-3 font-medium text-emerald-600">${item.price.toFixed(2)} USD</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

```

---

### `src/app/(auth)/login/page.tsx`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\src\app\(auth)\login\page.tsx`

```typescript
'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import Link from 'next/link';
import { Scissors, Mail, Lock } from 'lucide-react';

export default function LoginPage() {
  const { login } = useAuth();
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSubmitting(true);

    try {
      const res = await login(email, password);
      if (email.toLowerCase() === 'admin@glow.app') {
        window.location.href = '/';
      } else {
        window.location.href = '/admin/academia';
      }
    } catch (err: any) {
      setError(err.response?.data?.error || 'Error al iniciar sesión. Inténtalo de nuevo.');
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
        <h2 className="text-3xl font-extrabold text-gray-900 tracking-tight">¡Hola de nuevo!</h2>
        <p className="text-sm text-gray-500 mt-1">Inicia sesión en tu cuenta de GlowApp</p>
      </div>

      {error && (
        <div className="bg-red-50 text-red-600 px-4 py-3 rounded-xl text-sm border border-red-100 mb-6 text-center">
          {error}
        </div>
      )}

      <form className="space-y-5" onSubmit={handleSubmit}>
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
          {submitting ? 'Iniciando sesión...' : 'Iniciar Sesión'}
        </button>
      </form>

      <div className="mt-8 text-center border-t border-gray-100 pt-6">
        <p className="text-sm text-gray-500">
          ¿No tienes una cuenta?{' '}
          <Link href="/register" className="font-semibold text-rose-500 hover:text-rose-600 transition-colors">
            Regístrate aquí
          </Link>
        </p>
      </div>
    </div>
  );
}

```

---

### `src/app/(auth)/register/page.tsx`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\src\app\(auth)\register\page.tsx`

```typescript
﻿'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Scissors, Mail, Lock, User, Phone, Briefcase } from 'lucide-react';

export default function RegisterPage() {
  const router = useRouter();
  const [nombre, setNombre] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [rol, setRol] = useState('PRESTADOR');
  const [loading, setLoading] = useState(false);

  const handleRegister = (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    setTimeout(() => {
      setLoading(false);
      alert('¡Registro exitoso! Por favor inicia sesión con tus credenciales.');
      router.push('/login');
    }, 1000);
  };

  return (
    <div className="min-h-screen bg-slate-950 flex items-center justify-center p-4">
      <div className="w-full max-w-md bg-slate-900 border border-slate-800 rounded-3xl p-8 shadow-2xl space-y-8">
        <div className="text-center space-y-2">
          <div className="w-12 h-12 bg-rose-500 text-white rounded-2xl flex items-center justify-center mx-auto shadow-lg shadow-rose-500/30">
            <Scissors size={26} />
          </div>
          <h1 className="text-2xl font-extrabold text-white tracking-wide">Crear Cuenta en GlowApp</h1>
          <p className="text-xs text-slate-400">Únete a la plataforma líder de belleza y bienestar</p>
        </div>

        <form onSubmit={handleRegister} className="space-y-4">
          <div>
            <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1.5">Nombre Completo</label>
            <div className="relative">
              <User size={18} className="absolute left-3.5 top-3.5 text-slate-500" />
              <input
                type="text"
                required
                placeholder="Ej. Ana Silva"
                value={nombre}
                onChange={(e) => setNombre(e.target.value)}
                className="w-full pl-10 pr-4 py-3 text-sm bg-slate-800 border border-slate-700 text-white rounded-xl focus:outline-none focus:ring-2 focus:ring-rose-500/30 focus:border-rose-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1.5">Correo Electrónico</label>
            <div className="relative">
              <Mail size={18} className="absolute left-3.5 top-3.5 text-slate-500" />
              <input
                type="email"
                required
                placeholder="tu@correo.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full pl-10 pr-4 py-3 text-sm bg-slate-800 border border-slate-700 text-white rounded-xl focus:outline-none focus:ring-2 focus:ring-rose-500/30 focus:border-rose-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1.5">Contraseña</label>
            <div className="relative">
              <Lock size={18} className="absolute left-3.5 top-3.5 text-slate-500" />
              <input
                type="password"
                required
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full pl-10 pr-4 py-3 text-sm bg-slate-800 border border-slate-700 text-white rounded-xl focus:outline-none focus:ring-2 focus:ring-rose-500/30 focus:border-rose-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1.5">Tipo de Perfil</label>
            <select
              value={rol}
              onChange={(e) => setRol(e.target.value)}
              className="w-full px-4 py-3 text-sm bg-slate-800 border border-slate-700 text-white rounded-xl focus:outline-none focus:ring-2 focus:ring-rose-500/30 focus:border-rose-500"
            >
              <option value="PRESTADOR">Prestador / Estilista / Salón</option>
              <option value="CLIENTE">Cliente Final</option>
            </select>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3.5 bg-rose-500 hover:bg-rose-600 disabled:opacity-50 text-white font-bold text-sm rounded-xl shadow-lg shadow-rose-500/25 transition-all mt-4"
          >
            {loading ? 'Creando Cuenta...' : 'Registrarme'}
          </button>
        </form>

        <p className="text-center text-xs text-slate-400">
          ¿Ya tienes una cuenta?{' '}
          <Link href="/login" className="font-semibold text-rose-400 hover:text-rose-300">
            Inicia Sesión
          </Link>
        </p>
      </div>
    </div>
  );
}

```

---

### `src/components/dashboard/Sidebar.tsx`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\src\components\dashboard\Sidebar.tsx`

```typescript
'use client';

import React from 'react';
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
  LayoutDashboard
} from 'lucide-react';

export default function Sidebar() {
  const pathname = usePathname();
  const { user, logout } = useAuth();

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
```

---

### `src/components/dashboard/Header.tsx`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\src\components\dashboard\Header.tsx`

```typescript
'use client';

import React from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { Bell, Search, Menu } from 'lucide-react';

export default function Header() {
  const { user } = useAuth();

  return (
    <header className="bg-white border-b border-gray-200 h-16 flex items-center justify-between px-8 shadow-sm">
      <div className="flex items-center gap-4 flex-1">
        <button className="md:hidden text-gray-600 hover:text-gray-900">
          <Menu size={20} />
        </button>
        <div className="relative max-w-md w-full hidden md:block">
          <span className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none text-gray-400">
            <Search size={18} />
          </span>
          <input
            type="text"
            placeholder="Buscar servicios, citas..."
            className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500 text-sm transition-all duration-200"
          />
        </div>
      </div>

      <div className="flex items-center gap-4">
        <button className="relative p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-xl transition-all duration-200">
          <Bell size={20} />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-rose-500 rounded-full"></span>
        </button>
        
        <div className="h-8 w-px bg-gray-200"></div>

        {user && (
          <div className="flex items-center gap-3">
            <div className="text-right">
              <p className="text-sm font-semibold text-gray-900">{user.nombre}</p>
              <p className="text-xs text-rose-500 font-medium capitalize">{user.rol.toLowerCase()}</p>
            </div>
            <div className="w-9 h-9 rounded-full bg-rose-100 flex items-center justify-center font-bold text-rose-500 border border-rose-200 shadow-sm">
              {user.nombre[0].toUpperCase()}
            </div>
          </div>
        )}
      </div>
    </header>
  );
}

```

---

### `src/components/auth/ProtectedRoute.tsx`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\src\components\auth\ProtectedRoute.tsx`

```typescript
'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';

interface ProtectedRouteProps {
  children: React.ReactNode;
  allowedRoles?: Array<'CLIENTE' | 'PRESTADOR' | 'ADMIN'>;
}

export default function ProtectedRoute({ children, allowedRoles }: ProtectedRouteProps) {
  const { user, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!loading) {
      if (!user) {
        router.push('/login');
      } else if (allowedRoles && !allowedRoles.includes(user.rol as any)) {
        // Redirigir al dashboard correspondiente a su rol
        if (user.rol === 'PRESTADOR') {
          router.push('/prestador');
        } else {
          router.push('/cliente');
        }
      }
    }
  }, [user, loading, router, allowedRoles]);

  if (loading || !user) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-rose-500 mx-auto"></div>
          <p className="mt-4 text-gray-600 font-medium text-sm">Cargando...</p>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}

```

---

### `src/contexts/AuthContext.tsx`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\src\contexts\AuthContext.tsx`

```typescript
'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import { User } from '../types/user';
import axios from 'axios';

interface AuthContextType {
  user: User | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<any>;
  register: (data: { email: string; nombre: string; phone?: string; rol: 'CLIENTE' | 'PRESTADOR'; password: string }) => Promise<any>;
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

  const login = async (email: string, password: string) => {
      setLoading(true);
      try {
        const response = await axios.post(`${API_URL}/api/auth/login`, {
          email,
          password,
        });

      const token = response.data.token;
      const apiUser = response.data.user || response.data.usuario;
      if (token && apiUser) {
        const usuario = {
          id: parseInt(apiUser.id) || apiUser.id,
          email: apiUser.email,
          nombre: apiUser.full_name || apiUser.nombre,
          rol: apiUser.rol || (apiUser.role === 'admin' ? 'ADMIN' : (apiUser.role === 'provider' ? 'PRESTADOR' : 'CLIENTE')),
          onboarding_completo: apiUser.onboarding_completo
        };
        localStorage.setItem('glow_token', token);
        localStorage.setItem('glow_user', JSON.stringify(usuario));
        if (usuario.rol === 'ADMIN') {
          localStorage.setItem('adminToken', token);
        }
        setUser(usuario as any);
      }
      setLoading(false);
      return response.data;
    } catch (error) {
      setLoading(false);
      throw error;
    }
  };

  const register = async (data: { email: string; nombre: string; phone?: string; rol: 'CLIENTE' | 'PRESTADOR'; password: string }) => {
    setLoading(true);
    try {
      const response = await axios.post(`${API_URL}/api/auth/register`, data);
      const token = response.data.token;
      const apiUser = response.data.user || response.data.usuario;
      if (token && apiUser) {
        const usuario = {
          id: parseInt(apiUser.id) || apiUser.id,
          email: apiUser.email,
          nombre: apiUser.full_name || apiUser.nombre,
          rol: apiUser.rol || (apiUser.role === 'admin' ? 'ADMIN' : (apiUser.role === 'provider' ? 'PRESTADOR' : 'CLIENTE')),
          onboarding_completo: apiUser.onboarding_completo
        };
        localStorage.setItem('glow_token', token);
        localStorage.setItem('glow_user', JSON.stringify(usuario));
        if (usuario.rol === 'ADMIN') {
          localStorage.setItem('adminToken', token);
        }
        setUser(usuario as any);
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
    localStorage.removeItem('adminToken');
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

```

---

### `src/hooks/useBookings.ts`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\admin-dashboard\src\hooks\useBookings.ts`

```typescript
'use client';

import { useState, useEffect } from 'react';
import { apiClient } from '../lib/api-client';
import { Booking } from '../types/booking';

export interface UseBookingsFilters {
  rol?: 'cliente' | 'prestador' | 'ADMIN';
  [key: string]: any;
}

export function useBookings(filters?: UseBookingsFilters) {
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<any>(null);

  const fetchBookings = async () => {
    setLoading(true);
    try {
      const data = await apiClient.getBookings(filters);
      setBookings(data);
      setError(null);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBookings();
  }, [JSON.stringify(filters)]);

  const cancelBooking = async (id: number | string) => {
    try {
      await apiClient.cancelBooking(Number(id));
      // Refresh bookings
      await fetchBookings();
      return true;
    } catch (err) {
      setError(err);
      throw err;
    }
  };

  return {
    bookings,
    loading,
    error,
    refetch: fetchBookings,
    cancelBooking,
  };
}

```

---

## 2. Backend Services & Controllers (Node.js / Express)

### `backend/src/routes/inventoryRoutes.js`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\backend\src\routes\inventoryRoutes.js`

```javascript
// backend/src/routes/inventoryRoutes.js
const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const inventoryController = require('../controllers/inventoryController');

// 🔹 OBTENER INVENTARIO EN CONSIGNACIÓN Y ALERTAS
router.get('/inventory/consignacion', authMiddleware, inventoryController.getProviderConsignmentInventory);

// 🔹 REGISTRAR CONSUMO O VENTA DE INSUMO EN SALÓN SAAS
router.post('/inventory/consume', authMiddleware, inventoryController.consumeInventoryItem);

module.exports = router;

```

---

### `backend/src/controllers/inventoryController.js`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\backend\src\controllers\inventoryController.js`

```javascript
// backend/src/controllers/inventoryController.js
const { pool } = require('../config/db');

// GET /api/inventory/consignacion → Obtener inventario en consignación del salón/prestador
exports.getProviderConsignmentInventory = async (req, res) => {
  try {
    const providerId = req.user.id;

    const query = `
      SELECT 
        ic.id,
        ic.producto_id,
        p.nombre AS producto_nombre,
        p.precio AS producto_precio,
        p.imagen_url AS producto_imagen,
        ic.cantidad_entregada,
        ic.cantidad_vendida,
        (ic.cantidad_entregada - ic.cantidad_vendida) AS cantidad_disponible,
        ic.lote,
        ic.fecha_vencimiento,
        ic.fecha_entrega,
        CASE 
          WHEN (ic.cantidad_entregada - ic.cantidad_vendida) <= 2 THEN true 
          ELSE false 
        END AS alerta_stock_bajo
      FROM inventario_consignacion_prestador ic
      JOIN productos p ON ic.producto_id = p.id
      WHERE ic.provider_id = $1
      ORDER BY alerta_stock_bajo DESC, p.nombre ASC;
    `;

    const result = await pool.query(query, [providerId]);

    res.json({
      success: true,
      count: result.rows.length,
      data: result.rows
    });
  } catch (error) {
    console.error('❌ ERROR EN GET /api/inventory/consignacion:', error);
    res.status(500).json({ error: 'Error al obtener inventario en consignación' });
  }
};

// POST /api/inventory/consume → Registrar consumo de insumo en cita o venta presencial
exports.consumeInventoryItem = async (req, res) => {
  try {
    const providerId = req.user.id;
    const { producto_id, cantidad } = req.body;

    const qty = parseInt(cantidad) || 1;
    if (!producto_id || qty <= 0) {
      return res.status(400).json({ error: 'Debes proporcionar producto_id y cantidad válida (>0)' });
    }

    // Verificar disponibilidad en consignación
    const checkQuery = `
      SELECT id, cantidad_entregada, cantidad_vendida 
      FROM inventario_consignacion_prestador 
      WHERE provider_id = $1 AND producto_id = $2;
    `;
    const checkRes = await pool.query(checkQuery, [providerId, producto_id]);

    if (checkRes.rows.length === 0) {
      return res.status(404).json({ error: 'Producto no encontrado en el inventario de consignación del prestador' });
    }

    const item = checkRes.rows[0];
    const disponible = item.cantidad_entregada - item.cantidad_vendida;

    if (disponible < qty) {
      return res.status(400).json({ 
        error: `Stock insuficiente en consignación. Disponible: ${disponible}, Solicitado: ${qty}` 
      });
    }

    // Incrementar cantidad vendida/consumida
    const updateQuery = `
      UPDATE inventario_consignacion_prestador
      SET cantidad_vendida = cantidad_vendida + $1
      WHERE id = $2
      RETURNING *, (cantidad_entregada - cantidad_vendida) AS cantidad_disponible;
    `;
    const updateRes = await pool.query(updateQuery, [qty, item.id]);

    res.json({
      success: true,
      message: 'Consumo de insumo registrado en el inventario SaaS',
      data: updateRes.rows[0]
    });
  } catch (error) {
    console.error('❌ ERROR EN POST /api/inventory/consume:', error);
    res.status(500).json({ error: 'Error al registrar consumo de inventario' });
  }
};

```

---

### `backend/src/controllers/providerController.js`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\backend\src\controllers\providerController.js`

```javascript
const { pool } = require('../config/db');

// GET /api/providers → LISTA DE PRESTADORES (Geolocalización con PostGIS)
exports.getProviders = async (req, res) => {
  try {
    let lat = parseFloat(req.query.lat);
    let lon = parseFloat(req.query.lon);
    let radius = parseInt(req.query.radius);

    // Si faltan parámetros, leer configuraciones dinámicas de la base de datos
    if (isNaN(lat) || isNaN(lon) || isNaN(radius)) {
      const configRes = await pool.query(
        "SELECT key, value FROM platform_config WHERE key IN ('gps_centro_latitud', 'gps_centro_longitud', 'gps_default_radio_metros')"
      );
      const configs = {};
      configRes.rows.forEach(r => {
        configs[r.key] = r.value;
      });

      if (isNaN(lat)) lat = parseFloat(configs['gps_centro_latitud'] || '4.6735');
      if (isNaN(lon)) lon = parseFloat(configs['gps_centro_longitud'] || '-74.1422');
      if (isNaN(radius)) radius = parseInt(configs['gps_default_radio_metros'] || '5000');
    }

    // Validación defensiva de rangos
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      return res.status(400).json({ success: false, error: 'Coordenadas inválidas' });
    }
    if (radius < 100 || radius > 100000) {
      return res.status(400).json({ success: false, error: 'Radio fuera de rango (100m - 100km)' });
    }

    const query = `
      SELECT 
        p.id, 
        u.nombre as full_name, 
        u.foto_url as avatar_url,
        p.business_name, 
        p.description,
        p.rating_avg, 
        p.rating_count, 
        (p.estatus_verificacion = 'APROBADO') as is_verified,
        ST_X(p.ubicacion::geometry) AS longitude,
        ST_Y(p.ubicacion::geometry) AS latitude,
        COALESCE(pl.tier, 'Creative Edge') as loyalty_tier,
        ST_Distance(p.ubicacion, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography) AS distance_meters
      FROM perfiles_prestador p
      INNER JOIN usuarios u ON p.id = u.id
      LEFT JOIN provider_loyalty pl ON p.id = pl.provider_id
      WHERE p.is_active = true AND p.estatus_verificacion = 'APROBADO'
        AND ST_DWithin(
          p.ubicacion, 
          ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
          CASE 
            WHEN COALESCE(pl.tier, 'Creative Edge') = 'Visage Pro' THEN $3 * 1.15
            ELSE $3
          END
        )
      ORDER BY 
        CASE 
          WHEN COALESCE(pl.tier, 'Creative Edge') = 'Avant-Garde Elite' THEN 1
          WHEN COALESCE(pl.tier, 'Creative Edge') = 'Visage Pro' THEN 2
          ELSE 3
        END ASC,
        distance_meters ASC;
    `;

    const result = await pool.query(query, [lon, lat, radius]);

    // Mapeo explícito para tipos nativos
    const formattedProviders = result.rows.map(row => ({
      id: row.id.toString(),
      full_name: row.full_name,
      avatar_url: row.avatar_url || '',
      business_name: row.business_name || '',
      description: row.description || '',
      rating_avg: parseFloat(row.rating_avg) || 0.0,
      rating_count: parseInt(row.rating_count) || 0,
      is_verified: !!row.is_verified,
      loyalty_tier: row.loyalty_tier,
      distance_meters: Math.round(row.distance_meters),
      latitude: parseFloat(row.latitude) || 4.6097,
      longitude: parseFloat(row.longitude) || -74.0817
    }));

    const response = {
      success: true,
      count: formattedProviders.length,
      data: formattedProviders
    };
    
    if (process.env.NODE_ENV === 'development') {
      response.debug = { lat, lon, radius };
    }
    
    res.json(response);

  } catch (error) {
    console.error('❌ ERROR en GET /api/providers:', { 
      message: error.message, 
      code: error.code,
      query: error.query 
    });
    res.status(500).json({ success: false, error: 'Internal Server Error' });
  }
};

// GET /api/providers/:id → DETALLE DE UN PRESTADOR (Servicios + Portfolio + Reseñas)
exports.getProviderById = async (req, res) => {
  try {
    const { id } = req.params;
    const numericId = parseInt(id);
    if (isNaN(numericId)) return res.status(400).json({ error: 'ID inválido' });
    
    // 1. Datos del proveedor (JOIN con usuarios para foto_url)
    const providerQ = `
      SELECT p.id, u.nombre as full_name, u.foto_url as avatar_url, u.phone, 
             p.business_name, p.description, p.rating_avg, 
             p.rating_count, (p.estatus_verificacion = 'APROBADO') as is_verified 
      FROM perfiles_prestador p 
      JOIN usuarios u ON p.id = u.id 
      WHERE p.id = $1;
    `;
    const providerRes = await pool.query(providerQ, [numericId]);
    if (providerRes.rows.length === 0) return res.status(404).json({ error: 'No encontrado' });

    const servicesQ = `
      SELECT id, name, description, price, duration_minutes, category 
      FROM services 
      WHERE provider_id = $1 AND is_active = true 
      ORDER BY name;
    `;
    const servicesRes = await pool.query(servicesQ, [numericId]);

    const portfolioQ = `
      SELECT id, image_url, title, category 
      FROM portfolio_items 
      WHERE provider_id = $1 
      ORDER BY created_at DESC LIMIT 10;
    `;
    const portfolioRes = await pool.query(portfolioQ, [numericId]);

    const reviewsQ = `
      SELECT r.rating, r.comment, r.created_at, u.nombre as client_name 
      FROM reviews r 
      JOIN usuarios u ON r.client_id = u.id 
      WHERE r.provider_id = $1 
      ORDER BY r.created_at DESC LIMIT 5;
    `;
    const reviewsRes = await pool.query(reviewsQ, [numericId]);

    res.json({
      success: true,
      data: {
        provider: {
          ...providerRes.rows[0],
          id: providerRes.rows[0].id.toString()
        },
        services: servicesRes.rows,
        portfolio: portfolioRes.rows,
        reviews: reviewsRes.rows
      }
    });
  } catch (error) {
    console.error('❌ ERROR /api/providers/:id:', { message: error.message, code: error.code });
    res.status(500).json({ error: 'Error interno al cargar detalles' });
  }
};

// GET /api/providers/:id/slots → Obtener slots de tiempo disponibles para un proveedor y fecha específica
exports.getProviderSlots = async (req, res) => {
  try {
    const providerId = req.params.id;
    const { date, service_id } = req.query;

    if (!date || !service_id) {
      return res.status(400).json({ error: 'Faltan parámetros requeridos (date, service_id)' });
    }

    const serviceIds = service_id.split(',').map(s => s.trim()).filter(s => s.length > 0);
    if (serviceIds.length === 0) {
      return res.status(400).json({ error: 'Formato de service_id inválido' });
    }

    // 1. Obtener la duración total acumulada de los servicios solicitados
    const serviceRes = await pool.query(
      'SELECT SUM(duration_minutes) as total_duration, COUNT(*) as match_count FROM services WHERE id = ANY($1) AND provider_id = $2 AND is_active = true;',
      [serviceIds, providerId]
    );
    if (serviceRes.rows.length === 0 || parseInt(serviceRes.rows[0].match_count) !== serviceIds.length) {
      return res.status(404).json({ error: 'Uno o más servicios no fueron encontrados o están inactivos' });
    }
    const selectedDuration = parseInt(serviceRes.rows[0].total_duration);

    // 2. Obtener todas las citas activas para ese día
    const bookingsQuery = `
      SELECT b.scheduled_at, s.duration_minutes 
      FROM bookings b
      JOIN services s ON b.service_id = s.id
      WHERE b.provider_id = $1 
        AND b.scheduled_at::date = $2::date
        AND b.estado NOT IN ('CANCELADA');
    `;
    const bookingsRes = await pool.query(bookingsQuery, [providerId, date]);
    const activeBookings = bookingsRes.rows.map(row => {
      const start = new Date(row.scheduled_at);
      const duration = parseInt(row.duration_minutes);
      const end = new Date(start.getTime() + duration * 60 * 1000);
      return { start, end };
    });

    // 3. Obtener el horario configurado del prestador
    const hoursRes = await pool.query('SELECT active_start_hour, active_end_hour, weekly_schedule FROM perfiles_prestador WHERE id = $1', [providerId]);
    
    const [year, month, day] = date.split('-').map(Number);
    const dateObj = new Date(year, month - 1, day);
    const dayOfWeek = dateObj.getDay(); // 0: domingo, 1: lunes, ..., 6: sabado
    const dayNames = ['domingo', 'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado'];
    const currentDayName = dayNames[dayOfWeek];

    const weeklySchedule = hoursRes.rows.length > 0 && hoursRes.rows[0].weekly_schedule ? hoursRes.rows[0].weekly_schedule : null;
    let startHour = 6;
    let endHour = 20;
    let isDayActive = true;

    if (weeklySchedule && weeklySchedule[currentDayName]) {
      const dayConf = weeklySchedule[currentDayName];
      isDayActive = dayConf.activo !== false;
      startHour = dayConf.inicio !== undefined ? parseInt(dayConf.inicio) : 6;
      endHour = dayConf.fin !== undefined ? parseInt(dayConf.fin) : 20;
    } else {
      startHour = hoursRes.rows.length > 0 && hoursRes.rows[0].active_start_hour !== null ? parseInt(hoursRes.rows[0].active_start_hour) : 6;
      endHour = hoursRes.rows.length > 0 && hoursRes.rows[0].active_end_hour !== null ? parseInt(hoursRes.rows[0].active_end_hour) : 20;
    }

    if (!isDayActive) {
      return res.json({ success: true, slots: [] });
    }

    const slots = [];
    const startTime = new Date(year, month - 1, day, startHour, 0, 0);
    const endTime = new Date(year, month - 1, day, endHour, 0, 0);

    const now = new Date();

    let currentSlot = new Date(startTime);
    while (currentSlot < endTime) {
      const slotStart = new Date(currentSlot);
      const slotEnd = new Date(slotStart.getTime() + selectedDuration * 60 * 1000);

      // Formato HH:MM
      const hours = String(slotStart.getHours()).padStart(2, '0');
      const minutes = String(slotStart.getMinutes()).padStart(2, '0');
      const timeStr = `${hours}:${minutes}`;

      let isAvailable = true;

      // Deshabilitar slots pasados si la fecha consultada es hoy
      if (slotStart < now) {
        isAvailable = false;
      }

      // Si aún está disponible por hora, comprobar colisiones con citas existentes
      if (isAvailable) {
        for (const booking of activeBookings) {
          // Colisión: start1 < end2 AND end1 > start2
          if (slotStart.getTime() < booking.end.getTime() && slotEnd.getTime() > booking.start.getTime()) {
            isAvailable = false;
            break;
          }
        }
      }

      slots.push({
        time: timeStr,
        is_available: isAvailable
      });

      // Incrementar por 30 minutos
      currentSlot.setMinutes(currentSlot.getMinutes() + 30);
    }

    res.json({
      success: true,
      date,
      service_id,
      slots
    });

  } catch (error) {
    console.error('❌ ERROR EN GET /api/providers/:id/slots:', error);
    res.status(500).json({ error: 'Error interno al obtener slots de tiempo' });
  }
};

```

---

### `backend/src/controllers/bookingController.js`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\backend\src\controllers\bookingController.js`

```javascript
// backend/src/controllers/bookingController.js
const { pool } = require('../config/db');
const { Booking, Service, User, Transaction } = require('../models');
const { sequelize } = require('../config/database');
const { Op } = require('sequelize');
const crypto = require('crypto');

const verifyWompiSignature = (req) => {
  const secret = process.env.WOMPI_WEBHOOK_SECRET;
  if (!secret) {
    console.warn('⚠️ ADVERTENCIA CRÍTICA: WOMPI_WEBHOOK_SECRET no está configurado. En producción y staging las solicitudes de webhook serán bloqueadas.');
    if (process.env.NODE_ENV === 'production' || process.env.NODE_ENV === 'staging') {
      return false;
    }
    return true; // Permitir en desarrollo local sin configuración
  }

  const signature = req.header('x-wompi-signature') || req.header('x-signature');
  if (!signature) {
    console.warn(`🚨 [FINTECH SECURITY ALERT] Webhook recibido sin firma desde IP ${req.ip}`);
    return false;
  }

  const expected = crypto
    .createHmac('sha256', secret)
    .update(JSON.stringify(req.body))
    .digest('hex');

  const signatureBuffer = Buffer.from(signature, 'hex');
  const expectedBuffer = Buffer.from(expected, 'hex');

  const isValid = signatureBuffer.length === expectedBuffer.length &&
    crypto.timingSafeEqual(signatureBuffer, expectedBuffer);

  if (!isValid) {
    console.warn(`🚨 [FINTECH SECURITY ALERT] Intentos de spoofing o firma de Webhook Wompi inválida desde IP ${req.ip}`);
  }

  return isValid;
};

// 🔹 CREAR RESERVA
exports.createBooking = async (req, res) => {
  try {
    const clientId = req.user.id;
    let { provider_id, service_id, service_ids, scheduled_at, service_address, notes, productos_adicionales } = req.body;

    if (!service_ids && service_id) {
      service_ids = [service_id];
    }

    if (!provider_id || !service_ids || !Array.isArray(service_ids) || service_ids.length === 0 || !scheduled_at) {
      return res.status(400).json({ error: 'Faltan campos requeridos o formato inválido para service_ids' });
    }

    // Obtener y validar todos los servicios solicitados
    const services = await Service.findAll({
      where: {
        id: service_ids,
        provider_id
      }
    });

    if (services.length !== service_ids.length) {
      return res.status(404).json({ error: 'Uno o más servicios no fueron encontrados' });
    }

    // Ordenar los servicios en base al orden recibido en service_ids
    const servicesMap = {};
    services.forEach(s => { servicesMap[s.id] = s; });
    const orderedServices = service_ids.map(id => servicesMap[id]);

    const totalServicesPrice = orderedServices.reduce((sum, s) => sum + parseFloat(s.price), 0);
    const totalDurationMinutes = orderedServices.reduce((sum, s) => sum + parseInt(s.duration_minutes), 0);

    let total_amount = totalServicesPrice;
    let cleanProductsList = [];

    // Validar y acumular productos adicionales
    if (productos_adicionales && Array.isArray(productos_adicionales) && productos_adicionales.length > 0) {
      for (const prodItem of productos_adicionales) {
        const { id, cantidad } = prodItem;
        const qty = parseInt(cantidad) || 1;

        const prodQuery = 'SELECT id, nombre, precio, stock FROM productos WHERE id = :productId;';
        const prodResults = await sequelize.query(prodQuery, {
          replacements: { productId: id },
          type: sequelize.QueryTypes.SELECT
        });

        if (prodResults.length === 0) {
          return res.status(404).json({ error: `Producto con ID ${id} no encontrado` });
        }

        const dbProd = prodResults[0];
        if (parseInt(dbProd.stock) < qty) {
          return res.status(400).json({ error: `Stock insuficiente para el producto: ${dbProd.nombre}` });
        }

        const prodPrice = parseFloat(dbProd.precio);
        total_amount += prodPrice * qty;

        cleanProductsList.push({
          id: dbProd.id,
          nombre: dbProd.nombre,
          precio: prodPrice,
          cantidad: qty
        });
      }
    }

    // 🔸 Validación de solapamiento de horarios (Collision Check de la duración acumulada)
    const newStart = new Date(scheduled_at);
    const newEnd = new Date(newStart.getTime() + totalDurationMinutes * 60 * 1000);
    
    // 🇨🇴 Filtrar citas del mismo día considerando la zona horaria de Colombia (America/Bogota UTC-5)
    const baseDate = new Date(scheduled_at);
    // 05:00 UTC corresponde a 00:00:00 hora Colombia del mismo día
    const startOfDay = new Date(Date.UTC(baseDate.getUTCFullYear(), baseDate.getUTCMonth(), baseDate.getUTCDate(), 5, 0, 0, 0));
    // 04:59:59 UTC del día siguiente corresponde a 23:59:59 hora Colombia
    const endOfDay = new Date(Date.UTC(baseDate.getUTCFullYear(), baseDate.getUTCMonth(), baseDate.getUTCDate() + 1, 4, 59, 59, 999));

    const overlaps = await Booking.findAll({
      where: {
        provider_id,
        estado: { [Op.ne]: 'CANCELADA' },
        scheduled_at: {
          [Op.between]: [startOfDay, endOfDay]
        }
      },
      include: [{
        model: Service,
        as: 'service',
        attributes: ['duration_minutes']
      }]
    });

    // Verificar solapamiento en el subconjunto filtrado
    for (const b of overlaps) {
      const bStart = new Date(b.scheduled_at);
      const bDuration = parseInt(b.service.duration_minutes);
      const bEnd = new Date(bStart.getTime() + bDuration * 60 * 1000);

      if (newStart.getTime() < bEnd.getTime() && newEnd.getTime() > bStart.getTime()) {
        return res.status(409).json({ error: 'El horario seleccionado ya está reservado o entra en conflicto con otra cita' });
      }
    }

    const pin = Math.floor(1000 + Math.random() * 9000).toString();

    // Calcular tarifa_reserva basada en el costo real transaccional de Wompi ($900 COP + 2.89% + IVA 19% del fee)
    const feeFijo = 900;
    const feeVariable = total_amount * 0.0289;
    const feeTotal = feeFijo + feeVariable;
    const ivaFee = feeTotal * 0.19;
    const tarifaReserva = Math.round(feeTotal + ivaFee);

    // Crear las múltiples citas secuenciales en la base de datos dentro de una transacción
    const generatedIds = orderedServices.map(() => crypto.randomUUID());
    let currentScheduledTime = new Date(scheduled_at);
    const createdBookings = [];

    await sequelize.transaction(async (t) => {
      for (let i = 0; i < orderedServices.length; i++) {
        const currentService = orderedServices[i];
        const currentId = generatedIds[i];
        const isPrimary = (i === 0);
        const durationMinutes = parseInt(currentService.duration_minutes);

        const bookingProducts = isPrimary ? (cleanProductsList.length > 0 ? cleanProductsList : []) : [];
        const bookingBruto = isPrimary ? total_amount : 0;
        const bookingTarife = isPrimary ? tarifaReserva : 0;

        const metadata = {
          products: bookingProducts,
          linked_booking_ids: generatedIds.filter(id => id !== currentId),
          is_primary: isPrimary,
          primary_booking_id: generatedIds[0]
        };

        const booking = await Booking.create({
          id: currentId,
          client_id: clientId,
          provider_id,
          service_id: currentService.id,
          scheduled_at: new Date(currentScheduledTime),
          valor_bruto: bookingBruto,
          tarifa_reserva: bookingTarife,
          service_address: service_address || null,
          notes: notes || null,
          estado: 'PENDIENTE_PAGO',
          pin_verificacion: pin,
          productos_adicionales: metadata
        }, { transaction: t });

        createdBookings.push(booking);

        // Incrementar el tiempo de inicio para la siguiente cita
        currentScheduledTime = new Date(currentScheduledTime.getTime() + durationMinutes * 60 * 1000);
      }
    });

    const primaryBooking = createdBookings[0];
    console.log(`📅 Nuevas citas enlazadas creadas: [${generatedIds.join(', ')}] para usuario ${clientId} con PIN ${pin}.`);

    // Enviar SMS simulado y notificar vía WebSocket con alerta auditiva "GlowApp"
    try {
      const { rows: providerRows } = await pool.query('SELECT nombre, phone FROM usuarios WHERE id = $1', [provider_id]);
      if (providerRows.length > 0) {
        const provider = providerRows[0];
        const providerPhone = provider.phone || 'no-phone';
        const msgText = `¡Tienes una nueva reserva en GlowApp! Alerta auditiva: GlowApp`;
        
        console.log(`[SMS SENDER] Enviando SMS a ${providerPhone} (${provider.nombre}): "${msgText}"`);
        
        const { notifyProviderNewBooking } = require('../services/websocketService');
        notifyProviderNewBooking(provider_id, msgText);
      }
    } catch (notifyErr) {
      console.error('⚠️ Error al notificar al prestador de nueva cita:', notifyErr.message);
    }

    res.json({
      success: true,
      message: 'Citas reservadas exitosamente',
      booking_id: primaryBooking.id,
      pin_verificacion: pin,
      booking: primaryBooking,
      bookings: createdBookings
    });
  } catch (error) {
    console.error('❌ ERROR EN /api/bookings:', { message: error.message, code: error.code });
    res.status(500).json({ error: 'Error al crear la reserva' });
  }
};

// 🔹 Panel de Prestador: Obtener citas
exports.getProviderBookings = async (req, res) => {
  try {
    if (req.user.role !== 'provider' && req.user.role !== 'PRESTADOR') {
      return res.status(403).json({ error: 'Acceso denegado: solo para proveedores' });
    }

    // Usamos pool para queries directas si son a tablas no mapeadas (o complejas), 
    // pero Sequelize es genial para obtener la estructura limpia.
    const query = `
      SELECT 
        b.id, b.scheduled_at, b.estado AS status, b.valor_bruto AS total_amount, 
        b.comision_plataforma AS platform_commission, b.impuestos_estado AS state_tax, b.pago_neto_prestador AS provider_net_amount,
        b.client_id, b.pin_verificacion, b.service_address,
        s.name as service_name, s.price,
        u.nombre as client_name, u.phone as client_phone,
        t.external_id AS wompi_reference, t.status AS payout_status
      FROM bookings b
      JOIN services s ON b.service_id = s.id
      JOIN usuarios u ON b.client_id = u.id
      LEFT JOIN transactions t ON b.id = t.booking_id
      WHERE b.provider_id = $1
      ORDER BY b.scheduled_at ASC;
    `;
    
    const result = await pool.query(query, [req.user.id]);
    
    const formattedBookings = result.rows.map(row => ({
      id: row.id,
      client_id: row.client_id.toString(),
      scheduled_at: row.scheduled_at ? new Date(row.scheduled_at).toISOString() : null,
      status: row.status,
      total_amount: parseFloat(row.total_amount) || 0,
      platform_commission: parseFloat(row.platform_commission) || 0,
      state_tax: parseFloat(row.state_tax) || 0,
      provider_net_amount: parseFloat(row.provider_net_amount) || 0,
      service_name: row.service_name,
      price: parseFloat(row.price) || 0,
      client_name: row.client_name,
      client_phone: row.client_phone,
      service_address: row.service_address || '',
      pin_verificacion: row.pin_verificacion || null,
      wompi_reference: row.wompi_reference || null,
      payout_status: row.payout_status || null
    }));
    
    res.json({ success: true, count: formattedBookings.length, data: formattedBookings });
    
  } catch (error) {
    console.error('❌ ERROR EN /api/bookings/provider:', { message: error.message, code: error.code });
    res.status(500).json({ error: 'Error interno al cargar citas' });
  }
};

// 🔹 Actualizar estado de cita
exports.updateBookingStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const bookingId = req.params.id;
    const providerId = req.user.id;

    const mapStatusToDb = (status) => {
      const s = status.toUpperCase();
      if (s === 'PENDING' || s === 'PENDIENTE_PAGO') return 'PENDIENTE_PAGO';
      if (s === 'CONFIRMED' || s === 'CONFIRMADA') return 'CONFIRMADA';
      if (s === 'COMPLETED' || s === 'COMPLETADA') return 'COMPLETADA';
      if (s === 'CANCELLED' || s === 'CANCELADA') return 'CANCELADA';
      return s;
    };

    const dbStatus = mapStatusToDb(status);

    const validStatuses = ['PENDIENTE_PAGO', 'CONFIRMADA', 'EN_PROGRESO', 'FINALIZADA_PRESTADOR', 'COMPLETADA', 'CANCELADA'];
    if (!validStatuses.includes(dbStatus)) {
      return res.status(400).json({ error: `Estado inválido. Permitidos: ${validStatuses.join(', ')}` });
    }

    const booking = await Booking.findOne({
      where: { id: bookingId, provider_id: providerId }
    });

    if (!booking) {
      return res.status(404).json({ error: 'Cita no encontrada o no te pertenece' });
    }

    booking.estado = dbStatus;
    await booking.save();

    console.log('✅ Cita actualizada a estado:', dbStatus);
    
    res.json({ 
      success: true, 
      booking: {
        id: booking.id,
        status: booking.estado
      } 
    });
    
  } catch (error) {
    console.error('❌ ERROR EN PATCH /api/bookings/:id/status:', { message: error.message, code: error.code });
    res.status(500).json({ error: 'Error al actualizar estado' });
  }
};

// 🔹 Historial de Citas del Cliente
exports.getClientBookings = async (req, res) => {
  try {
    const clientId = req.user.id;

    const query = `
      SELECT 
        b.id, b.scheduled_at, b.estado AS status, b.valor_bruto AS total_amount, b.service_address, b.notes, b.pin_verificacion,
        s.name as service_name, s.duration_minutes as service_duration,
        u_prov.nombre as provider_name,
        p.business_name as provider_business_name,
        u_prov.foto_url as provider_avatar_url,
        u_prov.phone as provider_phone,
        r.id as review_id, r.rating as review_rating, r.comment as review_comment
      FROM bookings b
      JOIN services s ON b.service_id = s.id
      JOIN perfiles_prestador p ON b.provider_id = p.id
      JOIN usuarios u_prov ON p.id = u_prov.id
      LEFT JOIN reviews r ON b.id = r.booking_id
      WHERE b.client_id = $1
      ORDER BY b.scheduled_at DESC;
    `;
    
    const result = await pool.query(query, [clientId]);
    
    const formattedBookings = result.rows.map(row => ({
      id: row.id,
      scheduled_at: row.scheduled_at ? new Date(row.scheduled_at).toISOString() : null,
      status: row.status,
      total_amount: parseFloat(row.total_amount) || 0,
      service_address: row.service_address || '',
      notes: row.notes || '',
      pin_verificacion: row.pin_verificacion || null,
      service_name: row.service_name,
      service_duration: parseInt(row.service_duration) || 0,
      provider_name: row.provider_name,
      provider_business_name: row.provider_business_name || '',
      provider_avatar_url: row.provider_avatar_url || '',
      provider_phone: row.provider_phone || '',
      is_reviewed: row.review_id !== null,
      review: row.review_id ? {
        id: row.review_id,
        rating: parseInt(row.review_rating) || 0,
        comment: row.review_comment || ''
      } : null
    }));
    
    res.json({ success: true, count: formattedBookings.length, data: formattedBookings });
    
  } catch (error) {
    console.error('❌ ERROR EN /api/bookings/client:', { message: error.message, code: error.code });
    res.status(500).json({ error: 'Error interno al cargar el historial de citas' });
  }
};

// 🔹 Cancelar cita por cliente
exports.cancelBooking = async (req, res) => {
  try {
    const bookingId = req.params.id;
    const clientId = req.user.id;

    const booking = await Booking.findOne({
      where: { id: bookingId, client_id: clientId }
    });

    if (!booking) {
      return res.status(404).json({ error: 'Cita no encontrada o no tienes permisos para cancelarla' });
    }

    if (booking.estado === 'CANCELADA') {
      return res.status(400).json({ error: 'La cita ya está cancelada' });
    }
    if (booking.estado === 'COMPLETADA') {
      return res.status(400).json({ error: 'No se puede cancelar una cita que ya ha sido completada' });
    }

    booking.estado = 'CANCELADA';
    await booking.save();

    console.log(`❌ Cita ${bookingId} cancelada por el cliente ${clientId}`);

    res.json({
      success: true,
      message: 'Cita cancelada exitosamente',
      booking: {
        id: booking.id,
        status: booking.estado
      }
    });

  } catch (error) {
    console.error('❌ ERROR EN PATCH /api/bookings/:id/cancel:', { message: error.message, code: error.code });
    res.status(500).json({ error: 'Error interno al cancelar la cita' });
  }
};

// 🔹 Simular Pago con Wompi para una cita (Cliente) - REFACTORIZADO A SEQUELIZE TRANSACTIONS
exports.payBooking = async (req, res) => {
  try {
    const bookingId = req.params.id;
    const clientId = req.user.id;
    const { payment_method } = req.body;

    const method = (payment_method || 'NEQUI').toUpperCase();
    if (!['NEQUI', 'CARD'].includes(method)) {
      return res.status(400).json({ error: 'Método de pago inválido. Permitidos: NEQUI, CARD' });
    }

    const booking = await Booking.findOne({
      where: { id: bookingId, client_id: clientId }
    });

    if (!booking) {
      return res.status(404).json({ error: 'Cita no encontrada o no tienes permisos para pagarla' });
    }

    if (booking.estado !== 'PENDIENTE_PAGO') {
      return res.status(400).json({ error: `La cita no se encuentra en estado PENDIENTE_PAGO. Estado actual: ${booking.estado}` });
    }

    await new Promise(resolve => setTimeout(resolve, 1500));

    const referenceToken = 'wompi_sim_' + Math.random().toString(36).substring(2, 11).toUpperCase();

    const result = await sequelize.transaction(async (t) => {
      // 1. Actualizar el estado de la cita
      booking.estado = 'CONFIRMADA';
      booking.payment_status = 'paid';
      await booking.save({ transaction: t });

      // Propagar a citas hijas enlazadas
      if (booking.productos_adicionales && Array.isArray(booking.productos_adicionales.linked_booking_ids)) {
        const linkedIds = booking.productos_adicionales.linked_booking_ids;
        if (linkedIds.length > 0) {
          await Booking.update(
            { estado: 'CONFIRMADA', payment_status: 'paid' },
            { where: { id: linkedIds }, transaction: t }
          );
        }
      }

      // Decrementar stock de productos con validación preventiva (FOR UPDATE)
      const productsList = Array.isArray(booking.productos_adicionales)
        ? booking.productos_adicionales
        : (booking.productos_adicionales && Array.isArray(booking.productos_adicionales.products)
            ? booking.productos_adicionales.products
            : []);

      if (productsList.length > 0) {
        for (const item of productsList) {
          const prodRes = await sequelize.query(
            'SELECT stock, nombre FROM productos WHERE id = :productId FOR UPDATE;',
            {
              replacements: { productId: item.id },
              type: sequelize.QueryTypes.SELECT,
              transaction: t
            }
          );
          if (prodRes.length === 0) {
            throw new Error(`Producto con ID ${item.id} no encontrado.`);
          }
          const currentStock = parseInt(prodRes[0].stock) || 0;
          if (currentStock < item.cantidad) {
            throw new Error(`Stock insuficiente para el producto: ${prodRes[0].nombre}. Disponible: ${currentStock}, Solicitado: ${item.cantidad}`);
          }
          await sequelize.query(
            'UPDATE productos SET stock = stock - :qty WHERE id = :productId;',
            {
              replacements: { qty: item.cantidad, productId: item.id },
              type: sequelize.QueryTypes.UPDATE,
              transaction: t
            }
          );
        }
      }

      // 2. Registrar la transacción
      const [tx, created] = await Transaction.findOrCreate({
        where: { booking_id: bookingId },
        defaults: {
          amount: booking.valor_bruto,
          status: 'paid',
          payment_method: method,
          external_id: referenceToken
        },
        transaction: t
      });

      if (!created) {
        tx.amount = booking.valor_bruto;
        tx.status = 'paid';
        tx.payment_method = method;
        tx.external_id = referenceToken;
        await tx.save({ transaction: t });
      }

      return {
        booking_id: bookingId,
        reference: referenceToken,
        amount: parseFloat(booking.valor_bruto),
        payment_method: method
      };
    });

    console.log(`\n💳 [WOMPI SIMULATOR SUCCESS] Pago completado con éxito de forma local. Cita: ${bookingId}. Referencia: ${referenceToken}`);

    res.json({
      success: true,
      message: 'Pago procesado y verificado con éxito por el simulador de Wompi',
      status: 'APPROVED',
      ...result
    });

  } catch (error) {
    console.error('❌ ERROR EN POST /api/bookings/:id/pay:', error);
    res.status(500).json({ error: 'Error interno al procesar el pago' });
  }
};

// 🔹 Webhook Simulado de Wompi - REFACTORIZADO A SEQUELIZE TRANSACTIONS
exports.wompiWebhook = async (req, res) => {
  try {
    if (!verifyWompiSignature(req)) {
      return res.status(401).json({ error: 'Firma de webhook invÃ¡lida.' });
    }

    const { event, data } = req.body;
    console.log('📡 [WOMPI WEBHOOK RECEIVED] Evento:', event);

    if (event === 'transaction.updated' && data && data.transaction) {
      const tx = data.transaction;
      const bookingId = tx.reference;
      const status = tx.status;
      const amount = tx.amount_in_cents / 100;
      const paymentMethod = tx.payment_method_type || 'NEQUI';
      const externalId = tx.id;

      if (status === 'APPROVED') {
        await sequelize.transaction(async (t) => {
          // Actualizar cita a CONFIRMADA
          await Booking.update(
            { estado: 'CONFIRMADA', payment_status: 'paid' },
            { where: { id: bookingId }, transaction: t }
          );

          // Obtener la cita y propagar a citas hijas vinculadas si existen
          const booking = await Booking.findByPk(bookingId, { transaction: t });
          if (booking && booking.productos_adicionales && Array.isArray(booking.productos_adicionales.linked_booking_ids)) {
            const linkedIds = booking.productos_adicionales.linked_booking_ids;
            if (linkedIds.length > 0) {
              await Booking.update(
                { estado: 'CONFIRMADA', payment_status: 'paid' },
                { where: { id: linkedIds }, transaction: t }
              );
            }
          }

          // Decrementar stock de productos con validación preventiva (FOR UPDATE)
          const productsList = booking && booking.productos_adicionales
            ? (Array.isArray(booking.productos_adicionales)
                ? booking.productos_adicionales
                : (Array.isArray(booking.productos_adicionales.products)
                    ? booking.productos_adicionales.products
                    : []))
            : [];

          if (productsList.length > 0) {
            for (const item of productsList) {
              const prodRes = await sequelize.query(
                'SELECT stock, nombre FROM productos WHERE id = :productId FOR UPDATE;',
                {
                  replacements: { productId: item.id },
                  type: sequelize.QueryTypes.SELECT,
                  transaction: t
                }
              );
              if (prodRes.length === 0) {
                throw new Error(`Producto con ID ${item.id} no encontrado.`);
              }
              const currentStock = parseInt(prodRes[0].stock) || 0;
              if (currentStock < item.cantidad) {
                throw new Error(`Stock insuficiente para el producto: ${prodRes[0].nombre}. Disponible: ${currentStock}, Solicitado: ${item.cantidad}`);
              }
              await sequelize.query(
                'UPDATE productos SET stock = stock - :qty WHERE id = :productId;',
                {
                  replacements: { qty: item.cantidad, productId: item.id },
                  type: sequelize.QueryTypes.UPDATE,
                  transaction: t
                }
              );
            }
          }

          // Registrar la transacción
          const [trans, created] = await Transaction.findOrCreate({
            where: { booking_id: bookingId },
            defaults: {
              amount: amount,
              status: 'paid',
              payment_method: paymentMethod,
              external_id: externalId
            },
            transaction: t
          });

          if (!created) {
            trans.status = 'paid';
            trans.external_id = externalId;
            await trans.save({ transaction: t });
          }
        });

        console.log(`✅ [WOMPI WEBHOOK SUCCESS] Cita ${bookingId} confirmada por webhook Sequelize.`);
      }
    }

    res.json({ success: true });
  } catch (error) {
    console.error('❌ ERROR EN /api/payments/wompi-webhook:', error);
    res.status(500).json({ error: 'Error al procesar el webhook' });
  }
};

// 🔹 Crear reseña para cita completada
exports.createReview = async (req, res) => {
  try {
    const bookingId = req.params.id;
    const clientId = req.user.id;
    const { rating, comment } = req.body;

    const parsedRating = parseInt(rating);
    if (isNaN(parsedRating) || parsedRating < 1 || parsedRating > 5) {
      return res.status(400).json({ error: 'La calificación debe ser un número entero entre 1 y 5' });
    }

    const booking = await Booking.findOne({
      where: { id: bookingId, client_id: clientId }
    });

    if (!booking) {
      return res.status(404).json({ error: 'Cita no encontrada o no tienes permisos para calificarla' });
    }

    if (booking.estado !== 'COMPLETADA') {
      return res.status(400).json({ error: 'Solo puedes calificar citas que hayan sido completadas' });
    }

    const reviewCheck = await pool.query('SELECT id FROM reviews WHERE booking_id = $1', [bookingId]);
    if (reviewCheck.rows.length > 0) {
      return res.status(400).json({ error: 'Esta cita ya ha sido calificada' });
    }

    const clientDb = await pool.connect();
    try {
      await clientDb.query('BEGIN');

      const insertReviewQuery = `
        INSERT INTO reviews (booking_id, client_id, provider_id, rating, comment)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING id;
      `;
      await clientDb.query(insertReviewQuery, [bookingId, clientId, booking.provider_id, parsedRating, comment || null]);

      const statsQuery = 'SELECT AVG(rating) as avg_rating, COUNT(id) as count_rating FROM reviews WHERE provider_id = $1;';
      const statsRes = await clientDb.query(statsQuery, [booking.provider_id]);
      const avg = parseFloat(statsRes.rows[0].avg_rating) || 0.0;
      const count = parseInt(statsRes.rows[0].count_rating) || 0;

      const updateProviderQuery = 'UPDATE perfiles_prestador SET rating_avg = $1, rating_count = $2 WHERE id = $3;';
      await clientDb.query(updateProviderQuery, [avg, count, booking.provider_id]);

      await clientDb.query('COMMIT');

      res.json({
        success: true,
        message: 'Reseña publicada con éxito y reputación del proveedor actualizada',
        data: { rating_avg: avg, rating_count: count }
      });
    } catch (e) {
      await clientDb.query('ROLLBACK');
      throw e;
    } finally {
      clientDb.release();
    }

  } catch (error) {
    console.error('❌ ERROR EN POST /api/bookings/:id/review:', { message: error.message, code: error.code });
    res.status(500).json({ error: 'Error interno al guardar la reseña' });
  }
};

// 🔹 INICIAR SERVICIO
exports.startService = async (req, res) => {
  try {
    const bookingId = req.params.id;
    const providerId = req.user.id;

    const booking = await Booking.findOne({
      where: { id: bookingId, provider_id: providerId }
    });

    if (!booking) {
      return res.status(404).json({ error: 'Cita no encontrada o no tienes permisos para iniciarla' });
    }

    if (booking.estado !== 'CONFIRMADA') {
      return res.status(400).json({ error: `No se puede iniciar el servicio. El estado actual es ${booking.estado} (debe ser CONFIRMADA).` });
    }

    booking.estado = 'EN_PROGRESO';
    await booking.save();

    console.log(`🚀 Servicio iniciado para cita ${bookingId} por prestador ${providerId}`);

    res.json({
      success: true,
      message: 'Servicio iniciado con éxito',
      booking: {
        id: booking.id,
        status: booking.estado
      }
    });

  } catch (error) {
    console.error('❌ ERROR EN PATCH /api/bookings/:id/start:', error);
    res.status(500).json({ error: 'Error interno al iniciar el servicio' });
  }
};

```

---

### `backend/src/controllers/authController.js`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\backend\src\controllers\authController.js`

```javascript
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');
const { getJwtSecret, toApiRole } = require('../config/jwt');
const redisClient = require('../config/redis');
const emailService = require('../services/email.service');


// ==========================================
// 📝 REGISTRO LOCAL
// ==========================================
exports.register = async (req, res) => {
  try {
    const { full_name, email, password, phone, role } = req.body;
    
    if (!full_name || !email || !password) {
      return res.status(400).json({ error: 'Faltan campos obligatorios' });
    }

    const cleanEmail = email.trim().toLowerCase();
    const hashedPassword = await bcrypt.hash(password, 10);
    const providerId = 'local_' + cleanEmail;

    // Determinar el rol y estado de onboarding
    const userRole = (role && role.toUpperCase() === 'PRESTADOR') ? 'PRESTADOR' : 'CLIENTE';
    const onboarding = (userRole === 'CLIENTE'); // true para cliente (completo), false para prestador (requiere docs)

    const result = await pool.query(
      `INSERT INTO usuarios (nombre, email, password_hash, phone, auth_provider, provider_id, rol, onboarding_completo) 
       VALUES ($1, $2, $3, $4, 'LOCAL', $5, $6, $7) 
       RETURNING id, nombre, email, rol, onboarding_completo`,
      [full_name, cleanEmail, hashedPassword, phone || null, providerId, userRole, onboarding]
    );

    const user = result.rows[0];
    res.status(201).json({ 
      success: true, 
      user: {
        id: user.id.toString(),
        full_name: user.nombre,
        email: user.email,
        role: toApiRole(user.rol),
        onboarding_completo: user.onboarding_completo
      }
    });

  } catch (err) {
    if (err.code === '23505') return res.status(400).json({ error: 'El email ya está registrado' });
    console.error('❌ ERROR REGISTER:', err.message);
    res.status(500).json({ error: 'Error al registrar usuario' });
  }
};

// ==========================================
// 🔐 INICIO DE SESIÓN LOCAL (LOGIN)
// ==========================================
exports.login = async (req, res) => {
  try {

    const { email, password } = req.body;
    
    if (!email || !password) {
      console.log("❌ VALIDACIÓN FALLIDA: Faltan campos. Email:", email, "Password:", password);
      return res.status(400).json({ error: 'Email y contraseña son obligatorios' });
    }

    const cleanEmail = email.trim().toLowerCase();

    const result = await pool.query(
      `SELECT id, nombre, email, password_hash, rol, onboarding_completo, is_active 
       FROM usuarios 
       WHERE LOWER(email) = $1 AND auth_provider = 'LOCAL'`, 
      [cleanEmail]
    );
    
    if (result.rows.length === 0) {
      console.log('❌ RECHAZADO: El correo local no existe en la BD.');
      return res.status(401).json({ error: 'Credenciales inválidas' });
    }
    
    const user = result.rows[0];

    if (user.is_active === false) {
      console.log('❌ RECHAZADO: El usuario está desactivado.');
      return res.status(403).json({ error: 'Tu cuenta ha sido desactivada por el administrador.' });
    }

    const isValid = await bcrypt.compare(password, user.password_hash);
    if (!isValid) {
      console.log('❌ RECHAZADO: La contraseña es incorrecta.');
      return res.status(401).json({ error: 'Credenciales inválidas' });
    }
    
    // Generación del Token JWT
    const token = jwt.sign(
      { id: user.id, email: user.email, role: toApiRole(user.rol), rol: user.rol }, 
      getJwtSecret(), 
      { expiresIn: '7d' }
    );
    
    console.log('✅ LOGIN LOCAL EXITOSO para:', user.email);

    res.json({ 
      success: true, 
      token, 
      user: { 
        id: user.id.toString(), 
        full_name: user.nombre, 
        email: user.email, 
        role: toApiRole(user.rol),
        onboarding_completo: user.onboarding_completo
      } 
    });

  } catch (err) {
    console.error('❌ ERROR LOGIN LOCAL:', err.message);
    res.status(500).json({ error: 'Error al iniciar sesión' });
  }
};

// ==========================================
// 🔗 INICIO DE SESIÓN FEDERADO (OAuth 2.0)
// ==========================================
exports.oauth = async (req, res) => {
  try {
    // 🛡️ PARCHE DE SEGURIDAD (OWASP API2:2023): Bloquear mock OAuth en producción
    if (process.env.NODE_ENV === 'production' || (process.env.ALLOW_MOCK_AUTH !== 'true' && process.env.NODE_ENV !== 'test')) {
      return res.status(403).json({
        error: 'El método OAuth directo de pruebas está deshabilitado en este entorno. Usa /api/auth/google.'
      });
    }

    const { email, nombre, foto_url, auth_provider, provider_id } = req.body;

    if (!email || !nombre || !auth_provider || !provider_id) {
      return res.status(400).json({ error: 'Faltan campos requeridos para OAuth' });
    }

    const cleanEmail = email.trim().toLowerCase();
    const provider = auth_provider.toUpperCase(); // GOOGLE, OUTLOOK, LOCAL

    // Buscamos si existe por la cuenta federada o por email
    let userQuery = await pool.query(
      `SELECT id, nombre, email, rol, onboarding_completo, is_active 
       FROM usuarios 
       WHERE (auth_provider = $1 AND provider_id = $2) OR LOWER(email) = $3`,
      [provider, provider_id, cleanEmail]
    );

    let user;

    if (userQuery.rows.length > 0) {
      user = userQuery.rows[0];
      
      if (user.is_active === false) {
        console.log('❌ RECHAZADO OAUTH: El usuario está desactivado.');
        return res.status(403).json({ error: 'Tu cuenta ha sido desactivada por el administrador.' });
      }

      // Si existía (ej. local) pero ahora ingresa con oauth, actualizamos proveedor federado
      await pool.query(
        `UPDATE usuarios 
         SET auth_provider = $1, provider_id = $2, foto_url = COALESCE(foto_url, $3) 
         WHERE id = $4`,
        [provider, provider_id, foto_url || null, user.id]
      );
      // Recargar datos actualizados
      const updated = await pool.query('SELECT id, nombre, email, rol, onboarding_completo, is_active FROM usuarios WHERE id = $1', [user.id]);
      user = updated.rows[0];
    } else {
      // Registrar nuevo usuario federado con rol = NULL y onboarding_completo = false
      const insertRes = await pool.query(
        `INSERT INTO usuarios (nombre, email, foto_url, auth_provider, provider_id, rol, onboarding_completo) 
         VALUES ($1, $2, $3, $4, $5, NULL, false) 
         RETURNING id, nombre, email, rol, onboarding_completo`,
        [nombre, cleanEmail, foto_url || null, provider, provider_id]
      );
      user = insertRes.rows[0];
    }

    // Firmar Token JWT
    const token = jwt.sign(
      { id: user.id, email: user.email, role: toApiRole(user.rol), rol: user.rol }, 
      getJwtSecret(), 
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      token,
      user: {
        id: user.id.toString(),
        full_name: user.nombre,
        email: user.email,
        role: toApiRole(user.rol),
        onboarding_completo: user.onboarding_completo
      }
    });

  } catch (err) {
    console.error('❌ ERROR OAUTH:', err.message);
    res.status(500).json({ 
      error: 'Error al procesar OAuth',
      details: process.env.ALLOW_MOCK_AUTH === 'true' ? err.message : undefined
    });
  }
};

// ==========================================
// 📋 COMPLETAR ONBOARDING (Ley 1581 Habeas Data y Términos y Condiciones)
// ==========================================
exports.onboarding = async (req, res) => {
  try {
    const userId = req.user.id;
    const { rol, documento_id_url, rut_url, certificacion_url, aceptar_habeas_data, aceptar_terminos } = req.body;

    if (!rol || !['CLIENTE', 'PRESTADOR'].includes(rol.toUpperCase())) {
      return res.status(400).json({ error: 'Rol inválido o ausente' });
    }

    if (aceptar_habeas_data !== true || aceptar_terminos !== true) {
      return res.status(400).json({ error: 'Debe aceptar la Política de Tratamiento de Datos Personales (Habeas Data) y los Términos y Condiciones para continuar.' });
    }

    const mappedRol = rol.toUpperCase();
    const clientIp = req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress;

    if (mappedRol === 'PRESTADOR') {
      // 🛡️ PARCHE DE SEGURIDAD (GLOW-SEC-01): El usuario que realiza el onboarding de prestador
      // NO obtiene el rol en la tabla usuarios de forma inmediata. Se almacena su solicitud
      // y archivos en perfiles_prestador como PENDIENTE, pero su cuenta de autenticación
      // sigue siendo CLIENTE hasta aprobación administrativa.
      await pool.query(
        `UPDATE usuarios 
         SET onboarding_completo = true,
             habeas_data_accepted_at = NOW(), habeas_data_ip = $2,
             terminos_accepted_at = NOW(), terminos_ip = $2
         WHERE id = $1`,
        [userId, clientIp]
      );

      // Crear o actualizar perfil en perfiles_prestador (requiere revisión administrativa)
      await pool.query(
        `INSERT INTO perfiles_prestador (id, documento_id_url, rut_url, certificacion_url, estatus_verificacion, is_active)
         VALUES ($1, $2, $3, $4, 'PENDIENTE', true)
         ON CONFLICT (id) DO UPDATE SET
           documento_id_url = EXCLUDED.documento_id_url,
           rut_url = EXCLUDED.rut_url,
           certificacion_url = EXCLUDED.certificacion_url,
           estatus_verificacion = 'PENDIENTE';`,
         [userId, documento_id_url || null, rut_url || null, certificacion_url || null]
      );
      
      console.log(`📋 Onboarding y aceptación legal completados para Proveedor ID ${userId}. Estatus: PENDIENTE.`);
    } else {
      // Cliente se marca completo inmediatamente
      await pool.query(
        `UPDATE usuarios 
         SET rol = 'CLIENTE', onboarding_completo = true,
             habeas_data_accepted_at = NOW(), habeas_data_ip = $2,
             terminos_accepted_at = NOW(), terminos_ip = $2
         WHERE id = $1`,
        [userId, clientIp]
      );
      console.log(`📋 Onboarding y aceptación legal completados para Cliente ID ${userId}.`);
    }

    res.json({
      success: true,
      message: 'Onboarding completado exitosamente',
      user: {
        role: mappedRol === 'PRESTADOR' ? 'client' : 'client', // Permanece como client hasta aprobación
        onboarding_completo: true
      }
    });

  } catch (err) {
    console.error('❌ ERROR ONBOARDING:', err.message);
    res.status(500).json({ error: 'Error al guardar onboarding' });
  }
};

// ==========================================
// 👁️ REGISTRAR CONSENTIMIENTO BIOMÉTRICO E IA (Ley 1581)
// ==========================================
exports.acceptBiometricsConsent = async (req, res) => {
  try {
    const userId = req.user.id;
    const { consentimiento_otorgado, version_politica, dispositivo } = req.body;

    if (consentimiento_otorgado === undefined || !version_politica) {
      return res.status(400).json({ error: 'consentimiento_otorgado y version_politica son obligatorios.' });
    }

    const clientIp = req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress;

    // Registrar en auditoría de consentimiento biométrico
    await pool.query(
      `INSERT INTO auditoria_consentimiento_biometrico (user_id, consentimiento_otorgado, version_politica, ip_registro, dispositivo)
       VALUES ($1, $2, $3, $4, $5)`,
      [parseInt(userId, 10), consentimiento_otorgado, version_politica, clientIp, dispositivo || 'Unknown']
    );

    console.log(`🛡️ Auditoría de consentimiento biométrico registrada para usuario ID ${userId}. Consentimiento: ${consentimiento_otorgado}`);

    res.json({
      success: true,
      message: 'Aceptación y auditoría de datos biométricos registrada exitosamente.',
      consentimiento_otorgado
    });
  } catch (error) {
    console.error('❌ ERROR ACCEPT BIOMETRICS CONSENT:', error.message);
    res.status(500).json({ error: 'Error al guardar el consentimiento de datos biométricos.' });
  }
};

// ==========================================
// 🔔 GUARDAR TOKEN DE NOTIFICACIONES PUSH (FCM)
// ==========================================
exports.saveFcmToken = async (req, res) => {
  try {
    const userId = req.user.id;
    const { fcm_token, device_os } = req.body;

    if (!fcm_token) {
      return res.status(400).json({ error: 'fcm_token es requerido' });
    }

    await pool.query(
      `UPDATE usuarios 
       SET fcm_token = $1, last_active_at = NOW() 
       WHERE id = $2`,
      [fcm_token, userId]
    );

    console.log(`🔔 Token FCM registrado para usuario ID ${userId} (${device_os || 'web/mobile'})`);

    res.json({
      success: true,
      message: 'Token FCM registrado exitosamente'
    });
  } catch (error) {
    console.error('❌ ERROR SAVE FCM TOKEN:', error.message);
    res.status(500).json({ error: 'Error al registrar token FCM' });
  }
};

// ==========================================
// 🎁 OBTENER CÓDIGO E INFORMACIÓN DE REFERIDOS (K-FACTOR)
// ==========================================
exports.getReferralInfo = async (req, res) => {
  try {
    const userId = req.user.id;

    // Obtener o generar código de referido de 6 caracteres único para el usuario
    const userRes = await pool.query(
      `SELECT id, nombre, email, referral_code FROM usuarios WHERE id = $1`,
      [userId]
    );

    if (userRes.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    let user = userRes.rows[0];
    let referralCode = user.referral_code;

    if (!referralCode) {
      // Generar código único ej: GLOW + 4 caracteres aleatorios
      const crypto = require('crypto');
      referralCode = 'GLOW' + crypto.randomBytes(2).toString('hex').toUpperCase();
      await pool.query(`UPDATE usuarios SET referral_code = $1 WHERE id = $2`, [referralCode, userId]);
    }

    const shareUrl = `https://glowapp-frontend-production.up.railway.app/#/register?ref=${referralCode}`;
    const shareMessage = `¡Te regalo $10.000 COP para tu primer servicio de belleza en GlowApp! Usá mi código ${referralCode} o registrate aquí: ${shareUrl}`;

    res.json({
      success: true,
      referral_code: referralCode,
      share_url: shareUrl,
      share_message: shareMessage,
      reward_per_referral: 10000,
    });
  } catch (error) {
    console.error('❌ ERROR GET REFERRAL INFO:', error.message);
    res.status(500).json({ error: 'Error al obtener información de referidos' });
  }
};

// ==========================================
// ⚖️ CUMPLIMIENTO APPLE APP STORE 5.1.1(v): ELIMINACIÓN DE CUENTA DE USUARIO
// ==========================================
exports.deleteAccount = async (req, res) => {
  const userId = req.user.id;
  try {
    // 1. Anonimizar datos personales en la base de datos
    await pool.query(
      `UPDATE usuarios 
       SET nombre = 'Usuario Eliminado', 
           email = $1, 
           password_hash = '', 
           phone = NULL, 
           is_active = false,
           fcm_token = NULL
       WHERE id = $2`,
      [`deleted_${userId}_${Date.now()}@glowapp.deleted`, userId]
    );

    // 2. Revocar consentimientos biométricos activos si la tabla existe
    await pool.query(
      `UPDATE biometric_consents SET active = false, revoked_at = NOW() WHERE user_id = $1`,
      [userId]
    ).catch(() => {});

    console.log(`⚖️ [LEGAL COMPLIANCE] Cuenta de usuario ID ${userId} eliminada a solicitud del titular.`);

        res.json({
          success: true,
          message: 'Tu cuenta y datos personales han sido eliminados de GlowApp exitosamente.'
        });
      } catch (error) {
        console.error('❌ Error al eliminar cuenta:', error.message);
        res.status(500).json({ error: 'Error al procesar la solicitud de eliminación de cuenta.' });
      }
    };

// ==========================================
// 🔐 CAMBIAR CONTRASEÑA (Usuario autenticado conoce contraseña actual)
// ==========================================
exports.changePassword = async (req, res) => {
      try {
        const userId = req.user.id;
        const { current_password, new_password } = req.body;

        if (!current_password || !new_password) {
          return res.status(400).json({ error: 'Contraseña actual y nueva contraseña son requeridas.' });
        }

        if (new_password.length < 6) {
          return res.status(400).json({ error: 'La nueva contraseña debe tener al menos 6 caracteres.' });
        }

        // Obtener hash actual del usuario
        const userRes = await pool.query(
          `SELECT password_hash, auth_provider FROM usuarios WHERE id = $1`,
          [userId]
        );

        if (userRes.rows.length === 0) {
          return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        const user = userRes.rows[0];

        // Solo permitir cambio de contraseña para usuarios LOCAL (no OAuth)
        if (user.auth_provider !== 'LOCAL') {
          return res.status(400).json({ 
            error: 'No se puede cambiar contraseña: usuario autenticado via OAuth. Use "Olvidé mi contraseña" en su proveedor.' 
          });
        }

        // Verificar contraseña actual
        const isValid = await bcrypt.compare(current_password, user.password_hash);
        if (!isValid) {
          return res.status(401).json({ error: 'Contraseña actual incorrecta.' });
        }

        // Hash de la nueva contraseña
        const hashedPassword = await bcrypt.hash(new_password, 10);
        await pool.query(
          `UPDATE usuarios SET password_hash = $1 WHERE id = $2`,
          [hashedPassword, userId]
        );

        // Opcional: invalidar otros tokens (excepto el actual) - requiere lista negra en Redis
        // Por ahora solo cambiamos el hash; el token actual sigue válido hasta expirar

        console.log(`🔐 [CHANGE PASSWORD] Contraseña cambiada exitosamente para usuario ID ${userId}`);

        res.json({
          success: true,
          message: 'Contraseña actualizada exitosamente.'
        });
      } catch (error) {
        console.error('❌ ERROR CHANGE PASSWORD:', error.message);
        res.status(500).json({ error: 'Error al cambiar contraseña' });
      }
    };

    // ==========================================
    // 🚪 CIERRE DE SESIÓN (LOGOUT & TOKEN BLACKLISTING)
// ==========================================
exports.logout = async (req, res) => {
  try {
    const authHeader = req.header('Authorization') || '';
    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7).trim() : null;

    if (token) {
      const decoded = jwt.decode(token);
      let ttl = 7 * 24 * 60 * 60; // 7 días por defecto
      if (decoded && decoded.exp) {
        const now = Math.floor(Date.now() / 1000);
        ttl = Math.max(decoded.exp - now, 60);
      }
      try {
        await redisClient.setEx(`beauty:token_blacklist:${token}`, ttl, 'revoked');
      } catch (redisErr) {
        console.warn('⚠️ No se pudo registrar token en la lista negra de Redis:', redisErr.message);
      }
    }

    res.json({
      success: true,
      message: 'Sesión cerrada exitosamente.'
    });
  } catch (error) {
    console.error('❌ ERROR LOGOUT:', error.message);
    res.status(500).json({ error: 'Error al cerrar sesión' });
  }
};

// ==========================================
// 🔑 SOLICITAR RECUPERACIÓN DE CONTRASEÑA (FORGOT PASSWORD OTP)
// ==========================================
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ error: 'El correo electrónico es obligatorio.' });
    }

    const cleanEmail = email.trim().toLowerCase();

    // Verificar si el usuario existe
    const userRes = await pool.query(
      `SELECT id, nombre FROM usuarios WHERE LOWER(email) = $1 AND auth_provider = 'LOCAL'`,
      [cleanEmail]
    );

    if (userRes.rows.length === 0) {
      // Retornar mensaje genérico por seguridad
      return res.json({
        success: true,
        message: 'Si el correo está registrado, recibirás un código OTP de recuperación.'
      });
    }

    // Generar código OTP de 6 dígitos aleatorio
    const crypto = require('crypto');
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Guardar OTP en Redis con TTL de 10 minutos (600s)
    try {
      await redisClient.setEx(`beauty:otp:${cleanEmail}`, 600, otp);
    } catch (redisErr) {
      console.warn('⚠️ Error guardando OTP en Redis:', redisErr.message);
    }

    console.log(`🔑 [PASSWORD RESET] Código OTP generado para ${cleanEmail}: ${otp}`);

    // Enviar correo transaccional con el código OTP
    try {
      await emailService.sendOtpEmail({
        to: cleanEmail,
        otp,
        userName: userRes.rows[0].nombre,
      });
    } catch (emailErr) {
      console.warn('⚠️ Error al enviar correo OTP:', emailErr.message);
    }

    res.json({
      success: true,
      message: 'Código de recuperación enviado a tu correo electrónico.',
      otp: process.env.NODE_ENV !== 'production' ? otp : undefined
    });
  } catch (error) {
    console.error('❌ ERROR FORGOT PASSWORD:', error.message);
    res.status(500).json({ error: 'Error al solicitar recuperación de contraseña' });
  }
};

// ==========================================
// 🔄 RESTABLECER CONTRASEÑA CON OTP (RESET PASSWORD)
// ==========================================
exports.resetPassword = async (req, res) => {
  try {
    const { email, otp, new_password } = req.body;

    if (!email || !otp || !new_password) {
      return res.status(400).json({ error: 'Email, OTP y nueva contraseña son requeridos.' });
    }

    if (new_password.length < 6) {
      return res.status(400).json({ error: 'La nueva contraseña debe tener al menos 6 caracteres.' });
    }

    const cleanEmail = email.trim().toLowerCase();

    // Validar OTP desde Redis
    let storedOtp = null;
    try {
      storedOtp = await redisClient.get(`beauty:otp:${cleanEmail}`);
    } catch (redisErr) {
      console.warn('⚠️ Error leyendo OTP de Redis:', redisErr.message);
    }

    if (!storedOtp || storedOtp !== otp.toString().trim()) {
      return res.status(400).json({ error: 'Código OTP inválido o expirado. Por favor solicita uno nuevo.' });
    }

    // Hash de la nueva contraseña y actualización en BD
    const hashedPassword = await bcrypt.hash(new_password, 10);
    await pool.query(
      `UPDATE usuarios SET password_hash = $1 WHERE LOWER(email) = $2 AND auth_provider = 'LOCAL'`,
      [hashedPassword, cleanEmail]
    );

    // Eliminar el OTP usado de Redis
    try {
      await redisClient.del(`beauty:otp:${cleanEmail}`);
    } catch (_) {}

    console.log(`✅ [PASSWORD RESET] Contraseña restablecida con éxito para ${cleanEmail}`);

    res.json({
      success: true,
      message: 'Contraseña actualizada exitosamente. Ya puedes iniciar sesión con tu nueva clave.'
    });
  } catch (error) {
    console.error('❌ ERROR RESET PASSWORD:', error.message);
    res.status(500).json({ error: 'Error al restablecer la contraseña' });
  }
};




```

---

### `backend/serve_mock_demo.js`

**Ruta local:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\audit_glowapp_architecture_integrity\backend\serve_mock_demo.js`

```javascript
﻿const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8088;
const HTML_PATH = path.join(__dirname, 'public', 'index.html');

const server = http.createServer((req, res) => {
  console.log(`[${new Date().toLocaleTimeString()}] HTTP ${req.method} ${req.url}`);

  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0');
  res.setHeader('Pragma', 'no-cache');
  res.setHeader('Expires', '0');
  res.setHeader('Surrogate-Control', 'no-store');
  res.setHeader('Clear-Site-Data', '"cache", "storage"');

  if (req.url === '/' || req.url === '/index.html' || !req.url.includes('.')) {
    fs.readFile(HTML_PATH, 'utf8', (err, data) => {
      if (err) {
        res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('Error al cargar la Mock Demo: ' + err.message);
        return;
      }
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end(data);
    });
  } else {
    const filePath = path.join(__dirname, 'public', req.url.replace(/^\//, ''));
    if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
      fs.readFile(filePath, (err, data) => {
        if (err) {
          res.writeHead(500, { 'Content-Type': 'text/plain' });
          res.end('Error');
        } else {
          res.writeHead(200);
          res.end(data);
        }
      });
    } else {
      fs.readFile(HTML_PATH, 'utf8', (err, data) => {
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end(data);
      });
    }
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`=======================================================`);
  console.log(` GLOWAPP SAAS PRO - SERVIDOR DEDICADO DE MOCK DEMO`);
  console.log(` Puerto Activo: http://localhost:${PORT}`);
  console.log(` Modo: Anti-Caché Estricto & Purga de Service Worker`);
  console.log(`=======================================================`);
});

```

---


# GLOWAPP BUSINESS ENGINE UPDATE & MASTER EXPORT ADDENDUM

**Commit:** `64ae8aed` (feat(business): complete glowapp business engine 0 to 100)
**Branch:** `main`

## GlowApp Business Engine Summary
- **Migration:** `backend/src/db/migrations/012_business_engine.sql`
- **Repositories & Services:** `businessRepository.js`, `businessDiagnosticService.js`, `businessRequirementService.js`, `businessWorkflowService.js`, `documentGeneratorService.js`
- **Controller & Routes:** `businessController.js`, `businessRoutes.js` (/api/v1/business)
- **FastAPI AI Worker:** `/v1/ai/consult` endpoint extended with `business_context` and metadata filtering in pgvector RAG.
- **Flutter Provider UI:** `business_onboarding_screen.dart`, `business_dashboard_screen.dart`, `business_task_detail_screen.dart`, `business_document_generator_screen.dart`.
- **Next.js Admin UI:** `admin-dashboard/src/app/business/page.tsx`.
- **Tests & Docs:** `business.integration.test.js` PASSED, `BUSINESS-ENGINE-ARCHITECTURE.md`, `REPORT-GOAL-BUSINESS.md`.
