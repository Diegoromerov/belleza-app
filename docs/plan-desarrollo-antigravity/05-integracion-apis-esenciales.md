# 05 — Integración de APIs Esenciales (Semana 10)

## 📌 Objetivo
Integrar las APIs complementarias que enriquecen la experiencia: Open Beauty Facts (productos), OpenUV (FPS dinámico) y The Color API (paletas).

---

## 📋 Tareas

### Backend (Node.js)
- [ ] **Open Beauty Facts**:
  - Crear cliente `openBeautyFacts.js` con:
    - `searchByBarcode(barcode)` ➡️ devuelve producto.
    - `searchByIngredient(ingredient)` ➡️ devuelve lista de productos.
    - `searchByCategory(category)` ➡️ para ideas relacionadas.
  - Integrar en el orquestador: cuando Gemini recomiende ingredientes, buscar productos reales.
  - Fallback: si no encuentra productos, mostrar mensaje *"Consulta con tu especialista"*.
- [ ] **OpenUV**:
  - Crear cliente `openUV.js`:
    - `getUVByCity(lat, lng)` ➡️ devuelve índice UV y recomendación.
    - Cachear por ciudad/coordenadas en Redis (TTL: 1 hora) para no exceder el límite gratuito (50 req/día).
  - Integrar en la recomendación: agregar texto de FPS dinámico (ej. *"Hoy UV 8, usa FPS 50+"*).
- [ ] **The Color API**:
  - Crear cliente `colorApi.js`:
    - `getPalette(hexColor, count = 5)` ➡️ devuelve paleta armónica.
  - Integrar en `ResultsScreen`: mostrar carrusel de colores sugeridos (esmaltes, bases).

### Frontend (Flutter)
- [ ] Agregar widget de carrusel de colores en `ResultsScreen` (usando The Color API).
- [ ] Mostrar el índice UV y recomendación de FPS en la rutina AM.
- [ ] Botón "Ver más productos" que carga más resultados de Open Beauty Facts.

---

## ✅ Criterios de Aceptación
1. **Presentación de Productos:** Los productos de Open Beauty Facts se muestran con su imagen, nombre y marca.
2. **Robustez en Códigos:** La búsqueda por código de barras responde correctamente cruzando la compatibilidad de ingredientes.
3. **Caché de Radiación:** El índice UV se muestra en la rutina AM, respetando el límite diario de peticiones mediante el uso de caché en Redis.
4. **Carrusel de Tonos:** La paleta de colores sugerida se renderiza correctamente con los códigos HEX retornados.

---

## ⏱️ Estimación
* **Backend:** 3 días.
* **Frontend:** 2 días.
* **Total:** 1 semana.

