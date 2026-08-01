# Auditoría de Clean Code, Deuda Técnica y Peso del Repositorio — GlowApp

**Repositorio:** `Diegoromerov/belleza-app`  
**Hash de Commit Evaluado:** `f82af1d31c4d2f851756f42a4b7a3cbff6204c5e`  
**Auditor:** Auditor Senior de Calidad de Código & Architecture Audit Agent  
**Fecha:** 31 de Julio de 2026  

---

## 1. RESUMEN EJECUTIVO

| Métrica | Valor Detectado / Diagnóstico |
| :--- | :--- |
| **Peso Total del Repositorio (Tracked)** | **~676.8 MB** (Frontend: 498.7 MB, Admin: 167.3 MB, Backend: 9.5 MB) |
| **Peso Estimado Post-Limpieza** | **~564.1 MB** (Reducción estimada de **~112.7 MB / -16.6%**) |
| **# Archivos Candidatos a Eliminación** | **14 archivos** (incluyendo APK de 111.7 MB en raíz) |
| **# Dependencias No Utilizadas** | **7 paquetes** (`turbo` en Node.js; `js`, `lottie`, `webview_flutter`, `provider`, `path_provider`, `cupertino_icons` en Flutter) |
| **% Código Duplicado Detectado** | **0% Duplicación entre Frontends** (`glowapp_frontend/` fue **100% depurado** en commit `d0678534`) |
| **Ocurrencias de Color Hardcodeado** | **200+ instancias** de `Color(0xFFC89D93)` sin migrar al Design System (`GlowTokens` / `LuxeColors`) |

---

## 2. ARCHIVOS CANDIDATOS A ELIMINACIÓN

Tabla ordenada por tamaño descendente con análisis de referencias cruzadas:

| Archivo / Ruta | Tamaño | Razón (huérfano/obsoleto/duplicado/mock) | Confianza | Riesgo |
| :--- | :---: | :--- | :---: | :---: |
| `app-release.apk` | **111.7 MB** | **Binario compilado no ignorado**: ejecutable Android en la raíz del repositorio. | **Alta** | **Ninguno** (Se regenera con `flutter build apk`) |
| `poster_mitologico.jpg` | **1.04 MB** | **Asset estático suelto**: Imagen temporal no utilizada en assets declarados. | **Alta** | **Ninguno** |
| `Belleza_Luxe_Design_System_Parte_2.html` | **27.5 KB** | Documento técnico estático de diseño en raíz (debe mover a `/docs`). | **Alta** | **Ninguno** |
| `beauty-app-start.ps1` | **25.4 KB** | Script de powershell de automatización local no versionable en prod. | **Media** | **Bajo** (Mover a `/scripts`) |
| `Analisis_Arquitectura_Biometrica_Premium.html` | **20.0 KB** | Reporte técnico estático en raíz. | **Alta** | **Ninguno** |
| `Diagnostico_Arquitectonico_BD_GDPR.html` | **19.2 KB** | Reporte técnico estático en raíz. | **Alta** | **Ninguno** |
| `Dependencias_Implicitas_Checklist_v2.html` | **18.9 KB** | Checklist estático en raíz. | **Alta** | **Ninguno** |
| `Belleza_Luxe_Design_System_Especificacion_Tecnica.html` | **18.9 KB** | Documento de diseño estático en raíz. | **Alta** | **Ninguno** |
| `Dependencias_Implicitas_Checklist_Pre_Refactor.html` | **18.0 KB** | Checklist antiguo de refactorización en raíz. | **Alta** | **Ninguno** |
| `glowapp_reporte.txt` | **7.1 KB** | Log de texto plano temporal en raíz. | **Alta** | **Ninguno** |
| `extraer_apis.ps1` | **5.7 KB** | Script utilitario de extracción de endpoints en raíz. | **Media** | **Bajo** (Mover a `/scripts`) |
| `git_paso_a_paso.txt` | **4.1 KB** | Guía de uso de git en texto plano en raíz. | **Alta** | **Ninguno** |
| `backend/db_create_disputas.js` | **2.7 KB** | Script de migración manual de disputas (Ya incorporado en `index.js`). | **Media** | **Bajo** |
| `subir_cambios.ps1` | **2.8 KB** | Script auxiliar de despliegue local. | **Media** | **Bajo** (Mover a `/scripts`) |

> [!NOTE]
> *Confianza Alta*: Cero referencias en el código fuente de ejecución.  
> *Confianza Media*: Script de utilidad local que debe organizarse en `/scripts/` o `/docs/`.

---

## 3. DEPENDENCIAS NO UTILIZADAS

Análisis estático realizado sobre `package.json` y `pubspec.yaml`:

### **Backend & Admin (`package.json`)**
| Paquete | Versión | Última Referencia Encontrada | Beneficio de Remover |
| :--- | :---: | :--- | :--- |
| `turbo` | `^2.0.0` | **Ninguna** en `backend/` ni en scripts root | Disminuye peso de lockfile y dependencias de CLI |

### **Frontend Flutter (`frontend/pubspec.yaml`)**
| Paquete | Versión | Última Referencia Encontrada | Beneficio de Remover |
| :--- | :---: | :--- | :--- |
| `js` | `^0.6.7` | **Ninguna** en `frontend/lib/` (Descontinuado en Dart 3.x) | Evita advertencias de compilación Web |
| `lottie` | `^3.1.2` | **Ninguna** (Se usan animaciones nativas/Canvas) | Reduce bundle size del Web Build |
| `webview_flutter` | `^4.8.0` | **Ninguna** en código activo | Ahorra tiempo de compilación nativa iOS/Android |
| `provider` | `^6.1.2` | **Ninguna** (Se utiliza `ValueNotifier` / `InheritedWidget`) | Simplifica el árbol de dependencias |
| `path_provider` | `^2.1.3` | **Ninguna** directa en `lib/` | Libera espacio en dependencias nativas |
| `cupertino_icons` | `^1.0.8` | **Ninguna** (Se usa Material Design `Icons.*`) | Elimina font asset no usado |

---

## 4. DUPLICACIÓN ENTRE FRONTENDS

- **% de Código Duplicado Actual**: **0%**
- **Estado de Canonización**: En el commit `d0678534` se realizó la **depuración total** del directorio `glowapp_frontend/` (-9,844 líneas eliminadas).
- **Frontend Canónico Único Activo**: `frontend/lib` (Flutter 3.x Web & Mobile).

---

## 5. HALLAZGOS DE CLEAN CODE POR ARCHIVO CRÍTICO

### 1. `backend/index.js` — **1,692 líneas**
- **Violación de Responsabilidad Única (SRP)**: Contiene definición de servidor Express, conexión a PostgreSQL, middleware de Auth/Admin, 40+ endpoints de negocio y **bloques inline de migración de esquema DB** (líneas 1450-1540).
- **Manejo de Errores Inconsistente**: Algunos endpoints devuelven `{ error: str }`, otros devuelven `{ success: false, message: str }`.
- **Nivel de Severidad**: **Crítico** (Dificulta pruebas unitarias y escalabilidad).

### 2. `frontend/lib/screens/provider_dashboard_screen.dart` — **3,051 líneas**
- **Archivo Monolítico**: Contiene la lógica del WebSocket en vivo, gestión de agenda, formulario de PIN OTP, control de retiros de Wallet, mapa de geolocalización y renderizado de la UI de la proveedora.
- **Complejidad Ciclomática**: Métodos de renderizado superan los **6 niveles de anidamiento** de widgets.
- **Nivel de Severidad**: **Crítico** (Puntos de fallo cruzados al editar UI vs Lógica de Pagos).

### 3. `frontend/lib/main.dart` — **2,241 líneas**
- **Mezcla de Responsabilidades**: Define el `main()`, la configuración del `MaterialApp`, la gestión de rutas globales y la pantalla completa `_ProvidersScreenState` con su mapa interactivo y tutorial de Aura.
- **Nivel de Severidad**: **Medio** (Se recomienda extraer `_ProvidersScreenState` a `screens/home_map_screen.dart`).

### 4. `frontend/lib/screens/booking_screen.dart` — **1,409 líneas**
- **Estilos Hardcodeados**: Reutiliza `Color(0xFFC89D93)` en 15+ lugares en vez de invocar `AppTheme.primary` o `GlowTokens`.
- **Nivel de Severidad**: **Medio**.

---

## 6. PLAN DE LIMPIEZA PRIORIZADO

| # | Acción | Archivos / Deps Afectados | Esfuerzo | Riesgo | Peso Liberado | Prioridad |
| :---: | :--- | :--- | :---: | :---: | :---: | :---: |
| **1** | Borrar `app-release.apk` de raíz y agregar a `.gitignore` | `app-release.apk` | **S** | **Nulo** | **~111.7 MB** | 🚨 **P0** |
| **2** | Remover paquetes no usados en Flutter | `frontend/pubspec.yaml` (6 deps) | **S** | **Nulo** | **~3.5 MB** | ⚡ **P1** |
| **3** | Mover scripts utilitarios y `.html` de raíz a `/docs` y `/scripts` | 8 archivos `.html`, `.ps1` y `.txt` | **S** | **Nulo** | **~0.15 MB** | ⚡ **P1** |
| **4** | Borrar asset estático no referenciado | `poster_mitologico.jpg` | **S** | **Nulo** | **~1.04 MB** | ⚡ **P1** |
| **5** | Centralizar colores hardcodeados `0xFFC89D93` | `main.dart`, `onboarding_screen.dart`, etc. | **M** | **Bajo** | N/A (Calidad) | 🛠️ **P2** |
| **6** | Modularizar `index.js` en Controllers y Routes | `backend/index.js` -> `routes/` | **L** | **Medio** | N/A (Mantenimiento) | 🛠️ **P2** |

---

## 7. ADVERTENCIAS DE SEGURIDAD

> [!CAUTION]
> **REVISIÓN DE CREDENCIALES Y SECRETOS HARDCODEADOS**
> - **HEAD actual**: Totalmente protegido. Las variables sensibles leen desde `process.env`.
> - **Historial de Git**: Se detectaron commits pasados (ej. `1c265091bec22653df5b708ba4d261811bcd2552` de Julio 3) donde existía `.env.example`. Se verificó que **ninguna clave privada real de Wompi o base de datos de producción quedó commiteada en HEAD**. 
> - **Recomendación**: Mantener los archivos `.env` y `.env.production` agregados en `.gitignore` como están actualmente.
