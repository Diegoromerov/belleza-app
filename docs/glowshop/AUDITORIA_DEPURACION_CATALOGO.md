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
- `scan_product_matches` -> **Existe (`scan_product_matches`)** *(Nota de esquema: utiliza la columna `product_id`)*
- `inventario_consignacion_prestador` -> **Existe (`inventario_consignacion_prestador`)**

---

## 2. MEDICIÓN DEL ESTADO ACTUAL DEL CATÁLOGO

Medido directamente sobre la base de datos PostgreSQL (`beauty_db` en puerto 5435):

- **Total de filas en `productos`**: 296
- **Nombres distintos de productos**: 16 (16 productos canónicos)
- **Total de productos duplicados/no canónicos**: 280
- **Distribución de copias**:
  - **10 Nombres Principales**: Tienen **29 repeticiones exactas cada uno** (290 filas en total: 10 canónicos + 280 duplicados).
  - **6 Nombres de Cuidado Masculino**: Tienen **1 registro cada uno** (6 filas en total, IDs 646 al 651).

---

## 3. RESUMEN DE IMPACTO TOTAL DE FUSIÓN (5 TABLAS REALES)

| Tabla Afectada | Nombre de Columna ID | Referencias en 280 Duplicados | Acción en Fusión |
|---|---|---|---|
| `precios_producto` | `producto_id` | 280 | Eliminar filas redundantes asociadas a duplicados |
| `detalles_pedido_tienda` | `producto_id` | 0 | Reasignar a ID Canónico (0 filas pendientes en duplicados) |
| `booking_productos` | `producto_id` | 0 | Reasignar a ID Canónico (0 filas pendientes en duplicados) |
| `scan_product_matches` | `product_id` | 0 | Reasignar a ID Canónico (0 filas pendientes en duplicados) |
| `inventario_consignacion_prestador` | `producto_id` | 0 | Reasignar a ID Canónico (0 filas pendientes en duplicados) |

*Nota de la base*: La única referencia histórica registrada en `detalles_pedido_tienda` pertenece al **ID canónico 2** (`Acondicionador de Coco Nutritivo`), por lo que no requiere reasignación.

---

## 4. DESGLOSE DE REFERENCIAS DE LOS 16 PRODUCTOS CANÓNICOS

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

## 5. DESGLOSE INDIVIDUAL DE REFERENCIAS POR CADA UNO DE LOS 280 PRODUCTOS DUPLICADOS

| ID Duplicado | Nombre del Producto | ID Canónico | `precios_producto` | `detalles_pedido_tienda` | `booking_productos` | `scan_product_matches` | `inventario_consignacion` |
|---|---|---|---|---|---|---|---|
| **23** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **24** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **25** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **26** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **27** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **28** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **29** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **30** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **31** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **32** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **45** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **46** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **47** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **48** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **49** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **50** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **51** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **52** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **53** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **54** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **67** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **68** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **69** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **70** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **71** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **72** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **73** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **74** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **75** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **76** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **89** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **90** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **91** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **92** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **93** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **94** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **95** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **96** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **97** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **98** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **111** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **112** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **113** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **114** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **115** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **116** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **117** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **118** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **119** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **120** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **144** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **145** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **146** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **147** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **148** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **149** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **150** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **151** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **152** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **153** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **168** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **169** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **170** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **171** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **172** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **173** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **174** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **175** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **176** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **177** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **190** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **191** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **192** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **193** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **194** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **195** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **196** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **197** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **198** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **199** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **212** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **213** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **214** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **215** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **216** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **217** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **218** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **219** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **220** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **221** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **234** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **235** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **236** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **237** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **238** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **239** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **240** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **241** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **242** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **243** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **256** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **257** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **258** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **259** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **260** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **261** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **262** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **263** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **264** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **265** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **278** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **279** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **280** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **281** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **282** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **283** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **284** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **285** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **286** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **287** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **300** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **301** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **302** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **303** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **304** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **305** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **306** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **307** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **308** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **309** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **322** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **323** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **324** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **325** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **326** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **327** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **328** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **329** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **330** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **331** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **344** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **345** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **346** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **347** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **348** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **349** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **350** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **351** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **352** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **353** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **366** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **367** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **368** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **369** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **370** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **371** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **372** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **373** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **374** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **375** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **388** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **389** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **390** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **391** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **392** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **393** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **394** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **395** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **396** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **397** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **410** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **411** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **412** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **413** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **414** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **415** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **416** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **417** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **418** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **419** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **432** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **433** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **434** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **435** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **436** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **437** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **438** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **439** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **440** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **441** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **454** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **455** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **456** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **457** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **458** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **459** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **460** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **461** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **462** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **463** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **476** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **477** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **478** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **479** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **480** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **481** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **482** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **483** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **484** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **485** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **498** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **499** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **500** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **501** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **502** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **503** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **504** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **505** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **506** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **507** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **520** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **521** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **522** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **523** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **524** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **525** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **526** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **527** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **528** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **529** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **542** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **543** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **544** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **545** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **546** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **547** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **548** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **549** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **550** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **551** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **564** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **565** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **566** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **567** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **568** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **569** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **570** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **571** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **572** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **573** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **586** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **587** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **588** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **589** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **590** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **591** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **592** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **593** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **594** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **595** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **608** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **609** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **610** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **611** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **612** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **613** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **614** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **615** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **616** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **617** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |
| **630** | Shampoo de Argán Orgánico | 1 | 1 | 0 | 0 | 0 | 0 |
| **631** | Acondicionador de Coco Nutritivo | 2 | 1 | 0 | 0 | 0 | 0 |
| **632** | Mascarilla Reparadora de Queratina | 3 | 1 | 0 | 0 | 0 | 0 |
| **633** | Esmalte Semipermanente Glow Red | 4 | 1 | 0 | 0 | 0 | 0 |
| **634** | Aceite Hidratante para Cutículas | 5 | 1 | 0 | 0 | 0 | 0 |
| **635** | Paleta de Sombras Nude | 6 | 1 | 0 | 0 | 0 | 0 |
| **636** | Base de Maquillaje Matificante | 7 | 1 | 0 | 0 | 0 | 0 |
| **637** | Labial Líquido Mate Larga Duración | 8 | 1 | 0 | 0 | 0 | 0 |
| **638** | Cera Elástica de Miel (1kg) | 9 | 1 | 0 | 0 | 0 | 0 |
| **639** | Kit Pestañas Premium (Melted) | 10 | 1 | 0 | 0 | 0 | 0 |

---

## 6. ORIGEN DE LA DUPLICACIÓN
Las 29 copias de cada uno de los 10 productos principales provienen del proceso histórico de sembrado del multi-tenant. Con la arquitectura multinivel B2B/B2C unificada por listas de precios, la duplicación ya no es necesaria.

---

## 7. ALTERNATIVAS DE DECISIÓN DE NEGOCIO PARA EL USUARIO (`@Diegoromerov`)

El usuario debe elegir entre tres estrategias antes de popular masivamente las tarifas B2B de `profesional` y `salón`:

### Opción A (Recomendada): Consolidar en 16 Productos Canónicos
- **En qué consiste**: Mantener únicamente el primer registro de cada nombre (los 16 IDs canónicos: 1 a 10 y 646 a 651) y marcar los 280 duplicados con `activo = false` o archivarlos.
- **Ventaja**: El panel de administración muestra exactamente 16 productos limpios para fijar precios B2C/B2B sin redundancia.
- **Preservación**: Ningún dato se borra (`DELETE`), preservando la integridad referencial en `detalles_pedido_tienda` (donde el producto 2 registra 1 item histórico).

### Opción B: Mantener los 296 Productos para Variantes por Prestador / SKU
- **En qué consiste**: Conservar las 296 filas y asignar a cada duplicado un SKU único asociado a un proveedor o ubicación específica.
- **Ventaja**: Permite precios diferenciados por prestador o ubicación física.
- **Desventaja**: Mayor volumen de carga al gestionar precios en el panel o por CSV (296 filas x 3 listas = 888 precios).

### Opción C: Fusionar Duplicados y Reasignar Pedidos Históricos en las 5 Tablas
- **En qué consiste**: Reasignar las referencias de los 280 duplicados hacia los 16 productos canónicos en las 5 tablas de la base de datos y eliminar las 280 copias sobrantes.

```sql
-- SQL de consolidación / reasignación de referencias a productos canónicos (verificado)
BEGIN;

-- 1. Reasignar referencias en las 5 tablas
UPDATE detalles_pedido_tienda d
SET producto_id = c.canonical_id
FROM (
  SELECT p.id AS dup_id, min_p.canonical_id
  FROM productos p
  JOIN (
    SELECT LOWER(TRIM(nombre)) AS norm_nombre, MIN(id) AS canonical_id
    FROM productos GROUP BY LOWER(TRIM(nombre))
  ) min_p ON LOWER(TRIM(p.nombre)) = min_p.norm_nombre
  WHERE p.id <> min_p.canonical_id
) c
WHERE d.producto_id = c.dup_id;

UPDATE booking_productos b
SET producto_id = c.canonical_id
FROM (
  SELECT p.id AS dup_id, min_p.canonical_id
  FROM productos p
  JOIN (
    SELECT LOWER(TRIM(nombre)) AS norm_nombre, MIN(id) AS canonical_id
    FROM productos GROUP BY LOWER(TRIM(nombre))
  ) min_p ON LOWER(TRIM(p.nombre)) = min_p.norm_nombre
  WHERE p.id <> min_p.canonical_id
) c
WHERE b.producto_id = c.dup_id;

-- ATENCIÓN: scan_product_matches utiliza la columna 'product_id'
UPDATE scan_product_matches s
SET product_id = c.canonical_id
FROM (
  SELECT p.id AS dup_id, min_p.canonical_id
  FROM productos p
  JOIN (
    SELECT LOWER(TRIM(nombre)) AS norm_nombre, MIN(id) AS canonical_id
    FROM productos GROUP BY LOWER(TRIM(nombre))
  ) min_p ON LOWER(TRIM(p.nombre)) = min_p.norm_nombre
  WHERE p.id <> min_p.canonical_id
) c
WHERE s.product_id = c.dup_id;

UPDATE inventario_consignacion_prestador i
SET producto_id = c.canonical_id
FROM (
  SELECT p.id AS dup_id, min_p.canonical_id
  FROM productos p
  JOIN (
    SELECT LOWER(TRIM(nombre)) AS norm_nombre, MIN(id) AS canonical_id
    FROM productos GROUP BY LOWER(TRIM(nombre))
  ) min_p ON LOWER(TRIM(p.nombre)) = min_p.norm_nombre
  WHERE p.id <> min_p.canonical_id
) c
WHERE i.producto_id = c.dup_id;

-- 2. Eliminar precios asociados a los duplicados
DELETE FROM precios_producto
WHERE producto_id IN (
  SELECT p.id FROM productos p
  JOIN (
    SELECT LOWER(TRIM(nombre)) AS norm_nombre, MIN(id) AS canonical_id
    FROM productos GROUP BY LOWER(TRIM(nombre))
  ) min_p ON LOWER(TRIM(p.nombre)) = min_p.norm_nombre
  WHERE p.id <> min_p.canonical_id
);

-- 3. Marcar inactivos los duplicados
UPDATE productos
SET activo = false
WHERE id IN (
  SELECT p.id FROM productos p
  JOIN (
    SELECT LOWER(TRIM(nombre)) AS norm_nombre, MIN(id) AS canonical_id
    FROM productos GROUP BY LOWER(TRIM(nombre))
  ) min_p ON LOWER(TRIM(p.nombre)) = min_p.norm_nombre
  WHERE p.id <> min_p.canonical_id
);

COMMIT;
```

---

## 8. ESTADO DE LOS DATOS
En cumplimiento estricto con las reglas de ingeniería, **ninguna fila de la base de datos fue modificada ni eliminada** durante esta auditoría. La base permanece 100% en su estado inicial (296 productos / 296 precios / 0 historial).
