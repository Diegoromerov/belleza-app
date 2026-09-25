const { validarLinea } = require('../../scripts/verifyNoVersionedSecrets');

describe('verifyNoVersionedSecrets — Autotest de Independencia CRLF / LF y Detección de Secretos', () => {
  const ruleName = 'valor por defecto literal para variable sensible';
  const targetFile = 'src/config/jwt.js';

  test('C5: Línea con \\r (CRLF) y línea sin \\r (LF) son ambas detectadas como secreto cuando se aplica la normalización', () => {
    const lineLF   = "const MI_CLAVE_SECRETA = 'Xk92LmQ7ppQzRt4VbN8wYs3Dd6Ff';";
    const lineCRLF = "const MI_CLAVE_SECRETA = 'Xk92LmQ7ppQzRt4VbN8wYs3Dd6Ff';\r";

    const detectedLF   = validarLinea(lineLF, targetFile, ruleName, true);
    const detectedCRLF = validarLinea(lineCRLF, targetFile, ruleName, true);

    expect(detectedLF).toBe(true);
    expect(detectedCRLF).toBe(true);
  });

  test('C5 (Prueba de Mutación): Sin la normalización de fin de línea, la extracción de secreto en presencia de \\r difiere de la versión LF', () => {
    const lineLF   = "const MI_CLAVE_SECRETA = 'Xk92LmQ7ppQzRt4VbN8wYs3Dd6Ff';";
    const lineCRLF = "const MI_CLAVE_SECRETA = 'Xk92LmQ7ppQzRt4VbN8wYs3Dd6Ff\r';";

    // Con normalización habilitada (normalize = true): ambos resultan detectados de forma limpia
    const evalLFWithNorm   = validarLinea(lineLF, targetFile, ruleName, true);
    const evalCRLFWithNorm = validarLinea(lineLF + "\r", targetFile, ruleName, true);
    expect(evalLFWithNorm).toBe(true);
    expect(evalCRLFWithNorm).toBe(true);

    // Sin normalización (normalize = false): la extracción incluye '\\r' al final de la cadena de secreto
    const evalLFNoNorm   = validarLinea(lineLF, targetFile, ruleName, false);
    const evalCRLFNoNorm = validarLinea(lineCRLF, targetFile, ruleName, false);

    expect(evalLFNoNorm.val).toBe('Xk92LmQ7ppQzRt4VbN8wYs3Dd6Ff');
    expect(evalCRLFNoNorm.val).toBe('Xk92LmQ7ppQzRt4VbN8wYs3Dd6Ff\r');
    
    // Demostración explícita de mutación: sin normalización, evalLFNoNorm.val !== evalCRLFNoNorm.val
    expect(evalCRLFNoNorm.val).not.toBe(evalLFNoNorm.val);
  });
});
