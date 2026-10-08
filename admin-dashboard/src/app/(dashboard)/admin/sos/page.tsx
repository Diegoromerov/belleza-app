'use client';

import React, { useCallback, useEffect, useState } from 'react';
import {
  AlertCircle,
  CheckCircle2,
  Clock,
  Loader2,
  MapPin,
  Phone,
  RefreshCw,
  ShieldAlert,
  User,
} from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';

/**
 * Pantalla de alertas SOS.
 *
 * Consume GET /api/glow-admin/sos/active -> { success, count, data: [...] }
 * donde `data` YA es la coleccion (no `data.alerts`: ese campo no existe).
 *
 * El backend vive en backend/src/modules/admin-glow/ y se monto en index.js:448.
 * Antes de la fase 1 este modulo no estaba montado, asi que la ruta daba 404 y
 * el dashboard solo podia mostrar el contador en estado de error.
 */

interface SosAlert {
  id: number;
  client_name?: string | null;
  client_phone?: string | null;
  provider_name?: string | null;
  provider_phone?: string | null;
  latitude: string | number;
  longitude: string | number;
  fecha_creacion?: string | null;
  estado?: string | null;
}

const REFRESCO_MS = 30000;

/** Antiguedad legible de la alerta. Vacia si la fecha no es valida. */
function antiguedad(fecha?: string | null): string {
  if (!fecha) return '';
  const t = new Date(fecha).getTime();
  if (Number.isNaN(t)) return '';
  const min = Math.max(0, Math.floor((Date.now() - t) / 60000));
  if (min < 1) return 'hace menos de 1 min';
  if (min < 60) return `hace ${min} min`;
  const h = Math.floor(min / 60);
  if (h < 24) return `hace ${h} h ${min % 60} min`;
  return `hace ${Math.floor(h / 24)} d ${h % 24} h`;
}

function coordenadas(alerta: SosAlert): string {
  const lat = Number(alerta.latitude);
  const lng = Number(alerta.longitude);
  if (Number.isNaN(lat) || Number.isNaN(lng)) return 'Sin coordenadas';
  return `${lat.toFixed(5)}, ${lng.toFixed(5)}`;
}

export default function AdminSosPage() {
  const { user } = useAuth();
  const [alerts, setAlerts] = useState<SosAlert[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [resolviendo, setResolviendo] = useState<number | null>(null);
  const [aviso, setAviso] = useState<string | null>(null);

  const getBffHeaders = (contentType = 'application/json') => ({
    'X-Requested-With': 'XMLHttpRequest',
    ...(contentType ? { 'Content-Type': contentType } : {}),
  });

  const fetchAlerts = useCallback(async (silencioso = false) => {
    try {
      if (!silencioso) setLoading(true);
      const res = await fetch('/api/glow-admin/sos/active', { headers: getBffHeaders() });

      if (!res.ok) {
        // El BFF reenvia el 401/403 del backend; distinguirlo ayuda a saber si
        // es sesion caducada o permiso.
        if (res.status === 401) throw new Error('Sesion expirada. Vuelve a iniciar sesion.');
        if (res.status === 403) throw new Error('Tu usuario no tiene permisos de administrador.');
        throw new Error(`Error al cargar alertas SOS (HTTP ${res.status})`);
      }

      const json = await res.json();
      // `data` es la coleccion. Degradar a lista vacia en vez de romper el render.
      setAlerts(Array.isArray(json?.data) ? json.data : []);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error desconocido');
    } finally {
      if (!silencioso) setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchAlerts();
    const id = setInterval(() => fetchAlerts(true), REFRESCO_MS);
    return () => clearInterval(id);
  }, [fetchAlerts]);

  const resolver = async (id: number) => {
    if (!window.confirm(`Marcar la alerta #${id} como atendida?`)) return;
    setResolviendo(id);
    setAviso(null);
    try {
      const res = await fetch(`/api/glow-admin/sos/resolve/${id}`, {
        method: 'PATCH',
        headers: getBffHeaders(),
      });
      const json = await res.json().catch(() => null);
      if (!res.ok) {
        throw new Error(json?.error || `Error al resolver (HTTP ${res.status})`);
      }
      setAviso(`Alerta #${id} marcada como atendida.`);
      await fetchAlerts(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al resolver la alerta');
    } finally {
      setResolviendo(null);
    }
  };

  if (user?.rol !== 'ADMIN') {
    return (
      <div className="card">
        <div className="card-content flex items-center gap-3">
          <AlertCircle size={20} aria-hidden="true" />
          <div>
            <h2 className="card-title">Acceso denegado</h2>
            <p className="body-sm text-secondary">Solo los administradores pueden ver las alertas SOS.</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold tracking-tight">Alertas SOS</h1>
          <p className="text-secondary mt-1">
            Alertas de panico activas, con quien las emitio y con que cita estan asociadas.
          </p>
        </div>
        <button
          onClick={() => fetchAlerts()}
          disabled={loading}
          className="btn btn-secondary"
          aria-label="Recargar alertas"
        >
          {loading ? <Loader2 size={18} className="animate-spin" /> : <RefreshCw size={18} />}
          <span>Recargar</span>
        </button>
      </div>

      {/* Resumen */}
      <div className="kpi-grid">
        <div className="kpi-card">
          <div className="kpi-header">
            <span className="kpi-title">Alertas activas</span>
            <ShieldAlert size={18} aria-hidden="true" />
          </div>
          <div className="kpi-value">{error ? '—' : alerts.length}</div>
        </div>
        <div className="kpi-card">
          <div className="kpi-header">
            <span className="kpi-title">Mas antigua</span>
            <Clock size={18} aria-hidden="true" />
          </div>
          <div className="kpi-value body-sm">
            {alerts.length > 0 ? antiguedad(alerts[alerts.length - 1]?.fecha_creacion) || 'Sin fecha' : '—'}
          </div>
        </div>
      </div>

      {aviso && (
        <div className="card">
          <div className="card-content flex items-center gap-2">
            <CheckCircle2 size={18} aria-hidden="true" />
            <span className="body-sm">{aviso}</span>
          </div>
        </div>
      )}

      {error && (
        <div className="card">
          <div className="card-content flex items-center gap-2">
            <AlertCircle size={18} aria-hidden="true" />
            <span className="body-sm">{error}</span>
          </div>
        </div>
      )}

      {/* Listado */}
      <div className="card">
        <div className="card-header">
          <h2 className="card-title">Alertas activas</h2>
          <span className="chip-sm">Se actualiza cada 30 s</span>
        </div>

        <div className="table-container">
          <table className="table">
            <thead>
              <tr>
                <th>Alerta</th>
                <th>Cliente</th>
                <th>Prestador</th>
                <th>Ubicacion</th>
                <th>Emitida</th>
                <th className="col-actions">Acciones</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={6} className="text-center">
                    <Loader2 size={22} className="animate-spin mx-auto mb-2" aria-hidden="true" />
                    Cargando alertas...
                  </td>
                </tr>
              ) : alerts.length === 0 ? (
                <tr>
                  <td colSpan={6} className="text-center">
                    No hay alertas SOS activas.
                  </td>
                </tr>
              ) : (
                alerts.map((a) => (
                  <tr key={a.id}>
                    <td>
                      <span className="chip-sm">#{a.id}</span>
                    </td>
                    <td>
                      {a.client_name ? (
                        <span className="flex items-center gap-2">
                          <User size={15} aria-hidden="true" />
                          {a.client_name}
                          {a.client_phone && (
                            <a href={`tel:${a.client_phone}`} className="text-gold flex items-center gap-1">
                              <Phone size={14} aria-hidden="true" />
                              {a.client_phone}
                            </a>
                          )}
                        </span>
                      ) : (
                        <span className="text-subtle">Sin datos</span>
                      )}
                    </td>
                    <td>
                      {a.provider_name ? (
                        <span>{a.provider_name}</span>
                      ) : (
                        <span className="text-subtle">Sin cita asociada</span>
                      )}
                    </td>
                    <td>
                      {Number.isNaN(Number(a.latitude)) || Number.isNaN(Number(a.longitude)) ? (
                        <span className="text-subtle">Sin coordenadas</span>
                      ) : (
                        <a
                          href={`https://www.google.com/maps?q=${a.latitude},${a.longitude}`}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-gold flex items-center gap-1"
                        >
                          <MapPin size={14} aria-hidden="true" />
                          {coordenadas(a)}
                        </a>
                      )}
                    </td>
                    <td>
                      <span className="body-sm">{antiguedad(a.fecha_creacion) || 'Sin fecha'}</span>
                    </td>
                    <td className="col-actions">
                      <button
                        onClick={() => resolver(a.id)}
                        disabled={resolviendo === a.id}
                        className="btn btn-primary"
                      >
                        {resolviendo === a.id ? (
                          <Loader2 size={16} className="animate-spin" aria-hidden="true" />
                        ) : (
                          <CheckCircle2 size={16} aria-hidden="true" />
                        )}
                        <span>Atender</span>
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
