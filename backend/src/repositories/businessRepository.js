/**
 * GLOWAPP BUSINESS REPOSITORY
 * Data access layer for GlowApp Business Engine.
 */

const { verticals, requirements, documentTemplates } = require('../db/seed_business_data');

// In-memory data store with fallback for local runtime when DB pool is disconnected
const memoryProfiles = new Map();
const memoryTasks = new Map();
const memoryEvidences = new Map();
const memoryFindings = new Map();

class BusinessRepository {
  // Verticals
  async getVerticals() {
    return verticals;
  }

  async getVerticalByCode(code) {
    return verticals.find(v => v.code === code) || verticals[0];
  }

  // Business Profiles
  async createProfile({ id, provider_id, vertical_id, name, onboarding_mode, lifecycle_stage, city, country }) {
    const profile = {
      id: id || `biz-${Date.now()}`,
      provider_id,
      vertical_id: vertical_id || verticals[0].id,
      name,
      onboarding_mode: onboarding_mode || 'NEW_BUSINESS',
      lifecycle_stage: lifecycle_stage || (onboarding_mode === 'EXISTING_BUSINESS' ? 'OPERATION' : 'IDEA'),
      compliance_score: onboarding_mode === 'EXISTING_BUSINESS' ? 45.0 : 10.0,
      city: city || 'Bogotá',
      country: country || 'Colombia',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    memoryProfiles.set(profile.id, profile);
    return profile;
  }

  async getProfileByProviderId(providerId) {
    for (const profile of memoryProfiles.values()) {
      if (profile.provider_id === providerId) {
        return profile;
      }
    }
    // Default fallback profile for testing/demo
    const demoProfile = {
      id: `biz-demo-${providerId}`,
      provider_id: providerId,
      vertical_id: verticals[0].id,
      name: 'Salón de Belleza Demo',
      onboarding_mode: 'NEW_BUSINESS',
      lifecycle_stage: 'CONSTITUTION',
      compliance_score: 35.0,
      city: 'Bogotá',
      country: 'Colombia',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    memoryProfiles.set(demoProfile.id, demoProfile);
    return demoProfile;
  }

  async updateProfileStage(profileId, stage, complianceScore) {
    const profile = memoryProfiles.get(profileId);
    if (profile) {
      profile.lifecycle_stage = stage || profile.lifecycle_stage;
      if (complianceScore !== undefined) {
        profile.compliance_score = complianceScore;
      }
      profile.updated_at = new Date().toISOString();
      memoryProfiles.set(profileId, profile);
    }
    return profile;
  }

  // Requirements
  async getRequirementsByVertical(verticalId) {
    return requirements.filter(r => r.vertical_id === verticalId || !r.vertical_id);
  }

  // Tasks
  async createTasks(taskList) {
    const created = [];
    for (const t of taskList) {
      const task = {
        id: t.id || `task-${Date.now()}-${Math.random().toString(36).substr(2, 5)}`,
        business_profile_id: t.business_profile_id,
        requirement_id: t.requirement_id,
        title: t.title,
        description: t.description || '',
        stage: t.stage || 'ENTENDER',
        status: t.status || 'PENDING',
        due_date: t.due_date || new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };
      memoryTasks.set(task.id, task);
      created.push(task);
    }
    return created;
  }

  async getTasksByProfileId(profileId) {
    const list = [];
    for (const t of memoryTasks.values()) {
      if (t.business_profile_id === profileId) {
        list.push(t);
      }
    }
    if (list.length === 0) {
      // Auto-generate seed tasks if empty
      const defaultTasks = [
        {
          id: `task-1-${profileId}`,
          business_profile_id: profileId,
          requirement_id: requirements[0].id,
          title: 'Obtener Concepto Sanitario Municipal',
          description: 'Revisar condiciones del local y presentar solicitud a la Secretaría de Salud.',
          stage: 'ENTENDER',
          status: 'IN_PROGRESS',
          due_date: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000).toISOString()
        },
        {
          id: `task-2-${profileId}`,
          business_profile_id: profileId,
          requirement_id: requirements[1].id,
          title: 'Elaborar Manual de Bioseguridad y RH1',
          description: 'Personalizar el protocolo de desinfección y manejo de residuos con advertencias de ley.',
          stage: 'EXPLICAR',
          status: 'PENDING',
          due_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
        }
      ];
      return this.createTasks(defaultTasks);
    }
    return list;
  }

  async updateTaskStage(taskId, stage, status) {
    const task = memoryTasks.get(taskId);
    if (task) {
      task.stage = stage || task.stage;
      task.status = status || task.status;
      task.updated_at = new Date().toISOString();
      memoryTasks.set(taskId, task);
    }
    return task;
  }

  // Evidences
  async addEvidence({ id, task_id, file_path, evidence_type, validation_state, reviewer_notes }) {
    const evidence = {
      id: id || `ev-${Date.now()}`,
      task_id,
      file_path: file_path || '/uploads/evidence_placeholder.pdf',
      evidence_type: evidence_type || 'DOCUMENT',
      validation_state: validation_state || 'EVIDENCE_SUBMITTED',
      reviewer_notes: reviewer_notes || 'Evidencia subida correctamente por el usuario.',
      created_at: new Date().toISOString()
    };
    memoryEvidences.set(evidence.id, evidence);
    return evidence;
  }

  async getEvidencesByTaskId(taskId) {
    const list = [];
    for (const ev of memoryEvidences.values()) {
      if (ev.task_id === taskId) {
        list.push(ev);
      }
    }
    return list;
  }

  // Findings
  async createFindings(findingsList) {
    const created = [];
    for (const f of findingsList) {
      const finding = {
        id: f.id || `find-${Date.now()}-${Math.random().toString(36).substr(2, 5)}`,
        business_profile_id: f.business_profile_id,
        title: f.title,
        description: f.description,
        risk_level: f.risk_level || 'MEDIUM',
        status: f.status || 'OPEN',
        mitigation_plan: f.mitigation_plan || '',
        created_at: new Date().toISOString()
      };
      memoryFindings.set(finding.id, finding);
      created.push(finding);
    }
    return created;
  }

  async getFindingsByProfileId(profileId) {
    const list = [];
    for (const f of memoryFindings.values()) {
      if (f.business_profile_id === profileId) {
        list.push(f);
      }
    }
    return list;
  }

  // Templates
  async getDocumentTemplates() {
    return documentTemplates;
  }

  async getTemplateByCode(code) {
    return documentTemplates.find(t => t.code === code) || documentTemplates[0];
  }
}

module.exports = new BusinessRepository();
