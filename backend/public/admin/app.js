document.addEventListener('DOMContentLoaded', () => {
  // Helper de Fetch Autenticado para el Panel de Administración
  async function authFetch(url, options = {}) {
    let token = localStorage.getItem('admin_token');
    if (!token) {
      token = localStorage.getItem('flutter.token') || localStorage.getItem('token');
    }
    
    if (!token) {
      const email = prompt('Belleza App Control Center\nPor favor, ingresa tu correo de administrador:', 'admin@beautyapp.com');
      const password = prompt('Ingresa tu contraseña:');
      if (email && password) {
        try {
          const res = await fetch('/api/auth/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password })
          });
          const data = await res.json();
          if (data.token) {
            token = data.token;
            localStorage.setItem('admin_token', token);
          } else {
            alert('Error de login: ' + (data.error || 'Credenciales incorrectas.'));
          }
        } catch (err) {
          console.error('Error de autenticación:', err);
        }
      }
    }

    options.headers = {
      ...options.headers,
      'Authorization': `Bearer ${token}`
    };

    const res = await fetch(url, options);
    if (res.status === 401 || res.status === 403) {
      localStorage.removeItem('admin_token');
      alert('Sesión administrativa no autorizada o expirada. Por favor recarga la página para re-autenticarte.');
    }
    return res;
  }
  // Navigation elements
  const navItems = document.querySelectorAll('.menu-item');
  const sections = document.querySelectorAll('.view-section');
  const pageTitle = document.getElementById('page-title');
  const pageSubtitle = document.getElementById('page-subtitle');
  
  // Refresh button
  const refreshBtn = document.getElementById('refresh-metrics-btn');
  
  // Active SOS Banner
  const sosBanner = document.getElementById('active-sos-banner');
  const goToSosBtn = document.getElementById('go-to-sos-btn');

  // Leaflet Map settings
  let map;
  let markers = {}; // id -> Leaflet marker
  const fontibonCoords = [4.6735, -74.1422];
  
  // Data State
  let activeAlerts = [];
  let lastMetricsData = null;
  let charts = {}; // Instance container for Chart.js
  
  // Iconos personalizados para Leaflet
  const redSOSIcon = L.divIcon({
    html: '<i class="fa-solid fa-triangle-exclamation" style="color: #EF4444; font-size: 24px; text-shadow: 0 0 10px rgba(239, 68, 68, 0.7); animation: pulse-danger 1s infinite;"></i>',
    iconSize: [24, 24],
    iconAnchor: [12, 12],
    className: 'custom-leaflet-icon'
  });

  const resolvedSOSIcon = L.divIcon({
    html: '<i class="fa-solid fa-circle-check" style="color: #10B981; font-size: 20px;"></i>',
    iconSize: [20, 20],
    iconAnchor: [10, 10],
    className: 'custom-leaflet-icon'
  });

  // 1. Navigation Tab Switching
  navItems.forEach(item => {
    item.addEventListener('click', (e) => {
      e.preventDefault();
      
      // Remove active from menus
      navItems.forEach(n => n.classList.remove('active'));
      item.classList.add('active');
      
      // Toggle sections
      const targetSectionId = item.getAttribute('href').replace('#', '');
      sections.forEach(sec => sec.style.display = 'none');
      
      if (targetSectionId === 'dashboard') {
        document.getElementById('view-dashboard-sos').style.display = 'block';
        pageTitle.textContent = 'Centro de Control Operativo';
        pageSubtitle.textContent = 'Monitoreo de métricas y seguridad en tiempo real';
        // Recalcular tamaño del mapa por si estuvo oculto
        setTimeout(() => map.invalidateSize(), 100);
      } else if (targetSectionId === 'metrics') {
        document.getElementById('view-metrics').style.display = 'block';
        pageTitle.textContent = 'Métricas y Proyecciones Financieras';
        pageSubtitle.textContent = 'Simulación, estimaciones de ingresos y control de comisiones';
        if (lastMetricsData) renderMetricsCharts(lastMetricsData);
      } else if (targetSectionId === 'sos') {
        document.getElementById('view-dashboard-sos').style.display = 'block';
        pageTitle.textContent = 'Ubicación de Alertas SOS';
        pageSubtitle.textContent = 'Mapa geolocalizado de emergencias activas';
        setTimeout(() => map.invalidateSize(), 100);
      } else if (targetSectionId === 'analytics') {
        document.getElementById('view-analytics').style.display = 'block';
        pageTitle.textContent = 'Telemetría de Usabilidad';
        pageSubtitle.textContent = 'Análisis de comportamiento de usuarios de prueba';
      } else if (targetSectionId === 'transactions') {
        document.getElementById('view-transactions').style.display = 'block';
        pageTitle.textContent = 'Historial Operativo';
        pageSubtitle.textContent = 'Registro histórico de alertas de pánico y eventos';
      }
    });
  });

  goToSosBtn.addEventListener('click', () => {
    document.getElementById('nav-sos').click();
  });

  // 2. Initialize Leaflet Map
  function initMap() {
    map = L.map('sos-map').setView(fontibonCoords, 14);
    
    // Capa de mapa oscura premium (CartoDB Dark Matter)
    L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
      subdomains: 'abcd',
      maxZoom: 20
    }).addTo(map);
  }

  // 3. Connect to Real-Time SSE Stream
  function connectSSE() {
    const token = localStorage.getItem('admin_token') || localStorage.getItem('flutter.token') || localStorage.getItem('token');
    const sseUrl = '/api/admin/events/stream' + (token ? '?token=' + encodeURIComponent(token) : '');
    const eventSource = new EventSource(sseUrl);

    eventSource.onmessage = (event) => {
      try {
        const payload = JSON.parse(event.data);
        console.log('🔌 [SSE Recibido]:', payload);

        if (payload.type === 'sos_alert') {
          handleIncomingSOS(payload.data);
        } else if (payload.type === 'sos_resolved') {
          handleResolvedSOS(payload.data);
        }
      } catch (err) {
        console.error('Error al procesar mensaje SSE:', err);
      }
    };

    eventSource.onerror = (err) => {
      console.error('❌ Error en canal SSE. Intentando reconexión...', err);
      eventSource.close();
      setTimeout(connectSSE, 3000); // Reconexión automática
    };
  }

  // 4. Handle Incoming Real-Time Alertas
  function handleIncomingSOS(alert) {
    // Añadir a alertas activas si no existe
    if (!activeAlerts.some(a => a.id === alert.id)) {
      activeAlerts.unshift(alert);
    }
    
    // Play alert sound if wanted
    try {
      const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      const oscillator = audioCtx.createOscillator();
      const gainNode = audioCtx.createGain();
      oscillator.connect(gainNode);
      gainNode.connect(audioCtx.destination);
      oscillator.type = 'sawtooth';
      oscillator.frequency.setValueAtTime(880, audioCtx.currentTime); // A5
      gainNode.gain.setValueAtTime(0.15, audioCtx.currentTime);
      oscillator.start();
      setTimeout(() => oscillator.stop(), 500);
    } catch (_) {}

    updateSOSUIState();
    
    // Añadir marcador en mapa si tiene ubicación
    if (alert.latitude && alert.longitude) {
      addSOSMarker(alert);
      map.panTo([alert.latitude, alert.longitude]);
    }
  }

  function handleResolvedSOS(alert) {
    // Quitar o cambiar estado en las alertas activas
    activeAlerts = activeAlerts.filter(a => a.id !== alert.id);
    
    // Actualizar marcador
    if (markers[alert.id]) {
      map.removeLayer(markers[alert.id]);
      delete markers[alert.id];
    }
    
    updateSOSUIState();
    fetchMetrics(); // Recargar métricas para refrescar historial y totales
  }

  // 5. Update SOS Elements in UI (Table, Badges, Banners)
  function updateSOSUIState() {
    const activeCount = activeAlerts.filter(a => a.estado === 'ACTIVO').length;
    
    // KPI y Badges
    const kpiSos = document.getElementById('kpi-sos');
    const kpiSosSub = document.getElementById('kpi-sos-sub');
    const sosCard = document.getElementById('sos-kpi-card');
    const sosBadge = document.getElementById('sos-badge');
    
    kpiSos.textContent = activeCount;
    
    if (activeCount > 0) {
      kpiSosSub.textContent = `${activeCount} emergencias activas`;
      sosCard.classList.add('alerting');
      sosBadge.textContent = activeCount;
      sosBadge.style.display = 'inline-block';
      sosBanner.style.display = 'flex';
    } else {
      kpiSosSub.textContent = 'No hay emergencias';
      kpiSosSub.classList.remove('text-danger');
      sosCard.classList.remove('alerting');
      sosBadge.style.display = 'none';
      sosBanner.style.display = 'none';
    }
    
    // Rellenar tabla de alertas activas
    const tableBody = document.getElementById('alerts-table-body');
    if (activeAlerts.length === 0) {
      tableBody.innerHTML = `<tr><td colspan="5" class="empty-message">No se han registrado alertas de pánico.</td></tr>`;
      return;
    }
    
    tableBody.innerHTML = activeAlerts.map(alert => {
      const coordsText = (alert.latitude && alert.longitude) 
        ? `${parseFloat(alert.latitude).toFixed(4)}, ${parseFloat(alert.longitude).toFixed(4)}` 
        : 'Sin GPS';
      return `
        <tr id="alert-row-${alert.id}">
          <td>
            <strong>${alert.user_name || 'Usuario Prueba'}</strong><br>
            <span style="font-size: 11px; color: var(--text-muted);">${alert.email || alert.user_email || ''}</span>
          </td>
          <td>${alert.user_phone || alert.phone || '+573005556666'}</td>
          <td><i class="fa-solid fa-location-dot" style="color: var(--color-primary);"></i> ${coordsText}</td>
          <td><span class="status-pill active">Activo</span></td>
          <td>
            <button class="btn-resolve" onclick="resolveSOSAlert(${alert.id})">
              <i class="fa-solid fa-check"></i> Resolver
            </button>
          </td>
        </tr>
      `;
    }).join('');
  }

  // 6. Draw Map Markers
  function addSOSMarker(alert) {
    if (markers[alert.id]) {
      map.removeLayer(markers[alert.id]);
    }
    
    const lat = parseFloat(alert.latitude);
    const lon = parseFloat(alert.longitude);
    const isActivo = alert.estado === 'ACTIVO';
    
    const marker = L.marker([lat, lon], {
      icon: isActivo ? redSOSIcon : resolvedSOSIcon
    }).addTo(map);

    const popupContent = `
      <div style="font-family: 'Inter', sans-serif; padding: 4px;">
        <h4 style="font-family: 'Outfit', sans-serif; margin-bottom: 4px; color: ${isActivo ? '#EF4444' : '#10B981'};">
          🚨 SOS ${isActivo ? 'ACTIVO' : 'RESUELTO'}
        </h4>
        <strong>Usuario:</strong> ${alert.user_name || 'Usuario de prueba'}<br>
        <strong>Teléfono:</strong> ${alert.user_phone || alert.phone || ''}<br>
        <strong>Fecha:</strong> ${new Date(alert.creado_en).toLocaleString()}<br>
        ${isActivo ? `<button style="background: #10B981; color: white; border: none; padding: 4px 8px; border-radius: 4px; margin-top: 8px; font-weight: 700; cursor: pointer;" onclick="resolveSOSAlert(${alert.id})">Resolver</button>` : ''}
      </div>
    `;

    marker.bindPopup(popupContent);
    markers[alert.id] = marker;
  }

  // 7. Fetch Metrics & Build Charts
  async function fetchMetrics() {
    try {
      const response = await authFetch('/api/admin/metrics');
      const resData = await response.json();
      
      if (!resData.success) throw new Error(resData.error);
      
      const metrics = resData.data;
      lastMetricsData = metrics; // Guardar en caché global
      
      // A. Update KPI Cards
      document.getElementById('kpi-revenue').textContent = `$${metrics.total_revenue.toLocaleString('es-CO')}`;
      document.getElementById('kpi-commission').textContent = `$${(metrics.platform_commission || 0).toLocaleString('es-CO')}`;
      document.getElementById('kpi-tax').textContent = `$${(metrics.state_tax || 0).toLocaleString('es-CO')}`;
      
      const bookingsCount = metrics.bookings_status.reduce((sum, item) => sum + item.count, 0);
      document.getElementById('kpi-bookings').textContent = bookingsCount;
      
      const pendingBookings = metrics.bookings_status.find(b => b.estado === 'PENDIENTE_PAGO' || b.estado === 'PENDIENTE' || b.estado === 'PENDING')?.count || 0;
      document.getElementById('kpi-bookings-sub').textContent = `${pendingBookings} pendientes de pago`;
      
      // Actualizar gráficos financieros si la pestaña actual es metrics
      const activeTab = document.querySelector('.menu-item.active')?.getAttribute('href');
      if (activeTab === '#metrics') {
        renderMetricsCharts(metrics);
      }
      
      // Cargar alertas activas en el estado global
      activeAlerts = metrics.sos_alerts.filter(a => a.estado === 'ACTIVO');
      updateSOSUIState();
      
      // Dibujar marcadores de alertas activas e históricas con coordenadas en el mapa
      Object.values(markers).forEach(m => map.removeLayer(m));
      markers = {};
      
      metrics.sos_alerts.forEach(alert => {
        if (alert.latitude && alert.longitude) {
          addSOSMarker(alert);
        }
      });
      
      // B. Rellenar Historial de Alertas SOS
      const historyBody = document.getElementById('sos-history-body');
      if (metrics.sos_alerts.length === 0) {
        historyBody.innerHTML = `<tr><td colspan="7" class="empty-message">No hay alertas registradas en el historial.</td></tr>`;
      } else {
        historyBody.innerHTML = metrics.sos_alerts.map(alert => {
          const coords = (alert.latitude && alert.longitude) 
            ? `${parseFloat(alert.latitude).toFixed(5)}, ${parseFloat(alert.longitude).toFixed(5)}` 
            : 'N/A';
          return `
            <tr>
              <td>#${alert.id}</td>
              <td><strong>${alert.user_name || 'Desconocido'}</strong></td>
              <td>${alert.user_email || alert.email || ''}</td>
              <td>${alert.booking_id ? `<span style="font-size: 11px; font-family: monospace;">${alert.booking_id}</span>` : '<span style="color: var(--text-muted);">Ninguna</span>'}</td>
              <td>${coords}</td>
              <td>
                <span class="status-pill ${alert.estado === 'ACTIVO' ? 'active' : 'resolved'}">
                  ${alert.estado}
                </span>
              </td>
              <td>${new Date(alert.creado_en).toLocaleString()}</td>
            </tr>
          `;
        }).join('');
      }
      
      // C. Render / Update Charts
      renderCharts(metrics.telemetry_screens, metrics.telemetry_clicks);

    } catch (err) {
      console.error('Error al obtener métricas operativas:', err);
    }
  }

  // 8. Render Charts via Chart.js
  function renderCharts(screensData, clicksData) {
    const chartOptions = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false }
      },
      scales: {
        y: {
          grid: { color: 'rgba(255, 255, 255, 0.05)' },
          ticks: { color: '#9CA3AF' }
        },
        x: {
          grid: { display: false },
          ticks: { color: '#9CA3AF' }
        }
      }
    };

    // A. Chart: Screen Views
    if (charts.screens) charts.screens.destroy();
    
    const screenLabels = screensData.map(d => d.screen_name);
    const screenValues = screensData.map(d => d.count);
    
    charts.screens = new Chart(document.getElementById('screens-chart'), {
      type: 'bar',
      data: {
        labels: screenLabels.length ? screenLabels : ['Sin registros'],
        datasets: [{
          data: screenValues.length ? screenValues : [0],
          backgroundColor: '#C89D93',
          borderRadius: 8,
          barThickness: 24
        }]
      },
      options: chartOptions
    });

    // B. Chart: Clicks
    if (charts.clicks) charts.clicks.destroy();
    
    const clickLabels = clicksData.map(d => d.element_id || 'Elemento');
    const clickValues = clicksData.map(d => d.count);
    
    charts.clicks = new Chart(document.getElementById('clicks-chart'), {
      type: 'bar',
      data: {
        labels: clickLabels.length ? clickLabels : ['Sin registros'],
        datasets: [{
          data: clickValues.length ? clickValues : [0],
          backgroundColor: '#3B82F6',
          borderRadius: 8,
          barThickness: 24
        }]
      },
      options: {
        ...chartOptions,
        indexAxis: 'y' // Horizontal bar chart
      }
    });
  }

  // 9. API Call: Resolve Alert SOS
  window.resolveSOSAlert = async function(id) {
    if (!confirm('¿Seguro que deseas marcar esta alerta de pánico como RESUELTA?')) return;
    
    try {
      const response = await authFetch(`/api/admin/sos/resolve/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' }
      });
      const data = await response.json();
      
      if (data.success) {
        alert('Alerta marcada como resuelta.');
        // La actualización de la UI se controlará automáticamente tras la difusión SSE o recarga
      } else {
        alert('Error al resolver: ' + data.error);
      }
    } catch (err) {
      console.error('Error al resolver la alerta SOS:', err);
    }
  };

  // 8.5. Render Financial Metrics and Line Projections
  function renderMetricsCharts(metrics) {
    if (!metrics.projections || !metrics.categories) return;

    // A. Chart: Projections & Revenue Trend
    if (charts.projections) charts.projections.destroy();

    const projData = metrics.projections;
    const historyLabels = projData.history.map(h => h.month);
    const historyValues = projData.history.map(h => h.revenue);

    // Agregar mes de proyección
    const allLabels = [...historyLabels, `${projData.projectedMonth} (Proyección)`];
    const allValues = [...historyValues, projData.projectedRevenue];

    // Actualizar badge de tendencia
    const trendBadge = document.getElementById('projection-trend-badge');
    if (trendBadge) {
      trendBadge.textContent = projData.trend === 'CRECIENTE' ? '📈 Tendencia Creciente' : '📉 Tendencia Decreciente';
      trendBadge.style.backgroundColor = projData.trend === 'CRECIENTE' ? '#10B981' : '#EF4444';
    }

    const ctxProj = document.getElementById('projections-chart').getContext('2d');
    charts.projections = new Chart(ctxProj, {
      type: 'line',
      data: {
        labels: allLabels,
        datasets: [
          {
            label: 'Historial de Facturación',
            data: [...historyValues, null], // Omitir el último punto para la línea continua
            borderColor: '#C89D93',
            backgroundColor: 'rgba(200, 157, 147, 0.1)',
            borderWidth: 3,
            fill: true,
            tension: 0.3
          },
          {
            label: 'Proyección Futura',
            data: [...historyValues.map(() => null).slice(0, -1), historyValues[historyValues.length - 1], projData.projectedRevenue], // Conectar el último punto histórico con el proyectado
            borderColor: '#EF4444',
            borderDash: [6, 6],
            borderWidth: 3,
            pointBackgroundColor: '#EF4444',
            pointRadius: 6,
            fill: false
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: true, labels: { color: '#9CA3AF' } }
        },
        scales: {
          y: {
            grid: { color: 'rgba(255, 255, 255, 0.05)' },
            ticks: {
              color: '#9CA3AF',
              callback: (value) => `$${value.toLocaleString('es-CO')}`
            }
          },
          x: {
            grid: { display: false },
            ticks: { color: '#9CA3AF' }
          }
        }
      }
    });

    // B. Chart: Category Revenue Share (Doughnut)
    if (charts.categories) charts.categories.destroy();

    const catLabels = metrics.categories.map(c => c.category);
    const catRevenues = metrics.categories.map(c => c.revenue);

    // Fallback si no hay categorías en reservas completadas
    const finalLabels = catLabels.length ? catLabels : ['Sin datos'];
    const finalRevenues = catRevenues.length ? catRevenues : [1];
    const catColors = ['#E5CECA', '#C89D93', '#F5EBE6', '#A78BFA', '#3B82F6', '#10B981', '#F59E0B'];

    const ctxCat = document.getElementById('categories-chart').getContext('2d');
    charts.categories = new Chart(ctxCat, {
      type: 'doughnut',
      data: {
        labels: finalLabels,
        datasets: [{
          data: finalRevenues,
          backgroundColor: catColors.slice(0, finalLabels.length),
          borderWidth: 2,
          borderColor: '#1E293B' // Color oscuro del tema del panel
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: true,
            position: 'right',
            labels: { color: '#9CA3AF', boxWidth: 12 }
          }
        }
      }
    });
  }

  // Bind Refresh Event
  refreshBtn.addEventListener('click', () => {
    refreshBtn.disabled = true;
    refreshBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Cargando...';
    fetchMetrics().finally(() => {
      refreshBtn.disabled = false;
      refreshBtn.innerHTML = '<i class="fa-solid fa-arrows-rotate"></i> Actualizar';
    });
  });

  // Startup Init Execution
  initMap();
  fetchMetrics();
  connectSSE();
});
