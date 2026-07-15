# Hub Biométrico — Plan de Desarrollo para Antigravity 🌸

**Proyecto:** GlowApp — Módulo de lectura biométrica facial y de manos dentro de "Ideas".  
**Enfoque:** Zero IA propia, 100% APIs externas (YouCam, Gemini, Open Beauty Facts).  
**Duración estimada:** 12 semanas.  
**Equipo:** 1 Flutter, 1 Node.js, 0.5 UX, 0.5 DevOps.

---

## 📌 Objetivo
Construir un flujo de escaneo de rostro y manos que genere un perfil de belleza personalizado, con recomendaciones de productos reales y que potencie la sección de Ideas.

## 🛠️ Tecnologías Clave
- **Flutter** con MediaPipe (on‑device)
- **Node.js** backend (orquestación de APIs)
- **PostgreSQL** + **Redis** (perfil y caché)
- **APIs:** YouCam, Gemini, Open Beauty Facts, OpenUV, The Color API

---

## 🗺️ Estructura de Fases y Documentación

1. **[01-consentimiento-legal.md](file:///c:/beauty-app/docs/plan-desarrollo-antigravity/01-consentimiento-legal.md)** (Semana 1)
   * Pantalla de consentimiento, aceptación de Habeas Data (Ley 1581) y registro de logs de auditoría en base de datos.
2. **[02-captura-mediapipe.md](file:///c:/beauty-app/docs/plan-desarrollo-antigravity/02-captura-mediapipe.md)** (Semanas 2-4)
   * Captura en frontend, overlay de encuadre en pantalla y procesamiento con MediaPipe on‑device.
3. **[03-backend-orquestacion.md](file:///c:/beauty-app/docs/plan-desarrollo-antigravity/03-backend-orquestacion.md)** (Semanas 5-7)
   * Endpoints y orquestación en Node.js, lógica de negocio del backend y conexión con LLMs (Gemini).
4. **[04-resultados-y-recomendaciones.md](file:///c:/beauty-app/docs/plan-desarrollo-antigravity/04-resultados-y-recomendaciones.md)** (Semanas 8-9)
   * Dashboard interactivo de resultados de piel/cabello, recomendaciones y conversión (CTA) de servicios locales en el carrito.
5. **[05-integracion-apis-esenciales.md](file:///c:/beauty-app/docs/plan-desarrollo-antigravity/05-integracion-apis-esenciales.md)** (Semana 10)
   * Integración de APIs esenciales: Open Beauty Facts, OpenUV (radiación solar local) y The Color API.
6. **[06-qa-y-despliegue.md](file:///c:/beauty-app/docs/plan-desarrollo-antigravity/06-qa-y-despliegue.md)** (Semanas 11-12)
   * Pruebas unitarias, simulación de carga con Locust, hardening y despliegue continuo en Railway/AWS.

---

---

## 🚀 Kick-Off del Desarrollo — Hub Biométrico GlowApp

* **Inicio oficial:** Hoy
* **Equipo:** Antigravity (1 Flutter, 1 Node.js, 0.5 UX, 0.5 DevOps)
* **Duración estimada:** 12 semanas
* **Entregable final:** Módulo funcional dentro de la sección "Ideas".

### 1. Repositorio y Ramas
```bash
# Clonar repositorio principal
git clone https://github.com/glowapp/belleza-app.git
cd belleza-app

# Crear rama de desarrollo
git checkout -b feature/biometric-hub
```

**Estructura de ramas y carpetas asociadas:**
```
feature/biometric-hub
├── backend/
│   └── app/services/biometric/   # Nuevo módulo backend
├── frontend/
│   └── glow_app/lib/
│       ├── screens/biometric/    # Nuevas pantallas (ConsentScreen, WelcomeScreen)
│       └── services/biometric_service.dart
└── plan-desarrollo-antigravity/  # Documentación del plan y guías
```

### 2. Configuración del Entorno

#### Backend (Node.js + PostgreSQL + Redis)
```bash
# Instalar dependencias nuevas
cd backend
npm install axios redis dotenv

# Configurar variables de entorno (.env)
# YOCAM_API_KEY=tu_api_key_aqui
# GEMINI_API_KEY=tu_api_key_aqui
# REDIS_URL=redis://localhost:6379
# DATABASE_URL=postgresql://user:pass@localhost:5432/glowapp

# Iniciar Redis (si no está en docker-compose)
docker run -d --name redis-glowa -p 6379:6379 redis:alpine
```

#### Frontend (Flutter)
```bash
cd frontend/glow_app

# Agregar dependencias en pubspec.yaml
flutter pub add google_mlkit_face_detection
flutter pub add google_mlkit_hand_detection
flutter pub add camera
flutter pub add image_picker
flutter pub add mobile_scanner

# Obtener paquetes
flutter pub get
```

---

## 🛠️ Tareas Inmediatas (Primera Semana)

### 🔹 3.1 Backend — Tablas de Consentimiento y Perfil
* **Archivo de migración:** `backend/migrations/001_biometric_consent.sql`

```sql
-- Tabla de consentimiento biométrico
CREATE TABLE IF NOT EXISTS biometric_consents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    version VARCHAR(20) NOT NULL,
    accepted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ip INET,
    user_agent TEXT,
    revoked_at TIMESTAMP WITH TIME ZONE,
    active BOOLEAN DEFAULT TRUE,
    CONSTRAINT unique_active_consent UNIQUE (user_id) WHERE active = TRUE
);

-- Tabla de perfiles biométricos
CREATE TABLE IF NOT EXISTS beauty_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    face_scores JSONB NOT NULL,
    hands_diagnosis JSONB NOT NULL,
    recommendation TEXT NOT NULL,
    recommended_products JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_beauty_profiles_user_id ON beauty_profiles(user_id);
CREATE INDEX idx_biometric_consents_user_id ON biometric_consents(user_id);
```

* **Ejecutar migración:**
```bash
cd backend
# Para proyectos usando Knex CLI
npx knex migrate:latest
```

### 🔹 3.2 Backend — Endpoint de Consentimiento
* **Archivo:** `backend/app/routes/consent.js`

```javascript
const express = require('express');
const router = express.Router();
const db = require('../db'); // Conector de base de datos configurado

// POST /api/consent
router.post('/', async (req, res) => {
  const { userId, version, accepted } = req.body;
  
  if (!accepted) {
    return res.status(400).json({ error: 'Debe aceptar los términos' });
  }

  const clientIP = req.ip || req.connection.remoteAddress;
  const userAgent = req.headers['user-agent'];

  try {
    // Desactivar consentimientos anteriores
    await db('biometric_consents')
      .where({ user_id: userId, active: true })
      .update({ active: false, revoked_at: new Date() });

    // Crear nuevo consentimiento
    const [consent] = await db('biometric_consents')
      .insert({
        user_id: userId,
        version,
        ip: clientIP,
        user_agent: userAgent,
        active: true
      })
      .returning('*');

    res.json({ success: true, consentId: consent.id });
  } catch (error) {
    console.error('Error saving consent:', error);
    res.status(500).json({ error: 'Error al guardar consentimiento' });
  }
});

// GET /api/consent/status/:userId
router.get('/status/:userId', async (req, res) => {
  const { userId } = req.params;
  
  const consent = await db('biometric_consents')
    .where({ user_id: userId, active: true })
    .first();

  res.json({ hasConsent: !!consent });
});

module.exports = router;
```

### 🔹 3.3 Frontend — ConsentScreen
* **Archivo:** `frontend/glow_app/lib/screens/biometric/consent_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:glow_app/services/biometric_service.dart';

class BiometricConsentScreen extends StatefulWidget {
  const BiometricConsentScreen({super.key});

  @override
  State<BiometricConsentScreen> createState() => _BiometricConsentScreenState();
}

class _BiometricConsentScreenState extends State<BiometricConsentScreen> {
  bool _accepted = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacidad'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: Colors.purple),
            const SizedBox(height: 16),
            const Text(
              'Tu privacidad es importante',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Para ofrecerte recomendaciones personalizadas, necesitamos '
              'analizar tu rostro y manos mediante IA.\n\n'
              '• No almacenamos tus fotos en nuestros servidores.\n'
              '• Solo procesamos datos biométricos para este análisis.\n'
              '• Puedes revocar este consentimiento en cualquier momento.\n\n'
              'Al aceptar, autorizas el tratamiento de tus datos biométricos '
              'según la Ley 1581 de 2012.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            CheckboxListTile(
              title: const Text('Acepto los términos y condiciones'),
              value: _accepted,
              onChanged: (value) {
                setState(() {
                  _accepted = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCELAR'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _accepted && !_isLoading
                        ? () async {
                            setState(() => _isLoading = true);
                            try {
                              await BiometricService.saveConsent();
                              if (mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const Scaffold(body: Center(child: Text("WelcomeScreen"))),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error al guardar consentimiento. Intenta de nuevo.'),
                                ),
                              );
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accepted ? Colors.purple : Colors.grey,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('ACEPTAR'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### 🔹 3.4 Frontend — Servicio Biométrico
* **Archivo:** `frontend/glow_app/lib/services/biometric_service.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static const String baseUrl = 'http://localhost:8000/api'; // Cambiar en producción

  static Future<void> saveConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'test-user';

    final response = await http.post(
      Uri.parse('$baseUrl/consent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'version': '1.0',
        'accepted': true,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al guardar consentimiento');
    }
  }

  static Future<bool> hasConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'test-user';

    final response = await http.get(
      Uri.parse('$baseUrl/consent/status/$userId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['hasConsent'] ?? false;
    }
    return false;
  }

  static Future<Map<String, dynamic>> analyze(
    List<int> faceImage,
    List<int> handsImage,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'test-user';

    final response = await http.post(
      Uri.parse('$baseUrl/biometric/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'faceImage': base64Encode(faceImage),
        'handsImage': base64Encode(handsImage),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al analizar');
    }

    return jsonDecode(response.body)['results'];
  }
}
```

---

## 📋 Primer Sprint (Semanas 1-2) — Entregables

| Tarea | Responsable | Estado |
| :--- | :--- | :---: |
| Crear rama `feature/biometric-hub` | Backend/Frontend | ⬜ Pending |
| Configurar Redis local | Backend | ⬜ Pending |
| Ejecutar migraciones de BD | Backend | ⬜ Pending |
| Implementar endpoint `/consent` | Backend | ⬜ Pending |
| Implementar `ConsentScreen` UI | Frontend | ⬜ Pending |
| Conectar `ConsentScreen` con backend | Frontend | ⬜ Pending |
| Crear `WelcomeScreen` | Frontend | ⬜ Pending |
| Integrar cámara en `CaptureScreen` | Frontend | ⬜ Pending |
| Configurar MediaPipe Face Detection | Frontend | ⬜ Pending |
| Documentar API en Swagger/Postman | Backend | ⬜ Pending |

---

## 🔗 Enlaces Útiles para el Equipo

* **MediaPipe Flutter:** [google_mlkit_face_detection](https://pub.dev/packages/google_mlkit_face_detection)
* **YouCam API Docs:** [yce.perfectcorp.com](https://yce.perfectcorp.com)
* **Gemini API Docs:** [ai.google.dev](https://ai.google.dev/gemini-api/docs)
* **Open Beauty Facts API:** [world.openbeautyfacts.org](https://world.openbeautyfacts.org/api)
* **Flutter Camera:** [camera](https://pub.dev/packages/camera)

---

## ✅ Checklist de Inicio
- [ ] Miembros de equipo con acceso al repositorio principal.
- [ ] Variables de entorno configuradas localmente en `.env`.
- [ ] Redis corriendo localmente en el puerto `6379`.
- [ ] PostgreSQL inicializado con extensión gen_random_uuid habilitada.
- [ ] Dependencias de Flutter de ML Kit y Camera instaladas en `pubspec.yaml`.
- [ ] El servidor backend Express corriendo en localhost.
- [ ] App móvil compilándose correctamente en el simulador o dispositivo.


