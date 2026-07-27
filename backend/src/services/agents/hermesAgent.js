// backend/src/services/agents/hermesAgent.js
const { pool } = require('../../config/db');

/**
 * AGENTE HERMES: Especialista en Logística, Agendamiento Inteligente y Geometría PostGIS
 */
class HermesAgent {
  /**
   * Busca los prestadores y servicios más cercanos usando geolocalización PostGIS
   * @param {Object} params - { latitude, longitude, category, maxDistanceKm }
   * @returns {Promise<Object>} Resultado de la búsqueda espacial con distancia calculada
   */
  async findNearbyServices({ latitude, longitude, category, maxDistanceKm = 5 }) {
    const lat = parseFloat(latitude) || 4.6097;  // Bogotá centro por defecto
    const lon = parseFloat(longitude) || -74.0817;
    const radiusKm = parseFloat(maxDistanceKm) || 5;

    let query = `
      SELECT s.id as service_id, s.name, s.price, s.duration_minutes, s.category, 
             p.id as provider_id, p.business_name, p.rating_avg,
             ROUND((ST_Distance(p.ubicacion, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography) / 1000.0)::numeric, 2) as distance_km
      FROM services s
      JOIN perfiles_prestador p ON s.provider_id = p.id
      WHERE s.is_active = true AND p.is_active = true
    `;

    const params = [lat, lon, radiusKm];

    if (category) {
      query += ` AND (LOWER(s.category) LIKE $4 OR LOWER(s.name) LIKE $4)`;
      params.push(`%${category.toLowerCase()}%`);
    }

    query += ` AND ST_DWithin(p.ubicacion, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography, $3 * 1000)`;
    query += ` ORDER BY distance_km ASC, p.rating_avg DESC LIMIT 5;`;

    try {
      const res = await pool.query(query, params);
      return {
        status: 'success',
        foundCount: res.rows.length,
        searchOrigin: { latitude: lat, longitude: lon, radiusKm },
        services: res.rows
      };
    } catch (err) {
      console.error('❌ [HERMES Agent] Error en consulta PostGIS:', err.message);
      return { status: 'error', message: `Fallo al buscar prestadores: ${err.message}` };
    }
  }

  /**
   * Verifica la disponibilidad de agenda de un prestador evitando colisiones de citas
   * @param {Object} params - { providerId, serviceId, date }
   * @returns {Promise<Object>} Análisis de agenda y slots ocupados/libres
   */
  async checkAvailability({ providerId, serviceId, date }) {
    const targetDate = date || new Date().toISOString().split('T')[0];

    const query = `
      SELECT id, booking_date, start_time, duration_minutes, status 
      FROM bookings 
      WHERE provider_id = $1 
        AND booking_date = $2 
        AND status IN ('pending', 'confirmed');
    `;

    try {
      const res = await pool.query(query, [providerId, targetDate]);
      const occupiedSlots = res.rows.map(r => ({
        bookingId: r.id,
        startTime: r.start_time,
        status: r.status
      }));

      return {
        status: 'success',
        providerId,
        date: targetDate,
        totalOccupied: occupiedSlots.length,
        occupiedSlots,
        message: occupiedSlots.length > 0 
          ? `El prestador tiene ${occupiedSlots.length} citas agendadas el ${targetDate}.` 
          : `El prestador tiene disponibilidad completa para el ${targetDate}.`
      };
    } catch (err) {
      console.error('❌ [HERMES Agent] Error verificando agenda:', err.message);
      return { status: 'error', message: `Fallo al verificar agenda: ${err.message}` };
    }
  }
}

module.exports = new HermesAgent();
