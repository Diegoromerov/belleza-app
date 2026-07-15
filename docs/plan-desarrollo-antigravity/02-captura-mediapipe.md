# 02 — Captura con MediaPipe (Semanas 2-4)

## 📌 Objetivo
Construir la pantalla de captura que guía a la usuaria para tomar fotos de rostro y manos con calidad suficiente para las APIs externas, utilizando MediaPipe on‑device.

---

## 📋 Tareas

### Frontend (Flutter)
- [ ] Agregar dependencias en `pubspec.yaml`:
  ```yaml
  dependencies:
    google_mlkit_face_detection: ^0.10.0
    google_mlkit_hand_detection: ^0.10.0
    camera: ^0.10.5
    image_picker: ^1.0.4  # para fallback si la cámara no está disponible
  ```
- [ ] Implementar `CaptureScreen` con `CameraController` para procesar el stream de video.
- [ ] Integrar `FaceDetector` y `HandDetector` de Google ML Kit para validación en tiempo real.
- [ ] Dibujar una guía de máscara (Overlay) con `CustomPainter` (óvalo para rostro y silueta para manos).
- [ ] Implementar temporizador de captura automática (disparador tras 1 segundo continuo en estado Verde).
- [ ] Crear la pantalla explicativa inicial `WelcomeScreen` (introducción corta de 30 segundos).
- [ ] Diseñar el flujo de navegación: `ConsentScreen` ➡️ `WelcomeScreen` ➡️ `CaptureScreen` (Rostro ➡️ Manos ➡️ Procesando).
- [ ] Manejar la caída al selector de galería mediante `image_picker` si la cámara no se inicializa o no cuenta con permisos.

---

## ⚙️ Especificaciones de Validación e Integración

### 1. Validación del Rostro (`FaceMeshValidator`)
El pipeline procesa los cuadros de video en tiempo real y calcula:
* **Encuadre:** Bounding box del rostro debe abarcar al menos el 30% del ancho del visor de cámara.
* **Oclusión y Alineación:** Ausencia de giros extremos (pitch/yaw/roll < 15 grados) para asegurar vista frontal.
* **Luminosidad:** Contraste mínimo aceptable.
* **Instrucciones Dinámicas:** Devuelve estado (`red`, `yellow`, `green`) y mensajes en pantalla como *"Acércate más"*, *"Centra tu rostro"*, *"Mira hacia la luz"*.

### 2. Validación de Manos (`HandValidator`)
* **Detección:** Los 21 puntos clave de la mano deben detectarse de manera completa.
* **Silueta:** Posición y orientación dentro de las coordenadas de la silueta pintada en el overlay.
* **Extensión:** Verifica que los dedos estén extendidos (mano abierta) para una lectura correcta del color de esmalte y uñas.

### 3. Manejo de Memoria
* Las imágenes resultantes de la captura exitosa se guardan en memoria como variables `Uint8List` y no se persisten en disco para garantizar la privacidad y reducir el uso de almacenamiento.

---

## 🎨 Especificaciones de UX/UI
* **Overlay Reactivo:** El borde de la máscara del overlay cambia de color dinámicamente según el estado:
  * 🔴 **Rojo:** Sin rostro/mano detectada.
  * 🟡 **Amarillo:** Rostro/mano detectada pero mal alineada o con mala iluminación.
  * 🟢 **Verde:** Alineación óptima (inicia la cuenta regresiva de 1 segundo para la foto).
* **Indicador de Calidad:** Anillo circular o barra de progreso visual de captura automática.
* **Botón Cancelar:** Visible en todo momento para hacer pop e interrumpir el flujo regresando al Hub de Ideas.

---

## ✅ Criterios de Aceptación
1. **Inicialización Limpia:** La cámara se abre y adapta el visor al aspect ratio del dispositivo en iOS y Android.
2. **Overlay Adaptativo:** El overlay de `CustomPainter` se ajusta a pantallas de diversos tamaños (responsivo).
3. **Robustez Lumínica:** La detección de rostro responde correctamente ante diferentes tonos de piel y condiciones lumínicas de prueba.
4. **Detección Bidireccional:** La validación de manos funciona tanto para palma como para el dorso.
5. **Autodisparo Estable:** El autodisparo ocurre de forma consistente tras 1 segundo continuo en color verde.
6. **Cancelación Voluntaria:** Cancelar destruye los controladores de la cámara y retorna de inmediato al Hub de Ideas sin fugas de memoria.


