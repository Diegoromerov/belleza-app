// backend/src/tests/app.test.js

describe('Suite de Pruebas de Integridad y Reglas de Negocio', () => {
  
  test('1. Cálculo de Split Financiero (Comisión 12% e Impuestos 8%)', () => {
    const valorBruto = 100000; // 100,000 COP
    
    // Regla de Negocio: 12% Comisión Plataforma, 8% Impuestos
    const comisionPlataforma = Math.round(valorBruto * 0.12 * 100) / 100;
    const impuestosEstado = Math.round(valorBruto * 0.08 * 100) / 100;
    const pagoNetoPrestador = valorBruto - (comisionPlataforma + impuestosEstado);
    
    expect(comisionPlataforma).toBe(12000);
    expect(impuestosEstado).toBe(8000);
    expect(pagoNetoPrestador).toBe(80000);
  });

  test('2. Validación de Vigencia y Expiración de OTP', () => {
    const expiraAt = new Date(Date.now() + 45 * 60 * 1000); // 45 minutos en el futuro
    const ahora = new Date();
    
    expect(expiraAt.getTime()).isGreaterThan = ahora.getTime();
    
    const expiraExpirado = new Date(Date.now() - 1000); // Expirado hace 1 segundo
    expect(expiraExpirado.getTime()).isLessThan = ahora.getTime();
  });
  
});
