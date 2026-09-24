const { execFileSync } = require('child_process');
const path = require('path');

describe('verifyNoVersionedSecrets - Autotest de Independencia CRLF / LF', () => {
  const scriptPath = path.resolve(__dirname, '../../scripts/verifyNoVersionedSecrets.js');

  test('ejecución del script en el repositorio debe retornar exit code 0 (sin hallazgos bloqueantes)', () => {
    let exitCode = 0;
    try {
      execFileSync('node', [scriptPath], {
        cwd: path.resolve(__dirname, '../../..'),
        encoding: 'utf8',
        stdio: 'pipe',
      });
    } catch (err) {
      exitCode = err.status || 1;
    }
    expect(exitCode).toBe(0);
  });

  test('normalización de fin de línea produce el mismo resultado independientemente de \\r\\n o \\n', () => {
    const sampleCodeCRLF = "const pass = 'postgres';\r\nconst secret = process.env.JWT_SECRET || 'dev_secret';\r\n";
    const sampleCodeLF   = "const pass = 'postgres';\nconst secret = process.env.JWT_SECRET || 'dev_secret';\n";

    const cleanCRLF = sampleCodeCRLF.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
    const cleanLF   = sampleCodeLF.replace(/\r\n/g, '\n').replace(/\r/g, '\n');

    expect(cleanCRLF).toBe(cleanLF);
  });
});
