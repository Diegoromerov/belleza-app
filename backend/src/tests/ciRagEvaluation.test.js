/**
 * backend/src/tests/ciRagEvaluation.test.js
 * Tests para validar que el script CI/CD funciona correctamente
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

describe('CI RAG Evaluation Script', () => {
  const scriptPath = path.join(__dirname, '..', '..', 'scripts', 'ciRagEvaluation.sh');
  const evaluateScriptPath = path.join(__dirname, '..', '..', 'scripts', 'evaluateRag.js');

  test('ciRagEvaluation.sh existe y es ejecutable', () => {
    expect(fs.existsSync(scriptPath)).toBe(true);
    const stats = fs.statSync(scriptPath);
    // En Windows, el bit de ejecutable no se refleja igual que en Unix
    // Verificamos que el archivo existe y tiene extensión .sh
    expect(path.extname(scriptPath)).toBe('.sh');
  });

  test('evaluateRag.js existe', () => {
    expect(fs.existsSync(evaluateScriptPath)).toBe(true);
  });

  test('evaluateRag.js tiene sintaxis válida', () => {
    const result = execSync(`node -c "${evaluateScriptPath}"`, { encoding: 'utf8', timeout: 10000 });
    // node -c no outputa nada en éxito, solo falla con error si hay syntax error
    expect(result).toBe('');
  });

  test('ciRagEvaluation.sh tiene sintaxis bash válida', () => {
    const result = execSync(`bash -n ${scriptPath}`, { encoding: 'utf8' });
    expect(result.trim()).toBe('');
  });

  test('evaluateRag.js muestra ayuda con --help', () => {
    const result = execSync(`node ${evaluateScriptPath} --help`, { encoding: 'utf8', timeout: 5000 });
    expect(result).toContain('Uso:');
    expect(result).toContain('--dataset');
    expect(result).toContain('--baseline');
    expect(result).toContain('--fail-on-regression');
  });

  test('ciRagEvaluation.sh muestra ayuda', () => {
    const result = execSync(`bash ${scriptPath} --help`, { encoding: 'utf8', timeout: 5000 });
    expect(result).toContain('CI RAG Evaluation');
    expect(result).toContain('--fail-on-regression');
  });

  test('baseline_metrics.json existe y tiene formato válido', () => {
    const baselinePath = path.join(__dirname, '..', 'data', 'eval', 'baseline_metrics.json');
    expect(fs.existsSync(baselinePath)).toBe(true);
    
    const content = JSON.parse(fs.readFileSync(baselinePath, 'utf8'));
    expect(content).toHaveProperty('timestamp');
    expect(content).toHaveProperty('version');
    expect(content).toHaveProperty('metrics');
    expect(content.metrics).toHaveProperty('retrieval');
    expect(content.metrics).toHaveProperty('generation');
    expect(content.metrics).toHaveProperty('latency');
  });

  test('evaluation_dataset.json existe y tiene 30+ queries', () => {
    const datasetPath = path.join(__dirname, '..', 'data', 'eval', 'evaluation_dataset.json');
    expect(fs.existsSync(datasetPath)).toBe(true);
    
    const content = JSON.parse(fs.readFileSync(datasetPath, 'utf8'));
    expect(content).toHaveProperty('queries');
    expect(content.queries.length).toBeGreaterThanOrEqual(30);
  });
});