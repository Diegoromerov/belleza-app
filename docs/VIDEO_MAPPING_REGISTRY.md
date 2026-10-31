# GlowApp — Video Mapping Registry

**Versión:** 1.0 — 2026-10-31  
**Estado:** Firebase Storage activo (temporal) → Cloudflare Stream (futuro, bloqueado por pago)

---

## 1. Resumen

| Métrica | Valor |
|---------|-------|
| **Total videos** | 16 (8 cliente + 7 proveedor + 1 intro) |
| **Formatos por video** | 2 (MP4 + WebM) |
| **Total archivos** | 30 (intro solo existe en cliente/provider raíz, no duplicado) |
| **Storage actual** | Firebase Storage (2 proyectos) |
| **Storage futuro** | Cloudflare Stream (HLS adaptativo) |
| **Tamaño estimado** | ~33 MB eliminados del repo |

---

## 2. Cliente — glowapp-client (Project ID: 634593218804)

**Bucket:** `gs://glowapp-client.firebasestorage.app/` (raíz)

| Step ID | Título | MP4 URL | WebM URL | Tamaño MP4 | Tamaño WebM |
|---------|--------|---------|----------|------------|-------------|
| `step_01_welcome` | Bienvenida | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-client.firebasestorage.app/o/step_01_welcome.mp4?generation=1793424929556808&alt=media) | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-client.firebasestorage.app/o/step_01_welcome.webm?generation=1793423408194677&alt=media) | 2.3 MB | 2.6 MB |
| `step_02_citas` | Citas | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-client.firebasestorage.app/o/step_02_citas.mp4?generation=1793424929599040&alt=media) | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-client.firebasestorage.app/o/step_02_citas.webm?generation=1793423407462402&alt=media) | 2.6 MB | 2.5 MB |
| `step_03_glowshop` | GlowShop | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-client.firebasestorage.app/o/step_03_glowshop.mp4?generation=1793424928891142&alt=media) | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-client.firebasestorage.app/o/step_03_glowshop.webm?generation=1793423408198897&alt=media) | 2.5 MB | 2.5 MB |
| `step_04_glowia` | GlowIA | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-client.firebasestorage.app/o/step_04_glowia.mp4?generation=1793424929659765&alt=media) | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-client.firebasestorage.app/o/step_04_glowia.webm?generation=1793423408058845&alt=media) | 2.9 MB | 2.4 MB |
| `step_05_perfil` | Perfil | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-client.firebasestorage.app/o/step_05_perfil.mp4?generation=1793424928537476&alt=media) | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-client.firebasestorage.app/o/step_05_perfil.webm?generation=1793423409269013&alt=media) | 2.7 MB | 2.5 MB |
| `step_06_aurachat` | AuraChat | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-client.firebasestorage.app/o/step_06_aurachat.mp4?generation=1793424932237966&alt=media) | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-client.firebasestorage.app/o/step_06_aurachat.webm?generation=1793423404217276&alt=media) | 4.5 MB | 1.3 MB |
| `step_07_mapa` | Mapa | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-client.firebasestorage.app/o/step_07_mapa.mp4?generation=1793424932863032&alt=media) | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-client.firebasestorage.app/o/step_07_mapa.webm?generation=1793423404689606&alt=media) | 5.5 MB | 1.4 MB |
| `step_08_despedida` | Despedida | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-client.firebasestorage.app/o/step_08_despedida.mp4?generation=1793424931906132&alt=media) | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-client.firebasestorage.app/o/step_08_despedida.webm?generation=1793423403684021&alt=media) | 4.3 MB | 1.4 MB |

**Intro cliente:** `onboarding_intro.mp4` (solo MP4, 2.3 MB) — en `gs://glowapp-client.firebasestorage.app/onboarding_intro.mp4`

---

## 3. Proveedor — glowapp-provider (Project ID: 509840252897)

**Bucket:** `gs://glowapp-provider.firebasestorage.app/` (raíz)

| Step ID | Título | MP4 URL | WebM URL | Tamaño MP4 | Tamaño WebM |
|---------|--------|---------|----------|------------|-------------|
| `step_01_inicio` | Inicio | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-provider.firebasestorage.app/o/step_01_inicio.mp4?generation=1793423982815171&alt=media) | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-provider.firebasestorage.app/o/step_01_inicio.webm?generation=1793423587642458&alt=media) | ~2-5 MB | ~1-2 MB |
| `step_02_agenda` | Agenda | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-provider.firebasestorage.app/o/step_02_agenda.mp4?generation=1793423982432878&alt=media) | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-provider.firebasestorage.app/o/step_02_agenda.webm?generation=1793423589062291&alt=media) | ~2-5 MB | ~1-2 MB |
| `step_03_wallet` | Wallet | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-provider.firebasestorage.app/o/step_03_wallet.mp4?generation=1793423986125310&alt=media) | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-provider.firebasestorage.app/o/step_03_wallet.webm?generation=1793423588733260&alt=media) | ~2-5 MB | ~1-2 MB |
| `step_04_glowshop` | GlowShop | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-provider.firebasestorage.app/o/step_04_glowshop.mp4?generation=1793423982904872&alt=media) | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-provider.firebasestorage.app/o/step_04_glowshop.webm?generation=1793423588322724&alt=media) | ~2-5 MB | ~1-2 MB |
| `step_05_academia` | Academia | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-provider.firebasestorage.app/o/step_05_academia.mp4?generation=1793423980707330&alt=media) | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-provider.firebasestorage.app/o/step_05_academia.webm?generation=1793423587033637&alt=media) | ~2-5 MB | ~1-2 MB |
| `step_06_chat` | Chat | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-provider.firebasestorage.app/o/step_06_chat.mp4?generation=1793423983548019&alt=media) | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-provider.firebasestorage.app/o/step_06_chat.webm?generation=1793423587838998&alt=media) | ~2-5 MB | ~1-2 MB |
| `step_07_perfil` | Perfil | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-provider.firebasestorage.app/o/step_07_perfil.mp4?generation=1793423981968728&alt=media) | [Link](https://storage.googleapis.com/download/storage/v1/b/glowapp-provider.firebasestorage.app/o/step_07_perfil.webm?generation=1793423588305141&alt=media) | ~2-5 MB | ~1-2 MB |

**Intro proveedor:** `onboarding_intro.mp4` (solo MP4) — en `gs://glowapp-provider.firebasestorage.app/onboarding_intro.mp4`

---

## 4. Estructura en Código

**Archivo:** `packages/glow_core/lib/src/glowguide/config/video_mapping.dart`

```dart
class GlowGuideVideoMap {
  static const Map<String, Map<String, String>> client = {
    'step_01_welcome': {'mp4': 'https://storage.googleapis.com/...', 'webm': 'https://storage.googleapis.com/...'},
    // ... 8 steps
  };

  static const Map<String, Map<String, String>> provider = {
    'step_01_inicio': {'mp4': 'https://storage.googleapis.com/...', 'webm': 'https://storage.googleapis.com/...'},
    // ... 7 steps
  };

  // Helpers
  static String getMp4Url(String stepId, bool isProvider);
  static String getWebmUrl(String stepId, bool isProvider);
  static String getBestUrl(String stepId, bool isProvider); // Detección user-agent
  static bool hasUrls(String stepId, bool isProvider);
}
```

**Presenter:** `packages/glow_core/lib/src/glowguide/presenter/glowguide_presenter.dart`

```dart
class _GlowStepVideoPlayerState {
  bool _shouldUseMp4() {
    if (kIsWeb) {
      final ua = web.window.navigator.userAgent.toLowerCase();
      return ua.contains('safari') && !ua.contains('chrome');
    }
    return Platform.isIOS || Platform.isMacOS;
  }
  
  // Usa VideoPlayerController.networkUrl() con URL de video_mapping.dart
}
```

---

## 5. Migración Futura — Cloudflare Stream

**Cuando se desbloquee pago:**

1. **Subir a Cloudflare Stream Dashboard** (manual):
   - 16 videos × 2 formatos = 32 uploads (o solo MP4, Stream transcodifica a HLS)
   - Obtener UIDs: `UID_XXX` por video

2. **Actualizar `video_mapping.dart`**:
   ```dart
   // Reemplazar URLs Firebase Storage por:
   'step_01_welcome': 'https://iframe.videodelivery.net/UID_WELCOME',
   // El presenter cambia a iframe Player (HLS adaptativo)
   ```

3. **Migrar `GlowStepVideoPlayer`**:
   ```dart
   // De VideoPlayerController.networkUrl() a:
   // <iframe src="https://iframe.videodelivery.net/UID_XXX" ...>
   // Ventaja: HLS adaptativo, bitrate automático, DRM opcional
   ```

4. **Eliminar de Firebase Storage** (opcional, ahorro coste)

---

## 6. Estimación Costes

| Proveedor | Coste Estimado (mensual) | Notas |
|-----------|-------------------------|-------|
| **Firebase Storage** | ~$0.05-0.10 | 30 archivos, ~33 GB-mes (egress bajo, onboarding poco frecuente) |
| **Cloudflare Stream** | ~$1-5 | $1/1000 min stream + $5/1000 min storage; HLS adaptativo incluido |

---

## 7. Validación Rápida

```bash
# Test MP4 cliente
curl -s -o /dev/null -w "%{http_code}" "https://storage.googleapis.com/download/storage/v1/b/glowapp-client.firebasestorage.app/o/step_01_welcome.mp4?generation=1793424929556808&alt=media"
# → 200

# Test WebM cliente
curl -s -o /dev/null -w "%{http_code}" "https://storage.googleapis.com/download/storage/v1/b/glowapp-client.firebasestorage.app/o/step_01_welcome.webm?generation=1793423408194677&alt=media"
# → 200

# Test MP4 proveedor
curl -s -o /dev/null -w "%{http_code}" "https://storage.googleapis.com/download/storage/v1/b/glowapp-provider.firebasestorage.app/o/step_01_inicio.mp4?generation=1793423982815171&alt=media"
# → 200
```

---

## 8. Referencias

- **Firebase Console Storage:** https://console.firebase.google.com/project/glowapp-client/storage / glowapp-provider
- **Cloudflare Stream Dashboard:** https://dash.cloudflare.com/<account>/stream (requiere pago)
- **Código mapping:** `packages/glow_core/lib/src/glowguide/config/video_mapping.dart`
- **Código presenter:** `packages/glow_core/lib/src/glowguide/presenter/glowguide_presenter.dart`
- **Baseline:** `PLAN_UNIFICADO_BASELINE_2026-10-29.md` → Fase 7

---

*Generado automáticamente como parte de Fase 8 — Cleanup & Docs*