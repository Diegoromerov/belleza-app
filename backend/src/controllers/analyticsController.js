// src/controllers/analyticsController.js
const { AnalyticsEvent } = require('../models');

// Log an analytics event (telemetry)
async function logEvent(req, res) {
  try {
    let items = [];
    if (req.body && Array.isArray(req.body.events)) {
      items = req.body.events;
    } else if (Array.isArray(req.body)) {
      items = req.body;
    } else if (req.body && typeof req.body === 'object') {
      items = [req.body];
    }

    if (items.length === 0) {
      return res.status(200).json({ message: 'No events to log' });
    }

    const records = items.map(item => ({
      user_id: req.user ? req.user.id : (item.user_id || null),
      event_type: item.event_type || 'UNKNOWN',
      metadata: {
        ...(item.metadata || {}),
        session_id: item.session_id,
        screen_name: item.screen_name,
        element_id: item.element_id
      },
      occurred_at: item.creado_en || item.occurred_at || new Date()
    }));

    await AnalyticsEvent.bulkCreate(records, { ignoreDuplicates: true });
    return res.status(201).json({ message: 'Analytics events logged successfully', count: records.length });
  } catch (err) {
    console.error('Error logging analytics event:', err);
    return res.status(200).json({ message: 'Telemetry processed with warning', error: err.message });
  }
}

module.exports = { logEvent };
