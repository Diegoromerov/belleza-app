/**
 * GLOWAPP DOCUMENT GENERATOR & SIGNATURE SERVICE
 * Renders templates with business variables, inserts legal disclaimers, handles document persistence, versioning, download authorization, and electronic signatures.
 */

const businessRepository = require('../repositories/businessRepository');
const crypto = require('crypto');

class DocumentGeneratorService {
  async getTemplates() {
    return businessRepository.getDocumentTemplates();
  }

  async generateDocument({ templateCode, variables, providerId, tenantId, businessProfileId }) {
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

    const docRecord = await businessRepository.saveDocument({
      template_code: template.code,
      business_profile_id: businessProfileId || null,
      provider_id: providerId || 'system-default',
      tenant_id: tenantId || 'tenant-default',
      title: template.title,
      category: template.category,
      rendered_body: renderedBody,
      watermark: 'BORRADOR DE TRABAJO - REQUIERE REVISIÓN LEGAL',
      disclaimer: template.disclaimer,
      version: 1,
      status: 'DRAFT'
    });

    return {
      documentId: docRecord.id,
      templateCode: template.code,
      title: template.title,
      category: template.category,
      renderedBody: docRecord.rendered_body,
      disclaimer: docRecord.disclaimer,
      version: docRecord.version,
      status: docRecord.status,
      generatedAt: docRecord.created_at,
      watermark: docRecord.watermark
    };
  }

  async getDocumentForDownload(documentId, providerId, tenantId, role = 'provider') {
    const doc = await businessRepository.getDocumentById(documentId);
    if (!doc) {
      return { status: 404, error: 'Documento no encontrado' };
    }

    // Tenant & Ownership Authorization Check (BUS-SEC-002 Boundary)
    if (role !== 'admin') {
      if (doc.provider_id !== providerId && doc.tenant_id !== tenantId) {
        return { status: 403, error: 'FORBIDDEN: No tienes autorizacion para descargar documentos de otro tenant o prestador' };
      }
    }

    // Format downloadable document payload
    const formattedHtml = `
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>${doc.title}</title>
  <style>
    body { font-family: sans-serif; padding: 40px; color: #1e293b; line-height: 1.6; }
    .watermark { font-size: 10pt; color: #64748b; text-transform: uppercase; margin-bottom: 20px; font-weight: bold; border-bottom: 1px solid #cbd5e1; padding-bottom: 8px; }
    .title { font-size: 16pt; font-weight: bold; margin-bottom: 24px; color: #0f172a; }
    .content { white-space: pre-wrap; margin-bottom: 30px; font-size: 11pt; }
    .disclaimer { background-color: #f8fafc; border-left: 4px solid #e2e8f0; padding: 12px; font-size: 9pt; color: #475569; margin-top: 40px; }
    .signature-block { margin-top: 50px; border-top: 1px dashed #cbd5e1; padding-top: 15px; font-size: 10pt; }
  </style>
</head>
<body>
  <div class="watermark">${doc.watermark || 'DOCUMENTO OFICIAL GLOWAPP'} - VERSIÓN ${doc.version || 1} [ESTADO: ${doc.status}]</div>
  <div class="title">${doc.title}</div>
  <div class="content">${doc.rendered_body}</div>
  ${doc.signed_by ? `
  <div class="signature-block">
    <strong>FIRMADO ELECTRÓNICAMENTE POR:</strong> ${doc.signed_by}<br/>
    <strong>HASH DE FIRMA:</strong> <code>${doc.signature_hash}</code><br/>
    <strong>FECHA DE FIRMA:</strong> ${doc.signed_at}
  </div>` : ''}
  <div class="disclaimer">${doc.disclaimer}</div>
</body>
</html>
    `.trim();

    return {
      status: 200,
      doc,
      downloadUrl: `/api/v1/business/documents/${doc.id}/download`,
      htmlContent: formattedHtml
    };
  }

  async requestSignature(documentId, providerId, tenantId) {
    const doc = await businessRepository.getDocumentById(documentId);
    if (!doc) throw new Error('Documento no encontrado');

    if (doc.provider_id !== providerId && doc.tenant_id !== tenantId) {
      throw new Error('FORBIDDEN: No tienes permisos sobre este documento');
    }

    const updated = await businessRepository.updateDocumentSignature(documentId, 'PENDING_SIGNATURE', null, null);
    return {
      documentId: updated.id,
      status: updated.status,
      message: 'Solicitud de firma registrada. Documento en estado PENDING_SIGNATURE.'
    };
  }

  async signDocument({ documentId, providerId, tenantId, signerName, signatureHash }) {
    const doc = await businessRepository.getDocumentById(documentId);
    if (!doc) throw new Error('Documento no encontrado');

    if (doc.provider_id !== providerId && doc.tenant_id !== tenantId) {
      throw new Error('FORBIDDEN: No tienes permisos sobre este documento');
    }

    const generatedHash = signatureHash || crypto.createHash('sha256').update(`${doc.id}-${signerName}-${Date.now()}`).digest('hex');

    const updated = await businessRepository.updateDocumentSignature(
      documentId,
      'SIGNED',
      signerName || `Prestador (${providerId})`,
      generatedHash
    );

    return {
      documentId: updated.id,
      status: updated.status,
      signedBy: updated.signed_by,
      signatureHash: updated.signature_hash,
      signedAt: updated.signed_at,
      message: 'Documento firmado electrónicamente exitosamente.'
    };
  }
}

module.exports = new DocumentGeneratorService();
