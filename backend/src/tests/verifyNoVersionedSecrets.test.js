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

    // Con normalización habilitada (normalize = true)
    const resLFWithNorm   = analizarSalida(rawLF, { normalize: true });
    const resCRLFWithNorm = analizarSalida(rawCRLF, { normalize: true });
    expect(resLFWithNorm.hallazgos).toEqual(resCRLFWithNorm.hallazgos);

    // Sin normalización (normalize = false): rawCRLF produce una línea con \r al final
    const resLFNoNorm   = analizarSalida(rawLF, { normalize: false });
    const resCRLFNoNorm = analizarSalida(rawCRLF, { normalize: false });

    // Con los strips decorativos eliminados, la evaluación sin normalizar difiere o retiene \r
    expect(resCRLFNoNorm.hallazgos).not.toEqual(resLFNoNorm.hallazgos);
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
