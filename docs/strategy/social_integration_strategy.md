# Tesis Estratégica de Integración Social (TikTok, Instagram & Facebook) — GlowApp

**Plataforma:** GlowApp (Marketplace de Belleza y Salud en Bogotá)  
**Autor:** Consultor Senior de Growth & Social Commerce  
**Fecha:** 31 de Julio de 2026  
**Ubicación:** `/docs/strategy/social_integration_strategy.md`

---

## 1. RESUMEN ESTRATÉGICO

| Plataforma | Rol Principal en GlowApp | Prioridad de Implementación | Esfuerzo Técnico Estimado |
| :--- | :--- | :---: | :---: |
| **TikTok** | **Viral Loop de Resultados de IA & Microlearning B2B** (Share Kit + TikTok Webhooks) | **Alta (P0)** | **M** (Share Kit SDK + Custom Stickers) |
| **Instagram** | **Prueba Social, Portafolio de Prestadoras & Stories VTO** (Meta Content Publishing API) | **Alta (P0)** | **L** (Requires Meta App Review + Graph API) |
| **Facebook** | **Adquisición B2B/Comunidades & Login Social Legacy** (Facebook Login & Open Graph) | **Media (P1)** | **S** (Standard Social SDK) |

---

## 2. TIKTOK (Viral Loop de Resultados de IA & Microlearning B2B)

### 📍 Dónde y Cuándo (Puntos de Contacto Específicos)
1. **Post-Diagnóstico de IA Aura (`results_screen.dart`)**:
   - Tras completar un análisis de colorimetría o escáner capilar, aparece el botón: *"Publicar mi Palette DNA en TikTok"*.
   - **Formato**: Renderiza automáticamente una plantilla en video corto (9:16) con la paleta de colores sugerida, el avatar del usuario y una marca de agua estéticamente integrada de GlowApp.
2. **Post-Lección de Glow Academy (`course_detail_screen.dart`)**:
   - Al finalizar un módulo de microlearning por parte de una estilista/prestadora, se genera un certificado en video: *"Demuestra tus habilidades certificadas en TikTok"*.

### 🧠 Por Qué esta Plataforma Aquí
TikTok es una plataforma de **entretenimiento e identidad visual** donde los usuarios consumen y comparten etiquetas estéticas (ej: *"Soft Autumn"*, *"Clean Girl Aesthetic"*). Los diagnósticos de IA de Aura encajan perfectamente como contenido de auto-expresión. Para las prestadoras B2B, TikTok es su principal canal orgánico de adquisición de clientela en Bogotá.

### 📈 Beneficio Esperado
- **Adquisición (Growth/CAC)**: Cada video compartido incluye un enlace profundo de atribución (`https://glowapp.com.co/a/dna?ref=USER_ID`) que descarga la app o lleva al perfil de la proveedora.
- **UGC (User-Generated Content)**: Miles de videos orgánicos con el hashtag `#MiColorDnaGlowApp`.
- **Credibilidad**: Las prestadoras demuestran estar certificadas en Glow Academy ante sus seguidores de TikTok.

### 🛠️ Implementación Técnica
- **API**: **TikTok Share Kit for Mobile & Web SDK** + **TikTok Direct Post API**.
- **Tipo de Integración**: Deep link de compartir con imagen/video pre-generado + atribución por parámetros de URL.
- **Scopes Necesarios**: `user.info.basic`, `video.upload`, `video.publish`.
- **Aprobación de Plataforma**: Requiere **TikTok Developer App Review** para el permiso de publicación directa.

### ⚖️ Riesgo & Consideración Legal (Ley 1581)
- **Modal de Consentimiento Opt-in Separado**: Antes de enviar la imagen generada por IA a TikTok, se despliega un diálogo explicativo:  
  > 🔒 *"Confirmo que deseo exportar mi resultado estético a TikTok. Entiendo que mi fotografía y análisis de color serán procesados por TikTok fuera de la custodia segura de GlowApp."*

---

## 3. INSTAGRAM (Prueba Social, Portafolio de Prestadoras & Stories VTO)

### 📍 Dónde y Cuándo
1. **Ficha de la Proveedora (`provider_detail_screen.dart` / `provider_portfolio_screen.dart`)**:
   - Embed en vivo del feed de Instagram de la estilista para mostrar sus últimos trabajos verificados.
2. **Guardarropa Digital / VTO (`wardrobe_dashboard_screen.dart`)**:
   - Al probarse un nuevo look o estilo de uñas mediante Virtual Try-On, botón directo: *"Compartir este Look en Instagram Stories"*.

### 🧠 Por Qué esta Plataforma Aquí
Instagram es la **vitrina aspiracional por excelencia** y la herramienta de portafolio definitiva para estilistas y profesionales en Colombia. La audiencia usa Instagram para validar la calidad del trabajo de un salón antes de reservar.

### 📈 Beneficio Esperado
- **Credibilidad / Prueba Social**: Las clientas ven fotos reales y actualizadas del trabajo de la prestadora sin salir de GlowApp.
- **Retención & Engagement**: Las Stories interactivas generan conversación directa (DMs) en la red social.

### 🛠️ Implementación Técnica
- **API**: **Meta Graph API (Instagram Basic Display API & Instagram Graph API)** + **Instagram Messaging API**.
- **Tipo de Integración**: Embed seguro de carruseles de Instagram + Publicación de Sticker Assets en Instagram Stories.
- **Scopes Necesarios**: `instagram_graph_user_profile`, `instagram_graph_user_media`, `pages_show_list`.
- **Aprobación de Plataforma**: Requiere **Meta App Review** con envío de grabación de pantalla de la app en Flutter.

---

## 4. FACEBOOK (Adquisición B2B/Comunidades & Login Social)

### 📍 Dónde y Cuándo
1. **Pantalla de Registro (`register_screen.dart`)**:
   - Botón *"Continuar con Facebook"*.
2. **Comunidades de Prestadoras en Glow Academy**:
   - Botón *"Unirse a la Comunidad Oficial de Estilistas GlowApp en Facebook Groups"*.

### 🧠 Por Qué esta Plataforma Aquí
Facebook ha migrado de ser una red de auto-expresión juvenil a ser una **plataforma de comunidades locales y grupos B2B** en Colombia. Es el canal idóneo para conectar con dueñas de salones de belleza y estilistas de mayor trayectoria.

### 📈 Beneficio Esperado
- **Adquisición B2B**: Atracción de prestadoras desde grupos de belleza de Bogotá.
- **Reducción de Fricción**: Registro rápido con 1-clic.

### 🛠️ Implementación Técnica
- **API**: **Facebook Login SDK** + **Open Graph Meta Tags**.
- **Tipo de Integración**: OAuth 2.0 Social Login & Meta Pixel Tracking.
- **Scopes Necesarios**: `email`, `public_profile`.

---

## 5. MODELO DE DATOS E INTEROPERABILIDAD

Para garantizar que las conexiones sociales no corrompan la base de datos ni generen publicaciones duplicadas en la aplicación:

### 🗄️ Esquema PostgreSQL Propuesto (`migrations/008_social_integrations.sql`)

```sql
-- Tabla aislada para vinculación de cuentas sociales
CREATE TABLE IF NOT EXISTS user_social_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    provider VARCHAR(30) NOT NULL CHECK (provider IN ('TIKTOK', 'INSTAGRAM', 'FACEBOOK')),
    provider_user_id VARCHAR(255) NOT NULL,
    access_token TEXT NOT NULL,
    refresh_token TEXT,
    expires_at TIMESTAMPTZ NOT NULL,
    scopes TEXT[] DEFAULT '{}',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_user_provider UNIQUE (user_id, provider)
);

-- Tabla para registro auditable de contenidos compartidos (Evita Gaming/Abuso)
CREATE TABLE IF NOT EXISTS social_shares_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    platform VARCHAR(30) NOT NULL,
    content_type VARCHAR(50) NOT NULL, -- 'AI_COLORIMETRY', 'VTO_LOOK', 'ACADEMY_CERT'
    share_reference_id VARCHAR(255),
    reward_granted BOOLEAN DEFAULT FALSE,
    points_awarded INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 🔑 Manejo de Tokens y Privacidad Biométrica
1. **Encriptación de Tokens**: Los `access_token` y `refresh_token` se encriptan mediante AES-256 en reposo dentro de PostgreSQL.
2. **Aislamiento PHI/Biométrico**: Las imágenes del escáner facial **NUNCA** se almacenan en servidores sociales. Solo se exportan tarjetas de resultado procesadas gráficamente (`.png`/`.mp4`) tras confirmación explícita del usuario.

---

## 6. GESTIÓN DE GROWTH LOOPS & MITIGACIÓN DE ABUSO

```
┌────────────────────────────────────────────────────────┐
│               1. Diagnóstico de IA Aura                 │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│     2. Exportación a TikTok/Instagram Stories           │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│     3. Enlace de Atribución (Dynamic Deep Link)         │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│     4. Nueva Usuaria Descarga GlowApp (-30% CAC)       │
└────────────────────────────────────────────────────────┘
```

### 📊 Métricas Clave de Growth
- **K-factor (Coeficiente de Viralidad)**: Meta: $K > 0.3$ (Cada 10 usuarios que comparten traen 3 nuevos usuarios registrados).
- **Reducción de CAC**: Disminución del 25% en el costo de adquisición por cliente.

### 🛡️ Mitigación de Abuso (Anti-Gaming de Créditos)
Para evitar que los usuarios hagan *"publicaciones falsas"* o vacías solo para reclamar Puntos de Experiencia (XP) o descuentos:
1. **Verificación por Webhooks**: Los puntos XP solo se acreditan cuando el servidor de TikTok/Meta confirma mediante un **Webhook de publicación exitosa** que el contenido fue efectivamente posteado de forma pública.
2. **Límite de Recompensa**: Máximo 1 recompensa por usuario cada 24 horas por concepto de compartir en redes sociales.
