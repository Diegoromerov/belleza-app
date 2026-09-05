/**
 * GLOWAPP DOCUMENT GENERATOR SERVICE
 * Renders templates with business variables and inserts legal disclaimers.
 */

const businessRepository = require('../repositories/businessRepository');

class DocumentGeneratorService {
  async getTemplates() {
    return businessRepository.getDocumentTemplates();
  }

  async generateDocument({ templateCode, variables }) {
    const template = await businessRepository.getTemplateByCode(templateCode || 'TPL_LABOR_CONTRACT_BEAUTY');
    
    let renderedBody = template.template_body;
    const vars = variables || {};

    // Replace {{variable}} tokens
    Object.keys(vars).forEach(key => {
      const regex = new RegExp(`{{${key}}}`, 'g');
      renderedBody = renderedBody.replace(regex, vars[key]);
    });

    // Replace any remaining unpopulated tokens with placeholder
    renderedBody = renderedBody.replace(/{{[a-zA-Z0-9_]+}}/g, '[________]');

    return {
      templateCode: template.code,
      title: template.title,
      category: template.category,
      renderedBody,
      disclaimer: template.disclaimer,
      generatedAt: new Date().toISOString(),
      watermark: 'BORRADOR DE TRABAJO - REQUIERE REVISIÓN LEGAL'
    };
  }
}

module.exports = new DocumentGeneratorService();
