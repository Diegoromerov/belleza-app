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
      } else if (targetSectionId === 'users') {
        document.getElementById('view-users').style.display = 'block';
        pageTitle.textContent = 'Gestión de Clientes y Proveedores';
        pageSubtitle.textContent = 'Habilitar y desactivar cuentas de usuarios del sistema';
        fetchUsers();
      } else if (targetSectionId === 'disputes') {
        document.getElementById('view-disputes').style.display = 'block';
        pageTitle.textContent = 'Resolución de Disputas';
        pageSubtitle.textContent = 'Administración y conciliación financiera de reclamos';
        fetchDisputes();
      } else if (targetSectionId === 'tutorial') {
        document.getElementById('view-tutorial').style.display = 'block';
        pageTitle.textContent = 'Tutorial Interactivo de Onboarding';
        pageSubtitle.textContent = 'Simulación paso a paso del flujo de clientes en la app de belleza';
        initTutorial();
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

  // --- Gestión de Clientes y Proveedores ---
  let usersList = [];

  async function fetchUsers() {
    const tableBody = document.getElementById('users-table-body');
    tableBody.innerHTML = `<tr><td colspan="6" class="empty-message"><i class="fa-solid fa-spinner fa-spin"></i> Cargando usuarios...</td></tr>`;
    try {
      const response = await authFetch('/api/admin/users');
      const data = await response.json();
      if (!data.success) throw new Error(data.error || 'Error al obtener usuarios');
      
      usersList = data.users;
      renderUsers();
    } catch (err) {
      console.error('Error fetchUsers:', err);
      tableBody.innerHTML = `<tr><td colspan="7" class="empty-message text-danger">Error: ${err.message}</td></tr>`;
    }
  }

  function renderUsers() {
    const searchInputEl = document.getElementById('user-search-input');
    const roleFilterEl = document.getElementById('user-role-filter');
    if (!searchInputEl || !roleFilterEl) return;

    const searchVal = searchInputEl.value.toLowerCase().trim();
    const roleVal = roleFilterEl.value;
    const tableBody = document.getElementById('users-table-body');
    
    const filtered = usersList.filter(user => {
      const matchesSearch = (user.nombre || '').toLowerCase().includes(searchVal) || (user.email || '').toLowerCase().includes(searchVal);
      const matchesRole = roleVal === 'ALL' || user.rol === roleVal;
      return matchesSearch && matchesRole;
    });

    if (filtered.length === 0) {
      tableBody.innerHTML = `<tr><td colspan="7" class="empty-message">No se encontraron usuarios coincidentes.</td></tr>`;
      return;
    }

    tableBody.innerHTML = filtered.map(user => {
      const statusClass = user.is_active ? 'badge-success' : 'badge-danger';
      const statusText = user.is_active ? 'Activo' : 'Desactivado';
      const buttonClass = user.is_active ? 'btn-danger' : 'btn-success';
      const buttonText = user.is_active ? 'Desactivar' : 'Activar';
      const buttonIcon = user.is_active ? 'fa-user-slash' : 'fa-user-check';
      const phoneText = user.phone || 'Sin teléfono';
      const rolText = user.rol === 'PRESTADOR' ? 'Proveedor' : 'Cliente';
      
      let verifyCol = 'N/A';
      if (user.rol === 'PRESTADOR') {
        const vStatus = user.estatus_verificacion || 'PENDIENTE';
        let badgeClass = 'badge-warning';
        if (vStatus === 'APROBADO') badgeClass = 'badge-success';
        if (vStatus === 'RECHAZADO') badgeClass = 'badge-danger';
        
        verifyCol = `
          <div style="display: flex; flex-direction: column; gap: 4px; align-items: center;">
            <span class="badge ${badgeClass}">${vStatus}</span>
            <button class="btn btn-secondary btn-sm verify-docs-btn" style="padding: 2px 6px; font-size: 10px;" data-id="${user.id}">
              <i class="fa-solid fa-file-invoice"></i> Docs
            </button>
          </div>
        `;
      }

      return `
        <tr id="user-row-${user.id}">
          <td><strong>${user.nombre}</strong></td>
          <td>${user.email}</td>
          <td>${phoneText}</td>
          <td><span class="role-tag ${user.rol.toLowerCase()}">${rolText}</span></td>
          <td><span class="badge ${statusClass}">${statusText}</span></td>
          <td>${verifyCol}</td>
          <td>
            <button class="btn ${buttonClass} btn-sm toggle-user-btn" data-id="${user.id}" data-active="${user.is_active}">
              <i class="fa-solid ${buttonIcon}"></i> ${buttonText}
            </button>
          </td>
        </tr>
      `;
    }).join('');

    // Bind event listeners for toggle buttons
    document.querySelectorAll('.toggle-user-btn').forEach(btn => {
      btn.addEventListener('click', async (e) => {
        const userId = btn.getAttribute('data-id');
        const currentActive = btn.getAttribute('data-active') === 'true';
        const actionStr = currentActive ? 'desactivar' : 'activar';
        
        if (confirm(`¿Estás seguro de que deseas ${actionStr} a este usuario?`)) {
          btn.disabled = true;
          btn.innerHTML = `<i class="fa-solid fa-spinner fa-spin"></i> Procesando...`;
          try {
            const response = await authFetch(`/api/admin/users/${userId}/toggle-status`, {
              method: 'PATCH'
            });
            const resData = await response.json();
            if (!resData.success) throw new Error(resData.error || 'Error al actualizar');
            
            // Actualizar en el estado local
            const index = usersList.findIndex(u => u.id === userId);
            if (index !== -1) {
              usersList[index].is_active = resData.user.is_active;
            }
            renderUsers();
          } catch (err) {
            alert(`Error al cambiar estado del usuario: ${err.message}`);
            renderUsers();
          }
        }
      });
    });

    // Bind event listeners for document verification buttons
    document.querySelectorAll('.verify-docs-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const userId = btn.getAttribute('data-id');
        const user = usersList.find(u => u.id === userId);
        if (!user) return;

        document.getElementById('verify-provider-id').value = userId;
        
        const idLink = document.getElementById('doc-id-link');
        const rutLink = document.getElementById('doc-rut-link');
        const certLink = document.getElementById('doc-cert-link');

        // Configurar URLs o deshabilitar si no existen
        if (user.documento_id_url) {
          idLink.href = user.documento_id_url;
          idLink.style.display = 'inline-block';
        } else {
          idLink.style.display = 'none';
        }

        if (user.rut_url) {
          rutLink.href = user.rut_url;
          rutLink.style.display = 'inline-block';
        } else {
          rutLink.style.display = 'none';
        }

        if (user.certificacion_url) {
          certLink.href = user.certificacion_url;
          certLink.style.display = 'inline-block';
        } else {
          certLink.style.display = 'none';
        }

        document.getElementById('verify-docs-modal').style.display = 'flex';
      });
    });
  }

  // Bind verify modal actions
  const btnApproveDocs = document.getElementById('btn-approve-docs');
  const btnRejectDocs = document.getElementById('btn-reject-docs');

  if (btnApproveDocs) {
    btnApproveDocs.addEventListener('click', async () => {
      const providerId = document.getElementById('verify-provider-id').value;
      btnApproveDocs.disabled = true;
      try {
        const response = await authFetch(`/api/admin/users/${providerId}/verify`, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ status: 'APROBADO' })
        });
        const resData = await response.json();
        if (!resData.success) throw new Error(resData.error || 'Error al aprobar');
        
        alert('Proveedor aprobado y activado con éxito.');
        document.getElementById('verify-docs-modal').style.display = 'none';
        fetchUsers();
      } catch (err) {
        alert(`Error al aprobar proveedor: ${err.message}`);
      } finally {
        btnApproveDocs.disabled = false;
      }
    });
  }

  if (btnRejectDocs) {
    btnRejectDocs.addEventListener('click', async () => {
      const providerId = document.getElementById('verify-provider-id').value;
      if (confirm('¿Estás seguro de que deseas rechazar los documentos de este proveedor? Su perfil se mantendrá inactivo.')) {
        btnRejectDocs.disabled = true;
        try {
          const response = await authFetch(`/api/admin/users/${providerId}/verify`, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ status: 'RECHAZADO' })
          });
          const resData = await response.json();
          if (!resData.success) throw new Error(resData.error || 'Error al rechazar');
          
          alert('Documentación rechazada.');
          document.getElementById('verify-docs-modal').style.display = 'none';
          fetchUsers();
        } catch (err) {
          alert(`Error al rechazar proveedor: ${err.message}`);
        } finally {
          btnRejectDocs.disabled = false;
        }
      }
    });
  }

  // --- Gestión y Resolución de Disputas ---
  let disputesList = [];

  async function fetchDisputes() {
    const tableBody = document.getElementById('disputes-table-body');
    tableBody.innerHTML = `<tr><td colspan="7" class="empty-message"><i class="fa-solid fa-spinner fa-spin"></i> Cargando disputas...</td></tr>`;
    try {
      const response = await authFetch('/api/admin/disputes');
      const data = await response.json();
      if (!data.success) throw new Error(data.error || 'Error al obtener disputas');
      
      disputesList = data.disputes;
      renderDisputes();
    } catch (err) {
      console.error('Error fetchDisputes:', err);
      tableBody.innerHTML = `<tr><td colspan="7" class="empty-message text-danger">Error: ${err.message}</td></tr>`;
    }
  }

  function renderDisputes() {
    const stateFilterEl = document.getElementById('dispute-state-filter');
    if (!stateFilterEl) return;

    const stateVal = stateFilterEl.value;
    const tableBody = document.getElementById('disputes-table-body');
    
    const filtered = disputesList.filter(dispute => {
      return stateVal === 'ALL' || dispute.estado === stateVal;
    });

    if (filtered.length === 0) {
      tableBody.innerHTML = `<tr><td colspan="7" class="empty-message">No se encontraron disputas registradas.</td></tr>`;
      return;
    }

    tableBody.innerHTML = filtered.map(d => {
      const statusClass = d.estado === 'RESUELTA' ? 'badge-success' : 'badge-warning';
      
      let actionBtn = '';
      if (d.estado === 'ABIERTA') {
        actionBtn = `
          <button class="btn btn-resolve btn-sm open-resolve-btn" data-id="${d.id}">
            <i class="fa-solid fa-gavel"></i> Resolver
          </button>
        `;
      } else {
        actionBtn = `
          <span style="font-size: 11px; color: var(--text-muted);">
            Resuelto (${d.resolucion})<br>
            <em style="display:block; max-width: 150px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${d.nota_resolucion || ''}</em>
          </span>
        `;
      }

      return `
        <tr id="dispute-row-${d.id}">
          <td>
            <strong>${d.iniciado_por_nombre}</strong><br>
            <span style="font-size:10px; color:var(--text-muted);">${d.tipo_actor}</span>
          </td>
          <td>${d.cliente_nombre}</td>
          <td>${d.prestador_nombre}</td>
          <td>$${parseFloat(d.monto_disputado).toLocaleString('es-CO')}</td>
          <td>
            <strong>${d.tipo}</strong><br>
            <span style="font-size: 11px; color: var(--text-muted);">${d.descripcion || 'Sin descripción'}</span>
          </td>
          <td><span class="badge ${statusClass}">${d.estado}</span></td>
          <td>${actionBtn}</td>
        </tr>
      `;
    }).join('');

    // Bind click for resolve buttons
    document.querySelectorAll('.open-resolve-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.getAttribute('data-id');
        const dispute = disputesList.find(d => d.id === id);
        if (!dispute) return;

        document.getElementById('resolve-dispute-id').value = id;
        document.getElementById('resolve-note-input').value = '';
        document.getElementById('resolve-action-select').value = 'REEMBOLSO_COMPLETO';
        document.getElementById('resolve-pct-container').style.display = 'none';
        document.getElementById('resolve-pct-input').value = '0';
        
        document.getElementById('resolve-dispute-modal').style.display = 'flex';
      });
    });
  }

  // Bind change of select in dispute resolution
  const actionSelect = document.getElementById('resolve-action-select');
  if (actionSelect) {
    actionSelect.addEventListener('change', () => {
      const val = actionSelect.value;
      const pctContainer = document.getElementById('resolve-pct-container');
      const pctInput = document.getElementById('resolve-pct-input');
      
      if (val === 'REEMBOLSO_COMPLETO') {
        pctContainer.style.display = 'none';
        pctInput.value = '0';
      } else if (val === 'PAGO_PRESTADOR') {
        pctContainer.style.display = 'none';
        pctInput.value = '100';
      } else {
        pctContainer.style.display = 'block';
        pctInput.value = '50';
      }
    });
  }

  // Bind dispute resolve submission
  const btnSubmitResolution = document.getElementById('btn-submit-resolution');
  if (btnSubmitResolution) {
    btnSubmitResolution.addEventListener('click', async () => {
      const disputeId = document.getElementById('resolve-dispute-id').value;
      const resolucion = document.getElementById('resolve-action-select').value;
      const porcentaje_prestador = document.getElementById('resolve-pct-input').value;
      const nota_resolucion = document.getElementById('resolve-note-input').value.trim();

      if (!nota_resolucion) {
        alert('Por favor, ingrese una justificación para la resolución.');
        return;
      }

      btnSubmitResolution.disabled = true;
      btnSubmitResolution.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Resolviendo...';
      
      try {
        const response = await authFetch(`/api/admin/disputes/${disputeId}/resolve`, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ resolucion, porcentaje_prestador, nota_resolucion })
        });
        const resData = await response.json();
        if (!resData.success) throw new Error(resData.error || 'Error al resolver disputa');

        alert('Disputa resuelta y fondos distribuidos correctamente.');
        document.getElementById('resolve-dispute-modal').style.display = 'none';
        fetchDisputes();
      } catch (err) {
        alert(`Error al resolver disputa: ${err.message}`);
      } finally {
        btnSubmitResolution.disabled = false;
        btnSubmitResolution.innerHTML = 'Resolver Disputa';
      }
    });
  }

  const disputeFilterEl = document.getElementById('dispute-state-filter');
  if (disputeFilterEl) disputeFilterEl.addEventListener('change', renderDisputes);

  // Bind Search and Filter Events
  const searchEl = document.getElementById('user-search-input');
  const roleEl = document.getElementById('user-role-filter');
  if (searchEl) searchEl.addEventListener('input', renderUsers);
  if (roleEl) roleEl.addEventListener('change', renderUsers);

  // ==========================================
  // TUTORIAL INTERACTIVO: Flujo y Simulación
  // ==========================================
  let currentStep = 0;
  const totalSteps = 5;
  const screens = ['s0', 's1', 's2', 's3', 's4'];

  function initTutorial() {
    const stepItems = document.querySelectorAll('.step-item');
    const progressFill = document.getElementById('progressFill');
    const btnNext = document.getElementById('btnNext');
    const btnPrev = document.getElementById('btnPrev');

    function goTo(step) {
      if (step < 0 || step >= totalSteps) return;
      
      document.getElementById(screens[currentStep]).classList.remove('active');
      currentStep = step;
      document.getElementById(screens[currentStep]).classList.add('active');

      stepItems.forEach((el, i) => {
        el.classList.remove('active', 'done');
        if (i < currentStep) el.classList.add('done');
        if (i === currentStep) el.classList.add('active');
        
        const numEl = el.querySelector('.step-num');
        if (numEl) {
          numEl.textContent = i < currentStep ? '✓' : (i + 1);
        }
      });

      if (progressFill) {
        progressFill.style.width = (currentStep / (totalSteps - 1) * 100) + '%';
      }
      if (btnPrev) btnPrev.disabled = currentStep === 0;
      if (btnNext) {
        btnNext.textContent = currentStep === totalSteps - 1 ? 'Reiniciar' : 'Siguiente →';
      }
    }

    stepItems.forEach(el => {
      el.onclick = () => goTo(parseInt(el.dataset.step));
    });

    if (btnNext) {
      btnNext.onclick = () => {
        if (currentStep === totalSteps - 1) goTo(0);
        else goTo(currentStep + 1);
      };
    }

    if (btnPrev) {
      btnPrev.onclick = () => goTo(currentStep - 1);
    }

    const triggerGoS1 = document.getElementById('trigger-go-s1');
    if (triggerGoS1) triggerGoS1.onclick = () => goTo(1);

    const backToS0 = document.getElementById('back-to-s0');
    if (backToS0) backToS0.onclick = () => goTo(0);

    const triggerGoS2 = document.getElementById('trigger-go-s2');
    if (triggerGoS2) triggerGoS2.onclick = () => goTo(2);

    const backToS1 = document.getElementById('back-to-s1');
    if (backToS1) backToS1.onclick = () => goTo(1);

    const triggerGoS3 = document.getElementById('trigger-go-s3');
    if (triggerGoS3) triggerGoS3.onclick = () => goTo(3);

    const backToS2 = document.getElementById('back-to-s2');
    if (backToS2) backToS2.onclick = () => goTo(2);

    const triggerGoS4 = document.getElementById('trigger-go-s4');
    if (triggerGoS4) triggerGoS4.onclick = () => goTo(4);

    const btnResetTutorial = document.getElementById('btnResetTutorial');
    if (btnResetTutorial) btnResetTutorial.onclick = () => goTo(0);

    goTo(0);
  }

  // Startup Init Execution
  initMap();
  fetchMetrics();
  connectSSE();
});
