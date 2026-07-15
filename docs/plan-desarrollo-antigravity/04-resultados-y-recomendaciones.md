# 04 — Resultados y Recomendaciones (Semanas 8-9)

## 📌 Objetivo
Diseñar e implementar la pantalla de resultados que muestra el diagnóstico, recomendaciones y permite acciones como "Ver Ideas Relacionadas" y "Escanear producto".

---

## 📋 Tareas

### Frontend (Flutter)
- [ ] Crear `ResultsScreen` con:
  - `FutureBuilder` que carga el perfil desde el backend.
  - Widgets para mostrar scores (barras de progreso).
  - Tarjetas para cada sección (rostro, manos, recomendación, productos).
  - Botones de acción: "Ver Ideas Relacionadas", "Escanear Producto", "Volver a Ideas".
- [ ] Implementar **sección de productos sugeridos**:
  - Mostrar imagen, nombre, marca y precio (desde Open Beauty Facts).
  - Botón "+" para agregar a la rutina del usuario (guardar en tabla `user_routines`).
- [ ] Implementar **"Escanear Producto"**:
  - Abrir la cámara nativa utilizando la dependencia `mobile_scanner`.
  - Leer y decodificar el código de barras del empaque.
  - Llamar al endpoint `POST /api/product/check` (que usa la API de Open Beauty Facts).
  - Presentar feedback claro: *"Este producto es compatible con tu perfil"* o *"No recomendado"* detallando la justificación de la contraindicación.
- [ ] Implementar **"Ver Ideas Relacionadas"**:
  - Cerrar el hub retornando un mapa de argumentos al contexto padre: `Navigator.pop(context, { filter: 'uñas-almendradas', subtono: 'cálido' })`.
  - Configurar el receptor en el Hub de Ideas para capturar estos argumentos y aplicar los filtros de visualización inmediatamente.
- [ ] Implementar **"Volver a Ideas"**:
  - Cerrar el hub mediante pop estándar sin aplicar filtros.

### Backend (Node.js)
- [ ] Crear endpoint `POST /api/product/check`:
  - Body: `{ userId, barcode }`
  - Consultar base de datos/API de Open Beauty Facts para extraer la fórmula de ingredientes.
  - Comparar ingredientes con las contraindicaciones del perfil biométrico activo de la usuaria.
  - Devolver: `{ compatible: true/false, product: {...}, reason: "..." }`.
- [ ] Crear endpoint `POST /api/routine/add`:
  - Body: `{ userId, productId, step }`
  - Guardar el producto y el paso asignado en la tabla de persistencia `user_routines`.

---

## ✅ Criterios de Aceptación
1. **Presentación de Diagnóstico:** La pantalla renderiza todos los campos e imágenes en menos de 1 segundo tras la carga exitosa del backend.
2. **Visualización de Scores:** Las barras de progreso representan el porcentaje de salud dérmica y capilar con transiciones fluidas.
3. **Lectura de Códigos:** El escáner detecta códigos de barras estándar (EAN-13/UPC) bajo condiciones variables de iluminación.
4. **Cálculo de Compatibilidad:** Los productos incompatibles se destacan en rojo indicando el ingrediente específico de la alerta (p.ej. alérgenos o parabenos no indicados).
5. **Comunicación entre Pantallas:** El pop con filtros actualiza la vista principal de la sección de Ideas aplicando los filtros dinámicos.

---

## ⏱️ Estimación
* **Frontend:** 1.5 semanas.
* **Backend Endpoints:** 0.5 semanas.
* **Total:** 2 semanas.

