// backend/src/controllers/saasCalendarController.js
const saasCalendarService = require('../services/saasCalendarService');

/**
 * Controller for SaaS Staff Calendar Integrations (GAP-04 Phase 1 - N06-G)
 */

exports.getStaffStatus = async (req, res) => {
  try {
    const { membershipId } = req.params;
    const result = await saasCalendarService.getStaffCalendarStatus(req.activeContext, membershipId);
    res.json({ success: true, data: result });
  } catch (err) {
    console.error('Error in getStaffStatus:', err);
    res.status(err.status || 500).json({ error: err.message, code: err.code });
  }
};

exports.getGoogleAuthUrl = async (req, res) => {
  try {
    const { membershipId } = req.params;
    const result = await saasCalendarService.generateGoogleAuthUrl(req.activeContext, membershipId);
    res.status(200).json({ success: true, data: result });
  } catch (err) {
    console.error('Error in getGoogleAuthUrl:', err);
    res.status(err.status || 500).json({ error: err.message, code: err.code });
  }
};

exports.generateIcsToken = async (req, res) => {
  try {
    const { membershipId } = req.params;
    const result = await saasCalendarService.generateOrRotateIcsToken(req.activeContext, membershipId);
    res.status(201).json({ success: true, data: result });
  } catch (err) {
    console.error('Error in generateIcsToken:', err);
    res.status(err.status || 500).json({ error: err.message, code: err.code });
  }
};

exports.revokeIcsToken = async (req, res) => {
  try {
    const { membershipId } = req.params;
    const result = await saasCalendarService.revokeIcsToken(req.activeContext, membershipId);
    res.json({ success: true, data: result });
  } catch (err) {
    console.error('Error in revokeIcsToken:', err);
    res.status(err.status || 500).json({ error: err.message, code: err.code });
  }
};

exports.connectGoogle = async (req, res) => {
  try {
    const { membershipId } = req.params;
    const result = await saasCalendarService.connectGoogleCalendar(req.activeContext, membershipId, req.body);
    res.status(200).json({ success: true, data: result });
  } catch (err) {
    console.error('Error in connectGoogle:', err);
    res.status(err.status || 500).json({ error: err.message, code: err.code });
  }
};

exports.disconnectGoogle = async (req, res) => {
  try {
    const { membershipId } = req.params;
    const result = await saasCalendarService.disconnectGoogleCalendar(req.activeContext, membershipId);
    res.json({ success: true, data: result });
  } catch (err) {
    console.error('Error in disconnectGoogle:', err);
    res.status(err.status || 500).json({ error: err.message, code: err.code });
  }
};

exports.getIcsFeed = async (req, res) => {
  try {
    const { token } = req.params;
    const result = await saasCalendarService.getIcsFeed(token);
    res.setHeader('Content-Type', 'text/calendar; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${result.staff_name}_calendar.ics"`);
    res.send(result.ics_string);
  } catch (err) {
    console.error('Error in getIcsFeed:', err);
    res.status(err.status || 404).send('Feed de calendario no disponible.');
  }
};
