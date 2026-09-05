/**
 * GLOWAPP BUSINESS WORKFLOW SERVICE
 * Task lifecycle state machine: ENTENDER -> EXPLICAR -> RECOMENDAR -> EJECUTAR -> VERIFICAR
 */

const businessRepository = require('../repositories/businessRepository');

const STAGE_ORDER = ['ENTENDER', 'EXPLICAR', 'RECOMENDAR', 'EJECUTAR', 'VERIFICAR'];

class BusinessWorkflowService {
  async getTasksForProvider(providerId) {
    const profile = await businessRepository.getProfileByProviderId(providerId);
    return businessRepository.getTasksByProfileId(profile.id);
  }

  async advanceTaskStage(taskId, action, notes) {
    // Get task
    const tasks = await businessRepository.getTasksByProfileId('demo');
    const task = tasks.find(t => t.id === taskId) || { id: taskId, stage: 'ENTENDER', status: 'IN_PROGRESS' };

    const currentIndex = STAGE_ORDER.indexOf(task.stage);
    let nextStage = task.stage;
    let nextStatus = task.status;

    if (action === 'NEXT' && currentIndex < STAGE_ORDER.length - 1) {
      nextStage = STAGE_ORDER[currentIndex + 1];
    } else if (action === 'SUBMIT_EVIDENCE') {
      nextStage = 'VERIFICAR';
      nextStatus = 'SUBMITTED';
    } else if (action === 'VERIFY') {
      nextStage = 'VERIFICAR';
      nextStatus = 'VERIFIED';
    }

    const updated = await businessRepository.updateTaskStage(taskId, nextStage, nextStatus);

    return {
      task: updated,
      stage: nextStage,
      status: nextStatus,
      message: `Tarea avanzada a la etapa: ${nextStage}`
    };
  }

  async submitEvidence({ taskId, filePath, evidenceType, notes }) {
    const evidence = await businessRepository.addEvidence({
      task_id: taskId,
      file_path: filePath,
      evidence_type: evidenceType || 'DOCUMENT',
      validation_state: 'EVIDENCE_SUBMITTED',
      reviewer_notes: notes || 'Evidencia subida correctamente.'
    });

    await businessRepository.updateTaskStage(taskId, 'VERIFICAR', 'SUBMITTED');

    return {
      evidence,
      validation_state: 'EVIDENCE_SUBMITTED',
      message: 'Evidencia registrada y enviada a cola de verificación.'
    };
  }
}

module.exports = new BusinessWorkflowService();
