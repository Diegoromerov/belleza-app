# AUDITORÍA DE DEPURAICÓN DEL CATÁLOGO (GLOWSHOP B-01)

**Fecha**: 2026-09-24  
**Objetivo**: Presentar el análisis medido del catálogo actual (296 productos en base de datos) y las alternativas de decisión de negocio para el usuario `@Diegoromerov` **sin alterar ni mutar ningún dato existente**.

---

## 1. MEDICIÓN DEL ESTADO ACTUAL DEL CATÁLOGO

Medido directamente sobre la base de datos PostgreSQL (`beauty_db` en puerto 5435):

- **Total de filas en `productos`**: 296
- **Nombres distintos de productos**: 16
- **Distribución de copias**:
  - **10 Nombres Principales**: Tienen **29 repeticiones exactas cada uno** (290 filas en total, IDs 1 al 10 y sus duplicados).
  - **6 Nombres de Cuidado Masculino**: Tienen **1 registro cada uno** (6 filas en total, IDs 646 al 651).

### Tabla de Desglose Fiel de la Base de Datos

| ID Canónico | Nombre del Producto | Copias Existentes en BD | Costo Registrado | SKU Registrado |
|---|---|---|---|---|
| **1** | Shampoo de Argán Orgánico | 29 | $25.000,00 | `null` |
| **2** | Acondicionador de Coco Nutritivo | 29 | $30.000,00 | `null` |
| **3** | Mascarilla Reparadora de Queratina | 29 | `null` | `null` |
| **4** | Esmalte Semipermanente Glow Red | 29 | `null` | `null` |
| **5** | Aceite Hidratante para Cutículas | 29 | `null` | `null` |
| **6** | Paleta de Sombras Nude | 29 | `null` | `null` |
| **7** | Base de Maquillaje Matificante | 29 | `null` | `null` |
| **8** | Labial Líquido Mate Larga Duración | 29 | `null` | `null` |
| **9** | Cera Elástica de Miel (1kg) | 29 | `null` | `null` |
| **10** | Kit Pestañas Premium (Melted) | 29 | `null` | `null` |
| **646** | Bálsamo Hidratante de Barba (Cedro & Sándalo) | 1 | `null` | `null` |
| **647** | Cera de Peinado Matte Pomade (Fijación Fuerte) | 1 | `null` | `null` |
| **648** | Aceite de Crecimiento & Brillo para Barba (50ml) | 1 | `null` | `null` |
| **649** | Shampoo Anticaída & Estimulante Capilar Hombres | 1 | `null` | `null` |
| **650** | Gel Limpiador Facial Detox Masculino (Carbón Activado) | 1 | `null` | `null` |
| **651** | Loción Aftershave Hidratante Anti-Irritación | 1 | `null` | `null` |

---

## 2. ORIGEN DE LA DUPLICACIÓN
Las 29 copias de cada uno de los 10 productos principales provienen del proceso histórico de sembrado del multi-tenant (donde se replicó el catálogo para cada tenant/prestador en el esquema anterior). Con el modelo multinivel B2B/B2C unificado por listas de precios, la duplicación ya no es requerida y genera dispersión en la carga de precios por nivel.

---

## 3. ALTERNATIVAS DE DECISIÓN DE NEGOCIO PARA EL USUARIO (`@Diegoromerov`)

El usuario debe elegir entre tres estrategias antes de popular masivamente las tarifas B2B de `profesional` y `salón`:

### Opción A (Recomendada): Consolidar en 16 Productos Canónicos
- **En qué consiste**: Mantener únicamente el primer registro de cada nombre (los 16 IDs canónicos: 1 a 10 y 646 a 651) y marcar los 280 duplicados con `activo = false` o archivarlos.
- **Ventaja**: El panel de administración muestra exactamente 16 productos limpios para fijar precios B2C/B2B sin redundancia.
- **Preservación**: Ningún dato se borra (`DELETE`), preservando la integridad referencial de pedidos históricos.

### Opción B: Mantener los 296 Productos para Variantes por Prestador / SKU
- **En qué consiste**: Conservar las 296 filas y asignar a cada duplicado un SKU único asociado a un proveedor o lote específico.
- **Ventaja**: Permite precios diferenciados por prestador o ubicación física.
- **Desventaja**: Mayor volumen de carga al gestionar precios en el panel o por CSV (296 filas x 3 listas = 888 precios).

### Opción C: Fusionar Duplicados y Reasignar Pedidos Históricos
- **En qué consiste**: Reasignar los `producto_id` en `orden_items` hacia los 16 productos canónicos y eliminar lógicamente las 280 copias sobrantes.

---

## 4. ESTADO DE LOS DATOS
En cumplimiento estricto con las reglas de ingeniería, **ninguna fila de la base de datos fue modificada ni eliminada** durante esta auditoría. La base permanece 100% en su estado inicial (296 productos / 296 precios / 0 historial).
