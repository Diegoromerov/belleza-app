const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const BASELINE_FILE = path.join(__dirname, 'flutter_baseline.json');
const isUpdateMode = process.argv.includes('--update-baseline');

function getFlutterBinary() {
  if (process.env.FLUTTER_BIN) {
    return process.env.FLUTTER_BIN;
  }
  const defaultWindowsPath = 'C:\\flutter\\bin\\flutter.bat';
  if (fs.existsSync(defaultWindowsPath)) {
    return defaultWindowsPath;
  }
  return 'flutter';
}

const flutterBin = getFlutterBinary();

console.log(`🔍 Verificando Flutter analyze usando binario: "${flutterBin}"...`);

try {
  try {
    execSync(`"${flutterBin}" --version`, { stdio: 'ignore' });
  } catch (err) {
    console.error(`❌ ERROR CRÍTICO: No se pudo ejecutar el binario de Flutter en "${flutterBin}".`);
    console.error(`   Asegúrese de que Flutter está instalado o especifique FLUTTER_BIN.`);
    process.exit(1);
  }

  let rawOutput = '';
  try {
    rawOutput = execSync(`"${flutterBin}" analyze lib/`, {
      encoding: 'utf-8',
      cwd: path.join(__dirname, '..'),
      maxBuffer: 10 * 1024 * 1024
    });
  } catch (err) {
    rawOutput = (err.stdout || '') + '\n' + (err.stderr || '');
    if (!rawOutput.includes('issues found') && !rawOutput.includes('No issues found')) {
      console.error(`❌ ERROR CRÍTICO: El comando flutter analyze falló al ejecutarse o retornó salida vacía.`);
      process.exit(1);
    }
  }

  const lines = rawOutput.split('\n');
  const errors = [];
  const currentCounts = {};

  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed) continue;

    // regex: severity - message - path:line:col - code
    const match = trimmed.match(/^(error|warning|info)\s+-\s+(.+)\s+-\s+([^\s:]+):\d+:\d+\s+-\s+([a-z0-9_]+)$/i);
    if (match) {
      const [, severity, message, filePath, code] = match;
      const normalizedPath = filePath.replace(/\\/g, '/');
      const key = `${normalizedPath} - ${code}`;

      if (severity.toLowerCase() === 'error') {
        errors.push({ line: trimmed, key });
      }

      currentCounts[key] = (currentCounts[key] || 0) + 1;
    }
  }

  const totalIssues = Object.values(currentCounts).reduce((a, b) => a + b, 0);
  console.log(`📊 Hallazgos detectados en flutter analyze:`);
  console.log(`   - Errores   : ${errors.length}`);
  console.log(`   - TOTAL     : ${totalIssues}`);

  if (isUpdateMode) {
    let baselineCounts = {};
    if (fs.existsSync(BASELINE_FILE)) {
      try { baselineCounts = JSON.parse(fs.readFileSync(BASELINE_FILE, 'utf-8')); } catch (_) {}
    }
    const addedKeys = [];
    const increasedKeys = [];

    for (const [key, count] of Object.entries(currentCounts)) {
      if (!(key in baselineCounts)) {
        addedKeys.push(`${key} (nuevo: ${count})`);
      } else if (count > baselineCounts[key]) {
        increasedKeys.push(`${key} (${baselineCounts[key]} -> ${count})`);
      }
    }

    console.log(`💾 Guardando línea base congelada en "${BASELINE_FILE}" (${Object.keys(currentCounts).length} llaves únicas)...`);
    if (addedKeys.length > 0) console.log(`   + Llaves agregadas: ${addedKeys.length}`);
    if (increasedKeys.length > 0) console.log(`   + Conteos incrementados: ${increasedKeys.length}`);

    fs.writeFileSync(BASELINE_FILE, JSON.stringify(currentCounts, null, 2), 'utf-8');
    process.exit(0);
  }

  // 1. Errores de compilación son siempre bloqueantes
  if (errors.length > 0) {
    console.error(`❌ SE DETECTARON ${errors.length} ERRORES DE COMPILACIÓN EN FLUTTER:`);
    errors.forEach(e => console.error(`   ${e.line}`));
    process.exit(1);
  }

  // 2. Comparar conteos contra línea base si existe
  if (fs.existsSync(BASELINE_FILE)) {
    const baselineCounts = JSON.parse(fs.readFileSync(BASELINE_FILE, 'utf-8'));
    const increasedOrNew = [];

    for (const [key, currentCount] of Object.entries(currentCounts)) {
      const prevCount = baselineCounts[key] || 0;
      if (currentCount > prevCount) {
        increasedOrNew.push({ key, prevCount, currentCount });
      }
    }

    if (increasedOrNew.length > 0) {
      console.error(`❌ SE DETECTARON ${increasedOrNew.length} REGLAS CON CONTEO INCREMENTADO EN COMPARACIÓN A LA LÍNEA BASE:`);
      increasedOrNew.forEach(item => {
        console.error(`   + AUMENTADO: ${item.key} (anterior: ${item.prevCount}, actual: ${item.currentCount})`);
      });
      process.exit(1);
    }

    console.log(`✅ LÍNEA BASE RESPETADA: 0 reglas con conteo incrementado frente a las firmas congeladas.`);
  } else {
    console.log(`⚠️ No se encontró "${BASELINE_FILE}". Ejecute con --update-baseline para congelar la línea base.`);
  }

  console.log('✅ VERIFICACIÓN DE FLUTTER ANALYZE EXITOSA (0 errores, 0 conteos incrementados).');
  process.exit(0);

} catch (e) {
  console.error('❌ Error no controlado durante la verificación:', e.message);
  process.exit(1);
}
