# 🎨 UX Audit — Estándares de Experiencia de Usuario

## Requisitos Obligatorios para Toda Interfaz
1. **Loading State:** Todo botón o contenedor en estado asíncrono debe mostrar un componente Skeleton o Spinner.
2. **Empty State:** Cuando un listado no contenga elementos, se debe renderizar una vista ilustrativa y clara.
3. **Error State:** Los fallos de red deben capturarse y presentarse mediante mensajes amigables (Toast o Banner) evitando errores de consola no controlados.
4. **Prohibición:** Se prohíbe el uso de `alert()` y `confirm()` nativos del navegador. Utilizar modales de React/Tailwind.
