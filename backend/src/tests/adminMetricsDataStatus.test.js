const fs = require('fs');
const path = require('path');

describe('ORDEN A-02 — GET /api/admin/metrics (Honestidad de métricas financieras)', () => {
  const indexContent = fs.readFileSync(path.resolve(__dirname, '../../index.js'), 'utf8');

  test('C5: Math.random() no debe aparecer en ningún camino de cálculo de métricas en index.js', () => {
    const lines = indexContent.split('\n');
    const mathRandomMatches = [];
    lines.forEach((line, idx) => {
      if (line.includes('Math.random()')) {
        mathRandomMatches.push({ lineNum: idx + 1, content: line.trim() });
      }
    });

    // Debe haber solo 1 ocurrencia en todo index.js (línea 119: uniqueSuffix de subida de archivos)
    expect(mathRandomMatches.length).toBe(1);
    expect(mathRandomMatches[0].content).toContain('uniqueSuffix');
  });

  test('C1, C3: Declaración de estructura y manejo de estado degradado en GET /api/admin/metrics', () => {
    // Verificar que la ruta GET /api/admin/metrics verifica el estado de degradación de la BD
    expect(indexContent).toContain("res.setHeader('X-GlowApp-Degraded', 'memory-fallback')");
    expect(indexContent).toContain("let dataStatus = 'insuficiente'");
    expect(indexContent).toContain("dataStatus = 'completo'");
    expect(indexContent).toContain("projectedRevenue = null");
  });
});
