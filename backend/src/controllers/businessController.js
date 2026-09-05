/**
 * GLOWAPP BUSINESS CONTROLLER
 * Express HTTP handlers for GlowApp Business Engine endpoints.
 */

const businessDiagnosticService = require('../services/businessDiagnosticService');
const businessRequirementService = require('../services/businessRequirementService');
const businessWorkflowService = require('../services/businessWorkflowService');
const documentGeneratorService = require('../services/documentGeneratorService');

class BusinessController {
  // GET /api/v1/business/verticals
  async getVerticals(req, res) {
    try {
      const verticals = await businessRequirementService.getVerticalsCatalog();
      return res.status(200).json({ success: true, data: verticals });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  // POST /api/v1/business/diagnostic
  async runDiagnostic(req, res) {
    try {
      const providerId = req.user?.id || req.body.provider_id || 'demo-provider-1';
      const result = await businessDiagnosticService.runDiagnostic({
        provider_id: providerId,
        name: req.body.name,
        onboarding_mode: req.body.onboarding_mode,
        vertical_code: req.body.vertical_code,
        city: req.body.city,
        answers: req.body.answers
      });
      return res.status(200).json({ success: true, data: result });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  // GET /api/v1/business/summary
  async getSummary(req, res) {
    try {
      const providerId = req.user?.id || req.query.provider_id || 'demo-provider-1';
      const result = await businessDiagnosticService.getProfileSummary(providerId);
      return res.status(200).json({ success: true, data: result });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  // GET /api/v1/business/tasks
  async getTasks(req, res) {
    try {
      const providerId = req.user?.id || req.query.provider_id || 'demo-provider-1';
      const tasks = await businessWorkflowService.getTasksForProvider(providerId);
      return res.status(200).json({ success: true, data: tasks });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  // POST /api/v1/business/tasks/:id/advance
  async advanceTask(req, res) {
    try {
      const result = await businessWorkflowService.advanceTaskStage(req.params.id, req.body.action, req.body.notes);
      return res.status(200).json({ success: true, data: result });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  // POST /api/v1/business/tasks/:id/evidence
  async submitEvidence(req, res) {
    try {
      const result = await businessWorkflowService.submitEvidence({
        taskId: req.params.id,
        filePath: req.body.file_path,
        evidenceType: req.body.evidence_type,
        notes: req.body.notes
      });
      return res.status(200).json({ success: true, data: result });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  // GET /api/v1/business/templates
  async getTemplates(req, res) {
    try {
      const templates = await documentGeneratorService.getTemplates();
      return res.status(200).json({ success: true, data: templates });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  // POST /api/v1/business/documents/generate
  async generateDocument(req, res) {
    try {
      const doc = await documentGeneratorService.generateDocument({
        templateCode: req.body.template_code,
        variables: req.body.variables
      });
      return res.status(200).json({ success: true, data: doc });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }
}

module.exports = new BusinessController();
