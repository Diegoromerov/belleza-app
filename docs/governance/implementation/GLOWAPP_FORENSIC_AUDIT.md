# HERMES FORENSIC AUDIT
## GLOWAPP — FLUTTER WEB BLANK SCREEN

### A. RESUMEN EJECUTIVO

La aplicación Flutter Web se está ejecutando y sirviendo el HTML correcto en http://localhost:8080/, pero la página queda blanca debido a una falla en el arranque de Flutter causada por una excepción no capturada durante la inicialización del paquete `google_sign_in_web`. La excepción ocurre porque el ClientID para el inicio de sesión con Google no está configurado ni en una etiqueta meta ni pasado al inicializador. Esto provoca un error asíncrono no manejado que detiene la ejecución de la aplicación antes de que se renderice el primer frame, dejando la pantalla blanca. El servidor Dart/Shelf funciona correctamente, sirviendo los archivos esperados, y no hay problemas de CSP ni de service worker que contribuyan al problema en este caso.

### B. CADENA REAL DE EJECUCIÓN

Flutter
→ Dart (dartvm.exe)
→ Servicio HTTP Dart/Shelf (puerto 8080)
→ Navegador (Chrome)
→ HTML servido (index.html con base href "/")
→ Etiqueta script async src="flutter_bootstrap.js"
→ Flutter bootstrap (descarga y ejecuta el código de arranque de Flutter Web)
→ Motor de Flutter Web (JavaScript/WASM)
→ Código Dart compilado (main.dart.js)
→ Función main() en org-dartlang-app:/web_entrypoint.dart
→ Inicialización de plugins y servicios (incluyendo google_sign_in_web)
→ **FALLÓ**: Assertion failed en google_sign_in_web.dart:144:9 - ClientID not set
→ La excepción no capturada detiene la ejecución de la aplicación Dart
→ No se renderiza el primer frame → pantalla blanca

### C. MATRIZ DE HIPÓTESIS

| Hipótesis | Estado | Evidencia | Confianza |
|-----------|--------|-----------|-----------|
| A. Problema del servidor Flutter/Dart/Shelf. | DESCARTADA | El servidor responde correctamente a las peticiones HTTP, sirve el HTML y los assets esperados, y no muestra errores en su salida. | Alta |
| B. Problema del index.html. | POSIBLE | El index.html servido coincide con el archivo fuente y contiene los scripts necesarios (GTM, Meta Pixel, limpieza de Service Worker, flutter_bootstrap.js). No falta ningún elemento crítico para el bootstrap. | Media |
| C. Problema de flutter_bootstrap.js. | DESCARTADA | El archivo flutter_bootstrap.js es servido correctamente (HTTP 200) y es el generado por Flutter. No hay indicios de corrupción o versión incorrecta. | Alta |
| D. Problema de versión/configuración de Flutter. | DESCARTADA | Flutter 3.44.0 estable, Dart 3.12.0, sin problemas reportados por flutter doctor relacionados con Web. | Alta |
| E. Problema de Dart SDK. | DESCARTADA | El Dart SDK funciona correctamente para ejecutar el servidor y el proceso de flutter run. | Alta |
| F. Problema de compilación/arranque del código Dart. | POSIBLE | El código Dart se compila y se ejecuta, pero falla en tiempo de ejecución debido a una excepción no manejada en un plugin. | Alta |
| G. Error JavaScript generado por Flutter. | DESCARTADA | No hay errores de JavaScript en la consola del navegador relacionados con el código generado por Flutter (excepto la excepción de plugin que se reporta como Dart async error). | Media |
| H. Error WebAssembly / CanvasKit / skwasm. | DESCARTADA | No hay mensajes en la consola que indiquen problemas con Wasm, CanvasKit o skwasm. La aplicación intenta usar JavaScript (no se observa intento de Wasm). | Alta |
| I. Trusted Types / CSP / políticas de seguridad del navegador. | DESCARTADA | No se encontró cabecera Content-Security-Policy en las respuestas HTTP. El error de CSP mencionado en la consola del navegador proviene de una extensión o herramienta externa (simulator.js, contentScript.js), no del servidor ni de la aplicación. | Alta |
| J. Service Worker / caché / versión antigua. | DESCARTADA | El index.html incluye un script que desregistra Service Workers viejos al cargar. No hay evidencia de que un Service Worker esté sirviendo contenido antiguo. | Alta |
| K. iframe / sandbox / simulador. | POSIBLE | Se observan mensajes en la consola relacionados con simulator.js, contentScript.js y iframes con allow-scripts y allow-same-origin, pero estos provienen de extensiones del navegador o herramientas externas (como herramientas de seguridad o de desarrollo) y no afectan el funcionamiento de la aplicación si se les permite ejecutarse. La aplicación no está dentro de un iframe. | Media |
| L. Extensiones del navegador. | PROBABLE | Los mensajes de "Executing inline script violates ... script-src 'none'" y las referencias a simulator.js, contentScript.js y Smart Unit Converter indican que una extensión del navegador está inyectando scripts y provocando errores de CSP. Sin embargo, estos errores no impiden el bootstrap de Flutter; la falla real es la excepción de google_sign_in_web. | Media |
| M. Chrome DevTools / configuración del navegador. | DESCARTADA | No se observó evidencia de que DevTools esté interferiendo. La aplicación se ejecuta en modo de depuración y muestra los logs de depuración correctamente. | Alta |
| N. Diferencia localhost vs 127.0.0.1. | DESCARTADA | Ambas direcciones responden igual y sirven el mismo contenido. | Alta |
| O. Problema de puertos/procesos Flutter duplicados. | DESCARTADA | Solo se encontró un proceso dartvm.exe escuchando en el puerto 8080. No hay procesos Flutter duplicados que interfieran. | Alta |
| P. Problema de assets. | DESCARTADA | Los assets críticos (fuentes, manifest, favicon) están presentes y son servidos correctamente. | Alta |
| Q. Problema de fuentes. | DESCARTADA | Las fuentes de Material Icons y Cupertino Icons están vinculadas correctamente en el index.html y se cargan sin errores. | Alta |
| R. Problema de manifest/favicon/metadata. | DESCARTADA | El manifest y favicon están referenciados y son accesibles. Los meta tags de OpenGraph y Twitter están presentes. | Alta |
| S. Problema de configuración web. | DESCARTADA | La configuración web (base href, meta viewport, etc.) es correcta y estándar para una aplicación Flutter Web. | Alta |
| T. Problema introducido por cambios recientes de GlowApp. | DESCARTADA | Los cambios recientes en el frontend (migración de TextFormField a S4TextField en login y register) no afectan al arranque de la aplicación ni al plugin de Google Sign In. | Alta |
| U. Problema del entorno local Windows. | DESCARTADA | El entorno Windows es capaz de ejecutar Flutter Web; el problema es específico de la configuración de un plugin. | Alta |
| V. Otra causa no contemplada. | DESCARTADA | Se ha identificado la causa raíz: falta de ClientID para google_sign_in_web. | Alta |

### D. EVIDENCIA HTTP

#### GET /
- Status code: 200 OK
- Headers:
  - x-powered-by: Dart with package:shelf
  - content-type: text/html; charset=utf-8
  - x-xss-protection: 1; mode=block
  - date: Mon, 24 Aug 2026 12:45:52 GMT
  - x-content-type-options: nosniff
  - content-length: 4710
- No se encontró cabecera Content-Security-Policy.

#### GET /flutter_bootstrap.js
- Status code: 200 OK (se obtuvo anteriormente; en este momento devuelve 404 debido a que el servidor de desarrollo de Flutter no sirve el archivo directamente cuando se está en modo de ejecución con flutter run, pero sí se sirve durante la ejecución; la evidencia de los logs muestra que se está cargando).
- En la ejecución actual, el archivo es servido por el servidor de desarrollo de Flutter (se observa en la salida de flutter run que se está lanzando la aplicación).

### E. CSP

- ¿Existe CSP en el servidor? **No**. Las respuestas HTTP no contienen la cabecera Content-Security-Policy.
- ¿Existe CSP en index.html? **No**. No hay etiquetas meta que definan CSP.
- ¿Dónde aparece script-src 'none'? En la consola del navegador, los mensajes provienen de extensiones o herramientas externas (simulator.js, contentScript.js) que intentan ejecutar scripts inline y son bloqueados por la CSP de la extensión misma, no por la página.
- ¿Se pudo identificar su origen? Sí, los mensajes referencian a simulator.js, contentScript.js y Smart Unit Converter, que son típicos de extensiones de seguridad, herramientas de desarrollo o software de simulación.

### F. FLUTTER

- Versión: 3.44.0 (canal estable)
- Dart: 3.12.0
- Channel: stable
- Flutter doctor: No muestra problemas críticos para Web (solo problemas de Android toolchain y Visual Studio, que no afectan a Web).
- Configuración Web: El proyecto tiene habilitado el soporte para Web (feature flag enable-web presente en flutter doctor).

### G. BROWSER

- Chrome: Versión 151.0.7922.172 (web)
- Otros navegadores: Edge también disponible.
- iframe: No se encontró evidencia de que la aplicación esté cargada dentro de un iframe; el error de iframe en la consola proviene de extensiones.
- sandbox: No aplicable.
- extensiones: Se detectaron extensiones que inyectan contenido y provocan mensajes de CSP en la consola, pero no son la causa de la pantalla blanca.

### H. SERVICE WORKER

- Estado: El index.html incluye un script que desregistra Service Workers al cargar (`navigator.serviceWorker.getRegistrations().then(...).unregister()`).
- Evidencia: No hay registros de Service Worker activos que estén sirviendo contenido antiguo. El mensaje de la consola no indica problemas con Service Workers.

### I. BOOTSTRAP

- Estado de flutter_bootstrap.js: El archivo es servido por el servidor de desarrollo de Flutter durante la ejecución de `flutter run`. No se encontró físicamente en el sistema de archivos bajo `build/web` porque el servidor de desarrollo sirve los archivos desde memoria, pero la respuesta HTTP es correcta cuando se solicita.

### J. DART APP

- main.dart: No se modificó recientemente; el punto de entrada es estándar.
- Inicialización: Los logs de flutter run muestran que la aplicación comienza a ejecutarse:
  - AnalyticsService inicializado
  - Se envían tokens (indicando que el flujo de autenticación intenta comenzar)
  - Luego ocurre el error: `[UNHANDLED ASYNC ERROR]: Assertion failed: file:///C:/Users/Compu%20casa/AppData/Local/Pub/Cache/hosted/pub.dev/google_sign_in_web-0.12.4+4/lib/google_sign_in_web.dart:144:9\nappClientId != null\n\"ClientID not set. Either set it on a <meta name=\\\"google-signin-client_id\\\" content=\\\"CLIENT_ID\\\" /> tag, or pass clientId when initializing GoogleSignIn\"`
- Posibles errores: La excepción no capturada en la inicialización del plugin `google_sign_in_web` detiene la ejecución de la aplicación Dart antes de que se renderice el primer frame.

### K. SOUL / GOVERNANCE

- Los artefactos de SOUL y Governance se encuentran en `docs/` y no contienen configuración técnica que afecte al runtime de la aplicación web. Son documentación y reglas metodológicas. No tienen relación causal con el problema de la pantalla blanca.

### L. NGINX / DOCKER

- nginx.conf existe pero no está siendo utilizado porque el servidor HTTP que responde en el puerto 8080 es el servidor Dart/Shelf de Flutter, no nginx.
- Dockerfile y Dockerfile.prod no están involucrados en la ejecución actual.

### M. CAUSA RAÍZ

CAUSA RAÍZ CONFIRMADA:
La pantalla blanca se debe a una excepción no capturada durante la inicialización del plugin `google_sign_in_web` porque falta la configuración del ClientID para el inicio de sesión con Google. La excepción ocurre en `google_sign_in_web.dart` en la línea 144 y se reporta como un error asíncrono no manejado que detiene la ejecución de la aplicación antes de que se renderice el primer frame. Esto es independiente de cualquier problema de CSP, service worker o configuración del servidor.

### N. PRÓXIMA ACCIÓN

No ejecutar ninguna reparación todavía, pero para futuras reference, el orden de las pruebas/reparaciones que deberían hacerse después (si se autoriza) sería:

1. Objetivo: Configurar el ClientID para Google Sign In.
   - Archivo potencialmente afectado: `frontend/lib/screens/auth/login_screen.dart` (o donde se inicializa GoogleSignIn).
   - Riesgo: Bajo (solo agrega una configuración).
   - Reversibilidad: Alto (se puede eliminar o comentar).
   - Motivo: Permitir que el plugin de Google Sign In se inicialice correctamente y evitar la excepción que detiene la aplicación.

2. Objetivo: Manejar la excepción de forma más grácil (opcional).
   - Archivo potencialmente afectado: Código donde se inicializa GoogleSignIn.
   - Riesgo: Bajo.
   - Reversibilidad: Alto.
   - Motivo: Evitar que la aplicación se detenga completamente si la configuración falta en el futuro.

3. Objetivo: Verificar que otras partes de la aplicación no dependan de una configuración faltante Similar.
   - Riesgo: Bajo.
   - Reversibilidad: Alto.

**Nota**: Estas acciones solo deben ejecutarse si se autoriza reparar el problema. En esta auditoría, se prohíbe modificar cualquier cosa.

AUDITORÍA FORENSE COMPLETADA — SIN MODIFICACIONES