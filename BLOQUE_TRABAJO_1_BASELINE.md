# 📦 BLOQUE DE TRABAJO 1 - ESTADO INICIAL Y ACCIONES CRÍTICAS
## AURA IA CHAT - Baseline Inicial para Evaluación Post-Fix

---

## 📸 SNAPSHOT ESTADO INICIAL (Baseline)

### Fecha: 2026-08-06
### Commit: `HEAD` (pendiente confirmar hash)
### Entorno: Local `C:\beauty-app\backend` + Railway (pendiente deploy)

---

## 📊 MÉTRICAS BASELINE (Pre-Fix)

| Métrica | Valor Actual | Fuente |
|---------|--------------|--------|
| **RAG Activation Rate** | ~20% | Logs: solo "piel" activa |
| **Chunks/Query (piel grasa acné)** | 0 | Test local: `[]` |
| **Triggers Activos** | 5/25+ | `RAG_TRIGGER_KEYWORDS.length = 5` |
| **Threshold RAG** | 0.72 | `RAG_SIMILARITY_THRESHOLD=0.72` |
| **Chunks en BD** | ~5 | `beauty_knowledge_embeddings` = 5 artículos |
| **Metadata skin_type** | 100% "todas" | Corpus `001_skincare_basics.md` |
| **Triggers Faltantes** | 20+ | "acné", "grasa", "seca", etc. |
| **Threshold Efectivo** | 0.72 | Filtra similarity 0.65-0.71 |
| **RAG en Fallback Gemini** | ❌ No | `geminiService.js:517-622` |
| **Metadata Semántica** | 0% | `ingredients: []`, `contraindications: []` |

---

## 🧪 TEST BASELINE (Ejecutar AHORA - Guardar Output)

```bash
# EJECUTAR EN RAILWAY CONSOLE - GUARDAR OUTPUT COMPLETO
node -e "
const { searchBeautyKnowledge } = require('./src/services/ragService');

const tests = [
  'piel grasa acné',
  'rutina piel seca',
  'bakuchiol embarazo',
  'vitamina C niacinamida',
  'protector solar melasma',
  'retinol purge',
  'ácido hialurónico uso'
];

Promise.all(tests.map(q => 
  searchBeautyKnowledge(q, { topK: 5, threshold: 0.72 })
    .then(r => ({ 
      q, 
      chunks: r.length, 
      topSim: r[0]?.similarity || 0, 
      skins: [...new Set(r.map(c => c.skinType).filter(Boolean))],
      titles: r.map(c => c.title.substring(0,40))
    }))
))
.then(results => {
  console.log('=== BASELINE PRE-FIX ===');
  console.table(results.map(r => ({ 
    Query: r.q.substring(0,22), 
    Chunks: r.chunks, 
    TopSim: r.topSim, 
    SkinTypes: r.skins.join(',') || 'N/A',
    Titles: r.titles.join(' | ')
  })));
  
  const ok = results.every(r => r.chunks >= 3 && r.topSim > 0.7);
  console.log('\n' + (ok ? '✅ PASS' : '❌ FAIL') + ' - Baseline guardado');
  
  // Guardar JSON para comparación posterior
  const fs = require('fs');
  fs.writeFileSync('baseline_pre_fix.json', JSON.stringify({
    timestamp: new Date().toISOString(),
    commit: require('child_process').execSync('git rev-parse HEAD').toString().trim(),
    results,
    passed: ok
  }, null, 2));
  console.log('💾 Guardado: baseline_pre_fix.json');
});
"
```

**Output Esperado Baseline (FALLIDO):**
```
=== BASELINE PRE-FIX ===
┌──────────────────────┬───────┬────────┬──────────┬────────────────────────┐
│ Query                │ Chunks│ TopSim │ SkinTypes│ Titles                 │
├──────────────────────┼───────┼────────┼──────────┼────────────────────────┤
│ piel grasa acné      │ 0     │ 0      │ N/A      │                        │
│ rutina piel seca     │ 0     │ 0      │ N/A      │                        │
│ bakuchiol embarazo   │ 0     │ 0      │ N/A      │                        │
│ ...                  │ 0     │ 0      │ N/A      │                        │
└──────────────────────┴───────┴────────┴──────────┴────────────────────────┘

❌ FAIL - Baseline guardado
```

---

## 🎯 ACCIONES BLOQUE 1 (Ejecutar EN ORDEN)

### ✅ TAREA 1.1: Agregar Triggers (5 min)
**Archivo:** `backend/src/services/geminiService.js:76`
```bash
# Backup
cp backend/src/services/geminiService.js backend/src/services/geminiService.js.bak

# Aplicar patch (ver patch abajo)
```

### ✅ TAREA 1.2: Bajar Threshold (1 min - Railway Dashboard)
```bash
# Railway Dashboard → Variables → Editar:
RAG_SIMILARITY_THRESHOLD=0.65
```

### ✅ TAREA 1.3: Corregir Metadata Corpus (10 min)
**Archivo:** `backend/src/data/beauty_corpus/001_skincare_basics.md`
```bash
cp backend/src/data/beauty_corpus/001_skincare_basics.md backend/src/data/beauty_corpus/001_skincare_basics.md.bak
# Editar frontmatter de cada artículo (ver patch abajo)
```

### ✅ TAREA 1.4: Verificación Post-Fix (5 min)
```bash
# Ejecutar test de validación (ver script abajo)
# Guardar output: baseline_post_fix_fase1.json
```

---

## 📝 PATCHES EXACTOS PARA APLICAR

### PATCH 1: Triggers (`geminiService.js`)
```diff
*** Begin Patch
*** Update File: backend/src/services/geminiService.js
@@ -73,7 +73,22 @@
 /** 
  * Palabras clave que activan la búsqueda RAG de conocimiento técnico de belleza.
  * Ampliar este array si se añaden nuevas categorías de consulta.
  */
 const RAG_TRIGGER_KEYWORDS = ['piel', 'cabello', 'ingrediente', 'ingredientes', 'rutina'];
+const RAG_TRIGGER_KEYWORDS = [
+  'piel', 'cabello', 'ingrediente', 'ingredientes', 'rutina',
+  'acné', 'acne', 'grasa', 'seca', 'mixta', 'sensible',
+  'manchas', 'melasma', 'arrugas', 'envejecimiento', 'antiaging',
+  'protector', 'solar', 'fps', 'limpiador', 'serum', 'crema',
+  'hidratante', 'exfoliante', 'peeling', 'mascarilla',
+  'acne', 'rosacea', 'dermatitis', 'eczema', 'psoriasis',
+  'poros', 'puntos', 'negros', 'blancos', 'comedones',
+  'hiperpigmentacion', 'melasma', 'cloasma', 'pecas',
+  'arrugas', 'lineas', 'expresion', 'flacidez', 'elasticidad',
+  'bakuchiol', 'retinol', 'retinoide', 'tretinoina', 'adapaleno',
+  'niacinamida', 'acido', 'hialuronico', 'salicilico', 'glicolico',
+  'lactico', 'mandelico', 'azelaico', 'tranexamico',
+  'vitamina', 'c', 'e', 'b3', 'b5', 'retinol',
+  'protector', 'solar', 'fps', 'spf', 'uv', 'uva', 'uvb'
+];
*** End Patch
```

### PATCH 2: Corpus Metadata (`001_skincare_basics.md`)
```diff
*** Begin Patch
*** Update File: backend/src/data/beauty_corpus/001_skincare_basics.md
@@ -1,7 +1,10 @@
 ---
 category: skincare
-skin_type: todas
+skin_type: grasa,mixta,acneica,sensible
+ingredients: [niacinamida, ceramidas, zinc]
+contraindications: []
+concerns: [acne, poros, manchas, barrera, envejecimiento]
 season_station: todas
 age_range: todas
 source: glowapp_curated
@@ -17,6 +20,10 @@
 ---
 category: skincare
-skin_type: todas
+skin_type: todas
+ingredients: [retinol, retinoides, ceramidas]
+contraindications: [embarazo, fotosensibilidad, irritacion]
+concerns: [envejecimiento, arrugas, manchas, textura, acne]
 season_station: todas
 age_range: 25+
 source: glowapp_curated
@@ -33,6 +40,10 @@
 ---
 category: skincare
-skin_type: todas
+skin_type: todas
+ingredients: [acido hialuronico, ceramidas, glicerina]
+contraindications: []
+concerns: [deshidratacion, arrugas, elasticidad]
 season_station: todas
 age_range: todas
 source: glowapp_curated
@@ -49,6 +60,10 @@
 ---
 category: skincare
-skin_type: todas
+skin_type: todas
+ingredients: [vitamina c, acido ascorbico, niacinamida]
+contraindications: []
+concerns: [manchas, luminosidad, antioxidante, envejecimiento]
 season_station: todas
 age_range: todas
 source: glowapp_curated
@@ -65,6 +80,10 @@
 ---
 category: skincare
-skin_type: todas
+skin_type: todas, sensible
+ingredients: [bakuchiol, ceramidas, peptidos]
+contraindications: [embarazo: segura]
+concerns: [envejecimiento, arrugas, manchas, sensibilidad]
 season_station: todas
 age_range: todas
 source: glowapp_curated
*** End Patch
```

---

## 📁 ARCHIVOS DE CONTROL (Crear AHORA)

### 1. `baseline_pre_fix.json` - Se genera con test baseline
### 2. `baseline_post_fix_fase1.json` - Se genera tras Fase 1
### 3. `baseline_post_fix_fase2.json` - Tras Fase 2
### 4. `baseline_final.json` - Al final del plan

---

## ✅ CHECKLIST EJECUCIÓN BLOQUE 1

| Paso | Acción | Comando/Archivo | Verificación | Hecho |
|------|--------|-----------------|--------------|-------|
| 1 | Ejecutar Baseline Test | Ver script arriba | `baseline_pre_fix.json` creado | ☐ |
| 2 | Aplicar Patch 1 (Triggers) | `geminiService.js:76` | `git diff` muestra cambios | ☐ |
| 3 | Aplicar Patch 2 (Corpus) | `001_skincare_basics.md` | `git diff` muestra metadata | ☐ |
| 4 | Cambiar Threshold | Railway Variables | `RAG_SIMILARITY_THRESHOLD=0.65` | ☐ |
| 5 | Push + Redeploy | `git push origin main` | Railway deploy success | ☐ |
| 6 | Verificar Migraciones | `npx knex migrate:latest` | Exit 0 | ☐ |
| 7 | Verificar Esquema | `node scripts/verifyRagSchema.js` | Exit 0 | ☐ |
| 8 | Ejecutar Test Post-Fix | Script validación | `baseline_post_fix_fase1.json` | ☐ |
| 9 | Comparar | `diff baseline_pre_fix.json baseline_post_fix_fase1.json` | Chunks ≥3, sim>0.65 | ☐ |

---

## 🎯 CRITERIOS DE ÉXITO FASE 1

| Métrica | Baseline | Objetivo Fase 1 | Verificación |
|---------|----------|-----------------|--------------|
| Chunks "piel grasa acné" | 0 | ≥ 3 | `chunks >= 3` |
| Top Similarity | 0 | > 0.65 | `topSim > 0.65` |
| Skin Types detectados | N/A | `grasa` presente | `skins.includes('grasa')` |
| Triggers activos | 5 | ≥ 25 | `RAG_TRIGGER_KEYWORDS.length` |
| Threshold | 0.72 | 0.65 | Railway Variable |

---

## 🚨 ROLLBACK SI ALGO FALLA

```bash
# Restaurar archivos
cp backend/src/services/geminiService.js.bak backend/src/services/geminiService.js
cp backend/src/data/beauty_corpus/001_skincare_basics.md.bak backend/src/data/beauty_corpus/001_skincare_basics.md

# Restaurar threshold
railway variables set RAG_SIMILARITY_THRESHOLD=0.72 --service api

# Redeploy
git push origin main
```

---

## 📋 PRÓXIMO BLOQUE (Fase 2)

Una vez Fase 1 validada → **Bloque 2: Metadata Semántica + RAG en Fallback**

---

**FIRMA INICIAL:** _______________ **FECHA:** _______________  
**COMMIT INICIAL:** `git rev-parse HEAD` → _______________  
**RAILWAY DEPLOY ID:** _______________