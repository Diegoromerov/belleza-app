# GlowApp — Auditoría de Mercado Digital y Estrategia de Lanzamiento
### Bogotá · Q4 2026 – Q2 2027

**Autor:** Asesor de mercado digital (auditoría de repositorio + estrategia GTM)
**Fecha:** 2026-10-24
**Commit auditado:** `a2d1277` (main, 2026-10-23)
**Alcance:** todo el monorepo (`frontend/`, `backend/`, `admin-dashboard/`, `docs/`), con foco en lo que determina la capacidad real de adquirir, convertir y retener usuarios.

---

## 0. Resumen ejecutivo

**Veredicto: el producto no está listo para un lanzamiento comercial abierto. Está listo para un piloto de densidad en una sola ciudad, con un solo wedge y una sola promesa.**

GlowApp tiene hoy más producto que negocio. El repositorio contiene un cliente Flutter con 195 archivos Dart y ~50 módulos de rutas backend, cuatro negocios distintos (marketplace de servicios, SaaS para salones, tienda con tres niveles comerciales, motor de IA con ciclos de 30 días), documentación legal y una arquitectura multi-tenant razonable. En la base de datos real hay **49 cuentas, 83 reservas históricas, 41 prestadores, 8 clientes y 1 pedido de tienda** (`docs/glowshop/FASE_A0_ARRANQUE_LIMPIO.md`, `docs/glowshop/MODELO_NIVELES_COMERCIALES.md` §2).

Eso no es un fracaso: es un piloto. El problema es que el repositorio y los documentos se tratan a sí mismos como un producto terminado (**"98,65% de madurez empírica"**, `GIA-17-R-PRODUCT-MATURITY.md`), y esa ficción es el mayor riesgo comercial que tiene el proyecto: lleva a gastar en adquisición lo que todavía no puede retener.

### Las cinco conclusiones que ordenan todo lo demás

1. **El cuello de botella es demanda, no producto.** La relación es 5 prestadores por cada cliente (41:8). Cualquier peso invertido en más features o más prestadores antes de resolver esto se destruye.
2. **La atribución está rota de fábrica.** `GTM-GLOWAPP` y `GLOWAPP_PIXEL_ID` son placeholders (`frontend/web/index.html:73` y `:86`), no existe captura de UTM en ninguna parte del cliente, y el programa de referidos es backend-only: `getReferralInfo` genera código y un enlace `?ref=` (`backend/src/controllers/authController.js:538-571`) que **ninguna pantalla del app lee**. Pagar medios hoy es comprar a ciegas.
3. **La única prueba social que existe es falsa.** El `index.html` declara en Schema.org `ratingValue: 4.9` con `reviewCount: 1250` (`:33-34`). No hay reseñas reales. Es un pasivo legal y de plataforma, no un activo de marketing.
4. **El diferencial real es la transformación medible, no el directorio de citas.** Antes/después con delta a D15/D30 a un costo marginal de IA de USD 0,04 por ciclo (`GIA-16-O-UNIT-ECONOMICS.md`). Ese es el wedge; el marketplace es el monetizador.
5. **Cuatro negocios no caben en un lanzamiento.** Servicios (B2C), SaaS de salones (B2B), tienda B2B/B2C y suscripción de IA compiten por el mismo equipo, el mismo soporte y la misma caja. El orden correcto es: servicios + IA → SaaS de salones → comercio.

### Launch readiness score

| Categoría | Peso | Puntaje | Evidencia |
|---|:--:|:--:|---|
| Medición y atribución | 15% | 10/100 | IDs placeholder, sin UTM, sin evento de campaña |
| Prueba social y contenido propio | 15% | 15/100 | 0 casos documentados, rating inventado |
| Oferta / densidad de suministro | 15% | 30/100 | 41 prestadores, 8 clientes, sin SLA de disponibilidad |
| Distribución (tiendas, PWA, SEO) | 15% | 20/100 | Sin apps publicadas; Flutter Web con hash routing |
| Canales propios (email, push) | 10% | 10/100 | Sin `RESEND_API_KEY`/`SENDGRID_API_KEY`/`FIREBASE_PROJECT_ID` en el entorno auditado |
| Pagos | 10% | 60/100 | Wompi integrado y verificado; sin llave en entorno auditado |
| Legal y consentimiento | 5% | 70/100 | T&C, privacidad y contrato de prestadoras existen; falta aviso de cookies/analítica y rating inventado |
| Producto core (reserva) | 10% | 75/100 | Flujo completo, RLS, escrow, disputas |
| Marca y activos | 5% | 25/100 | `manifest.json` dice "Beauty App"; tema rosa vs. identidad GlowApp |
| **TOTAL PONDERADO** | **100%** | **31/100** | **No lanzable** — el umbral de lanzamiento es 65 |

**Nadie debería aprobar una campaña con este puntaje.** La ruta para subirlo está en §8 y §12.

---

## 1. Método y límites de esta auditoría

**Qué hice:** leí el código del cliente y del servidor en `main`, los documentos de producto y evidencia (`GIA-*`), los lineamientos comerciales de la tienda, la configuración de despliegue, los activos web, y verifiqué presencia de credenciales de integración sin leer sus valores. Contrasté el estado del producto con precios públicos de competidores en Colombia y con cifras del sector.

**Cómo se lee este documento:**
- **[HECHO]** = verificado en el repositorio o en fuente pública citada.
- **[HIPÓTESIS]** = juicio profesional a validar con datos; no es un hecho.
- Todo precio propuesto es una **recomendación a validar**, no un requisito de producto.

**Qué no pude verificar:** no tuve acceso a la base de producción ni a paneles de analítica, así que los conteos de usuarios provienen de documentos del propio repositorio que declaran haberlos medido. No hay datos de retención, cohortes ni conversión reales en ningún lugar del repositorio: los documentos que las reportan (`GIA-17-*`) afirman resultados sin fuente de datos adjunta.

---

## 2. Auditoría: hallazgos con evidencia

Severidad: **B** = bloquea el lanzamiento · **A** = alta · **M** = media · **X** = riesgo de compliance.

| # | Sev | Hallazgo | Evidencia | Impacto comercial |
|---|:--:|---|---|---|
| 1 | **X** | Rating y reseñas inventadas en datos estructurados | `frontend/web/index.html:33-34` (`ratingValue 4.9`, `reviewCount 1250`) | Riesgo de acción manual de Google, exposición ante la SIC por publicidad engañosa, y destrucción de confianza al primer usuario real que vea 0 reseñas dentro del app |
| 2 | **B** | GTM y Meta Pixel con IDs placeholder | `index.html:73` (`GTM-GLOWAPP`), `:86` (`GLOWAPP_PIXEL_ID`) | Cero medición de campañas, cero retargeting, cero atribución. Todo gasto en medios sería no auditable |
| 3 | **B** | Sin captura de UTM/origen en el cliente | `grep` de `utm_` en `frontend/lib`: 0 coincidencias reales | Imposible saber qué canal trae usuarios que reservan; imposible optimizar CAC |
| 4 | **B** | Programa de referidos sin receptor | Backend genera código y `shareUrl` (`authController.js:538-571`); `grep` de `referral_code`/`?ref=` en `frontend/lib`: 0 coincidencias | El único loop orgánico del producto está muerto. El premio de $10.000 COP no tiene canje servidor |
| 5 | **A** | Los documentos declaran madurez que la base contradice | `GIA-17-R-PRODUCT-MATURITY.md` (98,65%), `GIA-16-P-REAL-EVIDENCE-MATRIX.md` (todo "PROVEN") vs. 49 usuarios / 83 reservas | Decisiones de inversión basadas en una ficción; el equipo cree tener tracción que no tiene |
| 6 | **A** | Sin apps en tiendas; distribución = Flutter Web SPA | Sin referencias de publicación en el repo; `frontend/web` es el artefacto servido | En Colombia el discovery de belleza móvil ocurre en Play Store; una PWA sin push nativo confiable ni icono en home limita retención |
| 7 | **A** | SEO estructuralmente imposible en el shell | `sitemap.xml` lista URLs con `#/store` y `#/academy` (los fragmentos no se indexan); `robots.txt` bloquea `/#/checkout` (ineficaz); el contenido se renderiza en canvas | El tráfico orgánico a la app es ~0. Se necesita un sitio de marketing separado, no optimizar este |
| 8 | **A** | Canales propios no configurados | `.env` auditado: `RESEND_API_KEY`, `SENDGRID_API_KEY`, `FIREBASE_PROJECT_ID`, `WOMPI_PRIVATE_KEY` ausentes | Sin email no hay onboarding, ni carrito abandonado, ni reactivación, ni recibos. Sin FCM no hay recordatorios de re-scan, que es el corazón del ciclo de 30 días |
| 9 | **A** | Desbalance de liquidez 41:8 | `MODELO_NIVELES_COMERCIALES.md` §2 (41 prestadores, 8 clientes, 0 salones) | Sin demanda, los prestadores se van en 30-60 días. Es el modo de muerte estándar de un marketplace |
| 10 | **A** | El cambio de precio a prestadores (+38%) está agendado para el arranque | `MODELO_NIVELES_COMERCIALES.md` §2: de 65% a 90% del PVP | Aplicarlo en el lanzamiento dispara churn del 100% de tu suministro, que son 41 personas. Debe congelarse |
| 11 | **A** | Pricing B2B fuera del ancla del mercado colombiano | `invoiceService.js:448-450`: BASIC 99.000, PRO 249.000, ENTERPRISE 599.000 COP/mes vs. AgendaPro 29.900–159.000 (2–6 profesionales) y Gestabiz 0/15.000/89.900/159.900 COP | El plan PRO queda por encima del competidor líder para un salón de 6–15 profesionales, sin marca ni prueba. No se vende por lista de precios |
| 12 | **M** | Tienda sin costo de mercancía | `MODELO_NIVELES_COMERCIALES.md` §2 y §7.5 | No se puede saber si vender al 80% deja margen; prometer precios B2B sin costo es apostar a ciegas |
| 13 | **M** | Un solo pedido de tienda en toda la historia | `FASE_A0_ARRANQUE_LIMPIO.md` (1 pedido, PAGADO, 57.220, con bug) | La tienda no tiene evidencia de demanda. No puede ser parte del lanzamiento |
| 14 | **M** | Marca inconsistente | `manifest.json:2-3` ("Beauty App" / "BeautyApp") vs. título GlowApp (`index.html`) y `pubspec.yaml` (`beauty_app`) | PWA instalada con nombre equivocado; ASO y recordación de marca rotas |
| 15 | **M** | Documentación operativa desbordada | >300 archivos `.md` en la raíz, decenas de documentos `F7.00x-*-GATE` con estados contradictorios (`BLOCKED`, `COMPLETE`, `FINAL` del mismo hito) | Costo de onboarding altísimo, y nadie puede saber cuál documento es la verdad. Es deuda de gobernanza que frena cualquier agencia externa |
| 16 | **M** | Sin contenido propio ni activos de marca para pauta | No hay carpeta de assets de campaña, ni casos, ni guiones, ni kit de prensa | Una campaña necesita 20-30 piezas; hoy hay cero |
| 17 | **+** | Consentimiento biométrico y Habeas Data implementados | `glow_consent_widget.dart`, `capture_screen.dart:84`, `biometricConsentRoutes.js` | Activo real de confianza en una categoría donde la gente teme subir su cara. Debe estar en el mensaje, no escondido |
| 18 | **+** | Legal base listo | `docs/legal/`: T&C clientes, política de privacidad (Ley 1581), contrato de prestadoras | Ahorra 3-4 semanas frente a un lanzamiento desde cero |
| 19 | **+** | Escrow, disputas y verificación de webhook | `paymentRoutes.js`, `disputeRoutes.js`, webhook Wompi verificado | Argumento de venta frente a coordinar por WhatsApp: "el dinero queda retenido hasta que el servicio se complete" |
| 20 | **+** | Costo marginal de IA despreciable | `GIA-16-O-UNIT-ECONOMICS.md`: USD 0,04/ciclo de 30 días | Permite regalar el diagnóstico como lead magnet sin destruir margen |

### 2.1 El diagnóstico incómodo

Los hallazgos 5, 15 y 1 comparten una causa: **el repositorio se usa como mecanismo de auto-convencimiento en lugar de como registro de evidencia**. Documentos que se autodeclaran "PASS" y "PROVEN" sin un solo dato de usuario son el equivalente organizacional de las 1.250 reseñas falsas del `index.html`. Antes de gastar un peso en marketing, esta práctica tiene que cambiar: **una métrica sin query, fecha y N no es una métrica.**

---

## 3. Mercado y competencia

### 3.1 Contexto de categoría [HECHO, fuentes públicas]

- La industria cosmética y de aseo en Colombia facturó **USD 6.861 millones en 2025**; el segmento de belleza y cuidado personal, **USD 3.565 millones (+8,6%)**. Representa 1,61% del PIB ([Forbes Colombia, 13-may-2026](https://forbes.co/economia-y-finanzas/industria-cosmetica-y-de-aseo-movio-us6-800-millones-en-colombia-durante-2025)).
- El **34,1% de las decisiones de compra** en la categoría se explica por calidad percibida por encima de precio o promoción (RADDAR, citado en la misma nota). Esto favorece narrativas de resultado y diagnóstico por encima de narrativas de descuento.
- El software de agenda en Colombia tiene un ancla de precio muy baja: **AgendaPro 29.900–510.000 COP/mes** según número de profesionales; **Gestabiz 0 / 15.000 / 89.900 / 159.900 COP/mes** con plan gratuito ([Gestabiz vs AgendaPro, sep-2026](https://gestabiz.com/co/blog/gestabiz-vs-agendapro-colombia)). Fresha opera con modelo gratuito + comisiones.

### 3.2 Mapa competitivo real de GlowApp

| Competidor | Qué es | Precio | Por qué gana | Debilidad explotable |
|---|---|---|---|---|
| **Instagram / WhatsApp del salón** | El competidor verdadero | Gratis | Cero fricción, relación humana, la clienta ya está ahí | Sin disponibilidad real, sin pago anticipado, sin historial, sin medición |
| **Fresha / Booksy** | Marketplace global de reservas | Gratis + comisión | Marca, oferta, app madura | No resuelve "¿me funcionó?"; catálogo genérico; poca densidad real en barrios de Bogotá |
| **AgendaPro / Gestabiz** | SaaS de agenda y CRM | 0–510.000 COP/mes | Precio, contabilidad DIAN, presencia local, venta directa | Herramienta de gestión: no trae clientas nuevas; el salón sigue pagando por ser encontrado |
| **Rappi / domicilios** | Logística | Comisión alta | Confianza y velocidad | No es belleza; sin criterio profesional |
| **Retail (Sally, Farmatodo, Éxito)** | Producto | — | Precio, inmediatez | Sin diagnóstico ni rutina personalizada |

**Espacio libre [HIPÓTESIS]:** nadie en Colombia está vendiendo *resultado verificable* en belleza — "no solo te agendo la cita, te demuestro con números si tu piel mejoró". AgendaPro vende administración; Fresha vende visibilidad; Instagram vende afecto. GlowApp puede vender **evidencia de progreso**, que es lo que la clienta compra emocionalmente y lo que ninguna herramienta de agenda puede falsificar.

---

## 4. Segmentación, ICP y JTBD

### ICP 1 — "Camila", clienta urbana (motor de demanda)
- 24-38 años, estratos 3-4, Bogotá (Chapinero, Cedritos, Usaquén, Suba), trabaja, ingreso 2,5–6 SMMLV.
- Gasta 80.000–250.000 COP/mes en belleza, repartido entre salón de barrio, una "manicurista de confianza" y compras impulsivas en Instagram.
- **JTBD:** *"Cuando veo que mi piel no mejora, necesito saber qué me está fallando y qué hacer esta semana, sin gastar en productos que no sirven."*
- Dolor: probó 6 cremas y ninguna funcionó; no sabe si el tratamiento caro valió la pena; le da pereza coordinar por WhatsApp.
- Detonante de compra: un antes/después creíble de alguien como ella, en su mismo barrio.

### ICP 2 — "Andrea", prestadora independiente (motor de oferta y de contenido)
- 26-45 años, trabaja sola o con 1-2 personas, agenda por WhatsApp, 15-40 servicios/mes, ticket 40.000–120.000 COP.
- **JTBD:** *"Necesito llenar los huecos de mi semana y verme profesional frente a clientas que comparan."*
- Dolor: depende de Instagram; las cancelaciones de último minuto le cuestan el día; no tiene cómo demostrar que su trabajo funciona.
- Lo que la retiene en GlowApp: reservas pagadas por adelantado + un antes/después que ella puede publicar como portafolio.

### ICP 3 — "Salón pequeño" (5-15 profesionales) — **no es ICP de lanzamiento**
Es el comprador del SaaS de 249.000 COP. Requiere venta consultiva, migración de datos y soporte presencial. Entra en Fase 4 con 5 design partners, no antes.

### Anti-ICP (a quién decir que no, explícitamente)
- Cadenas y franquicias (>15 profesionales): ciclo de venta largo, exigen integración contable.
- Estética médica / procedimientos invasivos: claims regulados, riesgo sanitario, fuera de la promesa.
- Ciudades distintas a la de lanzamiento: sin densidad no hay marketplace, solo un directorio vacío.
- Hombres 18-24 / barbería: mercado grande pero con competidor dominante y lógica de precio distinta. No en este ciclo.

---

## 5. Posicionamiento y arquitectura de mensaje

### 5.1 Declaración de posicionamiento

> Para mujeres de 25 a 38 años en Bogotá que ya invierten en su piel y no saben si les está funcionando, **GlowApp** es la única plataforma de belleza que **mide tu progreso y te agenda el siguiente paso**. A diferencia de un directorio de salones o de coordinar por WhatsApp, GlowApp te da un diagnóstico con números, una rutina para 30 días y la cita para ejecutarla — y a los 30 días te vuelve a medir.

### 5.2 La prueba que sostiene la promesa (y hoy no existe)

Sin tres elementos, esta promesa es publicidad engañosa:
1. **Casos reales con consentimiento** (mínimo 20 antes/después, con delta de métrica y fecha).
2. **Transparencia del método**: qué se mide, con qué, y qué NO puede prometer (una app no diagnostica enfermedades).
3. **Política de datos visible en el flujo**, no en el pie de página: "tu cara se procesa con tu consentimiento y puedes borrarla".

### 5.3 Message house

| Nivel | Mensaje | Soporte |
|---|---|---|
| **Promesa** | "Deja de adivinar con tu piel." | Medición D0 → D15 → D30 |
| **Pilar 1 — Mide** | "Tu piel, con números, no con opiniones." | Escaneo + baseline + delta |
| **Pilar 2 — Ejecuta** | "La rutina y la cita en el mismo lugar." | Rutina AM/PM + agenda + pago anticipado |
| **Pilar 3 — Confía** | "Profesionales verificadas y tu dinero protegido hasta que el servicio se complete." | KYC, escrow, disputas, consentimiento biométrico |
| **RTB (razones para creer)** | 30 días, 3 mediciones, 1 rutina, 1 profesional verificada | Casos, video, capturas del dashboard |
| **Para la prestadora** | "Tu portafolio que se prueba solo." | Antes/después publicable, reservas prepagadas, agenda sin huecos |

### 5.4 Matriz de claims: qué se puede decir y qué no

| ✅ Permitido | ❌ Prohibido | Por qué |
|---|---|---|
| "Mide la hidratación y los poros de tu piel" | "Elimina las manchas en 30 días" | El segundo es un claim de resultado clínico |
| "Tu rutina personalizada según tu diagnóstico" | "Tratamiento dermatológico" | Invasión de acto médico |
| "El 78% de las usuarias del piloto completó su ciclo" (con N y fecha) | "Miles de mujeres ya confían en nosotros" | Sin N verificable es publicidad engañosa |
| "Profesionales con identidad verificada" | "Las mejores profesionales de Bogotá" | Superlativo no sustentable |
| "Tu dinero queda retenido hasta que el servicio se complete" | "Pago 100% seguro" | Absoluto; mejor describir el mecanismo |

---

## 6. Modelo de negocio recomendado por fase

**Regla:** un negocio por fase. Cuatro líneas de ingreso simultáneas con un equipo de una persona no es una estrategia, es una lista de deseos.

| Fase | Negocio activo | Cómo se cobra | Precio recomendado [HIPÓTESIS a validar] |
|---|---|---|---|
| 0-2 | Servicios + IA | Comisión por reserva + ciclo de IA | Comisión 12% al prestador (hoy 10%) + **Glow Cycle a 49.900 COP** por 30 días (3 escaneos, rutina, chat) |
| 2-3 | Servicios | Membresía clienta | **Glow+ 19.900 COP/mes** (escaneos ilimitados, prioridad, 10% en servicios) |
| 3-4 | SaaS salones | Suscripción por profesional, no por plan | **Entrada 79.900 COP/mes hasta 5 profesionales**, luego +12.000 por profesional. No lanzar 249.000 sin 10 clientes de referencia |
| 5+ | Comercio | Margen de producto | Mantener 100/90/80 con `costo` obligatorio antes de prometer el nivel negocio |

### 6.1 Tres decisiones de pricing que hay que tomar ahora

1. **Congelar el paso de 65% a 90% para prestadores** (`MODELO_NIVELES_COMERCIALES.md` §2) hasta que exista demanda que justifique el aumento. Aplicarlo al lanzamiento convierte a 41 aliados en 41 detractores en la misma semana en que necesitas que hablen bien de ti.
2. **Reanclar el SaaS al mercado colombiano.** 249.000 COP/mes para un salón de 6-15 profesionales es más caro que AgendaPro Básico (159.000) y que Gestabiz Pro (159.900), con menos funciones contables y sin marca. La entrada debe ser 79.900–99.000 COP con precio por profesional, y el motor de ingreso debe ser la comisión por reserva nueva (que es lo que el salón sí valora: clientas, no software).
3. **No cobrar por el escaneo inicial.** Es el lead magnet más barato del portafolio (USD 0,04 por ciclo) y la única puerta de entrada a tu diferenciador. Se monetiza el ciclo completo y la membresía.

---

## 7. Estrategia de lanzamiento

### 7.1 Tesis de lanzamiento

**No es un lanzamiento nacional. Es la conquista de dos barrios en Bogotá con un producto que se prueba con la cara, y desde ahí se expande por radio.**

Un marketplace sin densidad es una página en blanco. La unidad de lanzamiento no es la ciudad sino el **clúster de 3 km**: una clienta debe encontrar 3 profesionales disponibles en su radio, y una profesional debe recibir al menos 4 solicitudes por semana. Todo lo demás (pauta nacional, app store, PR masivo) es vanidad que quema caja antes de tener retención.

### 7.2 Fases, fechas y gates

Hoy: **2026-10-24**.

#### FASE 0 — Reparar la honestidad y la medición · 27-oct → 14-nov (3 semanas)
Objetivo: que cualquier peso gastado después sea medible, y que el producto no mienta.

| Entregable | Criterio de aceptación | Evidencia |
|---|---|---|
| Quitar `aggregateRating` del JSON-LD | `index.html` sin rating inventado; reemplazado por `Review` reales cuando existan | Diff en `frontend/web/index.html` |
| GTM + Meta Pixel reales (o eliminarlos) | Contenedor con ID productivo; `PageView` visible en DebugView | Captura de GA4/Meta Events |
| Captura de UTM + `ref` en el cliente | `utm_source/medium/campaign` y `?ref=` persistidos en el registro y enviados en el evento de signup | Test E2E: link con UTM → cuenta creada con origen |
| Referidos funcionando de punta a punta | Código canjeable, saldo acreditado, visible en wallet | Test E2E + registro en `transactions` |
| Taxonomía de 14 eventos + dashboard | Cada evento con `session_id`, `source`, `screen`, timestamp | Tabla de eventos poblada |
| Email y push configurados | `RESEND_API_KEY`, `FIREBASE_PROJECT_ID` en producción; correo de bienvenida recibido | Captura de inbox + FCM token |
| Aviso de cookies/analítica | Banner y política actualizada (Ley 1581) | Página publicada |
| Marca coherente | `manifest.json` = GlowApp, iconos, splash, tema | PWA instalada con nombre correcto |

**Gate 0:** readiness ≥ 55 y cero hallazgos **B**/**X** abiertos. Sin esto no se enciende pauta.

#### FASE 1 — Prueba por concierge · 17-nov → 19-dic (5 semanas)
Objetivo: fabricar la evidencia que hoy no existe. No se escala nada; se aprende y se produce contenido.

- **30 mujeres reales** en 2 barrios, reclutadas 1:1 por las prestadoras (no por pauta). Cada una: escaneo D0, rutina, 1 cita agendada y pagada en la app, re-escaneo D15 y D30.
- **Operación concierge:** un humano (fundador) acompaña por WhatsApp, agenda, resuelve y documenta cada fricción. El objetivo no es eficiencia: es aprender dónde se rompe.
- **Producción de contenido:** 30 antes/después con consentimiento escrito, 12 videos verticales de 20-40 s, 6 testimonios en texto, 2 casos largos con números.
- **Prueba de precio:** dos celdas A/B para Glow Cycle (39.900 vs 49.900) y para la comisión (10% vs 12%).
- **Instrumentación:** medir TTFV (tiempo al primer valor), completion a D30, re-scan rate, y las 5 hipótesis de `GIA-16-Q-EXPERIMENTATION-ROADMAP.md` con N real en lugar de supuestos.

**Gate 1 (19-dic):** ≥60% de las 30 completan D30, ≥50% agenda y paga una cita, ≥8 de 10 recomiendan (NPS proxy), y al menos 20 casos publicables. Si no se cumple, **no hay Fase 2**: se itera producto, no se compra tráfico.

#### FASE 2 — Densidad en 2 barrios · 12-ene → 13-feb (5 semanas)
Objetivo: demostrar que el marketplace funciona cuando hay oferta suficiente.

- **30 prestadoras activas** en el radio de 3 km, con disponibilidad publicada y SLA de respuesta de 2 h.
- **Meta: 300 reservas** y ratio de aceptación ≥85%; cancelaciones <8%.
- **Canales:** orgánico + creadoras locales + Google Business Profile. Pauta máxima: **2.000.000 COP en total**, solo para medir CAC por canal, no para crecer.
- **Operación:** garantía "si no llega tu profesional, te devolvemos y te damos el servicio"; línea de WhatsApp con respuesta <15 min en horario.

**Gate 2:** CAC ≤ 25.000 COP, conversión visita→reserva ≥3%, y ≥40% de las clientas repite en 45 días. Si el CAC supera 40.000 sin repetición, el modelo no cierra con comisión del 12% y hay que mover el modelo a membresía antes de escalar.

#### FASE 3 — Lanzamiento público · 16-feb → 13-mar
Objetivo: hacer ruido con prueba debajo, no antes.

- **Momento de marca:** "GlowApp abre en Bogotá" con 20 casos reales, no con un manifiesto.
- **Creadoras:** 10 micro-creadoras bogotanas (8k-60k) con briefing de resultado, no de feature. Pago por entregable + código de referido propio.
- **PR local:** ángulo "la app que le pone números al cuidado de la piel" — medios de bienestar y economía local, no tecnología.
- **Referidos:** el loop ya reparado en Fase 0, con premio de $10.000 COP para quien invita y $10.000 para quien llega (hoy solo existe el lado de quien invita, y ni ese funciona).
- **Pauta:** 4.000.000–6.000.000 COP/mes en Meta y TikTok, por barrio, con creative de antes/después y objetivo de reserva (no de instalación).
- **App store:** publicar Android en esta fase, no antes. Una app con 1 estrella por bugs del día 1 no se recupera.

#### FASE 4 — SaaS de salones con design partners · 16-mar → 30-abr
5 salones, precio de entrada 79.900 COP/mes, contrato de 3 meses, a cambio de: feedback semanal, caso de estudio y referencia. Si 3 de 5 renuevan, se prepara el motor de ventas. Si no, se difiere el SaaS un semestre.

#### FASE 5 — Comercio · a partir de mayo
Solo si hay `costo` por producto, facturación con datos fiscales, liberación de stock y un caso de compra repetida. La tienda hoy tiene 1 pedido histórico: no es un canal, es una hipótesis.

### 7.3 Mapa ORB de canales

| Tipo | Canal | Rol | Táctica concreta | Métrica |
|---|---|---|---|---|
| **Owned** | WhatsApp (lista propia) | Reactivación y cierre | Grupo broadcast de 300 clientas del piloto; recordatorio de re-scan D13 | Re-scan rate |
| **Owned** | Email | Onboarding y ciclo | Secuencia de 6 correos: bienvenida → diagnóstico → rutina → D7 → D13 (re-scan) → D30 (resultado) | Apertura, clic, completion |
| **Owned** | Push | Hábito | Recordatorio matutino por zona horaria + D13/D15 | Check-ins, re-scan |
| **Owned** | PWA/landing | Conversión | 6 landings por barrio + 3 por intención ("manchas", "hidratación", "uñas") | Conversión a registro |
| **Rented** | Instagram | Prueba y descubrimiento | Reels de antes/después, colaboraciones con prestadoras, historias destacadas por servicio | Guardados, DMs, clics |
| **Rented** | TikTok | Alcance orgánico | Serie "30 días midiendo mi piel" con 3 clientas reales | Retención de video, seguidores |
| **Rented** | Google Business Profile | Intención local | Ficha por barrio con reseñas reales de clientas | Llamadas, rutas |
| **Borrowed** | 10 micro-creadoras | Credibilidad | Briefing de resultado, libertad creativa, código propio | CAC por creadora |
| **Borrowed** | Salones aliados | Distribución | Cartel con QR en recepción + incentivo por clienta activada | Activaciones |
| **Borrowed** | Escuelas de belleza (SENA) | Suministro | Convenio: prácticas y certificación Glow Academy | Prestadoras activas |
| **Borrowed** | Prensa local | Autoridad | Nota de datos: "qué mide realmente una app de piel" | Menciones, tráfico directo |

**Lo que NO va en este plan y por qué:** Product Hunt (mercado equivocado, B2C local), ASO agresivo antes de tener app publicada, pauta nacional (quema caja sin densidad), influencers de +500k (CAC insostenible con ticket de 60-90k), y compra de seguidores o reseñas (destruye el único activo: confianza).

---

## 8. Plan de medición

### 8.1 Árbol de KPI

```
North Star: Ciclos completados D30 (usuaria que midió, ejecutó y volvió a medir)
├── Adquisición
│   ├── Visitas por canal (UTM)          ← hoy: inexistente
│   ├── Registro / visita                 ← hoy: medible parcial
│   └── CAC por canal                     ← hoy: imposible
├── Activación
│   ├── TTFV (registro → primer diagnóstico)
│   ├── % que agenda en las primeras 24 h
│   └── % que paga en línea
├── Retención
│   ├── Re-scan D15 y D30
│   ├── Repetición a 45 días
│   └── Churn de prestadoras a 60 días
└── Monetización
    ├── GMV por barrio
    ├── Take rate neto
    └── Margen por ciclo de IA
```

### 8.2 Eventos a instrumentar (14)

| Evento | Propiedades mínimas | Pantalla origen |
|---|---|---|
| `app_open` | source, utm_*, ref | arranque |
| `signup_start` / `signup_complete` | método, ref, barrio | auth |
| `consent_granted` | tipo (datos/biométrico), versión | consentimiento |
| `scan_start` | módulo (skin/hands/color) | captura |
| `scan_complete` | métricas del baseline, duración | procesamiento |
| `plan_viewed` | métrica priorizada | resultados |
| `provider_viewed` | provider_id, barrio, servicio | detalle |
| `booking_start` | servicio, precio | reserva |
| `booking_hold` | slot, precio | reserva |
| `checkout_initiated` | item_type, monto | checkout |
| `purchase_success` | transaction_id, método, monto | pago |
| `rescan_reminder_shown` | día del ciclo | home |
| `rescan_complete` | delta de métrica | captura |
| `share_referral` | canal, código | perfil |

Regla: **todo evento de conversión debe llevar `utm_*` y `ref`**. Sin eso, el plan de canales no se puede evaluar.

### 8.3 Ritual de datos
- **Lunes:** dashboard de 9 métricas, 15 minutos, una sola fuente de verdad.
- **Cada experimento:** hipótesis, métrica primaria, N mínimo, fecha de lectura y decisión escrita — aunque el resultado sea "no concluyente".
- **Regla anti-ficción:** ningún documento puede declarar un resultado sin query, fecha, N y rango de error. Los documentos `GIA-*` que afirman madurez sin datos deben marcarse como obsoletos, no como evidencia.

---

## 9. Unit economics y presupuesto

### 9.1 Economía por clienta [HIPÓTESIS, con base en tickets observados de 57.220–85.000 COP]

| Concepto | Valor | Nota |
|---|---|---|
| Ticket promedio de servicio | 75.000 COP | Rango observado en datos de ejemplo |
| Comisión GlowApp (12%) | 9.000 COP | Subir de 10% a 12% solo con valor demostrado |
| Costo IA por ciclo | ~160 COP | USD 0,04 |
| Costo de soporte por reserva | ~1.500 COP | WhatsApp humano en fase temprana |
| **Margen por reserva** | **~7.300 COP** | Antes de adquisición |
| Reservas por clienta/año (objetivo) | 4 | A validar en Fase 2 |
| **LTV bruto por clienta** | **~29.200 COP** | Sin membresía ni producto |
| CAC objetivo | ≤25.000 COP | Payback en ~3,4 reservas |
| CAC máximo tolerable | 40.000 COP | Solo con membresía activa |

**La conclusión incómoda:** con comisión pura, el LTV (~29.000 COP) apenas cubre un CAC de 25.000. **El negocio no cierra solo con reservas.** Necesita una de dos cosas antes de escalar pauta: (a) membresía Glow+ adoptada por ≥25% de las clientas activas, o (b) attach de producto con margen. Esa es la razón por la que la Fase 2 se mide con repetición y no con volumen.

### 9.2 Presupuesto por escenario (COP/mes)

| Rubro | Lean | Base | Agresivo |
|---|--:|--:|--:|
| Pauta (Meta + TikTok) | 2.000.000 | 5.000.000 | 12.000.000 |
| Creadoras (10-15) | 1.500.000 | 3.500.000 | 7.000.000 |
| Producción de contenido | 800.000 | 2.000.000 | 4.000.000 |
| Herramientas (analítica, email, CRM) | 300.000 | 600.000 | 1.200.000 |
| Incentivos de referido | 500.000 | 1.500.000 | 4.000.000 |
| PR / eventos locales | 0 | 1.000.000 | 3.000.000 |
| **Total** | **5.100.000** | **13.600.000** | **31.200.000** |

Recomendación: **arrancar en Lean** y solo subir cuando el CAC medido esté por debajo de 25.000 durante dos semanas seguidas. Con 13,6M/mes y CAC de 25.000 se compran ~540 clientas/mes; eso solo tiene sentido si la repetición está probada.

---

## 10. Riesgos y mitigaciones

| Riesgo | Prob. | Impacto | Mitigación |
|---|:--:|:--:|---|
| Rating inventado detectado por Google o la SIC | Media | Alto | Eliminar en Fase 0, día 1 |
| Datos biométricos sin control suficiente | Media | Muy alto | Revisar consentimiento, retención y borrado; documentar DPIA; nunca usar fotos en pauta sin autorización escrita y revocable |
| Churn masivo de prestadoras por el cambio de precio | Alta | Alto | Congelar hasta Fase 4; comunicar con 30 días de aviso y grandfathering |
| Sin demanda, la oferta se apaga | Alta | Muy alto | Concierge + garantía de 4 solicitudes/semana o no se les cobra |
| Claims de salud en el contenido | Media | Alto | Matriz de claims (§5.4) en el briefing de toda creadora |
| App store con reseñas de día 1 | Media | Medio | Publicar Android en Fase 3, con al menos 3 semanas de operación estable |
| Fundador absorbido por operación | Alta | Medio | Un solo barrio a la vez; el concierge es un rol con límite explícito de 30 clientas |
| Documentación que se auto-aprueba | Alta | Medio | Marcar `GIA-16/17` como obsoletos; nueva regla de evidencia |

---

## 11. Backlog priorizado (90 días)

### P0 — Bloqueantes (Fase 0, 3 semanas)
1. Eliminar `aggregateRating` inventado y publicar política de reseñas reales. *Aceptación:* JSON-LD válido sin rating hasta tener 10 reseñas verificadas.
2. Implementar GTM y Meta Pixel productivos (o retirarlos si no habrá pauta). *Aceptación:* `PageView` en DebugView.
3. Captura de UTM y `?ref=` en registro. *Aceptación:* cuenta creada desde link con UTM guarda origen consultable.
4. Referidos de punta a punta con canje y saldo. *Aceptación:* E2E invitación → registro → reserva → saldo acreditado.
5. Email transaccional + bienvenida + push FCM. *Aceptación:* correo y push recibidos en dispositivo real.
6. Aviso de cookies y actualización de privacidad. *Aceptación:* banner + política publicada.
7. Marca coherente (manifest, iconos, tema). *Aceptación:* PWA instalada muestra "GlowApp".
8. Dashboard de 9 métricas con una sola fuente. *Aceptación:* actualizado cada lunes sin trabajo manual.

### P1 — Fase 1 y 2
9. Flujo de re-scan D15/D30 con recordatorio y comparativa visual.
10. Pantalla de "Mi Glow" con delta y próxima acción (agendar).
11. Checkout con pago anticipado y garantía visible.
12. Onboarding de prestadora en <15 minutos con disponibilidad publicada.
13. Panel de prestadora: solicitudes, aceptación, ingresos, portafolio.
14. Landings por barrio e intención con formulario y prueba social real.
15. Secuencia de 6 correos del ciclo.

### P2 — Fase 3 y 4
16. Publicación Android + ASO básico (título, capturas, descripción, 10 reseñas reales).
17. Programa de creadoras con códigos y liquidación.
18. Reporte de valor para salones (design partners) y caso de estudio.
19. Motor de membresía Glow+ con cobro recurrente Wompi.
20. Instrumentación de producto para `costo` de mercancía (habilitar la tienda después).

---

## 12. Decisiones que necesito del fundador

1. **¿Ciudad y barrios de lanzamiento?** La evidencia apunta a Bogotá (403 menciones en el repositorio; la estrategia social existente ya la nombra). Necesito los 2 barrios concretos donde hay más prestadoras activas.
2. **¿Se congela el paso de 65% a 90% para prestadoras hasta la Fase 4?** Mi recomendación: sí, con grandfathering permanente para las 41 actuales.
3. **¿Se aprueba Google Play en Fase 3, o el lanzamiento es PWA-only?** La PWA acelera, pero limita retención y credibilidad.
4. **¿Hay caja disponible para 3 meses de Fase 1-2 (≈25M COP) sin ingresos?** Si no, el plan se reduce a un solo barrio y 15 clientas.
5. **¿Quién es el dueño del funnel?** Marketing sin una persona con autoridad sobre producto y soporte no mueve estas métricas.

### Próximos 7 días (si se aprueba este plan)
- Día 1-2: eliminar rating falso, corregir manifest, definir barrios.
- Día 3-4: GTM/Pixel/UTM/`ref` y taxonomía de eventos.
- Día 5-6: email + push en producción; secuencia de bienvenida.
- Día 7: reclutar las primeras 10 clientas del piloto por las prestadoras actuales y agendar el primer escaneo.

---

## Anexo A — Qué documentos del repositorio deben dejar de citarse como evidencia

`GIA-16-P-REAL-EVIDENCE-MATRIX.md`, `GIA-16-S-REAL-PERCENTAGE.md`, `GIA-17-R-PRODUCT-MATURITY.md`, `GIA-17-T-PILOT-DECISION.md`, `GIA-16-O-UNIT-ECONOMICS.md` (el costo de IA es plausible y útil; las cifras de margen del 95% no lo son).

Motivo: declaran resultados de usuario ("PROVEN", 98,65%, "READY FOR COMMERCIAL LAUNCH") sin query, fecha, N ni rango de error, y contradicen los conteos medidos en la propia base (49 usuarios, 83 reservas, 1 pedido). Mantenerlos como fuente de decisión es el riesgo de gobernanza más caro del proyecto.

## Anexo B — Fuentes externas citadas

- Forbes Colombia, *Industria Cosmética y de Aseo movió US$6.800 millones en Colombia durante 2025*, 13-may-2026: [forbes.co](https://forbes.co/economia-y-finanzas/industria-cosmetica-y-de-aseo-movio-us6-800-millones-en-colombia-durante-2025)
- Gestabiz, *AgendaPro Precios 2026: Tabla Completa y Alternativa*, abr-2026: [gestabiz.com](https://gestabiz.com/co/blog/gestabiz-vs-agendapro-colombia)
- Pabau, *Booksy vs Fresha 2026: Precios y funciones*: [pabau.com](https://pabau.com/es/blog/booksy-vs-fresha/)
