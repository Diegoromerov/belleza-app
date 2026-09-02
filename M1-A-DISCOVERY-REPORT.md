# M1-A — Discovery & Inventory Report

## 1. OBJETIVO
Realizar el inventario exhaustivo de archivos huérfanos, scripts temporales de migración, backups manuales y artefactos generados en `C:\beauty-app` sin ejecutar eliminaciones todavía.

## 2. INVENTARIO DE ARTEFACTOS HUÉRFANOS Y TEMPORALES IDENTIFICADOS (E0)

### 2.1. Scripts de Migración en la Raíz (`C:\beauty-app\*.py`, `*.js`, `*.txt`)
* **Scripts Python de reemplazo/migración de iconos y botones:**
  - `clean_duplicates.py`, `cleanup_menu_format.py`, `convert_aura_welcome_bg.py`, `convert_concierge_bg.py`, `convert_new_concierge_bg.py`, `convert_register_bg.py`, `debug.py`, `do_replace.py`, `final_cleanup.py`, `final_cleanup2.py`, `final_fix.py`, `final_migration.py`, `final_migration_correct.py`, `final_migration_script.py`, `final_replace.py`, `fix_blank_lines.py`, `fix_buttons.py`, `fix_buttons_regex.py`, `fix_button_assignments.py`, `fix_duplicate_method.py`, `fix_extra_parens.py`, `fix_formatting.py`, `fix_format_final.py`, `fix_iconwidget_calls.py`, `fix_menu_formatting.py`, `fix_menu_method.py`, `fix_menu_method2.py`, `fix_provider_buttons.py`, `fix_register.py`, `insert_missing_buttons.py`, `migrate_buttons.py`, `migrate_menu.py`, `migrate_menu_correct.py`, `migrate_menu_final.py`, `migrate_menu_final2.py`, `migrate_menu_final3.py`, `migrate_menu_final4.py`, `migrate_menu_simple.py`, `migrate_remaining.py`, `remove_duplicates.py`, `remove_duplicate_block.py`, `remove_duplicate_method_body.py`, `replace_assets.py`, `replace_icons.py`, `replace_inputs.py`, `replace_provider_buttons.py`, `replace_provider_exact.py`, `update_buttons.py`, `update_provider_detail.py`, `update_provider_detail_fixed.py`.
* **Archivos temporales de texto y diagnóstico:**
  - `test_change.txt`, `test_output.txt`, `IMPLEMENTACION_COMPLETADA.txt`, `provider_detail.patch`, `nul`.
* **Scripts de testing manual en raíz (no referenciados por npm test):**
  - `test-parseint.js`, `test-userid-validation.js`, `test-validation.js`, `test_F7.001-F.6.1-C.js`, `test_resilience_e2e.js`.

### 2.2. Scripts y Backups en Frontend (`frontend/lib/screens/`)
* **Scripts Python auxiliares:**
  - 55 scripts `.py` (`apply_changes.py`, `final_migration.py`, `provider_detail_screen_*.py`, etc.).
* **Archivos `.backup*` y `.original`:**
  - `provider_detail_screen.dart.backup2`
  - `provider_detail_screen.dart.backup3`
  - `provider_detail_screen.dart.backup_before_const_fix`
  - `provider_detail_screen.dart.backup_before_f14_1`
  - `provider_detail_screen.dart.backup_before_fix`
  - `provider_detail_screen.dart.backup_before_replace`
  - `provider_detail_screen.dart.backup_before_update2`
  - `provider_detail_screen.dart.backup_constfix`
  - `provider_detail_screen.dart.backup_imports`
  - `provider_detail_screen.dart.backup_imports2`
  - `provider_detail_screen.dart.original`
  - `frontend/lib/main.dart.backup`

### 2.3. Backups en Backend (`backend/src/services/`)
* `AutomaticRetentionService.js.backup*`
* `geminiService.js.backup`
* `resilienceService.js.backup`, `resilienceService.js.broken`
* `youcam.client.js.backup`

## 3. ESTADO DEL GATE
🟢 **PASS** (Inventario 100% catalogado con evidencia directa E0).
