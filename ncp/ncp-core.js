#!/usr/bin/env node
/**
 * NCP Core Orchestrator v1.0
 * Node Construction Protocol — Core Governance & Orchestration CLI
 * 
 * Responsabilidad:
 * - Orquestar el ciclo de vida del GOAL (Precheck, Dispatch, Validation, Audit, STOP).
 * - Cero autoridad genérica de escritura sobre código de aplicación.
 * - Enforzar ALLOWED_SCOPE e inmutabilidad de Activos Protegidos.
 * - Ejecución puntual One-Shot, determinista y sin procesos en background.
 */

const path = require('path');
const reader = require('./reader');
const verifier = require('./verifier');

/**
 * Formatea y emite un STOP record canónico
 * @param {object} params
 */
function emitStopRecord({ stopType, goalId, nodeId, agent, problem, evidence, impact, options, recommendation, decisionRequired }) {
  const border = '='.repeat(80);
  const divider = '-'.repeat(80);
  const record = [
    border,
    `                              ${stopType || 'ARCHITECTURAL_STOP'} 🔴`,
    border,
    `GOAL ID           : ${goalId || 'N/A'}`,
    `NODE ID           : ${nodeId || 'N/A'}`,
    `AGENTE EMISOR     : ${agent || 'NCP_CORE'}`,
    divider,
    `1. PROBLEMA       : ${problem || 'Problema no especificado'}`,
    `2. EVIDENCIA      : ${evidence || 'Evidencia no adjunta'}`,
    `3. IMPACTO        : ${impact || 'Impacto no evaluado'}`,
    `4. OPCIONES       : ${Array.isArray(options) ? options.map((o, i) => `\n   ${String.fromCharCode(65 + i)}) ${o}`).join('') : (options || 'N/A')}`,
    `5. RECOMENDACIÓN  : ${recommendation || 'N/A'}`,
    `6. DECISIÓN REQ.  : ${decisionRequired || 'Resolución explícita del Director'}`,
    border
  ].join('\n');

  console.error(record);
  return record;
}

/**
 * Comando: PRECHECK
 * Ejecuta el Pre-Execution Gate (12 checks)
 */
function cmdPrecheck(args) {
  const goalPath = args.goal || args.g;
  if (!goalPath) {
    console.error('ERROR: Debe especificar la ruta del GOAL usando --goal <ruta>');
    process.exit(2);
  }

  const goalRes = reader.readGoal(goalPath);
  if (!goalRes.success) {
    console.error(`ERROR AL CARGAR GOAL: ${goalRes.error}`);
    process.exit(2);
  }

  const contractPath = args.contract || args.c || 'ncp/NCP-CORE-IMPLEMENTATION-CONTRACT-v1.0.md';
  const contractRes = reader.readNodeContract(contractPath);
  const stateRes = reader.readArchitectureState();
  const decisionsRes = reader.readDecisionRecords();

  console.log('='.repeat(80));
  console.log('                 NCP CORE — PRE-EXECUTION GATE EVALUATION (12 CHECKS)');
  console.log('='.repeat(80));
  console.log(`GOAL TARGET       : ${goalRes.data.goal_id}`);
  console.log(`NODE TARGET       : ${goalRes.data.node_target}`);
  console.log('-'.repeat(80));

  const gateRes = verifier.verifyPreExecutionGate(
    goalRes.data,
    contractRes.data,
    stateRes.data,
    decisionsRes.data
  );

  for (const check of gateRes.checks) {
    const symbol = check.status === 'PASS' ? '✓ PASS' : '✗ FAIL';
    console.log(`[Check ${String(check.id).padStart(2, ' ')}] ${symbol.padEnd(8, ' ')} : ${check.name.padEnd(42, ' ')} | ${check.details}`);
  }

  console.log('-'.repeat(80));
  console.log(`RESULTADO FINAL   : ${gateRes.pass ? 'PRECHECK PASS 🟢 (12/12 Satisfechos)' : 'PRECHECK FAILED 🔴'}`);
  console.log('='.repeat(80));

  if (!gateRes.pass) {
    emitStopRecord({
      stopType: 'DEPENDENCY_STOP',
      goalId: goalRes.data.goal_id,
      nodeId: goalRes.data.node_target,
      agent: 'NCP_CORE',
      problem: `Pre-Execution Gate falló con ${gateRes.failed_checks} check(s) no satisfecho(s).`,
      evidence: JSON.stringify(gateRes.checks.filter(c => c.status === 'FAIL'), null, 2),
      impact: 'No se autoriza el despacho ni la ejecución de código sin 100% de pre-checks.',
      options: ['Corregir precondiciones del GOAL', 'Obtener aprobación arquitectónica del Director'],
      recommendation: 'Detener ejecución y revisar las precondiciones insatisfechas.',
      decisionRequired: '¿Autoriza el Director la subsanación de las precondiciones?'
    });
    process.exit(1);
  }

  process.exit(0);
}

/**
 * Comando: DISPATCH
 * Enruta y emite instrucción formal al agente asignado
 */
function cmdDispatch(args) {
  const goalPath = args.goal || args.g;
  if (!goalPath) {
    console.error('ERROR: Debe especificar --goal <ruta>');
    process.exit(2);
  }

  const goalRes = reader.readGoal(goalPath);
  if (!goalRes.success) {
    console.error(`ERROR: ${goalRes.error}`);
    process.exit(2);
  }

  const goal = goalRes.data;
  let targetAgent = 'IMPLEMENTER';

  const objLower = (goal.objective || '').toLowerCase();
  if (objLower.includes('auditar') || objLower.includes('seguridad') || objLower.includes('audit')) {
    targetAgent = 'AUDIT';
  } else if (objLower.includes('descubrimiento') || objLower.includes('evidencia') || objLower.includes('evidence')) {
    targetAgent = 'EVIDENCE';
  } else if (objLower.includes('diseñar') || objLower.includes('arquitectura') || objLower.includes('proponer')) {
    targetAgent = 'ARCHITECT';
  }

  console.log('='.repeat(80));
  console.log('                     NCP CORE — DISPATCH INSTRUCTION');
  console.log('='.repeat(80));
  console.log(`GOAL ID           : ${goal.goal_id}`);
  console.log(`NODE ID           : ${goal.node_target}`);
  console.log(`AGENTE ASIGNADO   : ${targetAgent}`);
  console.log(`ALLOWED_SCOPE     : [${(goal.allowed_scope || []).join(', ')}]`);
  console.log(`MANDATO           : ${targetAgent === 'IMPLEMENTER' ? 'INSPECT / IMPLEMENT / TEST / REPORT' : (targetAgent === 'AUDIT' ? 'VERIFY / TEST / AUDIT / REPORT / STOP' : 'READ / INSPECT / REPORT')}`);
  console.log('-'.repeat(80));
  console.log('REGLA DE ORO: Modificación física estrictamente restringida a ALLOWED_SCOPE.');
  console.log('='.repeat(80));

  process.exit(0);
}

/**
 * Comando: VALIDATE
 * Verifica scope, activos protegidos y ejecuta tests
 */
function cmdValidate(args) {
  const allowedScope = args.scope ? args.scope.split(',') : (args.allowed ? args.allowed.split(',') : []);
  const gitStatus = verifier.getGitStatus();

  console.log('='.repeat(80));
  console.log('                 NCP CORE — IMPLEMENTATION VALIDATION GATE');
  console.log('='.repeat(80));
  console.log(`ARCHIVOS MODIFICADOS (Git) : [${gitStatus.modified.concat(gitStatus.untracked).join(', ') || 'Ninguno'}]`);
  console.log(`ALLOWED_SCOPE DECLARADO    : [${allowedScope.join(', ') || 'N/A'}]`);
  console.log('-'.repeat(80));

  const allTouched = gitStatus.modified.concat(gitStatus.untracked);

  // 1. Verificación de Activos Protegidos
  const protectedCheck = verifier.verifyProtectedAssets(allTouched);
  if (!protectedCheck.pass) {
    console.error(`[FAIL] ACTIVO PROTEGIDO VIOLADO: ${protectedCheck.reason}`);
    emitStopRecord({
      stopType: protectedCheck.stop,
      agent: 'NCP_CORE',
      problem: protectedCheck.reason,
      evidence: `Archivos violados: ${protectedCheck.violated_assets.join(', ')}`,
      impact: 'Violación crítica de inmutabilidad en activo protegido.',
      options: ['Revertir modificaciones en activo protegido', 'Escalar a decisión del Director'],
      recommendation: 'Revertir de inmediato cambios en activos protegidos.',
      decisionRequired: '¿Se confirma la restitución del activo protegido?'
    });
    process.exit(1);
  }
  console.log('[PASS] Activos Protegidos : INTACTOS 🟢');

  // 2. Verificación de Scope (si fue suministrado)
  if (allowedScope.length > 0) {
    const scopeCheck = verifier.verifyScope(allowedScope, allTouched);
    if (!scopeCheck.pass) {
      console.error(`[FAIL] SCOPE VIOLADO: ${scopeCheck.reason}`);
      emitStopRecord({
        stopType: scopeCheck.stop,
        agent: 'NCP_CORE',
        problem: scopeCheck.reason,
        evidence: `Archivos fuera de scope: ${scopeCheck.unauthorized_files.join(', ')}`,
        impact: 'Modificación no autorizada fuera del alcance del GOAL.',
        options: ['Eliminar archivos no autorizados', 'Solicitar ampliación de scope al Director'],
        recommendation: 'Detener y restringir cambios al ALLOWED_SCOPE asignado.',
        decisionRequired: '¿Autoriza el Director ampliar el ALLOWED_SCOPE?'
      });
      process.exit(1);
    }
    console.log('[PASS] Scope Enforcement   : RESPETADO 🟢');
  }

  // 3. Ejecución de suite de tests si se especifica
  if (args.testCommand || args.t) {
    const cmd = args.testCommand || args.t;
    console.log(`[RUN ] Ejecutando Test Suite : ${cmd}`);
    const testRes = verifier.runValidationSuite(cmd);
    if (!testRes.pass) {
      console.error(`[FAIL] Test Suite Fallida:\n${testRes.output}`);
      emitStopRecord({
        stopType: 'VALIDATION_FAILED',
        agent: 'NCP_CORE',
        problem: 'Fallo en la suite de pruebas de validación.',
        evidence: testRes.output.substring(0, 1000),
        impact: 'El código implementado no supera los criterios de aceptación técnica.',
        options: ['Corregir errores de código locales', 'Revisar pruebas unitarias'],
        recommendation: 'Corregir implementación dentro del scope autorizado.',
        decisionRequired: '¿Reintentar tras corrección?'
      });
      process.exit(1);
    }
    console.log('[PASS] Test Suite          : 100% PASS 🟢');
  }

  console.log('='.repeat(80));
  console.log('VALIDATION GATE RESULT     : PASS 🟢 (Listo para Auditoría)');
  console.log('='.repeat(80));
  process.exit(0);
}

/**
 * Comando: STATUS
 * Muestra el estado arquitectónico consolidado
 */
function cmdStatus() {
  const stateRes = reader.readArchitectureState();
  const decisionsRes = reader.readDecisionRecords();
  const gitStatus = verifier.getGitStatus();

  console.log('='.repeat(80));
  console.log('                 NCP CORE — ARCHITECTURE STATE & DECISION REGISTRY');
  console.log('='.repeat(80));
  console.log(`FOUNDATION VERSION        : ${stateRes.data.foundation_version}`);
  console.log(`LAST MIGRATION            : ${stateRes.data.last_applied_migration}`);
  console.log(`CLOSED NODES              : [${stateRes.data.closed_nodes.join(', ')}]`);
  console.log(`CURRENT ACTIVE NODE       : ${stateRes.data.current_active_node}`);
  console.log(`CURRENT NODE STATE        : ${stateRes.data.current_node_state}`);
  console.log(`ACTIVE NODE CONTRACT      : ${stateRes.data.active_node_contract}`);
  console.log(`PROTECTED ASSETS COUNT    : ${stateRes.data.protected_assets.length} items`);
  console.log('-'.repeat(80));
  console.log('APPROVED DECISION RECORDS (ARCH-*):');
  for (const dec of decisionsRes.data) {
    console.log(`  • [${dec.decision_id}] (${dec.status}) ${dec.title} — Autoridad: ${dec.authority}`);
  }
  console.log('-'.repeat(80));
  console.log(`GIT REPOSITORY STATUS     : ${gitStatus.clean ? 'CLEAN 🟢' : `DIRTY 🟡 (${gitStatus.modified.length} modif, ${gitStatus.untracked.length} untracked)`}`);
  console.log('='.repeat(80));
  process.exit(0);
}

// ============================================================================
// CLI Entrypoint Router
// ============================================================================

function parseArgs(rawArgs) {
  const args = {};
  for (let i = 0; i < rawArgs.length; i++) {
    const arg = rawArgs[i];
    if (arg.startsWith('--')) {
      const key = arg.substring(2);
      const next = rawArgs[i + 1];
      if (next && !next.startsWith('--')) {
        args[key] = next;
        i++;
      } else {
        args[key] = true;
      }
    } else if (arg.startsWith('-')) {
      const key = arg.substring(1);
      const next = rawArgs[i + 1];
      if (next && !next.startsWith('-')) {
        args[key] = next;
        i++;
      } else {
        args[key] = true;
      }
    } else if (!args._command) {
      args._command = arg;
    }
  }
  return args;
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const cmd = (args._command || 'status').toLowerCase();

  switch (cmd) {
    case 'precheck':
      cmdPrecheck(args);
      break;
    case 'dispatch':
      cmdDispatch(args);
      break;
    case 'validate':
      cmdValidate(args);
      break;
    case 'status':
      cmdStatus();
      break;
    case 'help':
    case '--help':
    case '-h':
      console.log(`
Uso de NCP Core CLI:
  node ncp/ncp-core.js <comando> [opciones]

Comandos disponibles:
  status                                 Muestra el estado arquitectónico y decisiones
  precheck --goal <ruta> [--contract <c>] Evalúa los 12 checks del Pre-Execution Gate
  dispatch --goal <ruta>                 Genera la instrucción formal de despacho
  validate [--scope <s1,s2>] [-t <cmd>]  Valida scope, activos protegidos y tests
  help                                   Muestra este mensaje de ayuda
`);
      process.exit(0);
      break;
    default:
      console.error(`ERROR: Comando desconocido "${cmd}". Use "node ncp/ncp-core.js help" para ver comandos disponibles.`);
      process.exit(2);
  }
}

if (require.main === module) {
  main();
}

module.exports = {
  emitStopRecord,
  cmdPrecheck,
  cmdDispatch,
  cmdValidate,
  cmdStatus
};
