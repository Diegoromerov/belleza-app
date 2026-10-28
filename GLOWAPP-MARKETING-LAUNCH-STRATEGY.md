# GLOWAPP — ESTRATEGIA DE MERCADEO Y LANZAMIENTO
## Auditoría Senior (15 años exp.) | Producto: Marketplace Belleza + IA + SaaS B2B | Estado: Producción con usuarios reales

---

## 1. DIAGNÓSTICO ESTRATÉGICO (REALIDAD vs PERCEPCIÓN)

### 1.1 Lo que GlowApp ES hoy (Evidencia empírica GIA-17: 98.65% madurez)
| Activo | Estado | Valor Diferencial Real |
|--------|--------|------------------------|
| **Marketplace servicios a domicilio** | Operativo, transacciones Wompi reales | Logística última milla + geo-matching (HERMES/PostGIS) |
| **AURA (IA conversacional multi-agente)** | Operativo, 6 agentes, cache semántico, fallback LLM | Personalidad bogotana, tool-calling real (no RAG-only), anti-alucinación |
| **Diagnóstico biométrico (ATENA)** | Operativo, YouCam + Gemini Vision, cache Redis 30d | Scores dérmicos objetivos → paleta colorimetría + ingredientes → recomendación producto/servicio |
| **GlowStore (e-commerce 3 niveles)** | Funcional, migración MNC en curso (Fase A) | Modelo único: Consumidor/Profesional (revende)/Salón (insumo), precio como dato no columna |
| **SaaS B2B (CoPilot + VALKYRIE)** | Parcial/Experimental | Precios dinámicos autorizados por IA para llenar huecos, CRM básico, academia |
| **Split financiero 20/8% automático** | Maduro, compliance tributario colombiano | Transparencia prestador, liquidación al entregar |

### 1.2 Lo que GlowApp NO ES (Gaps críticos para el lanzamiento)
| Gap | Impacto Comercial | Prioridad |
|-----|-------------------|-----------|
| **Costo de mercancía (COGS) ausente** | Imposible validar rentabilidad nivel Salón (80%) ni Profesional (90%) | P0 — Bloquea MNC Fase A |
| **41 prestadores en 65% → saltan a 90%** | Riesgo churn masivo si no hay transición | P0 — Decisión comercial pendiente |
| **0 salones activos** | Canal B2B inexistente pese a rol/tabla lista | P1 — Requiere activación comercial |
| **Conciliación Wompi ↔ Wallet manual** | Disputas prestador, desconfianza liquidez | P1 — Automatizar job diario |
| **Academia contenido incompleto** | Retención prestador débil, sin certificaciones valoradas | P2 — Diferenciador B2B |
| **Tests E2E críticos ausentes** | Regresiones en checkout/IA/booking no detectadas | P0 — Riesgo reputacional |

### 1.3 Posicionamiento Real vs Competencia (Tracxn 2026 + Web Search)

| Competidor | Modelo | Funding | Diferenciador | Debilidad vs GlowApp |
|------------|--------|---------|---------------|----------------------|
| **LaManicurista** (Cali) | Marketplace servicios domicilio | — | Foco uñas, presencia local | Sin IA, sin diagnóstico, sin e-commerce B2B, sin SaaS |
| **Morado** (Bogotá) | Marketplace insumos B2B + Academy | **$5M (Tiger Global/H2O)** | Logística 24-72h, 60k+ salones potenciales | Sin marketplace servicios, sin IA diagnóstico, sin canal consumidor |
| **Ameiz** (Chile/Col) | Marketplace servicios domicilio | Fen Ventures | Match profesionales, expansión LatAm | Sin diagnóstico IA, sin e-commerce, sin SaaS salón |
| **BePretty** (Chile/Col/Mx/Arg) | **SaaS-enabled marketplace (ERP+CRM+e-com)** | — | Full-stack salón, N1 operador digital | Sin diagnóstico biométrico, sin IA conversacional, sin canal consumidor fuerte |
| **Singu** (Brasil) | Marketplace domicilio | **$3M Series A** | Escala Brasil, wellness | Sin IA, sin B2B insumos, sin diagnóstico |

**VENTANA DE OPORTUNIDAD**: GlowApp es **el único en LATAM** que combina: (1) Marketplace servicios domicilio + (2) Diagnóstico biométrico IA + (3) RAG técnico auditável (INVIMA/embarazo) + (4) E-commerce 3 niveles (consumidor/profesional/salón) + (5) SaaS B2B con pricing dinámico IA. **Nadie tiene el loop cerrado: Diagnóstico → Recomendación → Compra producto/servicio → Re-escaneo → Evolución medible (Glow Cycle).**

---

## 2. PROPUESTA DE VALOR Y POSICIONAMIENTO

### 2.1 Posicionamiento Central (Una frase)
> **"GlowApp es la única plataforma que transforma tu rutina de belleza en un ciclo medible de evolución: diagnosticas tu piel/cabello con IA médica, recibes productos y servicios personalizados, y ves tu progreso real cada 15/30 días — todo desde casa."**

### 2.2 Tres Pilares de Diferenciación (Comunicar en orden)

| Pilar | Claim | Proof Point (Técnico) | Beneficio Usuario |
|-------|-------|----------------------|-------------------|
| **1. IA que SABE de belleza (no alucina)** | "Tu dermatólogo de bolsillo 24/7" | RAG con 1024-dim NVIDIA embeddings, fuentes INVIMA, fallback full-text ES, cache semántico, observabilidad completa | Seguridad: no te recomienda retinol en embarazo; ingredientes contraindicados bloqueados |
| **2. Diagnóstico → Acción → Medición (Cerrado)** | "La única app que te dice si tu rutina FUNCIONA" | ATENA (YouCam/Gemini) → HESTIA (productos) → HERMES (servicios) → CHRONOS (re-booking) → Re-escaneo D15/D30 → Delta métrico real | Dejas de gastar en productos que no sirven; ves hidratación +20%, poros -15% |
| **3. Tres negocios en uno (Tú eliges tu rol)** | "Consumidor / Profesional que revende / Salón que se abastece" | MNC: 3 listas de precios, mínimos de venta (1/1/6), margen visible para revendedor, factura legal + envío | Profesional gana 10% margen + 10% comisión asistida; Salón compra insumo 20% bajo PVP |

### 2.3 Audiencias Prioritarias (Jerarquía de Lanzamiento)

| Prioridad | Audiencia | Tamaño Colombia | Dolor Principal | Hook GlowApp |
|-----------|-----------|-----------------|-----------------|--------------|
| **1. Early Adopters Tech-Bea** | Mujeres 22-35, urbanas, gasto belleza >$150k/mes, early adopters apps | ~800k | "Gasto en productos que no sé si funcionan; no tengo tiempo para ir al salón" | Diagnóstico gratis + rutina personalizada + entrega domicilio |
| **2. Prestadores Independientes** | Estilistas, manicuristas, esteticistas con agenda propia, buscan llenar huecos | ~41k activos (Cámara Comercio) | "Tengo huecos en agenda, no sé pricing, pierdo clientes" | VALKYRIE: IA sugiere promo 15% día lento + re-booking automático CHRONOS |
| **3. Salones Pequeños/Medianos** | 2-10 sillas, compran insumos por WhatsApp, sin ERP | ~15k-30k | "Compro caro, lento, sin factura, no sé qué necesito" | GlowStore Nivel Salón: 80% PVP, mínimo 6 unds, factura, envío 24-72h, IA sugiere reposición |
| **4. Consumidor Masivo (Post-PMF)** | Mujeres 18-50, gasto belleza $50-150k/mes | ~4M | "Quiero comodidad y precio justo" | Marketplace servicios + GlowStore consumidor + suscripción Glow Cycle |

---

## 3. ESTRATEGIA GO-TO-MARKET (3 FASES)

### FASE 0: FUNDAMENTOS (Semanas 1-4) — **ANTES DE CUALQUIER MARKETING**
> **Regla de oro**: No se gasta $1 en acquisition sin que el funnel de activación y retención esté instrumentado y validado.

| Acción | Owner | Entregable | Gate de Salida |
|--------|-------|------------|----------------|
| **COGS en productos** | Backend/Operations | `costo` poblado en 296 productos + margen por nivel validado | Informe rentabilidad Nivel Salón (80%) y Profesional (90%) |
| **Transición 41 prestadores 65%→90%** | Commercial/CS | Plan: lista transición 90d (65%→75%→85%→90%) + comunicación | 100% prestadores notificados, 0 churn no planificado |
| **Conciliación Wompi diaria automatizada** | Backend | Job nocturno: Wompi API transactions ↔ wallet balance + alerta Slack | 0 discrepancias >$1k por 7 días consecutivos |
| **Tests E2E críticos** | QA/Dev | Cypress/Playwright: Booking flow + AURA tool calls + Payment webhook | 100% passing en CI, coverage >80% flujos P0 |
| **Instrumentación funnel completa** | Analytics | Eventos: Visit→Register→Consent→Baseline→Plan→Check-in→Re-scan→Graduation | Dashboards tiempo real en /admin/metrics (GIA-17-C verificado) |
| **Onboarding Prestador → "Día 1 productivo"** | Product/CS | Checklist: Perfil verificado + 3 servicios + 5 fotos portfolio + 1 reserva test | Time-to-first-booking < 48h post-verificación |

---

### FASE 1: LAUNCH CONTROLADO "GLOW FOUNDERS" (Semanas 5-12)
**Objetivo**: 500 usuarios transformados (Glow Cycle completado D30) + 50 prestadores productivos + 10 salones piloto
**Presupuesto**: $0 paid media — 100% organic, referral, partnerships

| Canal | Táctica | KPI | Owner |
|-------|---------|-----|-------|
| **Referral Fundadores** | Programa "Glow Founders": primeros 500 usuarios reciben diagnóstico gratis + 20% descuento vida en GlowStore + badge exclusivo | 500 registros calificados (consent + baseline S0) | Growth/CS |
| **Prestadores Embajadores** | Reclutar 20 top-prestadores (rating >4.8, >50 bookings) → co-diseñan VALKYRIE promos + dan feedback Academy | 20 embajadores activos, NPS >9 | BD/CS |
| **Alianzas Salones Piloto** | 10 salones Bogotá/Medellín: GlowStore gratis 3 meses + CoPilot gratis 6 meses a cambio de data + casos de uso | 10 salones onboarded, 50+ órdenes B2B/mes | BD |
| **Content Marketing Técnico** | Blog/LinkedIn: "Por qué tu retinol no funciona", "INVIMA prohíbe X en embarazo", "Cómo medir hidratación real" — usando RAG como fuente | 10k visitas orgánicas/mes, 500 leads newsletter | Marketing |
| **PR Estratégico** | Pitch a Portafolio/El Tiempo/La República: "Colombiana crea IA que mide si tu rutina beauty funciona" + caso real usuario | 3 notas en Tier 1, 10k brand searches | Founder/Marketing |

**Gate de Salida Fase 1** (Semana 12):
- [ ] 500 usuarios con Glow Cycle D30 completado (re-escaneo + delta métrico)
- [ ] 50 prestadores con >5 bookings/semana
- [ ] 10 salones con >20 órdenes/mes cada uno
- [ ] CAC orgánico < $15k COP, LTV > $300k COP (proyectado)
- [ ] NPS consumidor > 50, NPS prestador > 40

---

### FASE 2: ESCALA REGIONAL (Semanas 13-28)
**Objetivo**: 10k usuarios activos mensuales (MAU) + 500 prestadores + 100 salones + PMF validado
**Presupuesto**: $200M-500M COP (paid + partnerships)

| Canal | Inversión | Táctica | KPI |
|-------|-----------|---------|-----|
| **Meta/Google Ads (Performance)** | $150M | Campañas: "Diagnóstico gratis IA" → Landing Baseline S0 → App Install. Audiencias: Lookalike 500 Founders + Intereses beauty/skincare | CAC < $40k COP, ROAS > 3x (primer pedido) |
| **Influencer Micro (10k-100k seg)** | $100M | 50 creators: "Me hice el Glow Cycle 30 días — esto pasó" (UGC real, no scripted). Código descuento trackable | 5k installs atribuidos, CPL < $25k |
| **Alianzas Estratégicas** | $50M | **Morado/BePretty**: Cross-promo (ellos no tienen diagnóstico IA ni marketplace consumidor). **Universidades estética**: Academy gratis estudiantes + certificación GlowApp | 500 leads B2B calificados/mes |
| **SEO/Content Evergreen** | $50M | Cluster: "diagnóstico facial gratis", "rutina piel seca embarazo", "productos INVIMA seguros", "colorimetría virtual" | 50k visitas orgánicas/mes mes 6 |
| **Email/WA Automation** | In-house | Secuencias: Onboarding → Baseline → Plan → Check-in D1 → Re-scan D15 → Graduation D30 → Upsell ciclo 2 | Activation rate > 60% (Baseline→Plan), Retention D30 > 40% |

**Gate de Salida Fase 2** (Semana 28):
- [ ] 10k MAU, 500 prestadores activos (>3 bookings/sem), 100 salones (>15 órdenes/mes)
- [ ] CAC blended < $35k COP, LTV > $400k COP, Payback < 60 días
- [ ] Glow Cycle completion rate > 35% (Baseline→D30 re-scan)
- [ ] Revenue mensual > $500M COP (take rate 20% servicios + margen GlowStore)
- [ ] Unit economics validados por cohorte mensual

---

### FASE 3: EXPANSIÓN NACIONAL + SERIES A (Semanas 29-52)
**Objetivo**: 50k MAU + 2k prestadores + 500 salones + Preparar Series A ($3-5M USD)
**Presupuesto**: $1-2B COP (requiere capital externo o revenue reinvertido)

| Palanca | Inversión | Detalle |
|---------|-----------|---------|
| **Geográfico** | $500M | Bogotá → Medellín → Cali → Barranquilla → Bucaramanga. Launch playbook por ciudad: 1) Prestadores locales 2) Salones ancla 3) Micro-influencers locales 4) Ads geo-targeted |
| **Producto V2** | $300M | Glow Cycle Hair (V2), Beauty Goals multi-dominio (boda/evento), Suscripción Glow Cycle ($89k/mes: diagnóstico trimestral + 15% desc GlowStore + prioridad booking) |
| **B2B SaaS Monetization** | $200M | CoPilot Pro: $200k/mes/salón (CRM + pricing dinámico + academy + analytics + marketplace insumos). Target: 200 salones pagando = $40M/mes ARR |
| **Team Growth** | — | Head of Growth, 2 Performance Marketers, 1 Brand/Content, 2 BD (B2B), 1 PR, 1 Marketing Ops/Analytics |
| **Series A Prep** | — | Data room: Cohort retention, Unit economics por segmento, TAM/SAM/SOM actualizado, Roadmap V2, Team bios |

---

## 4. MARKETING MIX POR AUDIENCIA

### 4.1 Consumidor Final (B2C)

| Etapa Funnel | Canal | Mensaje Clave | Formato | Presupuesto % |
|--------------|-------|---------------|---------|---------------|
| **Awareness** | Meta/Google/Influencers | "Tu piel te dice qué necesita. La IA lo lee." | Video 15s (antes/después real usuario), Carousel diagnóstico | 40% |
| **Consideration** | Landing Baseline S0, Blog SEO, WA nurture | "Gratis: Tu baseline dérmico en 2 min. Sin compromiso." | Landing interactiva (sube foto → ves scores hidratación/poros/manchas) | 25% |
| **Conversion** | App onboarding | "Empieza tu Glow Cycle 30 días. Primer servicio 20% off." | Flow: Consent → Foto → Baseline → Plan → Booking/Productos | 20% |
| **Activation** | In-app + Push + WA | "Día 1: Tu rutina AM/PM llega a domicilio. ¿La sigues?" | Checklist interactiva, recordatorios suaves, gamificación racha | 10% |
| **Retention** | App + Email + WA | "Día 15: Re-escanea y ve tu progreso real. Día 30: Graduación." | Comparativo visual S0 vs D15 vs D30, badge, siguiente ciclo sugerido | 5% |

**Métricas Norte B2C**: Activation Rate (Baseline→Plan) > 60%, D30 Retention > 40%, Glow Cycle Completion > 35%, LTV > $400k COP

### 4.2 Prestadores Independientes (B2B2C — Supply Side)

| Etapa | Canal | Mensaje | Formato |
|-------|-------|---------|---------|
| **Acquisition** | BD directo, Referidos prestadores, LinkedIn, Ferias belleza | "Llena tu agenda los martes. IA te dice cuándo y cuánto descontar." | Demo 10 min: Dashboard + VALKYRIE insight + Booking real |
| **Onboarding** | CS dedicado (1:20 ratio) | "En 48h tienes tu primera reserva. Te guiamos paso a paso." | Checklist interactivo, videollamada día 1, primer booking asistido |
| **Engagement** | In-app notifications, WA Business, Academy | "Tu insight semanal: Martes 14% ocupación → Promo GLOW-MARTES-15 autorizada" | Push semanal VALKYRIE, Academy micro-learning, Community WhatsApp |
| **Retention/Expansion** | Quarterly Business Review (QBR) | "Creciste 34% ingresos este trimestre. ¿Subimos precios 5%?" | Reporte PDF automatizado + llamada 30 min CS |

**Métricas Norte Supply**: Time-to-first-booking < 48h, Bookings/semana > 5, Churn mensual < 5%, NPS > 40, % agenda llena > 70%

### 4.3 Salones (B2B — GlowStore + SaaS)

| Etapa | Canal | Mensaje | Formato |
|-------|-------|---------|---------|
| **Acquisition** | BD especializado, Partners (distribuidores), Eventos gremiales | "Deja de comprar por WhatsApp. 80% PVP, factura, entrega 24h, IA te dice qué reponer." | Demo CoPilot + GlowStore Salón + Caso real Morado/BePretty |
| **Onboarding** | Implementation Manager | "Migramos tu catálogo en 1 semana. Entrenamos a tu equipo en 2h." | Migración CSV precios, Setup tenant, Training sesión grabada |
| **Expansion** | CoPilot insights, VALKYRIE | "Tu shampoo más vendido se acaba cada 12 días. Pedido automático activado." | Alertas stock, Pedidos recurrentes, Financing futuro (Factoring) |
| **Lock-in** | Contrato anual, Datos propietarios | "Tu historial de compras + clientes + preferencias = tu activo. Nosotros solo lo operamos." | Exportación datos, API acceso, Multi-usuario salón |

**Métricas Norte Salones**: Órdenes/mes > 15, Ticket promedio > $300k COP, Churn anual < 15%, CoPilot Pro attachment > 30%

---

## 5. BRAND Y COMUNICACIÓN

### 5.1 Arquitectura de Marca

```
GLOWAPP (Marca Madre)
├── GLOW CYCLE         → Producto estrella consumidor (IA diagnóstico + evolución medible)
├── GLOW STORE         → E-commerce 3 niveles (Consumidor / Profesional / Salón)
├── GLOW PRO           → SaaS para prestadores/salones (CoPilot + VALKYRIE + Academy)
└── AURA               → IA conversacional (personalidad bogotana, 6 agentes)
```

### 5.2 Voz y Tono (Brand Voice)

| Atributo | Descripción | Ejemplo |
|----------|-------------|---------|
| **Experta pero accesible** | Sabemos de INVIMA, ingredientes, biométrica — pero te lo explicamos como tu mejor amiga dermatóloga | "El retinol es oro, pero en embarazo es NO rotundo. Te doy alternativas seguras." |
| **Bogotana auténtica** | Jerga local natural, no forzada. Confianza, cercanía, humor seco. | "¿Piel de papel? Vamos a hidratar eso como se debe, parcera." |
| **Basada en evidencia** | Cada claim tiene source: RAG chunk, estudio, regulación. Cero marketing vacío. | "Según INVIMA Resolución 2024, esta concentración de ácido glicólico requiere uso profesional." |
| **Orientada a resultados** | Prometemos medición, no magia. "Verás el cambio o te devolvemos el diagnóstico." | "Tu hidratación subió 23% en 30 días. Aquí está la foto comparativa." |

### 5.3 Mensajes Clave por Audiencia

| Audiencia | Headline Principal | Sub-headline | CTA |
|-----------|-------------------|--------------|-----|
| **Consumidor** | "Tu belleza, medida y mejorada" | "IA que diagnostica, productos que funcionan, progreso que ves" | "Haz tu diagnóstico gratis" |
| **Prestador** | "Tu agenda, optimizada por IA" | "Llena huecos, sube precios inteligentemente, retén clientes automáticamente" | "Prueba Gratis 30 días" |
| **Salón** | "Abastece tu salón al precio real" | "80% PVP, factura legal, entrega 24h, IA que predice tu stock" | "Activa tu cuenta Salón" |

---

## 6. MÉTRICAS Y DASHBOARDS (NORTH STAR + GUARDRAILS)

### 6.1 North Star Metric
> **Usuarios Transformados Semanalmente (WTU)**: Usuarios que completan check-in D1 + re-escaneo D15 o D30 en la semana.
> *Validado en GIA-16-O: Coste por WTU = $0.055 USD | Margen bruto > 95%*

### 6.2 Dashboard Ejecutivo (Semanal)

| Métrica | Target Fase 1 | Target Fase 2 | Target Fase 3 | Fuente |
|---------|---------------|---------------|---------------|--------|
| **WTU (Usuarios Transformados/Sem)** | 50 | 500 | 2,500 | GIA-16-O / Analytics |
| **MAU Consumidor** | 1,000 | 10,000 | 50,000 | Analytics |
| **Prestadores Activos (>3 bookings/sem)** | 50 | 500 | 2,000 | Backend/Booking |
| **Salones Activos (>15 órdenes/mes)** | 10 | 100 | 500 | GlowStore/CoPilot |
| **Glow Cycle Completion Rate (D30)** | 35% | 40% | 45% | Analytics (GIA-17-C) |
| **CAC Blended** | <$15k (orgánico) | <$35k | <$50k | Finance/Attribution |
| **LTV (proyectado 12m)** | >$300k | >$400k | >$500k | Cohort Analysis |
| **Revenue Mensual (Take rate + GlowStore)** | $100M | $500M | $2.5B | Finance |
| **Take Rate Efectivo Servicios** | 18-20% | 20% | 20% | Booking/Payments |
| **Margen GlowStore (nivel consumidor)** | >35% | >40% | >45% | Finance/COGS |
| **NPS Consumidor** | >50 | >55 | >60 | Survey (trimestral) |
| **NPS Prestador** | >40 | >45 | >50 | Survey (trimestral) |

### 6.3 Guardrails (Alertas Automáticas — /api/admin/metrics + Slack)
| Alerta | Umbral | Acción |
|--------|--------|--------|
| **Drop WTU semana a semana** | >15% | War room: revisar funnel Baseline→Plan→Check-in→Re-scan |
| **Churn prestadores mensual** | >8% | CS outreach inmediato + revisar VALKYRIE insights |
| **Discrepancia Wompi-Wallet** | >$5k COP/día | Investigar + bloquear retiros hasta conciliar |
| **AURA latency P95** | >3s | Escalar a Dev: cache warming, model routing |
| **RAG fallback rate** | >20% | Revisar corpus, embeddings, threshold |
| **COGS missing >5% catálogo** | Any | Bloquear nuevos precios hasta completar |

---

## 7. CALENDARIO DE LANZAMIENTOS Y HITOS (ROADMAP MARKETING)

| Semana | Hito | Dependencia Técnica | Owner |
|--------|------|---------------------|-------|
| **S1-4** | **Fase 0 Completada** | COGS, Transición prestadores, Conciliación, Tests E2E, Funnel instrumentado | Tech/Commercial |
| **S5** | **Soft Launch "Glow Founders"** | 500 invitaciones, referral system live | Growth/Marketing |
| **S6-8** | **Content Engine Arranca** | Blog 2x/sem, LinkedIn 3x/sem, Newsletter semanal | Marketing |
| **S8** | **Primer Caso de Éxito Público** | Usuario con Glow Cycle D30 completado + delta métrico real | Marketing/CS |
| **S10** | **Primer Salón Piloto Facturando** | B2B flow end-to-end: orden → factura → entrega → liquidación | BD/Operations |
| **S12** | **Gate Fase 1 → Decisión Escalar** | 500 transformados, 50 prestadores, 10 salones | Director/Board |
| **S13** | **Paid Media Inicia** | Meta/Google campaigns live, tracking attribution | Growth |
| **S16** | **Influencer Campaign Launch** | 50 micro-influencers, UGC real | Marketing/Influencer Agency |
| **S20** | **Partnership Morado/BePretty Anunciado** | Cross-promo, co-branded content | BD/Founder |
| **S24** | **10k MAU Alcanzado** | Dashboard público interno | All |
| **S28** | **Gate Fase 2 → Series A Prep** | Unit economics validados, cohort retention >40% D30 | Founder/CFO |
| **S32** | **CoPilot Pro Launch (Paid SaaS)** | 20 salones beta pagando $200k/mes | Product/BD |
| **S36** | **Glow Cycle Hair V2 Beta** | Diagnóstico capilar + rutina | Product/AI |
| **S40** | **Expansión Medellín/Cali** | Playbook ciudad validado | Growth/BD |
| **S48** | **Series A Data Room Lista** | Métricas, proyecciones, team, roadmap | Founder/CFO |
| **S52** | **Series A Cerrada / 50k MAU** | $3-5M USD, valuation justificada | Founder/Board |

---

## 8. PRESUPUESTO MARKETING (PROYECCIÓN 12 MESES)

| Categoría | Fase 0 (S1-4) | Fase 1 (S5-12) | Fase 2 (S13-28) | Fase 3 (S29-52) | Total Año 1 |
|-----------|---------------|----------------|-----------------|-----------------|-------------|
| **Paid Media (Meta/Google/TikTok)** | $0 | $0 | $150M | $500M | $650M |
| **Influencers / Creadores** | $0 | $20M (product seeding) | $100M | $300M | $420M |
| **Content/SEO/PR** | $10M (herramientas) | $30M | $50M | $150M | $240M |
| **Eventos / Ferias / Alianzas** | $5M | $15M | $50M | $100M | $170M |
| **Referral / Loyalty Program** | $5M | $30M | $50M | $100M | $185M |
| **Team Marketing (Salarios + Freelancers)** | $0 | $80M | $200M | $500M | $780M |
| **Tech Stack (Attribution, Analytics, Automation)** | $20M | $30M | $50M | $100M | $200M |
| **Contingencia (15%)** | $6M | $26M | $97M | $247M | $376M |
| **TOTAL** | **$46M** | **$231M** | **$747M** | **$1.997B** | **~$3.0B COP** |

> **Nota**: Fase 3 presupuesta capital externo (Series A). Si no hay ronda, Fase 3 se autofinancia con revenue Fase 2 (proyectado $500M+/mes mes 7) → presupuesto real ~$1B COP.

---

## 9. RIESGOS Y MITIGACIONES

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| **Prestadores rechazan 90% (churn 30%+)** | Alta | Crítico | Lista transición 90d (65→75→85→90) + comunicación transparente + VALKYRIE muestra ganancia neta real |
| **COGS no disponible → MNC bloqueada** | Media | Crítico | Negociar con proveedores top 20 (80% revenue) costos reales; estimar resto con margen industria 45-55% |
| **Competidor (Morado/BePretty) lanza diagnóstico IA** | Media | Alto | Patente/Secreto industrial en pipeline biométrico + RAG; velocidad: lanzar Glow Cycle Hair V2 antes Q3 2026 |
| **Regulación DIAN cambia (facturación obligatoria apps)** | Baja | Medio | Fiscal adapter diseñado (FISCAL-BOUNDARY.md), listo para activar; no bloquea Fase 1-2 |
| **Wompi cambia APIs / comisiones** | Baja | Alto | Abstracción payment provider; tests webhook idempotentes; contrato comercial revisado trimestral |
| **CAC paid media no escala (saturación)** | Media | Medio | Diversificar: SEO evergreen, partnerships B2B, referral, email/WA owned channels; LTV focus |
| **Equipo técnico no entrega features V2 a tiempo** | Media | Alto | Roadmap realista (GIA-17-R 98.65% madurez), contratar 2 senior devs Q1 2026, tech debt sprints mensuales |

---

## 10. PRÓXIMOS PASOS INMEDIATOS (ESTA SEMANA)

1. **DECISIÓN DIRECTOR**: Confirmar transición 41 prestadores 65%→90% (lista transición 90d vs día 1) — *Requiere: AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — F7.006-MNC-PRICING*
2. **COGS SPRINT**: Asignar 1 dev + 1 ops para poblar `costo` en top 50 productos (80% revenue) en 5 días
3. **CONCILIACIÓN WOMPi**: Deploy job nocturno + alerta Slack esta semana
4. **TESTS E2E**: Priorizar Booking flow + AURA tool calls + Payment webhook en CI
5. **FOUNDERS LIST**: Extraer 500 mejores usuarios (LTV alto, NPS alto, referidos) para programa Glow Founders
6. **PR KIT**: Preparar press kit + caso de usuario real (anonimizado) + screenshots AURA/ATENA/Glow Cycle

---

## 11. APÉNDICE: EVIDENCIA TÉCNICA CLAVE (Para Deck Inversionistas)

| Documento | Hallazgo Clave | Relevancia Comercial |
|-----------|----------------|----------------------|
| **GIA-17-R** | 98.65% madurez empírica, 10/10 dimensiones PASS | Producto listo para escalar, no MVP |
| **GIA-16-O** | Coste/WTU $0.055 USD, Margen >95% | Unit economics best-in-class SaaS |
| **GIA-17-C** | Funnel empírico medible end-to-end | Atribución real, no vanity metrics |
| **GIA-17-L** | Comercio subordinado a diagnóstico (cero intrusión) | Diferenciador ético + confianza usuario |
| **MNC Doc** | Modelo 3 niveles validado, precio como dato | Escalable, legal, evita canibalización canales |
| **FISCAL-BOUNDARY** | Frontera fiscal clara, adapter futuro | Riesgo regulatorio contenido, no bloqueante |

---

**Documento vivo** — Se actualiza cada Gate de fase con datos reales. Próxima revisión: **Gate Fase 1 (Semana 12)**.

**Autor**: Asesor Senior Marketing Digital (15 años) | **Fecha**: 2026-10-24 | **Versión**: 1.0