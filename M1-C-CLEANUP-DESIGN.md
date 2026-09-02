# M1-C — Cleanup Design Plan

## 1. OBJETIVO
Establecer el plan seguro de eliminación por lotes y definir las salvaguardas de reversibilidad.

## 2. PLAN DE ELIMINACIÓN SEGURO (SAFE CLEANUP BATCHES)

* **Lote 1 (Raíz - Python):** Eliminar los 50 scripts `*.py` de la raíz generados durante migraciones anteriores de menú y botones.
* **Lote 2 (Frontend - Python):** Eliminar los 55 scripts `*.py` en `frontend/lib/screens/`.
* **Lote 3 (Backups & Broken):** Eliminar los archivos `.backup*`, `.original`, `.broken` en `frontend/lib/screens/` y `backend/src/services/`.
* **Lote 4 (Temporales y Tests Manuales en Raíz):** Eliminar `test_change.txt`, `test_output.txt`, `test-parseint.js`, `test-userid-validation.js`, `test-validation.js`, `test_F7.001-F.6.1-C.js`, `test_resilience_e2e.js`, `provider_detail.patch`, `IMPLEMENTACION_COMPLETADA.txt`.

## 3. SALVAGUARDAS Y REVERSIBILIDAD
* Todos los archivos a eliminar están registrados en el historial de Git anterior al commit baseline `a5acf71a` y pueden ser recuperados mediante `git checkout <commit> -- <file>` si fuera necesario.
* **Cero impacto en Glow IA+ / RAG / Biometría / Marketplace.**

## 4. ESTADO DEL GATE
🟢 **PASS**
