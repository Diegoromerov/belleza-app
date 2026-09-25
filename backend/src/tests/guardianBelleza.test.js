const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

describe('ORDEN A O-014 — Cargo 1: guardianBelleza.sh Runner Honesto', () => {
  const rootDir = path.resolve(__dirname, '../../..');
  const scriptPath = path.join(rootDir, 'backend/scripts/guardianBelleza.sh');
  const tmpDir = path.join(rootDir, 'backend/src/tests/tmp_mocks');

  const bashCmd = process.platform === 'win32'
    ? (fs.existsSync('C:\\Program Files\\Git\\bin\\bash.exe') ? 'C:\\Program Files\\Git\\bin\\bash.exe' : 'bash')
    : 'bash';

  beforeAll(() => {
    if (!fs.existsSync(tmpDir)) {
      fs.mkdirSync(tmpDir, { recursive: true });
    }
  });

  afterAll(() => {
    if (fs.existsSync(tmpDir)) {
      fs.rmSync(tmpDir, { recursive: true, force: true });
    }
  });

  test('(a) Con estadoKB.js que falla (exit 1), guardianBelleza.sh debe terminar con exit != 0', () => {
    const mockFailScript = path.join(tmpDir, 'mockFail.js');
    fs.writeFileSync(mockFailScript, 'console.error("Mock Fail"); process.exit(1);', 'utf8');

    const res = spawnSync(bashCmd, [scriptPath], {
      cwd: rootDir,
      encoding: 'utf8',
      env: { ...process.env, ESTADO_KB_SCRIPT: mockFailScript }
    });

    expect(res.status).not.toBe(0);
    expect(res.stdout).toContain('exit=1');
  });

  test('(b) Con estadoKB.js ausente, guardianBelleza.sh debe emitir NO DISPONIBLE y terminar con exit != 0', () => {
    const nonExistentScript = path.join(tmpDir, 'nonExistent.js');

    const res = spawnSync(bashCmd, [scriptPath], {
      cwd: rootDir,
      encoding: 'utf8',
      env: { ...process.env, ESTADO_KB_SCRIPT: nonExistentScript }
    });

    expect(res.status).not.toBe(0);
    expect(res.stdout).toContain('NO DISPONIBLE');
    expect(res.stdout).toContain('exit=no-disponible');
  });

  test('Caso Verde: Con estadoKB.js respondiendo OK (exit 0), guardianBelleza.sh termina con exit 0', () => {
    const mockOkScript = path.join(tmpDir, 'mockOk.js');
    fs.writeFileSync(mockOkScript, 'console.log("Mock OK"); process.exit(0);', 'utf8');

    const res = spawnSync(bashCmd, [scriptPath], {
      cwd: rootDir,
      encoding: 'utf8',
      env: { ...process.env, ESTADO_KB_SCRIPT: mockOkScript }
    });

    expect(res.status).toBe(0);
    expect(res.stdout).toContain('exit=0');
  });
});
