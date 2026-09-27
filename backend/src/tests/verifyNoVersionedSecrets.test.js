const { analizarSalida, validarLinea } = require('../../scripts/verifyNoVersionedSecrets');

describe('verifyNoVersionedSecrets — Pipeline Pure Scanner Test (CRLF / LF Invariance & Mutation Proof)', () => {
  const targetFile = 'src/config/jwt.js';
  const secretLine = "const MI_CLAVE_SECRETA = 'Xk92LmQ7ppQzRt4VbN8wYs3Dd6Ff';";

  test('C2: CRLF y LF entran por analizarSalida y producen el mismo conjunto de hallazgos (no vacío)', () => {
    const rawLF   = `${targetFile}:10:${secretLine}\n`;
    const rawCRLF = `${targetFile}:10:${secretLine}\r\n`;

    const resLF   = analizarSalida(rawLF);
    const resCRLF = analizarSalida(rawCRLF);

    expect(resLF.hallazgos.length).toBeGreaterThan(0);
    expect(resCRLF.hallazgos.length).toBeGreaterThan(0);
    expect(resCRLF.hallazgos).toEqual(resLF.hallazgos);
    expect(resCRLF.exitCode).toBe(1);
    expect(resLF.exitCode).toBe(1);
  });

  test('C3: Entrada conocida produce exactamente N hallazgos (comprueba que el escáner no está mudo)', () => {
    const rawInput = `${targetFile}:10:${secretLine}\n`;
    const res = analizarSalida(rawInput);

    expect(res.hallazgos).toHaveLength(1);
    expect(res.hallazgos[0]).toEqual({
      archivo: targetFile,
      numLinea: '10',
      nombre: 'valor por defecto literal para variable sensible'
    });
    expect(res.exitCode).toBe(1);
  });

  test('C4 (Prueba de Mutación): Sin normalización (normalize = false), la entrada CRLF retiene \\r y difiere de la versión LF limpia', () => {
    const rawLF   = `${targetFile}:10:${secretLine}\n`;
    const rawCRLF = `${targetFile}:10:${secretLine}\r\n`;

    const resLFWithNorm   = analizarSalida(rawLF, { normalize: true });
    const resCRLFWithNorm = analizarSalida(rawCRLF, { normalize: true });
    expect(resLFWithNorm.hallazgos).toEqual(resCRLFWithNorm.hallazgos);

    const resLFNoNorm   = analizarSalida(rawLF, { normalize: false });
    const resCRLFNoNorm = analizarSalida(rawCRLF, { normalize: false });

    expect(resCRLFNoNorm.hallazgos).not.toEqual(resLFNoNorm.hallazgos);
  });

  test('Regla 1: Contraseña documentada en prosa o comentario es detectada por el escáner (con y sin acento)', () => {
    const proseLineAccent = "-- contraseña para todos los usuarios es: secret123";
    const proseLineNoAccent = "// contrasena por defecto: secret123";
    const rawInputAccent = `seed.sql:1:${proseLineAccent}\n`;
    const rawInputNoAccent = `seed.sql:2:${proseLineNoAccent}\n`;

    const resAccent = analizarSalida(rawInputAccent);
    const resNoAccent = analizarSalida(rawInputNoAccent);

    expect(resAccent.hallazgos).toHaveLength(1);
    expect(resAccent.hallazgos[0].nombre).toBe('contraseña documentada en prosa o comentario');
    expect(resNoAccent.hallazgos).toHaveLength(1);
    expect(resNoAccent.hallazgos[0].nombre).toBe('contraseña documentada en prosa o comentario');
  });

  test('Regla 2: Hash de contraseña débil conocida (bcrypt) es detectado por el escáner', () => {
    // Hash bcrypt conocido de 'password123'
    const hashLine = "INSERT INTO usuarios VALUES ('$2a$10$XG3dsKkJJFx9cldnFJHGt.FJqYVTNiSsoJAaSVwUQkYis22mXk/7O');";
    const rawInput = `seed.sql:5:${hashLine}\n`;
    const res = analizarSalida(rawInput);

    expect(res.hallazgos).toHaveLength(1);
    expect(res.hallazgos[0]).toEqual({
      archivo: 'seed.sql',
      numLinea: '5',
      nombre: 'hash de contraseña débil conocida'
    });
    expect(res.exitCode).toBe(1);
  });

  test('Regla 3: Valor por defecto literal en variable sensible sigue siendo detectado (re-verificación de cobertura)', () => {
    const defaultValLine = "const DB_PASS = 'SuperSecret123!';";
    const rawInput = `src/config/db.js:15:${defaultValLine}\n`;
    const res = analizarSalida(rawInput);

    expect(res.hallazgos).toHaveLength(1);
    expect(res.hallazgos[0]).toEqual({
      archivo: 'src/config/db.js',
      numLinea: '15',
      nombre: 'valor por defecto literal para variable sensible'
    });
    expect(res.exitCode).toBe(1);
  });

  test('Regla 3 (ronda 2): Expresiones de fallback process.env.X || "literal" y process.env.X ?? "literal" son detectadas', () => {
    const line1 = "const DB_PASSWORD = process.env.DB_PASSWORD || 'Literal123!';";
    const line2 = "const JWT_SECRET = process.env.JWT_SECRET || 'devsecret123';";
    const line3 = "const API_KEY = process.env.API_KEY ?? 'live_key_1234567890';";

    expect(analizarSalida(`src/config/db.js:1:${line1}\n`).hallazgos).toHaveLength(1);
    expect(analizarSalida(`src/config/db.js:2:${line2}\n`).hallazgos).toHaveLength(1);
    expect(analizarSalida(`src/config/db.js:3:${line3}\n`).hallazgos).toHaveLength(1);
  });

  test('Coexistencia legacy: validarLinea (normalize = false) demuestra divergencia por \\r', () => {
    const lineLF   = "const MI_CLAVE_SECRETA = 'Xk92LmQ7ppQzRt4VbN8wYs3Dd6Ff';";
    const lineCRLF = "const MI_CLAVE_SECRETA = 'Xk92LmQ7ppQzRt4VbN8wYs3Dd6Ff\r';";

    const evalLFNoNorm   = validarLinea(lineLF, targetFile, 'valor por defecto literal para variable sensible', false);
    const evalCRLFNoNorm = validarLinea(lineCRLF, targetFile, 'valor por defecto literal para variable sensible', false);

    expect(evalLFNoNorm.val).toBe('Xk92LmQ7ppQzRt4VbN8wYs3Dd6Ff');
    expect(evalCRLFNoNorm.val).toBe('Xk92LmQ7ppQzRt4VbN8wYs3Dd6Ff\r');
    expect(evalCRLFNoNorm.val).not.toBe(evalLFNoNorm.val);
  });
});
