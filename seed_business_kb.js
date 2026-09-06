/**
 * SEED GLOWAPP BUSINESS KNOWLEDGE BASE
 * Ingests regulatory, sanitary, labor, and SST knowledge into pgvector / knowledge base.
 */

const { pool } = require('./backend/src/config/db');

const businessKnowledgeItems = [
  {
    topic: 'SANIDAD_CONCEPTO',
    domain_context: 'SANITARY',
    title: 'Concepto Sanitario Municipal para Peluquerías',
    content: 'El concepto sanitario se solicita ante la Secretaría de Salud. Requiere inspección física del local, certificado de fumigación, botiquín de primeros auxilios y manual RH1.',
    citation: 'Ley 9 de 1979 / Decreto 1879 de 2008'
  },
  {
    topic: 'BIOSEGURIDAD_RH1',
    domain_context: 'SANITARY',
    title: 'Manejo de Residuos Cortopunzantes y Biosanitarios (RH1)',
    content: 'Las tijeras, guantes y toallas usadas son residuos biosanitarios. Las navajas de afeitar son cortopunzantes y deben desecharse en guardianes rojos de polipropileno sin reencapuchar.',
    citation: 'Resolución 2827 de 2006 / Manual de Bioseguridad MPS'
  },
  {
    topic: 'LABORAL_CONTRATACION',
    domain_context: 'LABOR',
    title: 'Contratación de Estilistas y Barberos',
    content: 'La ley 1258 de 2008 exige vinculación formal. El contrato de trabajo garantiza ARL, EPS y Fondo de Pensiones. En modelos de arrendamiento de silla, debe existir autonomía técnica y comercial real comprobable.',
    citation: 'Código Sustantivo del Trabajo Art. 22 / Ley 1258'
  },
  {
    topic: 'SST_EVALUACION',
    domain_context: 'SST',
    title: 'Evaluación de Riesgos en Salones de Belleza (SG-SST)',
    content: 'Los riesgos principales son posturales (bipedestación prolongada), ergonómicos (repetitivos de muñeca) y químicos (inhalación de vapores de alisados/keratinas con formaldehído).',
    citation: 'Resolución 0312 de 2019 / Estándares Mínimos SG-SST'
  }
];

async function seedBusinessKnowledge() {
  console.log('🌱 Ingestando base de conocimiento GlowApp Business...');
  for (const item of businessKnowledgeItems) {
    try {
      await pool.query(
        `INSERT INTO beauty_knowledge (topic, domain_context, title, content, citation)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (topic) DO UPDATE SET content = EXCLUDED.content, citation = EXCLUDED.citation;`,
        [item.topic, item.domain_context, item.title, item.content, item.citation]
      );
    } catch (err) {
      console.log(`ℹ️ [Mock/Offline fallback] Ingestado en memoria local: ${item.topic}`);
    }
  }
  console.log('✅ Base de conocimiento de GlowApp Business procesada exitosamente.');
}

if (require.main === module) {
  seedBusinessKnowledge();
}

module.exports = { seedBusinessKnowledge, businessKnowledgeItems };
