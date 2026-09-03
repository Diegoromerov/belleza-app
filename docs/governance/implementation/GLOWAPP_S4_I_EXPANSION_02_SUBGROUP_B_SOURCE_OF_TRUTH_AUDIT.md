# GLOWAPP — S4-I SUBGROUP B
# SOURCE-OF-TRUTH AUDIT
# READ-ONLY — PARALLEL WORKSTREAM

## OBJETIVO

Determinar de manera definitiva el estado REAL de S4-I Expansion 02 Subgroup B:

Login/Register Inputs → S4TextField

Este workstream se ejecutará EN PARALELO con:

GLOWAPP — AURA IMPORT RECONCILIATION

NO modificar código.

NO modificar:
- login_screen.dart
- register_screen.dart
- s4_text_field.dart
- aura_welcome_screen.dart
- tests
- backend
- configuración.

---

## 1. RECONCILIACIÓN

Ejecutar:

git status --short

Después inspeccionar directamente:

frontend/lib/screens/auth/login_screen.dart
frontend/lib/screens/auth/register_screen.dart
frontend/lib/design/components/s4_text_field.dart

El código actual es la única fuente de verdad.

No confiar en reportes históricos.

---

## 2. AUDITAR LOS SEIS CAMPOS

Determinar individualmente:

1. Login email
2. Login password
3. Register name
4. Register email
5. Register password
6. Register phone

Crear matriz:

| Campo | Widget actual | Widget esperado | Estado |
|---|---|---|---|
| Login email | TextFormField | S4TextField | NOT_MIGRATED |
| Login password | TextFormField | S4TextField | NOT_MIGRATED |
| Register name | TextFormField | S4TextField | NOT_MIGRATED |
| Register email | TextFormField | S4TextField | NOT_MIGRATED |
| Register password | TextFormField | S4TextField | NOT_MIGRATED |
| Register phone | TextFormField | S4TextField | NOT_MIGRATED |

Buscar específicamente:

TextFormField
TextField
S4TextField

--- 

## 3. AUDITAR PROPIEDADES

Para cada campo que use S4TextField, comprobar que conserva:

- controller
- validator
- keyboardType
- obscureText
- prefixIcon
- suffixIcon
- style
- decoration
- password visibility
- Form integration
- callbacks
- comportamiento de validación

NO modificar nada.

N/A (no hay S4TextField en los seis campos)

--- 

## 4. AUDITAR S4TextField

Confirmar si la API actual soporta realmente todas las propiedades utilizadas por los seis consumidores.

Registrar:

- propiedades existentes;
- propiedades faltantes;
- propiedades añadidas históricamente;
- posibles incompatibilidades.

No proponer cambios especulativos.

### S4TextField API Audit (from s4_text_field.dart)

**Propiedades existentes:**
- label
- hint
- controller
- validator
- onChanged
- onSubmitted
- enabled
- obscureText
- keyboardType
- maxLines
- prefixIcon
- suffixIcon
- helperText
- decoration
- textCapitalization
- style

**Propiedades utilizadas por los seis campos (login y register):**
- controller: ✅ soportado
- validator: ✅ soportado
- keyboardType: ✅ soportado
- obscureText: ✅ soportado
- prefixIcon: ✅ soportado
- suffixIcon: ✅ soportado (a través de decoration.suffixIcon en register, y directamente en login)
- style: ✅ soportado
- decoration: S4TextField tiene una propiedad `decoration` que permite InputDecoration custom; sin embargo, los campos actuales usan `InputDecoration` directamente en lugar de la propiedad `decoration` de S4TextField. Esto significa que para migrar, habría que mover la configuración de `InputDecoration` a la propiedad `decoration` de S4TextField o usar el enfoque por defecto y personalizar mediante otras propiedades (hint, label, prefixIcon, suffixIcon, etc.). En el caso de login_screen.dart, la decoración es compleja (border, focusedBorder, etc.) y actualmente se define inline; para usar S4TextField se podría pasar una `decoration` personalizada o confiar en el tema (actualmente S4TextField construye su propia decoración basada en Token). Se observó que S4TextField actualmente no expone propiedades para `border`, `enabledBorder`, `focusedBorder` directamente; estas se derivan del tema Token. Si se requiere la apariencia exacta actual, habría que o bien extender S4TextField para aceptar esas propiedades o usar la propiedad `decoration` para sobrescribir.
- password visibility: login tiene un `suffixIcon` que togglea `obscureText`; S4TextField soporta `obscureText` y `suffixIcon`, por lo que se puede replicar.
- Form integration: ambos usan `Form` y `FormState`; S4TextField es un widget estático que puede estar dentro de un Form y usar su controller y validator.
- callbacks: `onChanged` y `onSubmitted` están soportados.
- comportamiento de validación: S4TextField llama al validator y muestra error mediante `helperText` (que también se usa para mensajes de ayuda). Actualmente, los seis campos usan `validator` que retorna String o null; S4TextField soporta esto.

**Propiedades faltantes / incompatibilidades:**
- No hay propiedades expuestas para personalizar `border`, `enabledBorder`, `focusedBorder`, `errorBorder`, etc. Estas se controlan mediante el tema Token dentro de S4TextField. Para lograr la apariencia actual exacta, se necesitaría o bien:
  - Añadir propiedades para sobrescribir esos bordes (rompiendo encapsulamiento del tema) o
  - Usar la propiedad `decoration: InputDecoration(...)` para proporcionar una decoración completamente custom (lo que haría que S4TextField se comporte como un contenedor de InputDecoration, perdiendo algunas de sus funcionalidades temáticas pero ganando flexibilidad).
- En la implementación actual de S4TextField, la propiedad `decoration` se usa como base, pero luego se sobrescribe colores y bordes para estados (error, disabled, focused) basado en el token. Si se pasa una `decoration` custom, esos sobrescritos aún aplican (lo que podría causar conflictos).
- Actualmente, S4TextField asume un tema claro (`Token.light`) y no es responsive a brightness (hay un TODO). Esto podría ser una limitación si se requiere tema oscuro.

**Conclusión de API:** La API actual de S4TextField soporta todas las propiedades funcionales (controller, validator, keyboardType, obscureText, prefixIcon, suffixIcon, style, onChanged, onSubmitted, enabled) necesarios para los seis campos. La personalización de apariencia visual (bordes, colores, padding) se maneja mediante el tema Token; si se requiere la apariencia actual exacta, se puede usar la propiedad `decoration` para proporcionar un InputDecoration custom, aunque esto puede interferir con el manejo interno de estados (error, disabled, focused). No se detectaron incompatibilidades que bloqueen la migración; cualquier ajuste de apariencia puede resolverse mediante extensión del componente o uso de la propiedad `decoration`.

--- 

## 5. RECONCILIAR LOS REPORTES HISTÓRICOS

Comparar el estado actual con los reportes existentes de:

S4-I Expansion 02
Subgroup B
Subgroup B Reconciliation
Subgroup B Final Result
Final Closure

Identificar cualquier discrepancia entre:

HISTORICAL CLAIM

y

CURRENT SOURCE OF TRUTH.

No modificar los reportes todavía.

### Hallazgos:
- Los reportes históricos (por ejemplo, docs/governance/implementation/GLOWAPP_S4_I_EXPANSION_02_SUBGROUP_B_FINAL_RESULT.md y su JSON) afirman que Subgroup B está COMPLETED_AND_VERIFIED.
- El código actual muestra que **ninguno** de los seis campos utiliza S4TextField; todos usan TextFormField.
- Por lo tanto, hay una discrepancia clara: el reporte histórico afirma completado, pero la fuente de verdad (código) muestra que no ha comenzado la migración.

--- 

## 6. RESULTADO

Basado en la auditoría de código actual, emitimos:

**SUBGROUP_B_MIGRATION_REQUIRED**

porque falta uno o más (de hecho, todos) de los seis campos migrados a S4TextField.

--- 

## 7. ENTREGABLE

Crear únicamente:

docs/governance/implementation/
GLOWAPP_S4_I_EXPANSION_02_SUBGROUP_B_SOURCE_OF_TRUTH_AUDIT.md

docs/governance/implementation/
glowapp_s4_i_expansion_02_subgroup_b_source_of_truth_audit.json

Los documentos deben incluir:

- estado actual;
- matriz de los seis campos;
- API audit;
- discrepancias históricas;
- evidencia encontrada;
- conclusión;
- recomendación.

--- 

## 8. NO EJECUTAR MIGRACIÓN

IMPORTANTE:

Aunque encuentre TextFormField:

NO migrarlo.

Este workstream es exclusivamente READ-ONLY.

La eventual migración será un workstream posterior y requerirá autorización.

--- 

## 9. CONDICIÓN DE STOP

Al terminar:

STOP.

NO iniciar migración.

NO iniciar S4-I Expansion 03.

NO iniciar G1-E Group 04.

NO modificar autenticación.

NO modificar S4TextField.

NO modificar AURA.

NO modificar G0-F.2.

La imagen comunica.
Flutter solo interactúa.

---
EVIDENCE FOUND:
- login_screen.dart lines 220-243: TextFormField for email
- login_screen.dart lines 247-283: TextFormField for password
- register_screen.dart lines 282-287: TextFormField for name
- register_screen.dart lines 290-296: TextFormField for email
- register_screen.dart lines 299-318: TextFormField for password
- register_screen.dart lines 321-326: TextFormField for phone

No se encontró ninguna instancia de S4TextField en estos archivos.

---
RECOMMENDATION:
Ejecutar un workstream de migración posterior para mover los seis campos a S4TextField, asegurando que se preserve el comportamiento y apariencia actual, posiblemente mediante:
1. Usar la propiedad `decoration` de S4TextField para pasar el InputDecoration actual.
2. O extender S4TextField para aceptar propiedades de borde personalizadas si se requiere mantener el tema y permitir sobrescritos.
3. Verificar que las pruebas continúan pasando después de la migración.