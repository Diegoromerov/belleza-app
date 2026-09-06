# GLOWAPP — G1-E
# QUALITY DEBT GROUP 03
# DISCOVERY ONLY — READ-ONLY

## BASELINE

Ejecutar: `flutter analyze`

Resultado: **848 issues** (ver salida completa en logs).

## INVENTARIO Y CLASIFICACIÓN

Los problemas encontrados se clasifican de la siguiente manera (según la salida de `flutter analyze`):

- **A — compilación**: Errores como `Target of URI doesn't exist: 'package:freezed_annotation/freezed_annotation.dart'` y `Undefined name 'freezed'` (dependencias faltantes).
- **B — corrección segura/localizada**: Sugerencias de tipo `prefer_const_constructors`, `unused_import`, `deprecated_member_use`. Son cambios mecánicos que no alteran el comportamiento.
- **C — dependencia**: Paquetes como `freezed_annotation` no declarados en `pubspec.yaml`.
- **D — deprecated APIs**: Uso de miembros obsoletos como `withOpacity`, `scale`, `activeColor`, `trackColor`.
- **E — const/style**: Sugerencias para agregar `const` a constructores y literales.
- **F — imports**: Importaciones sin usar (p.ej., `dart:math`).
- **G — arquitectura/deuda mayor**: No se observaron en esta tanda (los errores de dependencia podrían llevar a problemas mayores si no se resuelven, pero están clasificados como C).

## SELECCIÓN DE CANDIDATOS CLASS B

Se eligieron los siguientes problemas, cumpliendo con los criterios de ser inequívocos, de solución mecánica, sin cambio de comportamiento y sin afectar áreas protegidas (S1/S2/S3/S4, backend, auth, booking, payments, RAG/AURA):

| # | Descripción | Archivo | Líneas (aprox.) | Tipo de fix |
|---|-------------|---------|-----------------|-------------|
| 1 | Eliminar importación no usada `dart:math` | `lib/widgets/aura_3d_emblem.dart` | 1:8 | `unused_import` |
| 2 | Reemplazar uso deprecated `scale` por `scaleByDouble` | `lib/widgets/aura_3d_emblem.dart` | 88:17 | `deprecated_member_use` |
| 3 | Reemplazar `withOpacity` por `withValues` (2 ocurrencias) | `lib/widgets/product_quick_view_dialog.dart` | 36:24, 277:46 | `deprecated_member_use` |
| 4 | Añadir `const` a constructores donde corresponda (varias) | `lib/widgets/booking_recovery_banner.dart` | 35:15, 36:15, 40:26, 50:23, 55:11, 58:20, 60:11, 70:19, 73:22 | `prefer_const_constructors` |
| 5 | Añadir `const` a constructores donde corresponda (varias) | `lib/widgets/floating_navigation_dock.dart` | 40:15, 104:15, 107:24, 110:26 | `prefer_const_constructors` |

## VERIFICACIÓN DE EXCLUSIONES

Se excluyeron explícitamente los archivos mencionados en la consigna:
- `login_screen.dart`
- `register_screen.dart`
- `s4_text_field.dart`
- `ai_search_bar.dart`
- componentes modificados recientemente por S4-I (ninguno de los archivos seleccionados aparece en esa lista).

## PROPUESTA DE EJECUCIÓN

Para cada candidato, aplicar el cambio sugerido por el analyzer:
- Remover la línea de importación no utilizada.
- Reemplazar llamadas a miembros deprecated con su equivalente moderno.
- Añadir la palabra clave `const` a las invocaciones de constructores que lo permitan.

Los cambios son locales, de bajo riesgo y no modifican la lógica de negocio ni los contratos de API.

## RIESGO

**Riesgo mínimo**. Todas las correcciones son de estilo o de migración de APIs deprecated a sus reemplazos recomendados por el framework. No se altera el flujo de ejecución ni el estado de la aplicación.

## JUSTIFICACIÓN

Estos problemas pertenecen a la categoría **Class B**: son correcciones seguras y localizadas que mejoran la calidad del código sin introducir cambios funcionales. Resolverlos contribuye a reducir la deuda de calidad y mejora la mantenibilidad.

## EXCLUSIONES

Se excluyeron los archivos protegidos y aquellos con cambios recientes de S4-I, así como los relacionados con login, registro y campos de texto S4, tal como se指示 en el workstream.

## PRÓXIMOS PASOS

Si se aprueba esta selección, el siguiente workstream (ejecución) podría aplicar los cambios listados arriba y volver a ejecutar `flutter analyze` para verificar la reducción de issues.

---
**G1-E GROUP 03 = READY_FOR_EXECUTION**