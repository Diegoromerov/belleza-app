/**
 * NCP Core Test Suite v1.0
 * Comprehensive Verification of NCP Core Orchestrator, Reader & Verifier
 */

const assert = require('assert');
const path = require('path');
const reader = require('./reader');
const verifier = require('./verifier');

let totalTests = 0;
let passedTests = 0;
let failedTests = 0;

function test(name, fn) {
  totalTests++;
  try {
    fn();
    passedTests++;
    console.log(`  ✓ PASS: ${name}`);
  } catch (err) {
    failedTests++;
    console.error(`  ✗ FAIL: ${name}\n    Error: ${err.message}`);
  }
}

console.log('='.repeat(80));
console.log('                 NCP CORE v1.0 — COMPREHENSIVE TEST SUITE');
console.log('='.repeat(80));

// ============================================================================
// 1. READER TESTS
// ============================================================================
console.log('\n[TEST GROUP 1: Document & State Reader]');

test('Path Traversal Protection blocks ../ paths', () => {
  const isSafe = reader.isPathSafe('../../../etc/passwd');
  assert.strictEqual(isSafe, false, 'Should block path traversal outside REPO_ROOT');
});

test('Safe path resolution allows internal files', () => {
  const safePath = reader.resolveSafePath('ncp/NCP-CORE-CONTRACT-v1.0.md');
  assert.ok(safePath, 'Safe path should resolve');
  assert.ok(safePath.includes('NCP-CORE-CONTRACT-v1.0.md'), 'Path should include target filename');
});

test('Read text file returns error on missing file', () => {
  const res = reader.readTextFile('ncp/NON_EXISTENT_FILE.md');
  assert.strictEqual(res.success, false);
  assert.ok(res.error.includes('FILE_NOT_FOUND'));
});

test('Read valid Node Contract succeeds', () => {
  const res = reader.readNodeContract('ncp/NCP-CORE-CONTRACT-v1.0.md');
  assert.strictEqual(res.success, true);
  assert.ok(res.data.purpose, 'Should extract purpose');
  assert.ok(res.data.scope, 'Should extract scope');
});

test('Read Architecture State returns valid declared model', () => {
  const res = reader.readArchitectureState();
  assert.strictEqual(res.success, true);
  assert.strictEqual(res.data.foundation_version, 'v1.0');
  assert.ok(Array.isArray(res.data.closed_nodes));
  assert.ok(res.data.closed_nodes.includes('SAAS-FOUNDATION-v1.0'));
});

test('Read Decision Records returns approved ARCH-* decisions', () => {
  const res = reader.readDecisionRecords();
  assert.strictEqual(res.success, true);
  assert.ok(Array.isArray(res.data));
  const arch001 = res.data.find(d => d.decision_id === 'ARCH-CR-001');
  assert.ok(arch001, 'ARCH-CR-001 must exist');
  assert.strictEqual(arch001.status, 'APPROVED');
});

test('Parse structured GOAL markdown', () => {
  const sampleGoal = `
# GOAL — SAMPLE TEST GOAL
## FASE: DEFINIR
### OBJETIVO
Ejecutar verificación controlada.
### AUTORIDAD
DIRECTOR — AUTHORITY ROOT
### SCOPE AUTORIZADO
* /ncp/ncp-core.js
* /ncp/reader.js
`;
  const res = reader.readGoal(sampleGoal);
  assert.strictEqual(res.success, true);
  assert.ok(res.data.objective.includes('Ejecutar verificación'));
  assert.ok(res.data.authority.includes('DIRECTOR'));
  assert.ok(res.data.allowed_scope.length >= 2);
});

// ============================================================================
// 2. VERIFIER TESTS
// ============================================================================
console.log('\n[TEST GROUP 2: Gate & Verification Engine]');

test('Scope Verification: PASS when all modified files are in scope', () => {
  const allowed = ['ncp/ncp-core.js', 'ncp/reader.js', 'ncp/verifier.js'];
  const modified = ['ncp/ncp-core.js', 'ncp/reader.js'];
  const res = verifier.verifyScope(allowed, modified);
  assert.strictEqual(res.pass, true);
  assert.strictEqual(res.unauthorized_files.length, 0);
});

test('Scope Verification: FAIL (SCOPE_STOP) when modified file is outside scope', () => {
  const allowed = ['ncp/ncp-core.js'];
  const modified = ['backend/src/controllers/userController.js'];
  const res = verifier.verifyScope(allowed, modified);
  assert.strictEqual(res.pass, false);
  assert.strictEqual(res.stop, 'SCOPE_STOP');
  assert.ok(res.unauthorized_files.includes('backend/src/controllers/userController.js'));
});

test('Protected Assets: PASS when no protected assets are touched', () => {
  const modified = ['ncp/test-file.js'];
  const res = verifier.verifyProtectedAssets(modified);
  assert.strictEqual(res.pass, true);
});

test('Protected Assets: FAIL (SECURITY_STOP) when Foundation migration 065 is touched', () => {
  const modified = ['backend/migrations/065_saas_foundation_core.sql'];
  const res = verifier.verifyProtectedAssets(modified);
  assert.strictEqual(res.pass, false);
  assert.strictEqual(res.stop, 'SECURITY_STOP');
  assert.ok(res.reason.includes('PROTECTED_ASSET_VIOLATION'));
});

test('Protected Assets: FAIL (SECURITY_STOP) when Context Resolution migration 066 is touched', () => {
  const modified = ['backend/migrations/066_context_resolution_tenant_resolver.sql'];
  const res = verifier.verifyProtectedAssets(modified);
  assert.strictEqual(res.pass, false);
  assert.strictEqual(res.stop, 'SECURITY_STOP');
});

test('Protected Assets: FAIL (SECURITY_STOP) when SOUL design tokens are touched', () => {
  const modified = ['frontend/lib/core/theme/tokens.dart'];
  const res = verifier.verifyProtectedAssets(modified);
  assert.strictEqual(res.pass, false);
  assert.strictEqual(res.stop, 'SECURITY_STOP');
});

test('Pre-Execution Gate: 12 Checks evaluated with PASS on valid GOAL', () => {
  const sampleGoal = {
    goal_id: 'GOAL-TEST-001',
    node_target: 'NCP-CORE-v1.0',
    objective: 'Implementar NCP Core',
    authority: 'DIRECTOR — AUTHORITY ROOT',
    allowed_scope: ['ncp/ncp-core.js', 'ncp/reader.js', 'ncp/verifier.js']
  };
  const sampleContract = {
    file_path: path.resolve(__dirname, 'NCP-CORE-IMPLEMENTATION-CONTRACT-v1.0.md'),
    status: 'READY FOR DIRECTOR APPROVAL'
  };
  const gateRes = verifier.verifyPreExecutionGate(sampleGoal, sampleContract);
  assert.strictEqual(gateRes.pass, true);
  assert.strictEqual(gateRes.total_checks, 12);
  assert.strictEqual(gateRes.passed_checks, 12);
  assert.strictEqual(gateRes.failed_checks, 0);
});

test('Pre-Execution Gate: FAIL when Authority is missing Director', () => {
  const sampleGoal = {
    goal_id: 'GOAL-TEST-INVALID',
    node_target: 'NCP-CORE-v1.0',
    objective: 'Implementar algo no autorizado',
    authority: 'AUTONOMOUS_BOT',
    allowed_scope: []
  };
  const gateRes = verifier.verifyPreExecutionGate(sampleGoal);
  assert.strictEqual(gateRes.pass, false);
  assert.strictEqual(gateRes.stop_type, 'PRECHECK_GATE_STOP');
  const authCheck = gateRes.checks.find(c => c.id === 5);
  assert.strictEqual(authCheck.status, 'FAIL');
});

// ============================================================================
// 3. CORE CLI & STOP EMISSION TESTS
// ============================================================================
console.log('\n[TEST GROUP 3: Core Orchestrator & STOP Protocol]');

test('STOP Record formatting conforms to canonical 6-part schema', () => {
  const ncpCore = require('./ncp-core');
  const stopOutput = ncpCore.emitStopRecord({
    stopType: 'ARCHITECTURAL_STOP',
    goalId: 'GOAL-TEST',
    nodeId: 'NODE-TEST',
    agent: 'NCP_CORE',
    problem: 'Ambigüedad en contrato',
    evidence: 'Línea 42',
    impact: 'Bloqueo',
    options: ['Opción 1', 'Opción 2'],
    recommendation: 'Opción 1',
    decisionRequired: '¿Aprobado?'
  });
  assert.ok(stopOutput.includes('ARCHITECTURAL_STOP 🔴'));
  assert.ok(stopOutput.includes('1. PROBLEMA'));
  assert.ok(stopOutput.includes('2. EVIDENCIA'));
  assert.ok(stopOutput.includes('3. IMPACTO'));
  assert.ok(stopOutput.includes('4. OPCIONES'));
  assert.ok(stopOutput.includes('5. RECOMENDACIÓN'));
  assert.ok(stopOutput.includes('6. DECISIÓN REQ.'));
});

// ============================================================================
// SUMMARY
// ============================================================================
console.log('\n' + '='.repeat(80));
console.log(`TOTAL PRUEBAS EJECUTADAS : ${totalTests}`);
console.log(`PRUEBAS PASADAS          : ${passedTests} 🟢`);
console.log(`PRUEBAS FALLIDAS         : ${failedTests} 🔴`);
console.log('='.repeat(80));

if (failedTests > 0) {
  process.exit(1);
} else {
  console.log('ESTADO: SUITE NCP CORE 100% PASS 🟢\n');
  process.exit(0);
}
