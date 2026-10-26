# Auditoría: archivos monolíticos y tamaño de compilado

**Repositorio:** `beauty-app` · **App analizada:** `frontend/` (Flutter 3.44 / Dart 3.12)
**Rama:** `main` @ `a2d127776` · **Modo:** auditoría y planificación. **No se modificó código.**

---

## 0. Alcance, método y límites

**Método**

| Qué | Cómo |
|---|---|
| Métricas de código | Conteo de líneas, clases y métodos por archivo; parser de directivas `import`/`export` para detectar código no referenciado |
| Peso de assets | Suma real de bytes de `frontend/assets` e `frontend/images` |
| Peso de compilado | Medición del artefacto existente `frontend/build/web` (build release previo) |
| Dependencias nativas | Lectura de los `build.gradle` reales de cada plugin en la caché de pub |
| Config de build | `android/app/build.gradle.kts`, `gradle.properties`, `local.properties`, `nginx.conf`, `Dockerfile.prod`, `.github/workflows/ci.yml` |
| Verificación | `git status frontend` limpio al terminar (sin cambios en el árbol) |

**Límites declarados (importante)**

1. **No fue posible compilar Android en este equipo.** `android/local.properties` apunta a `D:\Android\Sdk`, que no existe; `ANDROID_HOME` también apunta ahí. El SDK visible (`C:\Android\Sdk`) tiene solo `platforms`, sin `build-tools`, `platform-tools` ni `ndk` (el `ndk.dir` configurado tampoco existe). Por lo tanto **no hay baseline de APK/AAB medido**: todas las cifras de impacto Android de este informe son hipótesis y están marcadas como tales.
2. El build web real (`flutter build web --release`) se lanzó pero quedó bloqueado (procesos `dart` a 0 % CPU, sin avanzar); se canceló. Las cifras web provienen del **artefacto ya existente** en `frontend/build/web` (`main.dart.js` del 16/10/2026), que es coherente con el `pubspec.yaml` actual (los 141 archivos de assets cuadran al byte con lo declarado).
3. Consecuencia: **Fase 0 del plan es hacer el build reproducible y medible.** Sin eso, ninguna cifra de este documento puede convertirse en un gate.

---

## 1. Hechos medidos

### 1.1 Dimensión del código Dart

| Métrica | Valor |
|---|---|
| Archivos `.dart` en `lib/` | 195 |
| Líneas en `lib/` (incluye líneas en blanco) | 75.866 |
| Archivos > 500 líneas | 39 |
| Líneas contenidas en esos 39 archivos | 47.521 (**62,6 %** de `lib/`) |
| Archivos sin ningún importador | 16 (15 reales + `main.dart`) → **3.156 líneas muertas** |
| `StatefulWidget` / `setState` | 153 widgets / 515 llamadas en 71 archivos |
| Uso de Riverpod | 45 referencias (`ref.watch`/`ConsumerWidget`) frente a 515 `setState` |
| `print`/`debugPrint` en producción | 127 |
| Paquetes resueltos (`pubspec.lock`) | 217 (31 dependencias directas) |

### 1.2 Archivos monolíticos (por clase más grande, no por archivo)

| Líneas | Clase más grande | Líneas de esa clase | Archivo |
|---:|---|---:|---|
| 4.732 | `_ProviderDashboardScreenState` | **4.277** | `lib/screens/provider_dashboard_screen.dart` |
| 3.273 | `_ProvidersScreenState` | **2.861** | `lib/main.dart` |
| 2.395 | `_ProviderDetailScreenState` | 2.376 | `lib/screens/provider_detail_screen.dart` |
| 2.409 | `_OnboardingScreenState` | 2.278 | `lib/screens/auth/onboarding_screen.dart` |
| 2.080 | `ApiService` | 2.042 | `lib/services/api_service.dart` |
| 1.887 | `_WalletScreenState` | 1.519 | `lib/screens/wallet_screen.dart` |
| 1.759 | `_BookingScreenState` | 1.724 | `lib/screens/booking_screen.dart` |
| 1.593 | `Token` + 10 clases más | 605 (`TypographyTokens`) | `lib/core/theme/tokens.dart` |
| 1.587 | `GlowIcon` | 1.443 | `lib/design/icons/glow_icon.dart` |
| 1.580 | `_StoreScreenState` | 1.553 | `lib/screens/store_screen.dart` |
| 1.411 | `_ClientBookingsScreenState` | 1.328 | `lib/screens/client_bookings_screen.dart` |
| 1.375 | `_WompiCheckoutWidgetState` | 1.302 | `lib/widgets/wompi_payment_sheet.dart` |

Evidencia de que son *god objects* y no solo archivos largos — responsabilidades mezcladas en una sola clase:

- `_ProvidersScreenState` (`main.dart`) gestiona: permisos GPS y geolocalización, carga y filtrado de proveedores, tutorial/GlowGuide, mutex de guía, alertas SOS, WebSocket de chat, gating de autenticación, navegación, bottom-nav con 4 variantes de item, quick view y tiles mock.
- `_ProviderDashboardScreenState` mezcla: agenda, WebSocket, perfil, ubicación activa, inicio/cierre de servicio, desglose de pagos, notas de cliente, calendario, SOS, analítica y el dashboard completo.

### 1.3 Código muerto (verificado con parser de imports, sin falsos positivos)

15 archivos sin un solo importador, 3.156 líneas:

| Líneas | Archivo |
|---:|---|
| 1.253 | `lib/core/theme/app_theme.dart` — define un `AppTheme` **homónimo** al de `tokens.dart` |
| 444 | `lib/screens/owner/owner_dashboard_screen.dart` |
| 356 | `lib/shared/glow_store_tokens.dart` |
| 316 | `lib/shared/onboarding_helper.dart` |
| 152 | `lib/screens/auth/role_selection_modal.dart` |
| 147 | `lib/services/notification_service.dart` |
| 130 | `lib/screens/ideas/aura_welcome_screen.dart` |
| 106 | `lib/design/components/academy_luxe_components.dart` |
| 66 | `lib/models/glow_cycle_model.dart` |
| 60 | `lib/design/components/s4_loading.dart` |
| 34 | `lib/core/photography/photography_repository.dart` |
| 27 | `lib/core/theme/belleza_luxe_gradients.dart` |
| 24 | `lib/models/glow_product.dart` |
| 21 | `lib/shared/calculations.dart` |
| 20 | `lib/design/icons.dart` |

Notas:
- Hay tests que cubren dos de esos archivos muertos (`owner_dashboard_screen_test.dart`, `aura_welcome_screen_test.dart`): **se está manteniendo y probando código que la app nunca ejecuta**.
- El sistema de diseño está fragmentado en 8 archivos de tema/tokens con solapamiento: `shared/theme.dart` (55 importadores, el de facto), `core/theme/tokens.dart` (21), `core/theme/belleza_luxe_theme.dart` (14), `shared/mens_theme.dart` (6), `shared/glow_tokens.dart` (5), `shared/app_tokens.dart` (1), `core/theme/app_theme.dart` (0), `shared/glow_store_tokens.dart` (0).

### 1.4 Composición del artefacto web (medido)

`frontend/build/web` = **85,97 MB en 181 archivos**

| Componente | MB | % |
|---|---:|---:|
| `canvaskit/` (6 variantes de wasm + `.symbols`) | 36,69 | 42,7 % |
| Assets de la app (vídeo, fuentes, imágenes) | 43,00 | 50,0 % |
| `main.dart.js` | 5,66 | 6,6 % |
| Resto (`index.html`, bootstrap, manifest, icons) | 0,62 | 0,7 % |

Dentro de `assets/` (43 MB, 141 archivos):

| Tipo | Archivos | MB |
|---|---:|---:|
| `.webm` (GlowGuide) | 15 | **30,18** |
| `.ttf` (9 fuentes) | 9 | 4,41 |
| `.mp4` (onboarding) | 1 | 4,20 |
| `.webp` / `.jpg` (imágenes) | 25 | 2,69 |
| `AssetManifest.bin` | 1 | 1,39 |
| `.svg` (iconos) | 80 | 0,03 |
| `.mp3` | 1 | 0,01 |

**El vídeo es el 34,38 MB del bundle: 39,9 % del artefacto web completo.**

Reparto del vídeo:

| Grupo | Archivos | MB |
|---|---:|---:|
| `assets/glowguide/videos/` (cliente, 8 pasos) | 8 | 15,78 |
| `assets/glowguide/videos/provider/` (7 pasos) | 7 | 14,40 |
| `assets/videos/onboarding_intro.mp4` | 1 | 4,20 |

Dentro de `canvaskit/` (36,69 MB) hay **6 builds de wasm** (28,03 MB) y **8,33 MB de `.symbols`**; un solo renderer se usa en runtime.

---

## 2. Lo que NO reduce el tamaño de compilado (verificado, para no gastar esfuerzo)

Estas hipótesis habituales las descarté con evidencia, porque una auditoría honesta debe decir también dónde **no** está el ahorro:

| Hipótesis | Veredicto | Evidencia |
|---|---|---|
| "Declarar `- assets/fonts/` además de `fonts:` duplica las fuentes" | **Falso** | `flutter_tools` deduplica por `entryUri` (`packages/flutter_tools/lib/src/asset.dart:619`). En `build/web/assets/fonts/` hay exactamente 9 `.ttf` = 4,41 MB, no 8,82 |
| "Refactorizar los monolitos reduce el APK" | **Falso** | Dart AOT solo compila lo alcanzable desde `main`; partir un archivo no cambia el conjunto alcanzable ni un byte |
| "Borrar los 15 archivos muertos reduce el binario" | **Casi** | Ya contribuyen 0 bytes (no son alcanzables). El beneficio es mantenibilidad, no tamaño |
| "Minificar Dart / ofuscar reduce tamaño" | **Falso** | `--obfuscate` no reduce; `--split-debug-info` saca símbolos del bundle pero no comprime código |
| "Pasar iconos SVG a red ahorra tamaño" | **No** | Los 80 SVG suman 0,03 MB |

**Distinción crítica que sí importa:** un archivo Dart muerto pesa 0 bytes, pero **una dependencia declarada en `pubspec.yaml` registra su código nativo aunque nunca se importe**. Los plugins se registran por `pubspec`, no por `import`. Ahí sí hay bytes reales.

---

## 3. Mapa de tamaño: dónde están los bytes

```
Bundle web 86 MB
├── 34,4 MB  vídeo empaquetado (webm/mp4)      ← palanca #1
├── 36,7 MB  canvaskit (6 variantes wasm)      ← palanca #2 (deploy, no runtime)
├──  5,7 MB  main.dart.js
├──  4,4 MB  fuentes (3,42 MB solo Cormorant)  ← palanca #3
└──  2,7 MB  imágenes (0,72 MB duplicadas)     ← palanca #4
```

Android (no medido, ordenado por probabilidad de impacto):

```
APK/AAB
├── modelos ML Kit empaquetados (face-detection + barcode)   ← palanca #1 Android
├── vídeo 34,4 MB (idéntico al web)                          ← misma palanca que web
├── sin R8/minify/shrinkResources (release sin ofuscar)       ← palanca #2 Android
├── media3 (exoplayer + dash + hls + rtsp + smoothstreaming)  ← palanca #3 Android
└── AOT de 71k líneas Dart + motor Flutter
```

---

## 4. Estrategia por fases

Orden por **impacto / riesgo / esfuerzo**. Cada fase es independiente y revisable por separado.

### Fase 0 — Baseline reproducible y gate de tamaño (BLOQUEANTE)

Sin esto no hay forma de atribuir ahorros ni de evitar regresiones.

1. Reparar el toolchain Android: instalar `build-tools`, `platform-tools` y el NDK `27.0.12077973` (o corregir `local.properties`/`ndk.dir` al SDK real). Hoy **el release Android no es reproducible en local** y probablemente tampoco en CI (CI solo hace `flutter analyze`).
2. Añadir al job `frontend-ci` (`.github/workflows/ci.yml`, hoy termina en `flutter analyze`):
   - `flutter build web --release` + tabla de tamaños por archivo publicada como artefacto.
   - `flutter build apk --release --analyze-size --target-platform android-arm64` y `flutter build appbundle --release --analyze-size`.
   - Guardar el JSON de `--analyze-size` y **comparar contra un baseline versionado**: falla el PR si el bundle crece > 2 % sin justificación.
3. Publicar la tabla de la sección 1.4 como `SIZE_BASELINE.md` y actualizarla en cada release.
4. Crear `key.properties` (hoy ausente → el release se firma con la config de debug, lo que además invalida cualquier medición de producción).

**Criterio de salida:** un comando local y un job de CI producen números reproducibles de APK, AAB y web.

---

### Fase 1 — Vídeo fuera del bundle (−30,2 MB sin degradar el producto, −34,4 MB si también sale el mp4)

**Mayor impacto de todo el informe y con infraestructura ya existente.**

**Evidencia:**
- Los **mismos 15 webm** existen ya servidos por el backend: `backend/public/assets/assets/glowguide/videos/` (59,5 MB con mp4+webm duplicados) y el backend hace `app.use(express.static(path.join(__dirname,'public')))` (`backend/index.js:381`). Es decir, `https://<backend>/assets/assets/glowguide/videos/step_01_welcome.webm` ya responde.
- La app **no tiene ningún mecanismo de asset remoto**: `VideoPlayerController.asset(...)` es la única vía (`glowguide_presenter.dart:233`, `shared/widgets/background_video_player.dart:38`).

**Plan propuesto:**
1. Reproducir los pasos con `VideoPlayerController.networkUrl` contra el backend, con `flutter_cache_manager` para que el segundo arranque sea offline.
2. Descarga bajo demanda por paso (8 archivos de cliente, 7 de proveedor): el usuario descarga ~2 MB por paso visto, no 30 MB antes de abrir la app.
3. Mantener el `poster` local (ya existe `images/aura_welcome_poster.webp`, 74 KB) como primer frame sin red.
4. Recomprimir antes de publicar: VP9/AV1 a 720p. Los actuales pesan ~2,4 MB cada uno.
5. **Corregir un bug detectado de paso:** `glowguide_presenter.dart:90` usa `assets/glowguide/videos/aura_pilot.webm` como fallback y **ese archivo no existe** en `frontend/assets` (sí existe en `.mp4` y en el backend). Hoy el fallback está roto.

**Riesgos:** la guía deja de funcionar offline en el primer uso; en web hay que respetar CORS. Mitigación: caché en disco + poster + timeout con reintento.

**Riesgo de mantenimiento a documentar:** `provider_guide.dart:35` construye la ruta del vídeo por interpolación (`step_${order}_${section}`). Cualquier herramienta de poda automática de assets **no puede** ver esas 7 referencias: si algún día se mueven a red, hay que tocar el generador de rutas, no solo el `pubspec`.

---

### Fase 2 — Fuentes (−3,0 a −3,3 MB)

**Evidencia:** `CormorantGaramond-{Regular,Medium,Bold}.ttf` = 1.168 KB **cada uno** (3,42 MB, el 78 % del peso de fuentes) para una app en español. Ese tamaño por peso es desproporcionado para el uso real: el conteo de glifos efectivamente usados debe medirse con el subsetting (hipótesis a confirmar, no hecho verificado).

**Plan:**
1. Subsetear a Latin-1 + puntuación española (`pyftsubset` / `glyphhanger`). Objetivo ~120-200 KB por peso → **ahorro esperado 2,9-3,1 MB** (hipótesis a verificar con la medición de Fase 0).
2. Evaluar si los 3 pesos de Cormorant se usan de verdad (55 archivos la referencian; hay que comprobar cuántos usan `Medium`).
3. `JetBrainsMono` (2 pesos, 366 KB) solo aparece en 13 archivos: validar si es esencial o decorativa.
4. Considerar una única variable font si se necesitan los 3 pesos.

---

### Fase 3 — Imágenes y basura del bundle (−0,7 MB)

**Evidencia (archivos realmente presentes en `build/web/assets/images`):**

| Archivo duplicado | Copias en el bundle | KB |
|---|---|---:|
| `login_background.jpg` | `images/` + `images/auth/` | 302 |
| `register_concierge_background.jpg` | `images/` + `images/auth/` | 518 |
| `register_concierge_background.webp` | `images/` + `images/auth/` | 144 |
| `onboarding_bg.webp` | `images/` + `images/auth/` | 160 |
| `metadata.json` | `images/` | 10 |

Causa: `pubspec.yaml` declara `images/` **y** `images/auth/` por separado, y existen copias en ambas.

Sobre `metadata.json`: su único lector es `core/photography/photography_repository.dart:17`, y ese archivo está en la lista de código muerto (§1.3). Es decir, se empaqueta y no llega a usarse nunca.

**Plan:** unificar rutas a una sola copia, convertir `aura_welcome_background.jpg` (405 KB, el archivo más pesado) a WebP/AVIF, y sacar `metadata.json` del bundle junto con el resto del código muerto.

---

### Fase 4 — Configuración de build Android (impacto por medir; estimación 5-12 MB, **hipótesis**)

**Evidencia:** `android/app/build.gradle.kts` en `buildTypes.release` define **solo** `signingConfig`. No hay `isMinifyEnabled`, ni `isShrinkResources`, ni reglas ProGuard, ni `abiFilters`, ni `splits`.

Propuestas (todas verificar con `--analyze-size` antes y después):

1. **R8 + shrinkResources**: `isMinifyEnabled = true`, `isShrinkResources = true`, `proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")`. Es la palanca estándar no aplicada.
2. **ML Kit no empaquetado** — la palanca más grande probable en Android:
   - `mobile_scanner 7.4.0` declara por defecto el modelo **empaquetado** (`com.google.mlkit:barcode-scanning:17.3.0`) y solo usa el de Play Services si se pasa la propiedad `dev.steenbakker.mobile_scanner.useUnbundled=true` (`mobile_scanner/android/build.gradle:63-69`). Añadirla a `gradle.properties`.
   - `google_mlkit_face_detection 0.10.1` depende de `com.google.mlkit:face-detection:16.1.6` (modelo empaquetado). Sustituir por `com.google.android.gms:play-services-mlkit-face-detection` (modelo descargado por Play Services) excluyendo el artefacto empaquetado.
   - **Contrapartida real:** requiere Google Play Services; en dispositivos sin GMS (o emuladores sin Play) la detección de rostro/escaneo deja de funcionar. Decisión de producto, no solo técnica.
3. **Podar media3**: `video_player_android` arrastra `media3-exoplayer-{hls,dash,rtsp,smoothstreaming}` y `just_audio` arrastra `{dash,hls,smoothstreaming}`. La app solo reproduce archivos locales (`webm`/`mp4`/`mp3`), no HLS/DASH/RTSP. Excluir esas extensiones vía `configurations.all { exclude(...) }` en `build.gradle.kts`.
4. **Distribución**: si se publica **AAB**, los splits de ABI/lenguaje/densidad ya los hace Play (no tocar). Si se publica **APK universal**, usar `--split-per-abi` (ahorro típico 10-15 MB por descarga, hipótesis).
5. **Dependencia muerta confirmada**: `share_plus: ^12.0.2` está declarada y tiene **0 imports** en `lib/`. Sus AARs se empaquetan igual. Quitarla.
6. Revisar `pubspec.yaml`: `http_parser: any` y `fake_async: any` usan `any` (reproducibilidad), y `build_runner` está como `dev_dependency` (no afecta al binario).

---

### Fase 5 — Entrega web: caché y compresión (impacto en transferencia real, no en el artefacto)

**Evidencia en `frontend/nginx.conf`:**

```nginx
location / {
    add_header Cache-Control "no-cache, no-store, must-revalidate";   # ← todo el sitio
    try_files $uri $uri/ /index.html;
}
location ~* \.(?:css|png|jpg|jpeg|gif|ico|svg|ttf|woff|woff2)$ { expires 1d; ... }
gzip_types ... application/javascript ...;   # sin application/wasm
```

Dos defectos de alto impacto acumulado:

1. **Nada está cacheado salvo 9 extensiones.** `main.dart.js`, `canvaskit.js`, `canvaskit.wasm`, **`.webm`**, **`.mp4`**, **`.webp`** caen en `location /` → `no-store`. Un usuario recurrente **vuelve a descargar 40+ MB en cada visita**. Más caro que cualquier reducción del artefacto.
2. **`wasm` no se comprime.** `canvaskit.wasm` (6,89 MB) viaja sin gzip; comprime a ~2 MB. Falta `application/wasm` en `gzip_types` (y no hay brotli).

**Plan:**
- Cachear `immutable, max-age=31536000` los archivos con hash/versión (`main.dart.js`, `canvaskit/*`, `assets/*`) y dejar solo `index.html`, `flutter_bootstrap.js` y `flutter_service_worker.js` en `no-store`.
- Añadir al regex de caché `webm|mp4|webp|wasm|otf|json`.
- Añadir `application/wasm` a gzip (o brotli) y `gzip_min_length`.
- Podar variantes no usadas de `canvaskit` en el `Dockerfile.prod` (`.symbols`, `skwasm*`, `wimp*`, `experimental_webparagraph/`, y `chromium/` si no se sirve): **−29 MB de imagen de despliegue**; el navegador solo descarga la que usa.
- **Inconsistencia de puerto detectada:** `Dockerfile.prod` termina en `FROM nginx:alpine` + `EXPOSE 80` y `docker-compose.prod.yml` publica `80:80`, pero `nginx.conf` solo declara `listen 8080; listen 3000;`. Tal como está, el contenedor no escucha en el puerto 80 que se publica. Confirmar en el despliegue real de Railway antes de tocar nada.

---

### Fase 6 — Monolitos: disciplina, no bytes

**Declaración explícita: esta fase NO reduce el tamaño de compilado.** Se incluye porque es el otro objetivo del encargo y porque es *condición para la Fase 1/4* (mover features a carga diferida o retirar dependencias exige fronteras de módulo que hoy no existen).

Orden por evidencia (líneas de la clase principal):

| Prioridad | Archivo | Clase | Líneas | Extracción propuesta |
|---|---|---|---:|---|
| P0 | `main.dart` | `_ProvidersScreenState` | 2.861 | Sacar a `lib/features/map/`: controlador de geolocalización, controlador de proveedores/filtros, coordinador de tutorial, servicio SOS, navegación. `main.dart` debe quedar en bootstrap + shell |
| P0 | `provider_dashboard_screen.dart` | `_ProviderDashboardScreenState` | 4.277 | Dividir en sub-widgets por sección del dashboard (agenda, pagos/payout, próximas citas, analítica), cada uno con su propio estado y controlador |
| P1 | `services/api_service.dart` | `ApiService` | 2.042 | Fachada delgada + clientes por dominio (`bookings_api`, `payments_api`, `store_api`, `saas_api`, `support_api`) manteniendo la firma pública actual para no tocar llamadas |
| P1 | `provider_detail_screen.dart` | `_ProviderDetailScreenState` | 2.376 | Extraer slivers, galería, reseñas y bloque de reserva (encaja con el contrato de diseño de `AGENTS.md`) |
| P1 | `booking_screen.dart` | `_BookingScreenState` | 1.724 | Extraer los 3 pasos (Cuándo y Dónde / Productos / Confirmación) como widgets con estado propio, preservando la lógica de negocio intacta |
| P2 | `auth/onboarding_screen.dart` | `_OnboardingScreenState` | 2.278 | Separar páginas del onboarding (4-5 pantallas) y el flujo de permisos |
| P2 | `wallet_screen.dart`, `store_screen.dart`, `client_bookings_screen.dart`, `chat_screen.dart` | estados | 1.269-1.553 | Mismo patrón sección-por-widget |

**Beneficio real esperado:** revisión de PRs por unidad, tests por sección (hoy hay 32 archivos de test para 71k líneas), reducción del coste de `flutter analyze`, y base para `deferred as` en el flujo `ideas` (cámara/VTO/scanner), que es lo único que sí puede mejorar arranque.

**Reglas de la fase (alineadas con `AGENTS.md`):** sin cambios de contrato de API, sin reescritura estilística, un archivo por PR, y `flutter analyze` + tests en worktree temporal antes de proponer el patch.

---

## 5. Presupuesto objetivo y métricas de aceptación

| Artefacto | Hoy (medido) | Objetivo propuesto | Cómo se verifica |
|---|---:|---:|---|
| Bundle web en disco | 85,97 MB | **≤ 45 MB** | `flutter build web` + tabla por archivo |
| Assets de vídeo en el bundle | 34,38 MB | **0 MB** | `build/web/assets/**/*.{webm,mp4}` vacío |
| Fuentes en el bundle | 4,41 MB | **≤ 1,6 MB** | subset verificado glifo a glifo |
| Transferencia inicial web (sin caché) | ~7 MB + media | **≤ 8 MB** | DevTools/Lighthouse |
| Transferencia en visita recurrente | ~40 MB (sin caché por `no-store`) | **≈ 0 MB** | cabeceras + DevTools |
| APK arm64 / AAB | **no medido** | definir tras Fase 0 | `--analyze-size` |

**Gate de CI:** el PR falla si el bundle web crece > 2 % o si aparece cualquier `.webm`/`.mp4` en `assets/`.

---

## 6. Riesgos y decisiones que requieren dueño de producto

| Riesgo | Impacto | Mitigación |
|---|---|---|
| Guía GlowGuide deja de funcionar offline | Alto (UX de primer uso) | caché persistente + poster local + reintento; decidir si el primer paso se queda embebido (~2,4 MB) |
| ML Kit sin Play Services en dispositivos sin GMS | Alto (función VTO/escáner rota) | medir cobertura de mercado; mantener empaquetado si no es aceptable |
| Excluir extensiones de media3 | Medio (formatos futuros) | documentar que solo se soportan archivos locales |
| Refactor de monolitos introduce regresiones | Medio-alto | worktree temporal, tests por sección, un archivo por PR |
| Build Android no reproducible | Bloquea todo lo anterior | Fase 0 es bloqueante |

---

## 7. Qué NO hacer (descartado con evidencia en §2)

- No refactorizar para "reducir el APK": no reduce.
- No mover los 80 SVG (0,03 MB) a red.
- No eliminar fuentes duplicadas: no lo están.
- No tocar `camera` + `google_mlkit_face_detection` + `mobile_scanner` como "dependencias no usadas": están todas alcanzables desde la navegación (`main.dart:61` → `ideas/welcome_screen` → `capture_screen`; `main.dart:361` `/makeup-lookbook` → `vto_live`; `results_screen.dart:775` → `product_scanner`).
- No confundir `--obfuscate` con reducción de tamaño.

---

## 8. Anexo — comandos de medición para la Fase 0

```powershell
# 1. Baseline Android (requiere SDK + build-tools + NDK)
flutter build apk --release --split-per-abi --analyze-size
flutter build appbundle --release --analyze-size

# 2. Baseline web
flutter build web --release
Get-ChildItem build\web -Recurse -File |
  Group-Object { $_.Directory.Name } |
  ForEach-Object { [pscustomobject]@{ Dir=$_.Name; MB=[math]::Round(($_.Group|Measure-Object Length -Sum).Sum/1MB,2) } }

# 3. Baseline de dependencias (para atribuir bytes a plugins)
flutter pub deps --style=compact

# 4. Tamaño de código y monolitos (el que se usó en esta auditoría).
#    Ojo: Measure-Object -Line NO cuenta líneas en blanco. Usar .Count del array.
Get-ChildItem lib -Recurse -Filter *.dart |
  ForEach-Object { [pscustomobject]@{ Lines=(Get-Content $_.FullName).Count; File=$_.FullName } } |
  Sort-Object Lines -Descending | Select-Object -First 20
```

**Orden de ejecución recomendado:** Fase 0 → Fase 1 → Fase 5 → Fase 2 → Fase 4 → Fase 3 → Fase 6.
(Fase 5 se adelanta porque es barata, de riesgo casi nulo y su impacto en transferencia real supera al de Fase 2 y 4.)

---

*Auditoría sin modificación de código. `git status frontend` limpio. Ninguna credencial, `.env` ni dato de usuario incluido en este documento.*
