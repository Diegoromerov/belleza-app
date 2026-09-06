# GLOWAPP — MAPA FUNCIONAL DE UNIDADES PRODUCTIVAS

---

## 1. Resumen Ejecutivo

GlowApp es una **plataforma de marketplace de belleza a domicilio** con capa de **inteligencia artificial conversacional (AURA)** y **módulos de análisis biométrico/visajismo**. Funciona como un sistema productivo de tres lados: **Cliente final** (reserva servicios, compra productos, recibe diagnóstico IA), **Prestador/Profesional** (gestiona agenda, servicios, portafolio, recibe pagos), y **Plataforma** (orquesta matching, pagos, comisiones, calidad, IA).

Arquitectónicamente: **Frontend Flutter** (iOS/Android/Web) + **Backend Node.js/Express** (PostgreSQL + PostGIS + pgvector) + **Servicios IA** (DeepSeek/Gemini + RAG vectorial + 6 agentes especializados). Todo desplegado en Railway.

La aplicación **ya opera en producción** con usuarios reales, transacciones Wompi, y flujos completos de reserva→pago→servicio→reseña.

---

## 2. Mapa General (Jerarquía 3 Niveles)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ DOMINIO 1: EXPERIENCIA DEL USUARIO FINAL (Cliente)                          │
├─────────────────────────────────────────────────────────────────────────────┤
│ 1.1  Captura y Onboarding de Identidad          →  AuthService, onboarding  │
│ 1.2  Descubrimiento y Búsqueda de Prestadores   →  ProviderDetailScreen     │
│ 1.3  Reserva y Checkout (Logística + Upsell)    →  BookingScreen (3 pasos) │
│ 1.4  Chat y Comunicación con Prestador          →  ChatList/ChatScreen     │
│ 1.5  Seguimiento de Citas y SOS                 →  BookingTrackingScreen   │
│ 1.6  Cartera y Pagos (Wallet)                   →  WalletScreen            │
│ 1.7  Tienda de Productos (GlowStore)            →  StoreScreen             │
│ 1.8  Módulo Ideas / Visajismo IA                →  AuraWelcome, Capture    │
│ 1.9  Diagnóstico Biométrico y Colorimetría      →  Designs/* screens       │
│ 1.10 Perfil y Fidelización                      →  UserProfileScreen       │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ DOMINIO 2: EXPERIENCIA DEL PRESTADOR (Profesional)                          │
├─────────────────────────────────────────────────────────────────────────────┤
│ 2.1  Dashboard y Gestión de Negocio             →  ProviderDashboardScreen │
│ 2.2  Gestión de Servicios y Precios             →  ProviderServicesScreen  │
│ 2.3  Portafolio Visual                          →  ProviderPortfolioScreen │
│ 2.4  Perfil y Verificación Legal                →  ProviderProfileScreen   │
│ 2.5  Agenda y Rutas (Geolocalización)           →  ProviderRouteScreen     │
│ 2.6  Academia y Capacitación                    →  AcademyScreen           │
│ 2.7  Inteligencia de Negocio (VALKYRIE)         →  glowProRoutes           │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ DOMINIO 3: INTELIGENCIA ARTIFICIAL (AURA + Agentes)                         │
├─────────────────────────────────────────────────────────────────────────────┤
│ 3.1  Orquestador Conversacional (AURA)          →  geminiService.js        │
│ 3.2  Agente ATENA — Biometría/Visajismo         →  atenaAgent.js           │
│ 3.3  Agente HERMES — Logística/PostGIS          →  hermesAgent.js          │
│ 3.4  Agente CHRONOS — Ciclo de Vida/Re-booking  →  chronosAgent.js         │
│ 3.5  Agente HESTIA — Personal Shopper/Store     →  hestiaAgent.js          │
│ 3.6  Agente VALKYRIE — B2B/Precios Dinámicos    →  valkyrieAgent.js        │
│ 3.7  RAG Conocimiento Técnico Belleza           →  ragService.js           │
│ 3.8  Cache Semántico + Observabilidad           →  semanticCache, ragObs   │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ DOMINIO 4: MARKETPLACE Y OPERACIONES                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│ 4.1  Motor de Reservas y Estados                →  bookingController.js    │
│ 4.2  Pagos Wompi + Split Financiero (20%/8%)    →  paymentRoutes, Wompi    │
│ 4.3  Catálogo de Servicios                      →  serviceController.js    │
│ 4.4  Catálogo de Productos (GlowStore)          →  productController.js    │
│ 4.5  Disputas y Mediación                       →  disputeController.js    │
│ 4.6  Reseñas y Reputación                       →  reviews (DB + API)      │
│ 4.7  Notificaciones Push + WebSocket            →  websocketService.js     │
│ 4.8  Analíticas y Telemetría                    →  analyticsRoutes.js      │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ DOMINIO 5: CONOCIMIENTO Y DATOS (RAG + Datos Maestros)                       │
├─────────────────────────────────────────────────────────────────────────────┤
│ 5.1  Base de Conocimiento Belleza (pgvector)    →  beauty_knowledge_emb.   │
│ 5.2  Ingesta Automática de Corpus               →  corpusAutoIngest.js     │
│ 5.3  Embeddings NVIDIA (1024-dim)               →  generateEmbedding()     │
│ 5.4  Perfiles Biométricos (Redis + PG)          →  beauty_profiles table   │
│ 5.5  Configuración Dinámica de Negocio          →  platform_config table   │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ DOMINIO 6: INFRAESTRUCTURA TRANSVERSAL                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│ 6.1  Autenticación y Autorización (JWT + OAuth) →  authController.js       │
│ 6.2  Consentimiento Biométrico (Habeas Data)    →  consentService.js       │
│ 6.3  Rate Limiting, Seguridad, Sanitización     →  middleware/*            │
│ 6.4  Jobs/Crons (Pagos, Lealtad, Limpieza)      →  paymentJobs, loyalty    │
│ 6.5  Migraciones y Seeds                        →  migrations/, seed.sql   │
│ 6.6  Design System Tokens (GlowStoreTokens)     →  tokens.dart, glow_store │
```

---

## 3. Inventario de Unidades Productivas (Fichas)

### 3.1 DOMINIO 1: EXPERIENCIA DEL USUARIO FINAL

| # | Unidad | Propósito | Valor | Actor | Entrada | Proceso | Salida | Estado |
|---|--------|-----------|-------|-------|---------|---------|--------|--------|
| 1.1 | **Captura y Onboarding de Identidad** | Registrar usuario, definir rol (Cliente/Prestador), capturar consentimientos legales (Habeas Data, Términos) | Base de confianza; cumple regulación colombiana | Usuario final | Email, nombre, foto, teléfono, contraseña/Google/Apple, rol, docs (si prestador) | Validación → Creación usuarios + perfiles_prestador (si aplica) → Token JWT → Onboarding incompleto flag | Usuario autenticado con token, perfil base, rol asignado | **Operativo** |
| 1.2 | **Descubrimiento y Búsqueda de Prestadores** | Mostrar lista/mapade prestadores cercanos con filtros, ratings, especialidad | Matching oferta-demanda geolocalizado | Usuario final | Lat/lon (opcional), filtros categoría | Query PostGIS (ST_DWithin) → Lista ordenada por distancia + rating | Lista de prestadores con datos clave (nombre, rating, especialidad, cover, distancia) | **Operativo** |
| 1.3 | **Reserva y Checkout (3 pasos: Cuándo/Dónde → Productos → Confirmación/Pago)** | Convertir intención en reserva confirmada con pago seguro y upsell de productos | **Core revenue**; reduce fricción; aumenta ticket promedio | Usuario final | ProviderId, ServiceIds, fecha/hora, dirección, notas, productos opcionales | Validación slots → Crear booking (PENDIENTE_PAGO) → Calcular split 20%/8% → Wompi Checkout → Confirmar → Notificar | Booking CONFIRMADA, transacción registrada, notificaciones enviadas | **Operativo** |
| 1.4 | **Chat y Comunicación con Prestador** | Canal directo cliente-prestador para coordinar detalles, enviar fotos, confirmar | Reduce no-shows; mejora experiencia | Usuario final + Prestador | Mensajes texto/imagen, partnerId | WebSocket tiempo real → Persistencia messages table → Push notifications | Historial chat sincronizado, notificaciones push | **Operativo** |
| 1.5 | **Seguimiento de Citas y SOS** | Tracking estado cita (confirmada→en progreso→completada), botón pánico geolocalizado | Seguridad física; transparencia operacional | Usuario final + Prestador | BookingId, lat/lon (SOS) | Polling/WS estado → PIN verificación 4 dígitos → Completar → SOS insert + SSE admin | Timeline visible, alerta SOS a admins en tiempo real | **Operativo** |
| 1.6 | **Cartera y Pagos (Wallet)** | Ver saldo disponible, historial retiros, solicitar retiro Nequi/Bancaria, ver comisiones | Liquidez prestador; transparencia financiera | Prestador | UserId autenticado | Agregaciones SQL (bookings COMPLETADA) → Cálculo neto → Retiros pendientes | Dashboard wallet con saldo, movimientos, botón retiro | **Funcional pero incompleto** (falta conciliación automática) |
| 1.7 | **Tienda de Productos (GlowStore)** | E-commerce editorial de productos belleza con filtro audiencia (Mujeres/Hombres), carrito lateral, checkout Wompi | Diversificación revenue; cross-sell post-servicio | Usuario final | Catálogo productos, audience mode | Filtrado por tag_especialidad + gender_target → Carrito local → Checkout Wompi (STORE_ prefix) | Orden creada, productos descontados stock, analytics | **Operativo** |
| 1.8 | **Módulo Ideas / Visajismo IA** | Inspiración visual (uñas, piel, cabello, cejas), diagnóstico facial IA, redirección a herramientas | Diferenciación IA; engagement pre-reserva | Usuario final | Imagen selfie, selección módulo | Análisis IA (face-shape, skin-tone, etc) → Recomendación visual → Redirect booking | Resultado diagnóstico + botón "Reservar este look" | **Operativo** (algunos módulos experimentales) |
| 1.9 | **Diagnóstico Biométrico y Colorimetría** | Análisis rostro/manos → subtono, fototipo, paleta colorimetría, ingredientes recomendados | Personalización profunda; fidelización | Usuario final | Foto rostro/manos | ATENA Agent → Scores hidratación, poros, arrugas, subtono → Paleta + ingredientes | Perfil biométrico guardado (Redis 30d + PG), recomendaciones | **Operativo** (cache Redis + PG) |
| 1.10 | **Perfil y Fidelización** | Historial reservas, racha check-ins, nivel usuario, badges, preferencias | Retención; gamificación | Usuario final | UserId | Agregaciones bookings + xp_logs + streak logic | Perfil completo con métricas engagement | **Funcional pero incompleto** (streak parcial) |

---

### 3.2 DOMINIO 2: EXPERIENCIA DEL PRESTADOR

| # | Unidad | Propósito | Valor | Actor | Entrada | Proceso | Salida | Estado |
|---|--------|-----------|-------|-------|---------|---------|--------|--------|
| 2.1 | **Dashboard y Gestión de Negocio** | Vista unificada: citas hoy, ingresos, rating, estado online, accesos rápidos | Centro de mando diario | Prestador | ProviderId | Agregaciones tiempo real (bookings hoy, rating_avg, is_online) | Dashboard con KPIs + acciones rápidas | **Operativo** |
| 2.2 | **Gestión de Servicios y Precios** | CRUD servicios (nombre, precio, duración, categoría, activo), precios por servicio | Control oferta; pricing dinámico | Prestador | Formulario servicio | Validación → Insert/Update services table → Cache invalidation | Lista servicios gestionable | **Operativo** |
| 2.3 | **Portafolio Visual** | Subir/eliminar/ordenar fotos de trabajos realizados con título y categoría | Prueba social; conversión | Prestador | Imagen + metadata | Upload → portfolio_items → Grid 3 cols en detail | Portafolio público en ProviderDetail | **Operativo** |
| 2.4 | **Perfil y Verificación Legal** | Datos negocio, docs legales (RUT, cédula, certificación), estado verificación, horario semanal | Cumplimiento legal; confianza cliente | Prestador | Formulario + archivos | Multer upload → perfiles_prestador update → Admin review → APROBADO/RECHAZADO | Perfil verificado + badge "Verificado" | **Operativo** |
| 2.5 | **Agenda y Rutas (Geolocalización)** | Ver citas en mapa, navegar a cliente, activar/desactivar online con GPS | Logística última milla; eficiencia | Prestador | BookingId, lat/lon | PostGIS routing → MapScreen + Navigation | Ruta optimizada, check-in GPS | **Funcional pero incompleto** (routing básico) |
| 2.6 | **Academia y Capacitación** | Cursos, certificaciones, progress tracking para prestadores | Calidad servicio; retención prestador | Prestador | Contenido academy | academyRoutes + learning paths | Dashboard academia con progreso | **Experimental/Parcial** |
| 2.7 | **Inteligencia de Negocio (VALKYRIE)** | Análisis ocupación por día/hora, descuentos dinámicos autorizados, promo codes | Optimización ingresos; llenar huecos | Prestador | ProviderId, histórico 30d | Agregación bookings por ISODOW → Día más lento → Promo 15% mañana | Insights + código promo autorizado | **Operativo** (agente funcional) |

---

### 3.3 DOMINIO 3: INTELIGENCIA ARTIFICIAL (AURA + Agentes)

| # | Unidad | Propósito | Valor | Actor | Entrada | Proceso | Salida | Estado |
|---|--------|-----------|-------|-------|---------|---------|--------|--------|
| 3.1 | **Orquestador Conversacional (AURA)** | Chatbot principal: personalidad bogotana, tool calling 8 herramientas, fallback DeepSeek→Gemini, cache semántico | **Diferenciador estratégico**; atención 24/7 | Usuario final | Texto usuario + imagen opcional + userId | 1) Cache semántico 2) RAG si keywords 3) Services context 4) Historial comprimido 5) DeepSeek tool calling 6) Fallback Gemini 7) Guardar + WS notify | Respuesta natural + tool calls ejecutados + redirección UI | **Operativo** (robusto con circuit breakers) |
| 3.2 | **Agente ATENA — Biometría/Visajismo** | Diagnóstico facial/manos: scores, subtono, paleta colorimetría, ingredientes activos | Personalización IA; base para recomendaciones | AURA (tool call) | userId | Redis cache (30d) → PG beauty_profiles → Enriquecer (paleta, ingredientes) → Guardar Redis | Perfil biométrico estructurado + recomendaciones | **Operativo** |
| 3.3 | **Agente HERMES — Logística/PostGIS** | Búsqueda geoespacial prestadores cercanos, verificación disponibilidad agenda | Matching espacial-temporal preciso | AURA (tool call) | lat, lon, categoría, radio | ST_DWithin PostGIS → JOIN services + perfiles_prestador → Orden distancia+rating | Top 5 prestadores con distancia km | **Operativo** |
| 3.4 | **Agente CHRONOS — Ciclo de Vida/Re-booking** | Detectar tratamientos vencidos según cadencia por categoría (uñas 21d, cabello 30d, piel 45d) | Re-booking proactivo; LTV | AURA (tool call) | userId | Últimas 5 bookings COMPLETADA → Calcular días transcurridos vs ciclo → Urgencia alta/media | Lista tratamientos pendientes mantenimiento | **Operativo** |
| 3.5 | **Agente HESTIA — Personal Shopper/Store** | Recomendar productos GlowStore compatibles con perfil biométrico o query texto | Cross-sell inteligente; ticket promedio | AURA (tool call) | userId (opcional), queryText, categoría | ATENA para ingredientes → Query productos BD (stock>0) → Fallback hardcoded | Lista productos recomendados + ingredientes match | **Operativo** |
| 3.6 | **Agente VALKYRIE — B2B/Precios Dinámicos** | Análisis ocupación semanal, autorizar promos 15% en horas muertas, generar códigos | Revenue optimization prestador | AURA (tool call) | providerId | Bookings 30d → GROUP BY ISODOW → Día menor ocupación → Promo código | Insights + promo autorizada GLOW-DIA-15 | **Operativo** |
| 3.7 | **RAG Conocimiento Técnico Belleza** | Búsqueda vectorial (pgvector 768/1024 dim) + fallback full-text español sobre ingredientes, regulación, seguridad | **Ventaja competitiva**: respuestas técnicas auditables con fuentes | AURA (RAG trigger) | Query usuario, filtros (skin_type, categoría, ingredientes) | Embedding NVIDIA → HNSW search (threshold 0.45, topK 5) → Format context → Inyectar en system prompt | Chunks con similitud, fuente, sección, cita exacta | **Operativo** (con observabilidad completa) |
| 3.8 | **Cache Semántico + Observabilidad** | Cache embeddings queries similares (TTL), trazabilidad completa (latencia, chunks, modelo, tools, errors) | Cost optimization; debuggabilidad; calidad | Sistema interno | Embedding query + respuesta | findSimilarInCache → HIT/MISS → setCache → Log rag_queries + métricas | Hit rate, latencias P50/P95, fallback rate, cache hit rate | **Operativo** (métricas en /api/metrics) |

---

### 3.4 DOMINIO 4: MARKETPLACE Y OPERACIONES

| # | Unidad | Propósito | Valor | Actor | Entrada | Proceso | Salida | Estado |
|---|--------|-----------|-------|-------|---------|---------|--------|--------|
| 4.1 | **Motor de Reservas y Estados** | Máquina de estados: PENDIENTE_PAGO → CONFIRMADA → EN_PROGRESO → FINALIZADA_PRESTADOR → COMPLETADA / CANCELADA | Núcleo transaccional; integridad estados | Sistema | Eventos: pago, start, complete PIN, cancel | Triggers DB (calc_booking_split 20%/8%) + validaciones PIN + geofence 500m | Booking con estado consistente, split financiero calculado | **Operativo** (MADURO) |
| 4.2 | **Pagos Wompi + Split Financiero** | Checkout seguro (Nequi/Tarjeta), webhook confirmación, split automático 12% comisión + 8% impuestos → 80% neto prestador | **Monetización core**; compliance financiero | Usuario + Sistema | BookingId, method (NEQUI/CARD) | Wompi SDK → Webhook → Update payment_status → Wallet credit prestador | Transacción APPROVED, wallet actualizado, notificación | **Operativo** (CRÍTICO) |
| 4.3 | **Catálogo de Servicios** | CRUD servicios por prestador, categorías, precios, duración, activo/inactivo | Inventario vendible | Prestador + Admin | Formulario servicio | Validación → services table (UUID) → Índices provider_id + category | Servicio disponible en búsqueda y booking | **Operativo** |
| 4.4 | **Catálogo de Productos (GlowStore)** | Productos con tag_especialidad, gender_target, stock, precio, imagen | Inventario retail | Admin + Sistema | Seed/manual insert | productos table → Filtros audience (Men/Women) → API /api/products | Catálogo filtrado por audiencia | **Operativo** |
| 4.5 | **Disputas y Mediación** | Proceso estructurado: ABIERTA → EN_REVISION → RESUELTA (SLA 48h), reembolso % según evidencia | Confianza; protección ambas partes | Cliente/Prestador/Admin | BookingId, tipo, descripción, evidencia, monto | Trigger SLA 48h → Admin review → Resolución % prestador/cliente → Wallet adjust | Disputa cerrada, fondos movidos, audit trail | **Operativo** |
| 4.6 | **Reseñas y Reputación** | Rating 1-5 + comentario + fotos opcional, solo post-COMPLETADA, 1 por booking | Prueba social; calidad | Cliente | BookingId, rating, comment, photos | Validación booking COMPLETADA → Insert reviews → Update rating_avg/rating_count | Review visible en ProviderDetail, rating actualizado | **Operativo** |
| 4.7 | **Notificaciones Push + WebSocket** | Tiempo real: chat, booking updates, SOS, admin events | Inmediatez; reduce polling | Todos | Eventos servidor | WS server compartido puerto HTTP → notifyUserChatMessage/JobUpdate → FCM push fallback | Mensajes entregados <1s, fallback push | **Operativo** |
| 4.8 | **Analíticas y Telemetría** | Eventos batch (SCREEN_VIEW, TAP, etc), dashboard admin métricas (revenue, bookings, users, SOS, proyección lineal) | Toma de datos; health check | Admin + Sistema | Batch events array + userId opcional | Insert user_activity_logs → Agregaciones SQL tiempo real → Proyección regresión lineal | Dashboard /api/admin/metrics + telemetría cruda | **Operativo** |

---

### 3.5 DOMINIO 5: CONOCIMIENTO Y DATOS

| # | Unidad | Propósito | Valor | Actor | Entrada | Proceso | Salida | Estado |
|---|--------|-----------|-------|-------|---------|---------|--------|--------|
| 5.1 | **Base de Conocimiento Belleza (pgvector)** | 768/1024-dim embeddings de artículos técnicos: ingredientes, regulación INVIMA, contraindicaciones embarazo, protocolos | **Fuente de verdad técnica**; evita alucinaciones IA | RAG Service | Chunks con title, content, category, metadata, embedding | Migraciones SQL → beauty_knowledge_embeddings → HNSW index | Chunks recuperables por similitud coseno | **Operativo** (datos sembrados) |
| 5.2 | **Ingesta Automática de Corpus** | Jobs periódicos que scraean/fetchean fuentes autorizadas y generan embeddings | Actualización conocimiento sin intervención manual | Sistema (cron) | URLs fuentes configuradas | corpusAutoIngest → Chunking → Embedding NVIDIA → Upsert pgvector | Nuevos chunks indexados | **Funcional pero incompleto** (fuentes limitadas) |
| 5.3 | **Embeddings NVIDIA (1024-dim)** | Generación embeddings via NVIDIA API (nv-embedqa-e5-v5) para queries y corpus | Calidad semántica superior | RAG Service | Texto query/documento | HTTP POST NVIDIA → Validar 1024 dims → Return vector | Vector listo para búsqueda | **Operativo** |
| 5.4 | **Perfiles Biométricos (Redis + PG)** | Cache 30d en Redis de diagnósticos ATENA, fallback PG beauty_profiles | Latencia <100ms para perfiles recurrentes | ATENA Agent | userId | Redis GET → Miss → PG SELECT → Enriquecer → Redis SETEX 30d | Perfil completo con scores, paleta, ingredientes | **Operativo** |
| 5.5 | **Configuración Dinámica de Negocio** | Parámetros runtime: comisiones, OTP, ventanas, GPS, riesgo, sin deploy | Agilidad operacional | Admin + Sistema | platform_config table | READ/WRITE via adminRoutes → Cache in-memory | Configuración viva | **Operativo** |

---

### 3.6 DOMINIO 6: INFRAESTRUCTURA TRANSVERSAL

| # | Unidad | Propósito | Valor | Actor | Entrada | Proceso | Salida | Estado |
|---|--------|-----------|-------|-------|---------|---------|--------|--------|
| 6.1 | **Autenticación y Autorización (JWT + OAuth)** | Register/Login (email/pass, Google, Outlook, Apple), JWT 24h, refresh, roles CLIENTE/PRESTADOR/ADMIN | Seguridad; control acceso | Todos | Credenciales / OAuth tokens | bcrypt hash → JWT sign (HS256) → SecureStorage (Flutter) / httpOnly cookie (Web) | Token válido, userId en request | **Operativo** (MADURO) |
| 6.2 | **Consentimiento Biométrico (Habeas Data)** | Granular: all_biometric, facial_analysis, hand_analysis, marketing; audit log accesos | Cumplimiento Ley 1581/2012 Colombia | Usuario + IA | userId, consent_type, granted | consentService → consent_logs table → Check en tool calls biométricos | Consent granted/denied + audit trail | **Operativo** |
| 6.3 | **Rate Limiting, Seguridad, Sanitización** | Helmet CSP, CORS, rate limits (analyze 30/h, global 1000/15min), XSS sanitizer, PII redaction logs | Protección abuso; compliance | Sistema | Requests HTTP | Middleware chain → 429/403/200 | Requests filtrados, logs limpios | **Operativo** |
| 6.4 | **Jobs/Crons (Pagos, Lealtad, Limpieza)** | Maduración pagos 24h, retiros auto >20k COP c/ 3d, conciliación diaria, expiración nail_tryon | Automatización financiera/operacional | Sistema (cron) | Schedule (node-cron) | paymentJobs → wallet updates + transactions + notifications | Jobs ejecutados, logs | **Operativo** |
| 6.5 | **Migraciones y Seeds** | Esquema versionado (migrations/*.sql), seeds dev, auto-migrate on startup | Deploy seguro; reproducibilidad | Sistema | Archivos .sql ordenados | initDatabase() → ALTER TABLE idempotentes → Seeds condicionales | DB schema vActual | **Operativo** |
| 6.6 | **Design System Tokens (GlowStoreTokens)** | 4 superficies, 5 radios, 3 sombras, tipografía dual, audience-aware (creamSilk/obsidianBg), status colors | Consistencia visual; multi-audiencia | Frontend | Token class + Expression enum | Token.light/dark + expression(women/men/aura) → Colores/radios/sombras resueltos | UI coherente Women/Men/AURA | **Operativo** (LOCKED v1.0) |

---

## 4. Mapa de Dependencias Funcionales

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  AUTENTICACIÓN  │────▶│   PERFIL USER   │────▶│   ONBOARDING    │
│   (6.1)         │     │   (1.1)         │     │   (1.1)         │
└─────────────────┘     └────────┬────────┘     └────────┬────────┘
                                 │                       │
                                 ▼                       ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  CONSENTIMIENTO │◀───│  BIOMETRÍA      │◀───│  MÓDULO IDEAS   │
│   BIOMÉTRICO    │     │  (ATENA 3.2)    │     │  (1.8)          │
│   (6.2)         │     └────────┬────────┘     └────────┬────────┘
└─────────────────┘              │                       │
                                 ▼                       ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   RAG CONOCIM.  │────▶│   AURA ORQUEST. │◀───│  CHAT (1.4)     │
│   (5.1/5.3)     │     │   (3.1)         │     └────────┬────────┘
└─────────────────┘     └────────┬────────┘              │
                                 │                       │
         ┌───────────────────────┼───────────────────────┼───────────────┐
         ▼                       ▼                       ▼               ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐ ┌─────────────────┐
│  HERMES (3.3)   │     │  CHRONOS (3.4)  │     │  HESTIA (3.5)   │ │ VALKYRIE (3.6)  │
│  Geo + Agenda   │     │  Re-booking     │     │  Productos      │ │  B2B Insights   │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘ └────────┬────────┘
         │                       │                       │                  │
         ▼                       ▼                       ▼                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        MOTOR DE RESERVAS (4.1)                              │
│  BookingScreen (1.3) ──▶ createBooking ──▶ Wompi (4.2) ──▶ CONFIRMADA      │
│       │                           │                    │                   │
│       ▼                           ▼                    ▼                   │
│  PRODUCTOS (1.7/4.4)         SPLIT 20/8%          WALLET (1.6/2.1)        │
│  Cross-sell paso 2                                                         │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────┐
                    │  ESTADOS: START → PIN     │
                    │  COMPLETADA → REVIEW (4.6)│
                    │  DISPUTA (4.5) si hay     │
                    └───────────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────┐
                    │  NOTIFICACIONES (4.7)     │
                    │  WS + Push + SSE Admin    │
                    └───────────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────┐
                    │  ANALÍTICAS (4.8/5.5)     │
                    │  Telemetría + Proyección  │
                    └───────────────────────────┘
```

**Flujo crítico de dependencias (orden de auditoría):**
1. **Autenticación (6.1)** → todo lo demás requiere userId autenticado
2. **Motor de Reservas (4.1)** → núcleo transaccional; BookingScreen (1.3) lo consume
3. **Pagos Wompi (4.2)** → sin pago no hay booking CONFIRMADA
4. **AURA Orquestador (3.1)** → consume 6 agentes + RAG; entry point chat
5. **RAG (3.7/5.1)** → fuente verdad técnica; sin ella AURA alucina
6. **ATENA (3.2)** → base para HESTIA (3.5) y Módulo Ideas (1.8/1.9)
7. **HERMES (3.3)** → descubrimiento (1.2) y disponibilidad en booking
8. **CHRONOS (3.4)** → re-booking proactivo; alimenta AURA
9. **VALKYRIE (3.6)** → insights prestador (2.7); optimización revenue
10. **GlowStore (1.7/4.4)** → cross-sell en booking paso 2; checkout independiente
11. **Disputas (4.5)** → seguridad post-servicio; depende booking COMPLETADA
12. **Analíticas (4.8)** → transversal; consume todos los eventos

---

## 5. Principales Flujos de Negocio/Producto

### FLUJO 1: Primera Reserva Cliente (Happy Path)
```
INICIO: Usuario abre app → Home (lista prestadores cerca)
  │
  ├─▶ 1.2 Descubrimiento: PostGIS ST_DWithin → ProviderDetailScreen
  │       │
  │       ├─▶ Ve servicios, portfolio, reviews, rating, badge verificado
  │       ├─▶ Banner IA "Pregúntale a AURA" → /ideas (1.8)
  │       └─▶ Botón "RESERVAR CITA" → BookingScreen (1.3)
  │
  ├─▶ PASO 1 - LOGÍSTICA:
  │       ├─▶ Selecciona servicio(s) → _loadRecommendedProducts() (HESTIA 3.5)
  │       ├─▶ Calendario → _loadSlots() (HERMES 3.3 checkAvailability)
  │       ├─▶ Elige hora → Dirección servicio → Notas opcional
  │       └─▶ "Continuar" (validación: servicio+fecha+hora+dirección)
  │
  ├─▶ PASO 2 - CROSS-SELL PRODUCTOS:
  │       ├─▶ Productos filtrados por tag_especialidad del servicio
  │       ├─▶ Qty selector + bundle discount 15% si ≥2
  │       └─▶ "Continuar" u "Omitir"
  │
  ├─▶ PASO 3 - RESUMEN Y PAGO:
  │       ├─▶ Resumen logístico + desglose precio (servicio + productos - desc + IVA 19%)
  │       ├─▶ WompiCheckoutSheet (Nequi/Tarjeta) → payBooking API
  │       ├─▶ Webhook Wompi → payment_status=paid → Booking CONFIRMADA
  │       ├─▶ Split trigger: comision_plataforma 12% + impuestos_estado 8% = 20% total
  │       ├─▶ Wallet prestador credit: pago_neto_prestador (80%)
  │       └─▶ Notificaciones WS + Push a ambos
  │
  ├─▶ POST-RESERVA:
  │       ├─▶ Chat (1.4) para coordinar
  │       ├─▶ Tracking (1.5): CONFIRMADA → EN_PROGRESO (start) → PIN 4 dígitos → COMPLETADA
  │       ├─▶ Review (4.6) obligatorio post-COMPLETADA
  │       └─▶ CHRONOS (3.4) programa re-booking automático según cadencia
  │
FIN: Ciclo cerrado → Fidelización → Próxima reserva sugerida por CHRONOS
```

### FLUJO 2: Consulta IA AURA con Tool Calling
```
INICIO: Usuario abre Chat → Escribe "¿Qué me recomiendas para piel seca en embarazo?"
  │
  ├─▶ AURA (3.1) processAssistantMessage(userId, text)
  │
  ├─▶ shouldSearchBeautyKnowledge() → TRUE (keywords: piel, embarazo, ingrediente)
  │
  ├─▶ PARALELO: getServicesContext() (cache 5min) + searchBeautyKnowledge() (RAG 3.7)
  │       │
  │       ├─▶ Embedding NVIDIA (5.3) → vector 1024
  │       ├─▶ HNSW pgvector (threshold 0.45, topK 5)
  │       ├─▶ Fallback full-text ES si vector falla
  │       └─▶ formatKnowledgeContext() → Sección "CONOCIMIENTO TÉCNICO DE BELLEZA (RAG)"
  │
  ├─▶ SystemInstruction = BASE_PERSONALIDAD + CATALOGO_SERVICIOS + RAG_SECTION
  │
  ├─▶ Historial 20 msg (comprimido >20 con resumen)
  │
  ├─▶ Cache Semántico (3.8): findSimilarInCache(embedding) → HIT? return cached
  │
  ├─▶ DeepSeek Tool Calling (circuit breaker):
  │       ├─▶ Tool: search_beauty_knowledge_rag → RAG chunks
  │       ├─▶ Tool: recommend_glowstore_products → HESTIA (3.5) → ATENA (3.2) ingredientes
  │       ├─▶ Tool: search_nearby_services → HERMES (3.3) PostGIS
  │       ├─▶ Tool: trigger_ui_redirection → "Redirección Módulo Ideas: skin-tone"
  │       └─▶ Síntesis final → respuesta natural bogotana
  │
  ├─▶ Fallback Gemini si DeepSeek falla (circuit breaker OPEN)
  │
  ├─▶ Guardar mensaje AI_USER_ID=0 → messages table
  │
  ├─▶ notifyUserChatMessage WS + Push
  │
  ├─▶ setCache(embedding, respuesta) para futuro HIT
  │
  └─▶ logRagQuery (trazabilidad completa: latencias, chunks, modelo, tools, cache_hit)
FIN: Respuesta entregada + métricas registradas
```

### FLUJO 3: Prestador Recibe Reserva y Completa Servicio
```
INICIO: Booking CONFIRMADA creada (via Flujo 1)
  │
  ├─▶ Notificación WS push a prestador: "Nueva reserva"
  │
  ├─▶ ProviderDashboardScreen (2.1): Ve cita en "Hoy" con cliente, dirección, hora
  │
  ├─▶ ProviderRouteScreen (2.5): Mapa con ruta GPS optimizada (PostGIS)
  │
  ├─▶ EN PROGRESO: Prestador toca "Iniciar servicio" → booking EN_PROGRESO
  │
  ├─▶ CHECK-IN GPS: Valida geofence 500m (platform_config gps_tolerancia_metros)
  │
  ├─▶ FINALIZAR: Prestador toca "Finalizar" → pide PIN 4 dígitos al cliente
  │
  ├─▶ PIN válido → booking FINALIZADA_PRESTADOR → Cliente confirma → COMPLETADA
  │
  ├─▶ TRIGGERS AUTOMÁTICOS:
  │       ├─▶ calc_booking_split() ya ejecutado en createBooking (valor_bruto conocido)
  │       ├─▶ Wallet prestador: +pago_neto_prestador (disponible tras ventana 2h config)
  │       ├─▶ CHRONOS (3.4): Registra servicio completado para futuro re-booking
  │       ├─▶ ATENA (3.2): Si hay foto post-servicio → actualizar perfil biométrico
  │       └─▶ Review prompt a cliente (4.6)
  │
  ├─▶ RETIRO: Prestador ve saldo en Wallet (1.6/2.1) → Solicita retiro Nequi/Bancaria
  │       ├─▶ Validación: monto ≥ 50k COP (demanda) o ≥ 20k (auto), 3 días entre retiros
  │       └─▶ Job procesa → transferencia → transaction status=paid
  │
FIN: Dinero en cuenta prestador → Ciclo económico cerrado
```

### FLUJO 4: Cross-sell Productos en Checkout (Booking Paso 2)
```
INICIO: BookingScreen paso 1 completado (servicio+fecha+hora+dirección)
  │
  ├─▶ _loadRecommendedProducts() → ApiService.fetchProductsByTag(tag)
  │       │
  │       ├─▶ tag mapeado por _mapServiceToTag(category, name):
  │       │       Uñas/Manicura → "Uñas"
  │       │       Cabello/Corte/Balayage → "Cabello"
  │       │       Facial/Piel → "Estética"
  │       │       Cejas/Maquillaje → "Maquillaje"
  │       └─▶ GET /api/products?tag=X → productos table filtrado
  │
  ├─▶ UI Paso 2: Cards con imagen, precio, stock, botón +/- qty
  │       ├─▶ Banner social proof: "87% añaden estos productos"
  │       ├─▶ Banner urgencia: "15% descuento kit 2+ productos"
  │       └─▶ _selectedProductsQty map local
  │
  ├─▶ Usuario añade/quita → _selectedProductsQty actualizado
  │
  ├─▶ Paso 3 Resumen: Recalcula productsSubtotal + bundleDiscount (15% si qty≥2)
  │       ├─▶ subtotal = servicesPrice + productsSubtotal - discount
  │       ├─▶ tax = subtotal * 0.19
  │       └─▶ grandTotal = subtotal + tax → Wompi amount
  │
  ├─▶ Pago Wompi → booking_id + productos_adicionales array en createBooking
  │
  ├─▶ Backend: booking row + order_items (implícito en productos_adicionales JSON)
  │
  ├─▶ Stock decrementado en productos table
  │
  ├─▶ Analytics: logAddToCart + logPurchaseSuccess (metadata addon_hydration, wallet_cashback)
  │
FIN: Productos en camino al cliente + revenue incremental capturado
```

---

## 6. Estado de Madurez por Unidad

| Clasificación | Unidades | Comentario |
|--------------|----------|------------|
| **OPERATIVO** (MADURO) | 1.1, 1.2, 1.3, 1.4, 1.5, 1.7, 1.10, 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 5.1, 5.3, 5.4, 5.5, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6 | Código en producción, flujos completos, tests básicos, observabilidad |
| **FUNCIONAL PERO INCOMPLETO** | 1.6 (Wallet conciliación), 1.9 (algunos módulos Ideas), 2.5 (routing básico), 5.2 (fuentes limitadas) | Funciona pero falta profundidad, edge cases, o automatización |
| **EXPERIMENTAL** | 1.8 (módulos nails-style, hair-diagnostic), 2.6 (Academia) | En desarrollo, no crítico para revenue actual |
| **PARCIALMENTE INTEGRADO** | 1.9 ↔ 3.2 (cache Redis OK pero invalidación manual), 3.5 ↔ 4.4 (HESTIA usa fallback hardcoded si BD vacía) | Conexiones existen pero no robustas |
| **HUÉRFANO** | nail_tryon_jobs table (legacy), backgroundWorkerService (nailTryon, pqrsf, vtoAttribution comentados en index.js) | Código existe pero no se usa; comentado en startup |
| **DUPLICADO** | Embeddings: NVIDIA (1024) en ragService vs Gemini embedding (768) legacy en beauty_knowledge_embeddings; Auth: AuthService (Flutter) + api_service.dart _getAuthHeaders duplican lógica token | Dos sistemas conviven; migración parcial |

---

## 7. Unidades Críticas (Si fallan, GlowApp se detiene)

| Prioridad | Unidad | Justificación |
|-----------|--------|---------------|
| **P0** | **4.1 Motor de Reservas + 4.2 Pagos Wompi + Split Financiero** | Núcleo transaccional; sin reservas no hay revenue; split 20%/8% es compliance financiero |
| **P0** | **6.1 Autenticación JWT + OAuth** | Todo lo demás requiere usuario autenticado; token en SecureStorage crítico seguridad |
| **P0** | **3.1 AURA Orquestador** | Diferenciador principal; si cae, pierden IA 24/7 y tool calling (booking, productos, geo) |
| **P1** | **3.7 RAG + 5.1/5.3 Base Conocimiento + Embeddings** | Sin RAG, AURA alucina en temas médicos/regulatorios (riesgo legal embarazo/lactancia) |
| **P1** | **1.3 BookingScreen (3 pasos)** | UX crítica de conversión; cualquier bug = carrito abandonado directo |
| **P1** | **4.7 Notificaciones WS + Push** | Tiempo real para chat, tracking, SOS; sin ello experiencia se degrada severamente |
| **P2** | **3.2 ATENA + 3.3 HERMES** | Agentes base para tool calls frecuentes; degradan AURA a chatbot genérico si fallan |
| **P2** | **2.1/2.2 Dashboard + Servicios Prestador** | Si prestador no gestiona agenda/servicios, oferta se seca |

---

## 8. Unidades Estratégicas (Diferenciación Competitiva)

| Unidad | Por qué es estratégica | Madurez actual | Inversión sugerida |
|--------|------------------------|----------------|-------------------|
| **AURA Orquestador (3.1) + 6 Agentes** | Personalidad bogotana única, tool calling real (no RAG-only), multi-LLM fallback, cache semántico | Operativo | **Optimizar**: latencia P95, hit rate cache, añadir agente de retención |
| **RAG Conocimiento Belleza (3.7/5.1)** | Fuente auditable con resoluciones INVIMA exactas, seguridad embarazo/lactancia, anti-alucinación | Operativo | **Expandir**: más corpus (dermatología, tricología), evaluación RAGAS continua |
| **ATENA Biometría (3.2) + Módulo Ideas (1.8/1.9)** | Diagnóstico facial/manos → paleta colorimetría + ingredientes → recomendación producto/servicio | Operativo (parcial) | **Integrar**: cerrar loop ATENA→HESTIA→Booking automático |
| **VALKYRIE B2B (3.6)** | Precios dinámicos autorizados por IA para llenar huecos; único en mercado LATAM beauty | Operativo | **Escalar**: más variables (estacionalidad, competencia, clima) |
| **GlowStore Tokens + Audience-aware (6.6)** | Design system multi-audience (Women/Men/AURA) con paridad visual; base para escalar UI | Locked v1.0 | **Extender**: nuevos componentes, motion tokens, dark mode Women |
| **Split Financiero 20%/8% Automático (4.1/4.2)** | Compliance tributario colombiano automatizado; transparencia prestador | Maduro | **Auditar**: conciliación automática diaria vs Wompi |

---

## 9. Duplicaciones y Solapamientos

| Duplicación | Qué hace cada uno | Dónde se usan | Más maduro | Coexistencia legítima |
|-------------|-------------------|---------------|------------|----------------------|
| **Embeddings duales** | NVIDIA 1024-dim (ragService.js, producción) vs Gemini 768-dim (legacy schema vector(768)) | RAG search usa NVIDIA; beauty_knowledge_embeddings tiene columna vector(768) legacy | NVIDIA (activo) | NO — migrar columna a vector(1024) y re-embedding completo |
| **Token management** | AuthService.getToken() (Flutter SecureStorage) + ApiService._getToken() (idéntico) + api_service.dart _getAuthHeaders() | Todo frontend API calls | AuthService (centralizado) | NO — consolidar en AuthService; ApiService delegar |
| **Servicios: portafolio_servicios JSONB vs services table** | perfiles_prestador.portafolio_servicios (DEPRECADO, marcado en schema.sql) vs services table (fuente verdad) | ProviderDetailScreen lee services table; portafolio_servicios no se escribe | services table | NO — DROP column portafolio_servicios en migración futura |
| **Autenticación: authController.js vs authRoutes.js** | authController.js tiene lógica; authRoutes.js solo monta rutas | index.js usa authRoutes | Separación correcta (controller/routes) | SÍ — patrón MVC correcto |
| **Chat: messages table + WebSocket + Push FCM** | Triple canal: WS tiempo real + Push fallback + Persistencia | ChatScreen, ChatListScreen | WS principal | SÍ — capas de redundancia necesarias |
| **Geolocalización: web_geolocation.dart (3 archivos: stub, web, impl)** | Platform channels para web vs mobile | LocationService, BookingScreen | Implementación condicional kIsWeb | SÍ — pattern Flutter estándar |

---

## 10. Fragmentaciones (Capacidad repartida en excesivas partes)

| Capacidad | Partes involucradas | Diagnóstico |
|-----------|---------------------|-------------|
| **Crear Reserva (end-to-end)** | BookingScreen.dart (1409 líneas, 3 pasos UI) → ApiService.createBooking() → bookingController.js (28KB) → bookingRoutes.js → calc_booking_split trigger → Wompi webhook → Wallet update → Notificaciones | **Complejidad accidental**: lógica de precios (descuentos, IVA) duplicada en Flutter (BookingScreen _confirmBooking) y backend (trigger). BookingScreen calcula grandTotal localmente para UI pero backend recalcula. **Unificar**: backend source of truth; frontend solo muestra desglose devuelto por API. |
| **Perfil Biométrico** | atenaAgent.js (enriquece) → beauty_profiles table → Redis cache → AURA tool call → Módulo Ideas (CaptureScreen, diagnósticos) → GlowUpCardScreen | **Separación correcta** (agente + cache + UI) pero invalidación cache manual. **Optimizar**: event-driven invalidation (on new diagnosis). |
| **Catálogo Productos** | productos table → productController.js → ApiService.fetchProductsByTag() → BookingScreen _loadRecommendedProducts() → StoreScreen _fetchProducts() → HESTIA Agent recommendProducts() | **Duplicación lógica filtro**: _mapServiceToTag() en BookingScreen vs tag_especialidad en productos vs HESTIA query. **Unificar**: endpoint único `/api/products/recommend?serviceId=` que encapsule mapping. |
| **Design System Tokens** | tokens.dart (core) + glow_store_tokens.dart (GlowStore) + belleza_luxe_theme.dart + mens_theme.dart + AppTheme (legacy) | **Fragmentación histórica**: 5 archivos tokens. GlowStoreTokens es facade S1-compliant; AppTheme/belleza_luxe_theme son legacy. **Migrar**: todo a GlowStoreTokens + Token class (tokens.dart). |
| **Analytics/Telemetría** | AnalyticsService (Flutter) → /api/analytics/events batch → user_activity_logs → /api/admin/metrics SQL agregaciones | **Bien separado** (cliente batch + server agg) pero eventos hardcoded strings. **Unificar**: enum/event schema compartido. |

---

## 11. Código Huérfano / Funcionalidad Dudosa

| Archivo/Componente | Evidencia | Clasificación | Acción |
|--------------------|-----------|---------------|--------|
| `nail_tryon_jobs` table + `nailTryonWorker` (comentado en index.js:1656) | Schema existe; worker comentado "legacy"; sin UI activa | **Legado** | DROP table + limpiar schema.sql |
| `backgroundWorkerService.js` (nailTryon, pqrsfReview, vtoAttribution) | Comentado en index.js:1657 "usar backgroundWorkerService actual" | **Funcionalidad abandonada** | Eliminar código muerto o documentar si reactivarán |
| `designsController.js` (87KB) vs `niaBeautyRoutes.js` | designsController masivo; niaBeautyRoutes nuevo; ambos sirven /api/designs* | **Duplicación funcional en migración** | Auditar endpoints: consolidar en designsController o migrar todo a niaBeauty |
| `geminiService.js.backup` (35KB) | Backup en mismo directorio; no referenciado | **Basura** | Eliminar |
| `R6_RECOVERY2_PRE/POST_REBUILD.sql` (84MB + 12MB) | Dumps recuperación R6; no son migraciones | **Basura temporal** | Mover a /backups o eliminar |
| `scratch/` directory | Archivos test sueltos (scratch_test_gemini.js, etc) | **Basura desarrollo** | Limpiar |
| `frontend/lib/screens/designs/*.dart` (6 archivos) | EvolutionDashboard, MedicalValidation, GlowUpCard, PaletteCard, ColorimetriaHistorial, WardrobeDashboard, OutfitResult | **Experimental/Parcial** — algunos sin backend completo | Auditar cada uno: ¿tiene API backend? ¿se usa en producción? |
| `frontend/lib/widgets/aura_multi_agent_chat.dart` | Widget chat multi-agente; ¿se usa? | **Dudoso** | Verificar imports en main.dart / screens |

---

## 12. Deuda Funcional/Técnica Relevante (Impacto Real)

| Deuda | Unidades Afectadas | Impacto Real | Esfuerzo Estimado |
|-------|-------------------|--------------|-------------------|
| **Lógica precios duplicada (Flutter + Backend)** | 1.3 BookingScreen, 4.1 Motor Reservas | Riesgo inconsistencias grandTotal; Wompi amount puede no cuadrar con backend | 2-3 días (endpoint `/api/bookings/preview` que devuelve desglose) |
| **Columna vector(768) vs embeddings 1024** | 3.7 RAG, 5.1 Base Conocimiento | Búsqueda vectorial usa NVIDIA 1024 pero tabla tiene 768; HNSW index puede fallar silenciosamente | 1 día (ALTER COLUMN + re-embedding corpus) |
| **portafolio_servicios JSONB deprecado pero no dropeado** | 2.2 Servicios, 1.2 Descubrimiento | Confusión desarrolladores; migrations futuras lo ignoran | 30 min (migración DROP COLUMN) |
| **Cache Redis ATENA sin invalidación automática** | 3.2 ATENA, 1.9 Diagnóstico | Perfil stale 30d tras nuevo diagnóstico; usuario ve datos viejos | 2 días (event-driven: on beauty_profiles insert → Redis DEL) |
| **HESTIA fallback hardcoded si BD vacía** | 3.5 HESTIA, 1.7/4.4 GlowStore | Recomienda productos fake (prod-001, prod-002) si tabla productos vacía | 1 día (seed productos mínimos + quitar fallback) |
| **AuthService + ApiService duplican _getToken()** | 6.1 Auth, todo frontend API | Doble mantenimiento; riesgo desync SecureStorage | 1 día (ApiService delegar a AuthService) |
| **BookingScreen 1409 líneas (God component)** | 1.3 Reserva | Dificil testear; lógica negocio mezclada con UI | 1 semana (extraer BookingViewModel/Provider + step widgets) |
| **Design System fragmentado (5 archivos tokens)** | 6.6, todo frontend UI | Inconsistencias visuales; migración lenta a GlowStoreTokens | 2 semanas (migración incremental por pantalla) |
| **Falta conciliación automática Wompi ↔ Wallet** | 1.6 Wallet, 4.2 Pagos | Prestador ve saldo pero no confirma que Wompi liquidó; disputes manuales | 3 días (job diario: Wompi API transactions ↔ wallet balance) |
| **Tests E2E inexistentes para flujos críticos** | 1.3, 3.1, 4.1, 4.2 | Regresiones en checkout/pago/IA no detectadas hasta producción | Continuo (prioridad: booking flow + AURA tool calls) |

---

## 13. Oportunidades de Optimización (Sin Ejecutar Cambios)

| Oportunidad | Unidades | Descripción |
|-------------|----------|-------------|
| **Endpoint `/api/bookings/preview`** | 1.3, 4.1 | Backend calcula desglose completo (servicios + productos + descuentos + IVA + split) → Frontend solo renderiza; elimina duplicación lógica precios |
| **Cache invalidation event-driven ATENA** | 3.2, 1.9 | PostgreSQL NOTIFY/LISTEN o trigger → Redis DEL → perfil siempre fresco |
| **Unificar catálogo productos recomendados** | 1.3, 1.7, 3.5, 4.4 | Single endpoint `/api/products/recommend?serviceId=&userId=` que haga mapping tag + filtro audience + ingredientes ATENA |
| **RAGAS evaluation pipeline** | 3.7, 5.1 | Automatizar evaluación calidad RAG (faithfulness, answer_relevancy, context_precision) en CI/CD |
| **Circuit breaker métricas en /api/admin/metrics** | 3.8, 4.8 | Exponer estado breakers (deepseek/gemini/embedding) + hit rate cache semántico en dashboard admin |
| **Booking recovery service → Web push nativo** | 1.3, 4.7 | `booking_recovery_service.dart` usa localStorage; migrar a Service Worker + Push API para web PWA |
| **Provider geofence check-in automático** | 2.5, 4.1 | Al llegar a 100m del service_address → auto START booking (reduce fricción prestador) |
| **CHRONOS push notifications proactivas** | 3.4, 4.7 | Cuando treatment due → push "Tu manicura vence en 3 días, ¿agendamos?" con deep link a booking |
| **VALKYRIE insights → AURA tool call automático** | 3.6, 3.1 | Si usuario pregunta "¿cuándo voy?" y es prestador → AURA llama VALKYRIE y sugiere promo día lento |
| **Design System migration completada** | 6.6 | Terminar migración AppTheme/belleza_luxe_theme → GlowStoreTokens + Token class en todas las pantallas |

---

## 14. Candidatos a Auditoría Profunda (Ordenados por Prioridad)

| Orden | Unidad | Razones |
|-------|--------|---------|
| **Auditoría 1** | **4.1 Motor de Reservas + 4.2 Pagos Wompi + Split Financiero** | Núcleo monetario; compliance legal; cualquier bug = pérdida dinero real + confianza |
| **Auditoría 2** | **3.1 AURA Orquestador + 3.7 RAG + 3.8 Cache/Observabilidad** | Diferenciador IA; superficie de ataque (prompt injection, PII leakage); latencia P95; fallback chains |
| **Auditoría 3** | **1.3 BookingScreen (3 pasos)** | God component 1409 líneas; lógica negocio en UI; crítico conversión; accesibilidad; responsive |
| **Auditoría 4** | **1.2 ProviderDetailScreen + 2.1/2.2/2.3/2.4 Dashboard Prestador** | Pares cliente-prestador; SliverAppBar parallax; trust signals (verificado, rating, portfolio); CTA conversion |
| **Auditoría 5** | **6.1 Auth + 6.2 Consentimiento Biométrico** | Seguridad base; Habeas Data Ley 1581; SecureStorage; OAuth flows; token refresh |
| **Auditoría 6** | **3.2 ATENA + 1.8/1.9 Módulo Ideas/Visajismo** | Pipeline biométrico completo: captura → diagnóstico → cache → recomendación → booking |
| **Auditoría 7** | **4.5 Disputas + 4.6 Reseñas + 4.7 Notificaciones** | Post-servicio; trust & safety; SLA 48h; mediation logic; push/WS reliability |
| **Auditoría 8** | **5.1/5.2/5.3 RAG Pipeline + Corpus Ingestion** | Calidad conocimiento; fuentes autorizadas; embedding drift; evaluación continua |
| **Auditoría 9** | **6.6 Design System (GlowStoreTokens + Token class)** | Consistencia visual; migración legacy; audience parity; accessibility tokens |
| **Auditoría 10** | **2.5 Agenda/Rutas + 4.7 Notificaciones + 1.5 Tracking/SOS** | Logística última milla; geofence; routing; SOS real-time; provider UX |
| **Auditoría 11** | **3.6 VALKYRIE B2B + 3.4 CHRONOS + 3.3 HERMES** | Agentes especializados; revenue optimization; re-booking; geo |
| **Auditoría 12** | **1.7 GlowStore E-commerce + 4.4 + 3.5 HESTIA** | Cross-sell; funnel booking→productos; recomendación personalizada |
| **Auditoría 13** | **1.6 Wallet/Retiros + 2.1 + 4.2 Conciliación** | Liquidez prestador; conciliación Wompi; auto-retiros |
| **Auditoría 14** | **4.8 Analíticas + 5.5 Telemetría + Config Dinámica** | Observabilidad negocio; proyecciones; feature flags |
| **Auditoría 15** | **6.5 Migraciones/Seeds + 6.3 Infra Transversal** | Deploy safety; rate limiting; jobs; security hygiene |

---

## 15. Matriz Final de Priorización

| Prioridad | Unidad | Función | Estado | Criticidad | Valor Estratégico | Complejidad | Problema Principal | Acción Futura |
|-----------|--------|---------|--------|------------|-------------------|-------------|-------------------|---------------|
| 1 | Motor de Reservas (4.1) | Estados + split financiero | Operativo | **P0** | Alto | Media | Lógica precios duplicada Flutter/Backend | **Refactorizar** (endpoint preview) |
| 2 | Pagos Wompi (4.2) | Checkout + webhook + split | Operativo | **P0** | Alto | Alta | Falta conciliación automática diaria | **Optimizar** (job conciliación) |
| 3 | Autenticación (6.1) | JWT + OAuth + SecureStorage | Operativo | **P0** | Alto | Baja | Duplicación _getToken en ApiService | **Refactorizar** (centralizar AuthService) |
| 4 | AURA Orquestador (3.1) | Chat IA + 8 tools + fallback | Operativo | **P0** | **Muy Alto** | Alta | Latencia P95; cache hit rate bajo | **Optimizar** (cache warming, model routing) |
| 5 | RAG Conocimiento (3.7/5.1) | Búsqueda vectorial + fallback | Operativo | **P1** | **Muy Alto** | Media | Columna vector(768) vs 1024 dims | **Corregir** (migrar + re-embed) |
| 6 | BookingScreen (1.3) | 3-step checkout + cross-sell | Operativo | **P1** | Alto | **Muy Alta** | God component 1409 líneas; lógica en UI | **Refactorizar** (ViewModel + step widgets) |
| 7 | ProviderDetailScreen (1.2) | Descubrimiento + trust signals | Operativo | **P1** | Alto | Alta | Parallax/cover genérico; trust info disperso | **Optimizar** (UI + personalización) |
| 8 | ATENA Biometría (3.2) | Diagnóstico facial/manos | Operativo | **P1** | Alto | Media | Cache Redis sin invalidación automática | **Optimizar** (event-driven invalidation) |
| 9 | GlowStore (1.7/4.4) | E-commerce + cross-sell | Operativo | **P1** | Medio | Media | HESTIA fallback hardcoded; filtro duplicado | **Integrar** (endpoint unificado recommend) |
| 10 | VALKYRIE B2B (3.6) | Precios dinámicos prestador | Operativo | **P2** | **Muy Alto** | Baja | Solo ocupación simple; sin variables externas | **Expandir** (estacionalidad, clima, competencia) |
| 11 | HERMES Geo (3.3) | PostGIS búsqueda + disponibilidad | Operativo | **P2** | Alto | Baja | checkAvailability usa booking_date (legacy) vs scheduled_at | **Corregir** (unificar campo fecha) |
| 12 | CHRONOS Re-booking (3.4) | Ciclo vida tratamientos | Operativo | **P2** | Medio | Baja | Hardcoded cycles; no aprende de usuario | **Mejorar** (ML ciclos personalizados) |
| 13 | Dashboard Prestador (2.1) | KPIs + acciones rápidas | Operativo | **P2** | Medio | Media | Métricas básicas; sin comparativas temporales | **Expandir** (tendencias, cohortes) |
| 14 | Disputas (4.5) | Mediación SLA 48h | Operativo | **P2** | Medio | Media | Flujo manual admin; sin plantillas resolución | **Optimizar** (plantillas + auto-suggest) |
| 15 | Notificaciones WS (4.7) | Tiempo real + Push + SSE | Operativo | **P1** | Alto | Media | Reconnection logic; delivery guarantees | **Robustecer** (ack + retry + dead letter) |
| 16 | Wallet/Retiros (1.6/2.1) | Saldo + retiros Nequi/Bancaria | Funcional incompleto | **P2** | Medio | Media | Sin conciliación Wompi; retiro manual admin | **Completar** (conciliación + auto-retiro) |
| 17 | Módulo Ideas/Visajismo (1.8/1.9) | Diagnóstico IA + inspiración | Experimental/Parcial | **P3** | **Muy Alto** | Alta | Módulos sueltos; sin funnel a booking medido | **Integrar** (tracking conversión Ideas→Booking) |
| 18 | Design System (6.6) | Tokens multi-audience | Operativo (Locked) | **P2** | Alto | **Muy Alta** | 5 archivos tokens legacy; migración incompleta | **Migrar** (plan fases por pantalla) |
| 19 | Corpus Ingestion (5.2) | Auto-ingesta conocimiento | Funcional incompleto | **P3** | Medio | Alta | Fuentes limitadas; sin evaluación calidad | **Expandir** (fuentes + RAGAS eval) |
| 20 | Academia Prestador (2.6) | Capacitación + certificaciones | Experimental | **P4** | Bajo | Alta | Parcial; sin integración rating/verificación | **Investigar** (validar necesidad real) |
| 21 | Cache Semántico (3.8) | Embedding cache + observabilidad | Operativo | **P2** | Medio | Media | Hit rate no medido en dashboard; TTL fijo | **Optimizar** (métricas + TTL adaptativo) |
| 22 | Consentimiento Biométrico (6.2) | Habeas Data granular + audit | Operativo | **P1** | Alto | Baja | Bien implementado; revisar coverage tool calls | **Auditar** (cobertura completa) |
| 23 | Analíticas/Telemetría (4.8) | Eventos batch + dashboard admin | Operativo | **P2** | Medio | Media | Proyección lineal simple; sin alertas automáticas | **Mejorar** (anomaly detection + alertas) |
| 24 | Migraciones/Seeds (6.5) | Schema versionado + auto-migrate | Operativo | **P1** | Alto | Baja | Funciona; revisar idempotencia y rollback | **Auditar** (test rollback en staging) |
| 25 | Portafolio Prestador (2.3) | Fotos trabajos + likes | Operativo | **P3** | Medio | Baja | Funcional; sin moderación contenido | **Optimizar** (moderación IA + orden drag-drop) |

---

## 16. Secuencia Óptima de Auditoría Profunda (Respuesta a Pregunta Central)

> **"Si tuviera que entender GlowApp sin leer todo su código, ¿cuáles son las unidades de funcionamiento que necesito conocer y en qué orden debería estudiarlas?"**

**Orden basado en dependencias críticas + criticidad + valor estratégico:**

```
AUDITORÍA 1  →  Motor de Reservas + Pagos Wompi + Split Financiero (4.1 + 4.2)
                 └─ Núcleo monetario; compliance; sin esto no hay negocio

AUDITORÍA 2  →  Autenticación JWT + Consentimiento Biométrico (6.1 + 6.2)
                 └─ Base de seguridad; todo lo demás requiere userId autenticado + consentimientos

AUDITORÍA 3  →  AURA Orquestador + RAG + Cache/Observabilidad (3.1 + 3.7 + 3.8)
                 └─ Diferenciador estratégico IA; superficie riesgo (PII, alucinaciones, latencia)

AUDITORÍA 4  →  BookingScreen 3-pasos (1.3)
                 └─ UX crítica conversión; god component; lógica precios duplicada

AUDITORÍA 5  →  ProviderDetailScreen + Dashboard Prestador (1.2 + 2.1/2.2/2.3/2.4)
                 └─ Par cliente-prestador; trust signals; CTA conversión; SliverAppBar parallax

AUDITORÍA 6  →  ATENA Biometría + Módulo Ideas/Visajismo (3.2 + 1.8/1.9)
                 └─ Pipeline IA completo: captura → diagnóstico → cache → recomendación → booking

AUDITORÍA 7  →  Disputas + Reseñas + Notificaciones (4.5 + 4.6 + 4.7)
                 └─ Post-servicio; trust & safety; SLA; tiempo real reliability

AUDITORÍA 8  →  RAG Pipeline + Corpus Ingestion (5.1 + 5.2 + 5.3)
                 └─ Calidad conocimiento; fuentes; embedding drift; evaluación continua

AUDITORÍA 9  →  Design System Tokens (6.6)
                 └─ Consistencia visual; migración legacy; audience parity; accessibility

AUDITORÍA 10 →  Agenda/Rutas + Tracking/SOS (2.5 + 4.7 + 1.5)
                 └─ Logística última milla; geofence; routing; SOS real-time

AUDITORÍA 11 →  VALKYRIE B2B + CHRONOS + HERMES (3.6 + 3.4 + 3.3)
                 └─ Agentes especializados; revenue optimization; re-booking; geo

AUDITORÍA 12 →  GlowStore E-commerce + HESTIA (1.7 + 4.4 + 3.5)
                 └─ Cross-sell; funnel booking→productos; recomendación personalizada

AUDITORÍA 13 →  Wallet/Retiros + Conciliación (1.6 + 2.1 + 4.2)
                 └─ Liquidez prestador; conciliación Wompi; auto-retiros

AUDITORÍA 14 →  Analíticas + Telemetría + Config Dinámica (4.8 + 5.5)
                 └─ Observabilidad negocio; proyecciones; feature flags

AUDITORÍA 15 →  Migraciones/Seeds + Infra Transversal (6.5 + 6.3 + 6.4)
                 └─ Deploy safety; rate limiting; jobs; security hygiene
```

---

## 17. Conclusión: Qué Conservar / Mejorar / Refactorizar / Investigar / Retirar

| Categoría | Unidades | Acción |
|-----------|----------|--------|
| **CONSERVAR (Core Maduro)** | 4.1, 4.2, 6.1, 3.1, 3.7, 1.3, 1.2, 2.1, 2.2, 2.3, 2.4, 3.2, 3.3, 3.4, 3.5, 3.6, 4.5, 4.6, 4.7, 5.1, 5.3, 5.4, 5.5, 6.2, 6.3, 6.4, 6.5, 6.6 | Base sólida; no tocar salvo bugs críticos |
| **OPTIMIZAR (Funcional con deuda)** | 1.3 (BookingScreen), 1.6 (Wallet), 2.5 (Rutas), 3.8 (Cache métricas), 4.8 (Analíticas), 1.7/4.4 (GlowStore unificado), 3.2 (ATENA cache invalidation) | Mejoras incrementales; ROI alto |
| **REFACTORIZAR (God components / duplicación)** | 1.3 → ViewModel + steps, 6.1 → centralizar AuthService, 4.1/1.3 → endpoint preview precios, Design System → migración completa | Requiere sprints dedicados; tests primero |
| **INTEGRAR (Fragmentado)** | 3.5+4.4+1.3 (productos recommend), 1.8/1.9+3.2 (Ideas→ATENA→Booking), 3.6+3.1 (VALKYRIE→AURA auto), 3.4+4.7 (CHRONOS→Push) | Cerrar loops; funnels medibles |
| **INVESTIGAR (Experimental / Dudoso)** | 1.8/1.9 (módulos Ideas sueltos), 2.6 (Academia), 5.2 (Corpus fuentes), nail_tryon_jobs, background workers legacy | Validar necesidad real antes de invertir |
| **RETIRAR (Código muerto)** | nail_tryon_jobs table, geminiService.js.backup, R6_RECOVERY*.sql, scratch/, portafolio_servicios JSONB (DROP), workers comentados | Limpieza inmediata; cero riesgo |

---

**Este mapa funcional permite ahora auditar UNA UNIDAD A LA VEZ con la secuencia correcta, entendiendo sus dependencias, criticidad y el impacto real de cada cambio sobre el sistema productivo GlowApp.**