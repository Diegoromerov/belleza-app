# AUDITORÍA DE DEPURAICÓN DEL CATÁLOGO (GLOWSHOP B-02)

**Fecha**: 2026-09-24  
**Objetivo**: Presentar el análisis medido del catálogo actual (296 productos en base de datos) y las alternativas de decisión de negocio para el usuario `@Diegoromerov` **sin alterar ni mutar ningún dato existente**.

---

## 1. COMPROBACIÓN DE TABLAS REALES AFECTADAS

Verificación asertiva en PostgreSQL mediante `to_regclass`:

```sql
SELECT 
  to_regclass('detalles_pedido_tienda')::text AS detalles_pedido_tienda, 
  to_regclass('precios_producto')::text AS precios_producto, 
  to_regclass('booking_productos')::text AS booking_productos, 
  to_regclass('scan_product_matches')::text AS scan_product_matches, 
  to_regclass('inventario_consignacion_prestador')::text AS inventario_consignacion_prestador;
```

**Resultado de la comprobación**:
- `detalles_pedido_tienda` -> **Existe (`detalles_pedido_tienda`)** *(Reemplaza la denominación incorrecta `orden_items`)*
- `precios_producto` -> **Existe (`precios_producto`)**
- `booking_productos` -> **Existe (`booking_productos`)**
- `scan_product_matches` -> **Existe (`scan_product_matches`)**
- `inventario_consignacion_prestador` -> **Existe (`inventario_consignacion_prestador`)**

---

## 2. MEDICIÓN DEL ESTADO ACTUAL DEL CATÁLOGO

Medido directamente sobre la base de datos PostgreSQL (`beauty_db` en puerto 5435):

- **Total de filas en `productos`**: 296
- **Nombres distintos de productos**: 16
- **Distribución de copias**:
  - **10 Nombres Principales**: Tienen **29 repeticiones exactas cada uno** (290 filas en total, IDs 1 al 10 y sus duplicados).
  - **6 Nombres de Cuidado Masculino**: Tienen **1 registro cada uno** (6 filas en total, IDs 646 al 651).

### Tabla de Desglose Fiel de Referencias por Producto Canónico (5 Tablas)

| ID Canónico | Nombre del Producto | Copias BD | `precios_producto` | `detalles_pedido_tienda` | `booking_productos` | `scan_product_matches` | `inventario_consignacion` |
|---|---|---|---|---|---|---|---|
| **1** | Shampoo de Argán Orgánico | 29 | 1 | 0 | 0 | 0 | 0 |
| **2** | Acondicionador de Coco Nutritivo | 29 | 1 | 1 | 0 | 0 | 0 |
| **3** | Mascarilla Reparadora de Queratina | 29 | 1 | 0 | 0 | 0 | 0 |
| **4** | Esmalte Semipermanente Glow Red | 29 | 1 | 0 | 0 | 0 | 0 |
| **5** | Aceite Hidratante para Cutículas | 29 | 1 | 0 | 0 | 0 | 0 |
| **6** | Paleta de Sombras Nude | 29 | 1 | 0 | 0 | 0 | 0 |
| **7** | Base de Maquillaje Matificante | 29 | 1 | 0 | 0 | 0 | 0 |
| **8** | Labial Líquido Mate Larga Duración | 29 | 1 | 0 | 0 | 0 | 0 |
| **9** | Cera Elástica de Miel (1kg) | 29 | 1 | 0 | 0 | 0 | 0 |
| **10** | Kit Pestañas Premium (Melted) | 29 | 1 | 0 | 0 | 0 | 0 |
| **646** | Bálsamo Hidratante de Barba (Cedro & Sándalo) | 1 | 1 | 0 | 0 | 0 | 0 |
| **647** | Cera de Peinado Matte Pomade (Fijación Fuerte) | 1 | 1 | 0 | 0 | 0 | 0 |
| **648** | Aceite de Crecimiento & Brillo para Barba (50ml) | 1 | 1 | 0 | 0 | 0 | 0 |
| **649** | Shampoo Anticaída & Estimulante Capilar Hombres | 1 | 1 | 0 | 0 | 0 | 0 |
| **650** | Gel Limpiador Facial Detox Masculino (Carbón Activado) | 1 | 1 | 0 | 0 | 0 | 0 |
| **651** | Loción Aftershave Hidratante Anti-Irritación | 1 | 1 | 0 | 0 | 0 | 0 |

---

## 3. ORIGEN DE LA DUPLICACIÓN
Las 29 copias de cada uno de los 10 productos principales provienen del proceso histórico de sembrado del multi-tenant. Con la arquitectura multinivel B2B/B2C unificada por listas de precios, la duplicación ya no es necesaria.

---

## 4. ALTERNATIVAS DE DECISIÓN DE NEGOCIO PARA EL USUARIO (`@Diegoromerov`)

El usuario debe elegir entre tres estrategias antes de popular masivamente las tarifas B2B de `profesional` y `salón`:

### Opción A (Recomendada): Consolidar en 16 Productos Canónicos
- **En qué consiste**: Mantener únicamente el primer registro de cada nombre (los 16 IDs canónicos: 1 a 10 y 646 a 651) y marcar los 280 duplicados con `activo = false` o archivarlos.
- **Ventaja**: El panel de administración muestra exactamente 16 productos limpios para fijar precios B2C/B2B sin redundancia.
- **Preservación**: Ningún dato se borra (`DELETE`), preservando la integridad referencial en `detalles_pedido_tienda` (donde el producto 2 registra 1 item histórico).

### Opción B: Mantener los 296 Productos para Variantes por Prestador / SKU
- **En qué consiste**: Conservar las 296 filas y asignar a cada duplicado un SKU único asociado a un proveedor o ubicación específica.
- **Ventaja**: Permite precios diferenciados por prestador o ubicación física.
- **Desventaja**: Mayor volumen de carga al gestionar precios en el panel o por CSV (296 filas x 3 listas = 888 precios).

### Opción C: Fusionar Duplicados y Reasignar Pedidos Históricos en `detalles_pedido_tienda`
- **En qué consiste**: Reasignar los `producto_id` en `detalles_pedido_tienda` (1 referencia en producto 2) hacia los 16 productos canónicos y eliminar lógicamente las 280 copias sobrantes.

---

## 5. ESTADO DE LOS DATOS
En cumplimiento estricto con las reglas de ingeniería, **ninguna fila de la base de datos fue modificada ni eliminada** durante esta auditoría. La base permanece 100% en su estado inicial (296 productos / 296 precios / 0 historial).
