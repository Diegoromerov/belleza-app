# GLOWAPP — LOGIN SCREEN
# VISUAL ANOMALY SOURCE-OF-TRUTH AUDIT
# READ-ONLY — NO IMPLEMENTATION
# DO NOT MODIFY CODE

## CONTEXTO

GLOWAPP está ejecutándose correctamente en Flutter Web:

@url:`http://localhost:8080/#/login`

La pantalla Login carga correctamente y muestra:

- Logo GlowApp
- Título "INICIAR SESIÓN"
- Campo correo
- Campo contraseña
- Botón "ENTRAR AL RITUAL"
- Recuperación de contraseña
- Componentes S4TextField funcionando

Sin embargo, en la pantalla aparece una anomalía visual:

DOS LÍNEAS DIAGONALES ROJAS atraviesan prácticamente toda la pantalla formando una X:

- una desde la esquina superior izquierda hacia la zona inferior derecha
- otra desde la esquina superior derecha hacia la zona inferior izquierda

La anomalía es claramente visible en ejecución Web.

## OBJETIVO

Determinar exactamente cuál es el origen de esas líneas rojas.

NO corregirlas.
NO modificar código.
NO modificar estilos.
NO modificar Theme.
NO modificar Login.
NO modificar S4TextField.
NO modificar assets.
NO modificar navegación.
NO modificar configuración.
NO implementar ninguna solución.

Este workstream es exclusivamente DISCOVERY / READ-ONLY.

---

# INVESTIGACIÓN

Inspeccionar el código actual y determinar si las líneas provienen de alguno de estos mecanismos:

1. Flutter debug rendering
2. Widget de layout/debug
3. `CustomPaint`
4. `CustomPainter`
5. `Canvas.drawLine`
6. `Border`
7. `ShapeDecoration`
8. `Container` con decoración
9. `Stack`
10. `Positioned`
11. Overlay
12. Error widget
13. `MaterialApp` / `Scaffold`
14. Theme
15. Responsive layout
16. Imagen o asset
17. SVG
18. Background decoration
19. Gesture/debug visualization
20. algún componente reutilizado por Login
21. alguna capa global de la aplicación
22. CSS generado para Flutter Web
23. browser/devtools/debug overlay
24. otro origen no contemplado.

---

# SOURCE OF TRUTH

Buscar referencias reales en el repositorio relacionadas con:

- `drawLine`
- `CustomPaint`
- `CustomPainter`
- `Paint`
- `Colors.red`
- `color: Colors.red`
- `Border`
- `Border.all`
- `debug`
- `debugPaint`
- `showPerformanceOverlay`
- `checkerboard`
- `Stack`
- `Positioned`
- líneas diagonales
- overlays
- decorators
- backgrounds

No limitar la búsqueda exclusivamente a login_screen.dart.

Determinar si el origen está:

A. dentro de Login
B. dentro de un componente reutilizado
C. en Theme / Design System
D. en layout global
E. en configuración Flutter
F. en modo debug
G. en navegador
H. en otro lugar.

---

# REPRODUCCIÓN

Si es posible sin modificar nada:

1. inspeccionar Login
2. determinar qué widget genera las líneas
3. identificar el archivo
4. identificar el widget/clase responsable
5. identificar la propiedad o código responsable
6. explicar por qué aparece en Web.

NO aplicar ningún fix.

---

# MATRIZ DE RESULTADO

Crear una tabla:

| Elemento | Resultado |
|---|---|
| Origen identificado | NOT DETERMINED |
| Archivo | N/A |
| Widget/Clase | N/A |
| Línea aproximada | N/A |
| Propiedad responsable | N/A |
| ¿Es producción o debug? | N/A |
| ¿Afecta solamente Login? | N/A |
| ¿Afecta otras pantallas? | N/A |
| ¿Es intencional? | N/A |
| Severidad | N/A |
| Solución potencial | SOLO DESCRIBIR |
| Requiere modificación | SI/NO |

---

# IMPORTANTE

Si las líneas son intencionales dentro del diseño existente, indicarlo.

Si son un artefacto de debug, demostrarlo.

Si son consecuencia de un error de layout, demostrarlo.

Si no es posible determinarlo con certeza, declarar:

SOURCE_NOT_DETERMINED

y explicar qué evidencia falta.

NO inventar la causa.

---

# GOVERNANCE

Crear únicamente:

docs/governance/implementation/
GLOWAPP_LOGIN_VISUAL_ANOMALY_AUDIT.md

docs/governance/implementation/
glowapp_login_visual_anomaly_audit.json

Los documentos deben contener:

- objetivo
- evidencia
- archivos inspeccionados
- búsqueda realizada
- origen identificado
- causa
- impacto
- clasificación
- recomendación
- estado final.

NO modificar ningún archivo Dart.

NO modificar ningún archivo de configuración.

NO modificar ningún test.

NO modificar assets.

NO realizar ningún fix.

---

# VEREDICTO

Utilizar uno de:

VISUAL_ANOMALY_SOURCE_IDENTIFIED

VISUAL_ANOMALY_CONFIRMED_DEBUG

VISUAL_ANOMALY_CONFIRMED_DESIGN

VISUAL_ANOMALY_CONFIRMED_LAYOUT

VISUAL_ANOMALY_SOURCE_NOT_DETERMINED

Después del diagnóstico:

STOP.

La imagen comunica.
Flutter solo interactúa.
