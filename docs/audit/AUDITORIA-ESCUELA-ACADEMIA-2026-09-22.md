# Auditoría "ESCUELA" (Academia Glow / GlowAcademy) — Belleza App

**Fecha:** 2026-09-22 · **Repo auditado:** `C:\beauty-app` @ `d018587d` (clon autoritativo)
**Método:** lectura de código + replay real de las migraciones en PostgreSQL 16.15 aislado (contenedor temporal, ya eliminado) + contraste con `backend/backup_beauty_db.sql` (dump de producción, 01-sep-2026).

**Etiquetas de evidencia**
- `[V]` verificado ejecutando código/SQL (replay PG o queries verbatim de los endpoints).
- `[D]` verificado contra el dump de producción `backend/backup_beauty_db.sql`.
- `[L]` leído en el código (no ejecutado).

---

## T1 — Ubicación del código de "Escuela" dentro de beauty-app

No existe la palabra "escuela" en el código: el feature se llama **Academia Glow / GlowAcademy / Glow Academy Pro** (`academy*`, `learning*`).

### Backend (Node/Express)

| Archivo | LOC | Estado | Montaje |
|---|---|---|---|
| `backend/src/routes/academyRoutes.js` | 284 | **VIVO** | `backend/index.js:399` `/api/academy` |
| `backend/src/routes/academyAdminRoutes.js` | 498 | **VIVO** | `backend/index.js:400` `/api/admin/academy` |
| `backend/src/routes/learningPathRoutes.js` | 60 | **MUERTO** (no montado) y **roto**: `:8` requiere `../models/academy_courses`, archivo inexistente `[V]` | — |
| `backend/src/controllers/learningPathController.js` | 67 | **MUERTO**, duplicado literal de `learningPathRoutes.js` | — |
| `backend/src/models/LearningPath.js` / `PathCourse.js` | 18 / 16 | modelos del layer Pro | — |
| `backend/src/models/QrCertificate.js` | — | usado por `glowProRoutes.js` | `index.js:401` `/api/glow-pro` |
| `backend/src/controllers/xpLogController.js` + `routes/xpLogRoutes.js` | — | montado `index.js:409` `/api/xp-logs`, **roto** (ver B15) | — |

Migraciones que crean el dominio (solo `backend/migrations/*.sql`; el runner corre los 3 runners filtrando `.sql`):

| Migración | Contenido |
|---|---|
| `008_academia_glow.sql` | 5 tablas base + `academy_certificates` + seeds de 2 cursos, módulos, lecciones y quizzes |
| `023_glow_academy_pro.sql` | 14 tablas "Pro": `learning_paths`, `path_courses`, `xp_logs`, `user_levels`, `badges`, `community_*`, `portfolios`, `mentorship_sessions`, `qr_certificates`, `events`, `event_registrations`, `analytics_events`, `app_locales`, `user_consents` |
| `025_curso_colorimetria_cabello.sql` | curso `...003` + 2 módulos + 3 lecciones + 2 quizzes |
| `026_curso_colorimetria_completo.sql` | 3 tablas nuevas (`academy_consentimientos`, `academy_worksheet_submissions`, `academy_ai_discrepancy_log`) + re-seed de 9 módulos / 15 lecciones del curso `...003` |
| `033_add_id_academy_certificates.sql` | intenta añadir `id` y cambiar la PK |
| `034_add_fks_to_academy_tables.sql` | intenta añadir 3 FKs (a `badges`, `badges`, `academy_certificates.id`) |
| `20260716220001-create-academy_certificates.js`, `20260716220939-create-learning_paths.js` | **nunca se ejecutan** (los runners solo aceptan `.sql`) `[L]` |

### Frontend (Flutter)

| Archivo | LOC | Estado |
|---|---|---|
| `frontend/lib/screens/academy/academy_screen.dart` | 268 | hub **vivo** (`main.dart:265` `/provider/academy`; `provider_dashboard_screen.dart:2426` y botón central `:2582-2586`) |
| `frontend/lib/screens/academy/glow_color_screen.dart` | 15 | puente: redirige a `CourseDetailScreen(courseId: 'c0000000-…-0003')` hardcodeado |
| `frontend/lib/screens/academy/course_detail_screen.dart` | 398 | **vivo** (consume `/api/academy/courses/:id`) |
| `frontend/lib/screens/academy/quiz_screen.dart` | 367 | **vivo** (consume quiz + submit) |
| `frontend/lib/screens/academy/glow_consent_widget.dart` | 140 | **vivo** (Ley 1581) |
| `frontend/lib/screens/academy/glow_nback_screen.dart` / `glow_beauty_screen.dart` | 402 / 183 | vivos pero **100% locales** (juego N-Back, tutoriales), sin backend |
| `frontend/lib/screens/academy/course_list.dart` | 208 | **HUÉRFANO**: nadie lo importa `[V]` |
| `frontend/lib/screens/academy/lesson_view.dart` | 214 | **HUÉRFANO**: solo lo importa `course_list.dart` `[V]` |
| `frontend/lib/widgets/academy/progress_card.dart` | 81 | solo usado por el huérfano `course_list.dart` |
| `frontend/lib/design/components/academy_luxe_components.dart`, `glow_glass_card.dart` | 106 / 29 | UI |

### Admin (Next.js)

| Archivo | LOC | Estado |
|---|---|---|
| `admin-dashboard/src/app/(dashboard)/admin/academia/page.tsx` | 357 | listado + stats + delete (vivo) |
| `admin-dashboard/src/app/(dashboard)/admin/academia/[id]/page.tsx` | 1425 | editor (módulos/lecciones/quizzes) con `// @ts-nocheck` en `:1` |
| `admin-dashboard/src/app/(dashboard)/admin/academia/nuevo/page.tsx` | 262 | alta de curso |
| `Sidebar.tsx`, `(auth)/login/page.tsx` | 110 / 106 | navegación y redirect |

### Contenido (offsets de la "escuela")

| Fuente | Qué es |
|---|---|
| `docs/academy/modulo-1/leccion-1..4-*.md` | las **4 únicas** lecciones con contenido real (Módulo 1, teoría del color) |
| `docs/modulo-1-urls.md` | 45 fuentes recopiladas del Módulo 1 |
| `backend/data/corpus/colorimetria_capilar_tinte_auto_*.json` | 1113 archivos de corpus para el RAG (no ligados a `academy_lessons`) `[V]` |
| `backend/scripts/buildCanonicalCorpus.js`, `ingest_json_chunks.js` | pipeline del corpus RAG, **no** de la academia |

> La tabla `academy_lessons` solo aparece en `academyRoutes.js` y `academyAdminRoutes.js`: **el contenido de la escuela no entra al RAG** `[V]`.

---

## T2 — Lectura interpretativa: qué hace y cómo lo hace

### Qué es
Una **escuela profesional embebida en la app de prestadores** ("Academia Glow"): cursos → módulos → lecciones → cuestionario → insignia/certificado, con un módulo de cumplimiento (bioseguridad) y otro de colorimetría con consentimiento de datos biométricos. Es la pieza que da el "sello" de la plataforma: certificar a las estilistas antes de dejarlas atender clientas a domicilio.

Hoy conviven **dos mitades que apenas se tocan**:

1. **Mitad real (backend + admin + `course_detail_screen` + `quiz_screen`)**: todo vive en PostgreSQL.
   - Autoría: `/api/admin/academy/*` CRUD de cursos, módulos, lecciones, quizzes y stats, consumido por el dashboard Next.
   - Alumno: `/api/academy/courses` (lista + progreso + `has_certificate`), `/api/academy/courses/:id` (módulos con lecciones y estado), `/api/academy/lessons/:id/complete` (upsert idempotente en `academy_progress`), `/api/academy/courses/:id/quiz` + `/submit-quiz` (califica, y si supera umbral inserta en `academy_certificates`).
   - Cumplimiento: `/api/academy/consent` (+ `/status`) y `/worksheets/submit` (exige consentimiento vigente para subir fotos) y `/ai-discrepancy/log`.
2. **Mitad escaparate (Flutter)**: `glow_nback_screen`, `glow_beauty_screen`, `course_list.dart`/`lesson_view.dart` no llaman a ninguna API: pintan datos inventados (incluido `_completedLessonIndices = {0}` que muestra la lección 1 como ya vista).

### Cómo lo hace (flujo real, verificado en código)
```
provider_dashboard_screen.dart:2426 / 2582  →  AcademyScreen (hub)
   ├─ tarjeta "Entrenamiento Cognitivo" → GlowNBackScreen (local, sin backend)
   ├─ tarjeta "Belleza & Educación"     → GlowBeautyScreen (local, sin backend)
   └─ tarjeta "Colorimetría Capilar"    → GlowColorScreen → CourseDetailScreen('c0000000-…-0003')  ← único curso alcanzable
            GET /api/academy/courses/:id            → curso + módulos + lecciones + hasCertificate
            (lección id a0000000-…-0000 → GlowConsentWidget → POST /api/academy/consent)
            POST /api/academy/lessons/:id/complete  → academy_progress
            si TODAS las lecciones están completas y no hay certificado → botón "Tomar Examen"
            QuizScreen → GET /quiz → POST /submit-quiz → INSERT academy_certificates (85 líneas de UI de "insignia desbloqueada")
```
- **Datos**: seeds en SQL (`008`, `025`, `026`) aplicados en **cada arranque** del backend (`index.js:1627-1650`, orden alfabético, errores "ya existe" ignorados).
- **Criterio de aprobación**: `QUIZ_PASS_PCT` con default 80 (`academyRoutes.js:250`); la variable **no está definida en ningún `.env`/workflow** `[V]`.
- **Certificado**: fila en `academy_certificates (provider_id, course_id, obtained_at)` + `badge_name` del curso. No hay PDF, URL ni QR.
- **Admin**: 3 pantallas que consumen CRUD; el editor de curso usa `@ts-nocheck`.

### Diagnóstico interpretativo
Es un **MVP de LMS de autoría interna**: el modelo de datos está bien pensado para lo que hace (progreso idempotente, umbral configurable, emisión única de certificado), pero está **a medio construir en las tres dimensiones que importan para una escuela que certifica**: (a) el contenido no vive en la base (placeholders + video Rick Astley), (b) no hay *gating* server-side de ningún tipo (ni prerrequisitos, ni consumo, ni intentos), y (c) el certificado no es un artefacto verificable, así que no sirve como credencial ante clientes/empleadores. Al mismo tiempo, el andamiaje "Pro" (paths, XP, badges, QR certificates, foros, mentorías) está **declarado en migraciones pero sin tablas en producción ni API funcional**: es deuda de producto, no capacidad instalada.

---

## T3 — Benchmarking: prácticas buenas y mejorables

### Contra quién se compara
| Referente | Qué aporta al benchmark |
|---|---|
| **Moodle** (activity completion, restrict access, course completion criteria) | la gramática estándar de "completar y desbloquear" en un LMS |
| **Teachable / Thinkific** (course compliance: passing grade, retake limit, randomización de preguntas) | el patrón de "no avanzas si no apruebas" para cursos de creador |
| **1EdTech Open Badges 2.0/3.0 + CTDL** | el estándar de credencial verificable: assertion hospedada o firmada, verificación pública, revocación |
| **SCORM / xAPI / cmi5** | telemetría de consumo y "registration" (matrícula) como entidad de primer nivel |
| **Wella ED / Wella Color Expert / L'Oréal ACCESS** | cómo la industria belleza estructura certificación por niveles (Insider → Specialist → Expert), blended y comunidad |
| **Ley 1581 de 2012 (Colombia) + SIC** | datos biométricos = sensibles; consentimiento previo, explícito e informado; finalidad; retención; revocación |

### Buenas prácticas que el código YA tiene
| # | Práctica | Evidencia | Referente que la respalda |
|---|---|---|---|
| 1 | Jerarquía normalizada curso→módulo→lección con `sort_order` y CASCADE | `008:4-27` | Moodle/SCORM (estructura de curso) |
| 2 | Progreso idempotente por alumno+lección con PK compuesta | `008:29-35` + `academyRoutes.js:97-102` (`ON CONFLICT DO UPDATE`) | "activity completion" de Moodle |
| 3 | Umbral de aprobación configurable por entorno | `academyRoutes.js:250` | passing grade de Teachable/Thinkific |
| 4 | Emisión única del certificado (una assertion por alumno+curso) | `academyRoutes.js:255-259` (`ON CONFLICT DO NOTHING`, PK compuesta) | Open Badges (no duplicar assertions) |
| 5 | Banco de preguntas separado del alumno y **respuesta correcta no enviada al cliente** | `academyRoutes.js:207-210` (solo `id, question, options`) | higiene anti-fuga de exámenes |
| 6 | **Verificación server-side del consentimiento biométrico** antes de aceptar evidencias fotográficas | `academyRoutes.js:159-163` (y `026:14-25` con FK al consentimiento) | Ley 1581 art. 5-6: es el único punto del repo donde el consentimiento se comprueba en el servidor, no solo en la UI |
| 7 | Autorización por router en el admin (no ruta por ruta) | `academyAdminRoutes.js:10` `router.use(authMiddleware, adminMiddleware)` | evita el fallo clásico de olvidar una ruta |
| 8 | Separación consentimiento/evidencia/calificación (worksheets con `calificado`, `calificacion_nota`, `retroalimentacion`) | `026:14-25` | rúbrica/asignaciones de Thinkific |
| 9 | Log de discrepancias IA-vs-humano para reentrenamiento | `026:28-36` + `academyRoutes.js:184-193` | MLOps: captura de ground truth |

### Prácticas que se pueden mejorar (ordenadas por impacto)
| # | Hueco | Estado actual (evidencia) | Práctica de referencia | Dirección de mejora |
|---|---|---|---|---|
| 1 | **No hay *gating* server-side** | `submit-quiz` no consulta `academy_progress` (`academyRoutes.js:222-282`); `courses/:id` entrega `content_text` y `video_url` de todas las lecciones aunque no estén desbloqueadas (`:54-62`) | Moodle *restrict access* / Teachable *course compliance* | Rechazar el examen sin curso completo + no enviar el contenido de lecciones bloqueadas |
| 2 | **Examen trivialmente vulnerable** | 2 preguntas fijas por curso, intentos ilimitados, sin tiempo, sin pool (`academyRoutes.js:204-282`) | LearnPress/Thinkific: pool + randomización + límite de intentos | Banco de ≥20 preguntas por curso, N aleatorias, máx. 3 intentos, registro de intentos |
| 3 | **No existe matrícula (enrollment)** | "inscritos" se deriva de `academy_progress` (`academyAdminRoutes.js:43-49`); no hay `academy_enrollments` | SCORM/cmi5 *Registration* | Tabla de matrícula con estado, origen y fechas → habilita cohortes, drip, becas, revocación de acceso |
| 4 | **"Completado" auto-declarado** | el alumno sólo pulsa "Marcar como Completada" (`course_detail_screen.dart:282-290`) | cmi5: statements `initialized/completed` desde el reproductor | Registrar tiempo de consumo desde el player (o exigir % de video) para que la formación obligatoria sea auditable |
| 5 | **Certificado no verificable** | fila + `badge_name`, sin URL/QR/firma (`academyRoutes.js:255-269`); existe `qr_certificates` (`023:97`) sin usar | Open Badges 2.0 hospedado o firmado (JWS/Ed25519) + página `verify/<id>` sin login + fecha de última verificación | `certificate_id`, `verification_url`, `qr_code`, endpoint público de verificación y estado `valid/revoked` |
| 6 | **Borrado en cascada de credenciales** | `DELETE /courses/:id` borra progreso y certificados (`008:29-44` + `academyAdminRoutes.js:154-168`) | Open Badges: revocar (`revokedAssertions`), no borrar | Soft-delete del curso + estado `REVOKED` con motivo |
| 7 | **Sin analítica de aprendizaje** | `/stats` sólo cuenta filas (`academyAdminRoutes.js:451-497`) | xAPI/LRS | Tablas de intentos + tasas de aprobación/abandono por lección |
| 8 | **Contenido fuera de la base** | 15 lecciones con `CONTENIDO_LECCION_*_AQUI` `[V]`; todas las `video_url` apuntan a `youtube.com/watch?v=dQw4w9WgXcQ` `[V]`; el contenido real está en `docs/academy/` (4 lecciones) | CMS/CLI de publicación con fuente única | Script `publish-lesson` que sube los `.md` a `academy_lessons` (y alimenta el RAG) en lugar de un `INSERT` en migración |
| 9 | **Sin versionado del currículo** | `academy_modules`/`lessons` sin `version`/`locale` (`008:13-27`); `app_locales` (`023:135`) sin uso | CTDL: *criteria* y *assessment* dentro de la credencial | `curriculum_version` + criterios del logro guardados con el certificado |
| 10 | **Consentimiento sin prueba ni retención** | no se guarda versión/texto aceptado; `fecha_revocacion` nunca se escribe; UI promete borrado a 12 meses sin job (`glow_consent_widget.dart:96-100`) | Ley 1581: finalidad, revocación, retención limitada, SIC | Snapshot del texto + IP/hash + revocación efectiva + job de purga de evidencias |

---

## T4 — Errores, bugs y daños

### Daño de datos (bloqueante)

#### B1 `[V]` — Colisión de IDs de seed: el curso de colorimetría está partido y el de bioseguridad contaminado
`026` reusa los mismos UUID que `008`/`025` (`b0000000-…-0001..0003`, `a0000000-…-0001..0007`) pero con otro `course_id`/`module_id`, y la cláusula `ON CONFLICT (id) DO UPDATE` **solo actualiza `title`/`sort_order`/`content_text`**, nunca `course_id` ni `module_id`.

Replay real en PostgreSQL 16.15 (008→023→025→026→033→034), estado final:

```
curso c001  mod ...001 sort=1  Módulo 1: Fundamentos de la Teoría del Color      ← debería ser "Protocolo de Bioseguridad"
curso c001  mod ...002 sort=2  Módulo 2: Colorimetría Capilar: Niveles y Tonos   ← debería ser "Experiencia Premium al Cliente"
curso c002  mod ...003 sort=3  Módulo 3: Colorimetría Facial y Subtono de Piel   ← debería ser "Gel-X Avanzado"
curso c003  mod ...000/004/005/006/007/008                                       ← faltan los módulos 1, 2 y 3
Lecciones de c001: "1. La Rueda Cromática Interactiva", "2. Matiz, Valor e Intensidad", "3. La Química de las Melaninas"
Lecciones de c003: 11 (no 15) y con contenido cruzado (p.ej. "2. El Test de Porosidad" dentro del "Módulo 4: Diagnóstico Práctico")
```
Impacto: (a) el único curso alcanzable desde la app (`GlowColorScreen` → `c0000000-…-0003`) muestra 6 módulos desordenados (0, 4, 5, 6, 7, 8) con 11 de 15 lecciones y lecciones fuera de su módulo; (b) el **curso obligatorio de bioseguridad** (cuyo quiz sigue preguntando por esterilización de instrumental) exhibe títulos de teoría del color; (c) se repite en **cada arranque** del backend. `[D]` El dump de producción confirma el mismo esquema de PK/DDL, es decir, el patrón es reproducible en prod.

#### B2 `[V]` — La migración 034 falla siempre y la FK de `qr_certificates` nunca existe
```
FALLA 034_add_fks_to_academy_tables.sql (rc=3)
psql: /tmp/034_...sql:35: ERROR: there is no unique constraint matching given keys
                                    for referenced table "academy_certificates"
```
Causa raíz: `033:14-17` busca la PK con `constraint_name LIKE '%provider_id%'`, pero PostgreSQL la llamó `academy_certificates_pkey` (`008:71`) → el bloque nunca entra → `id SERIAL` se añade (`[V]` columna `id integer NOT NULL DEFAULT nextval(...)`) pero **nunca es única ni PK**, y `034` no puede crear la FK. El runner silencia el error (no contiene "already exists") y lo deja en un `console.warn`: falla en cada boot sin que nadie lo vea. `[D]` El dump también trae `academy_certificates_pkey PRIMARY KEY (provider_id, course_id)` y **ninguna** `fk_qr_certificates_certificate_id`: la función "certificado con QR verificable" no puede operar.

### Alto

#### B3 `[L]` — Bypass de certificación
`POST /api/academy/courses/:id/submit-quiz` (`academyRoutes.js:222-282`) no verifica que el curso esté completo, que exista consentimiento ni que el alumno sea prestador: con 2 llamadas HTTP se obtiene el certificado sin abrir una lección. El *gating* vive solo en la UI (`course_detail_screen.dart:291-310`). Además `POST /lessons/:id/complete` (`:94-109`) acepta cualquier UUID de lección sin validar que pertenezca al curso, y con un UUID malformado responde 500 (`invalid input syntax for type uuid`) en vez de 400.

#### B4 `[L]` — La API del alumno no distingue rol
`academyRoutes.js` solo usa `authMiddleware` (ningún `requireRole`); `academy_progress.provider_id` / `academy_certificates.provider_id` referencian `usuarios(id)` sin discriminar rol (`008:29,68`). Un `CLIENTE` autenticado puede emitirse certificados de prestadora.

#### B5 `[L]` — `pool.connect()` fuera del `try` ⇒ el proceso Node puede morir
`academyAdminRoutes.js:61`, `:249`, `:349`. Con Express 4.18.2 (sin captura de promesas async) y Node 24.19 (unhandled rejection = salida del proceso), un fallo de `pool.connect()` (pool agotado, PG caído) **termina el backend**, no devuelve 500.

#### B6 `[L]` — Transacción abierta devuelta al pool
`POST /api/admin/academy/courses` hace `BEGIN` (`:63`) y, si falta un campo, `return res.status(400)` **después** (`:67-69`): el `finally` llama `client.release()` y `pg-pool` **no emite ROLLBACK** (verificado en `node_modules/pg-pool/index.js` `_release`), así que la conexión vuelve al pool en `idle in transaction` y puede ser reutilizada por otro request con locks abiertos. Mismo patrón de riesgo (sin validación de entrada) en `/modules/reorder` (`:248-267`) y `/lessons/reorder` (`:348-367`).

#### B7 `[V]` — El contenido de las lecciones es un placeholder en la base
`026:60-82`: 15 lecciones con `content_text = 'CONTENIDO_LECCION_*_AQUI'` y `video_url` idéntica a `youtube.com/watch?v=dQw4w9WgXcQ` (las 26 lecciones sembradas en 008/025/026 comparten esa URL). `course_detail_screen.dart:266` pinta ese texto tal cual: el alumno que hoy abre el curso de colorimetría ve marcadores internos.

#### B8 `[L]` — Consentimiento Ley 1581 mal instrumentado
- Revocar deja el registro como "recién aceptado": `ON CONFLICT DO UPDATE SET aceptado=$2, fecha_aceptacion=NOW(), fecha_revocacion=NULL` (`academyRoutes.js:118-124`) ⇒ `fecha_revocacion` no se escribe nunca.
- `GET /consent/status` responde `hasConsent: true` aunque `aceptado` sea `false` (`:137-148`).
- La UI promete "se eliminan automáticamente en 12 meses" (`glow_consent_widget.dart:96-100`) y no existe ningún job que purgue `academy_worksheet_submissions.evidencia_foto_url` (el `AutomaticRetentionService` existe pero está apagado por flag y no toca esas tablas) `[L]`.
- No se guarda versión del texto aceptado ni evidencia de la aceptación (hash/IP/timestamp de firma).

### Medio

| ID | Bug | Evidencia |
|---|---|---|
| B9 | **Reordenar no se persiste**: `moveModule`/`moveLesson` solo mutan estado React; los endpoints `POST /modules/reorder` y `/lessons/reorder` existen y **no los llama ningún cliente** `[V]` (grep `reorder` en `admin-dashboard/src`) ⇒ hay que entrar a editar y guardar módulo por módulo | `[id]/page.tsx:230-237,321-342` vs `academyAdminRoutes.js:248,348` |
| B10 | **Tres criterios de aprobación distintos**: UI Flutter "100% de las preguntas" (`quiz_screen.dart:206`), admin "requiere 100% aciertos" (`[id]/page.tsx:694`), backend 80% (`academyRoutes.js:250`, y `QUIZ_PASS_PCT` sin definir en ningún lado `[V]`) | — |
| B11 | `setState()` antes del `if (!mounted)` en el `catch` ⇒ "setState called after dispose" si el usuario sale mientras se envía el examen | `quiz_screen.dart:84-92` |
| B12 | Reproductor falso: imagen fija de Unsplash + botón play que solo lanza un SnackBar + rótulo "Streaming HD de lección disponible", ignorando `video_url` | `course_detail_screen.dart:195-231` |
| B13 | Pantallas huérfanas con progreso inventado: `course_list.dart` y `lesson_view.dart` no se importan desde ningún sitio `[V]`; `lesson_view` arranca con la lección 1 marcada como completada y 4 lecciones ficticias de "visagismo/espectrometría" | `lesson_view.dart:23,38-45` |
| B14 | Admin: tarjeta "Certificados" **hardcodeada a 0** (`[id]/page.tsx:777`) y `// @ts-nocheck` que desactiva el type-check de 1425 líneas (`:1`) | — |
| B15 | **Gamificación rota**: `xpLogController.js:42,59` consulta/inserta `xp_logs(points, description)` pero `023:27-34` define `xp_amount/reason/metadata` ⇒ 500 en `/api/xp-logs` (montado en `index.js:409`). Además `learningPathRoutes.js:8` requiere un modelo inexistente: montarlo rompe el arranque | `[V]` grep + `[L]` |
| B16 | `academy_progress.completed BOOLEAN NOT NULL DEFAULT TRUE` (`008:32`): un INSERT que omita la columna marca la lección como completada | — |
| B17 | **La capa "Academy Pro" no tiene tablas en producción**: `[D]` el dump (01-sep) no contiene `learning_paths`, `path_courses`, `xp_logs`, `user_levels`, `badges`, `qr_certificates`, `events`, `user_consents`, `user_badges` (solo `analytics_events`, creada por `create_required_tables.sql`). En un replay limpio `023` sí aplica ⇒ en ese entorno la migración nunca completó: `/api/glow-pro/certificates` y `/api/glow-pro/events` deben estar dando `relation does not exist` | `glowProRoutes.js:35,44,55,64` |
| B18 | Categorías sin whitelist ni CHECK en la base (`008:7 category VARCHAR(100) NOT NULL`): el admin ofrece 9 categorías, la API acepta cualquier string | — |
| B19 | **Cero tests**: ninguna suite de `backend/tests` ni de `frontend/test` menciona la academia `[V]`; 1425 líneas de admin con type-checking apagado | — |
| B20 | `POST /worksheets/submit` y `/ai-discrepancy/log` no validan que `lessonId/leccionId` pertenezca al curso del alumno ni deduplican (el log de discrepancias es un INSERT libre) | `academyRoutes.js:154-198` |

### Lo que está bien y conviene no romper
Progreso y certificado idempotentes por PK compuesta; `correct_index` nunca sale al cliente; consentimiento verificado en servidor antes de aceptar fotos; autorización admin a nivel de router; CASCADE evita huérfanos; separación de tablas de evidencia/calificación/consentimiento bien modelada.

---

## PROMPT DE CORRECCIÓN (para pasar a Antigravity)

```
Contexto: repo C:\beauty-app. La auditoría de la Academia Glow (informe completo en
C:\Users\Compu casa\auditorias\belleza-app\AUDITORIA-ESCUELA-ACADEMIA-2026-09-22.md)
encontró daño de datos reproducible y fallos de integridad. Trabaja en este orden y
entrega evidencia de cada paso (comando + salida), no descripciones.

FASE 0 — Reproducir antes de tocar
1. Levanta un PostgreSQL 16 limpio en Docker y aplica en orden 008, 023, 025, 026, 033, 034.
   Adjunta la salida: 034 debe fallar con "no unique constraint matching given keys".
2. Consulta y adjunta: módulos por curso, lecciones por módulo, PK de academy_certificates.

FASE 1 — Reparar el daño de datos (bloqueante)
3. Nueva migración 038_fix_academia_seed_collisions.sql que:
   a. re-apunte los módulos b0000000-…-0004 y …-0005 al curso c0000000-…-0003 con sus
      títulos correctos ("Módulo 1: Fundamentos de Colorimetría Capilar" / "Módulo 2: Técnicas de
      Decoloración y Balayage") y sort_order 1 y 2;
   b. cree los módulos del curso …0003 que faltan (los que hoy viven en …0001/…0002) con UUID
      NUEVOS, y re-asigne sus lecciones (a0…0001..0007) con UPDATE academy_lessons.module_id;
   c. restaure los títulos originales de los módulos/lecciones del curso …0001 (bioseguridad) y
      …0002 (Gel-X).
   Debe ser idempotente y no depender del orden de arranque.
4. Renombra los UUID de 026 a un namespace nuevo y cambia su ON CONFLICT a DO NOTHING para que
   el seed no vuelva a sobrescribir cursos ajenos en cada boot.
5. Excluye los .down.sql de los 3 runners y prohíbe seeds destructivos en arranque: los seeds de
   contenido pasan a un comando explícito (npm run seed:academy).

FASE 2 — Credenciales (034)
6. Nueva migración 039_fix_certificate_surrogate_key.sql que detecte la PK por columnas
   (pg_constraint/junta a pg_attribute), no por nombre: añade UNIQUE(id) o convierte id en PK y
   garantiza UNIQUE(provider_id, course_id). Después, aplica la FK de qr_certificates.
   Verifica con \d academy_certificates y pg_constraint.

FASE 3 — Integridad del examen y del certificado
7. submit-quiz: rechazar con 409 si el curso no está 100% completado; validar rol provider/salon;
   registrar intentos en academy_quiz_attempts (nueva tabla) con límite configurable
   (QUIZ_MAX_ATTEMPTS, default 3) y devolver el intento restante.
8. GET /courses/:id: no devolver content_text/video_url de lecciones no desbloqueadas.
9. POST /lessons/:id/complete: validar que la lección pertenece a un curso existente y responder
   400 ante UUID inválido (no 500).
10. Emitir certificado verificable: certificate_id en la respuesta, verification_url
    (/verify/<code>), qr_code y endpoint público sin login que devuelva válido/revocado.
11. DELETE /courses/:id pasa a soft-delete; los certificados nunca se borran (estado REVOKED).

FASE 4 — Consentimiento Ley 1581
12. Al revocar: fecha_revocacion = NOW(), aceptado = false y CONSERVAR fecha_aceptacion.
13. /consent/status: hasConsent solo si aceptado = true.
14. Guardar versión del texto de consentimiento + hash y IP al aceptar.
15. Job de purga de evidencias fotográficas a los 12 meses, activado por flag y con log de
    auditoría; si no se implementa, quitar la promesa de la UI (glow_consent_widget.dart).

FASE 5 — Resistencia a fallos y limpieza
16. academyAdminRoutes: pool.connect() dentro del try en las 3 rutas y ROLLBACK en todo camino
    de salida; añadir try/catch a los handlers async (Express 4 no captura rechazos).
17. Borrar o conectar: learningPathRoutes.js + learningPathController.js (require inexistente),
    course_list.dart, lesson_view.dart, progress_card.dart; arreglar xpLogController
    (xp_amount/reason) o retirar /api/xp-logs.
18. Admin: quitar @ts-nocheck, arreglar "Certificados: 0" y persistir el reordenamiento con los
    endpoints /reorder (o eliminarlos).
19. Publicar el contenido real: script publish-lesson que cargue docs/academy/**/*.md en
    academy_lessons y reemplace las 15 `video_url` placeholder.

FASE 6 — Verificación
20. Tests: suite de integración de academia (curso→lección→progreso→quiz→certificado) + test
    anti-regresión de la colisión de seeds (aplicar 008+026 y comprobar que c001 no cambia) +
    test de score/intentos. Todo debe fallar en rojo antes del fix.
21. npm run test verde y evidencia de CI.
```
