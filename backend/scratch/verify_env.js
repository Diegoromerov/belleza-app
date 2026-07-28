// backend/scratch/verify_env.js
const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');

// Cargar archivo .env (desarrollo o producción)
const envPath = process.argv[2] 
  ? path.resolve(process.argv[2]) 
  : (fs.existsSync(path.resolve(__dirname, '../.env.production')) 
      ? path.resolve(__dirname, '../.env.production') 
      : path.resolve(__dirname, '../.env'));

console.log(`\n🔍 Verificando archivo de entorno: ${envPath}\n`);

if (!fs.existsSync(envPath)) {
  console.error(`❌ El archivo no existe en la ruta: ${envPath}`);
  process.exit(1);
}

const envConfig = dotenv.parse(fs.readFileSync(envPath));

function maskValue(val) {
  if (!val) return '❌ Ausente';
  const str = String(val).trim();
  if (str.length === 0) return '❌ Vacío';
  
  // Detectar si es un marcador de posición no reemplazado
  const placeholders = ['tu_', 'prod_', 'aqui', 'reemplazar', 'real', 'ejemplo'];
  const isPlaceholder = placeholders.some(p => str.toLowerCase().includes(p) && !str.startsWith('sk-') && !str.startsWith('AIza'));
  
  if (isPlaceholder) {
    return `⚠️ ALERTA: Parece un marcador de posición ("${str.substring(0, 15)}...")`;
  }
  
  if (str.length <= 8) {
    return `✅ OK (Longitud: ${str.length} chars)`;
  }
  return `✅ Configurado (${str.substring(0, 4)}...${str.substring(str.length - 4)} | ${str.length} chars)`;
}

const requiredKeys = [
  'NODE_ENV',
  'PORT',
  'DATABASE_URL',
  'REDIS_URL',
  'GEMINI_API_KEY',
  'OPENUV_API_KEY',
  'DEEPSEEK_API_KEY',
  'YOUCAM_API_KEY',
  'JWT_SECRET',
  'ENCRYPTION_KEY',
  'ALLOWED_ORIGINS'
];

let errors = 0;
let warnings = 0;

console.log('--- REPORTE DE VALIDACIÓN DE ARCHIVO .ENV ---');
requiredKeys.forEach(key => {
  const val = envConfig[key];
  const status = maskValue(val);
  console.log(`${key.padEnd(20)} : ${status}`);
  if (status.includes('❌')) errors++;
  if (status.includes('⚠️')) warnings++;
});

console.log('\n---------------------------------------------');
if (errors === 0 && warnings === 0) {
  console.log('🎉 ¡Perfecto! El archivo .env está completamente configurado con claves reales.\n');
} else {
  console.log(`⚠️ Se encontraron ${errors} errores y ${warnings} advertencias (marcadores de posición no reemplazados).\n`);
}
