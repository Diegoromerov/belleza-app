# FISCAL-BOUNDARY.md

# FRONTERA FISCAL EN GLOWAPP

## 1. PRINCIPIO FUNDAMENTAL
Durante la Fase 1, GlowApp opera como **SaaS operativo B2B** para peluquerías, centros de estética y spas, **sin asumir obligaciones fiscales propias del salón**.

La frontera se define así:

```
OPERACIÓN COMERCIAL DEL SALÓN   ← gestión de citas, servicios, productos, pagos internos
                              |
                              v
OBLIGACIÓN FISCAL DEL SALÓN    ← emisión de facturas electrónicas, retenciones, declaraciones DIAN
```

GlowApp **no cruza** esa frontera en la Fase 1.

## 2. QUÉ INFORMACIÓN PUEDE MANEJAR GLOWAPP SIN CONVERTIRSE EN FACTURADOR FISCAL

Los siguientes datos y flujos son operativos y **no requieren** que GlowApp actúe como responsable fiscal:

- **Registro interno de pagos**: monto, método de pago (NEQUI, tarjeta, PSE, efectivo), referencia externa del PSP, estado (aprobado, rechazado, pendiente), timestamp.
- **Comprobantes internos de pago**: recibo que muestra el monto pagado, método, fecha, referencia externa, pero **sin**:
  - CUFE (Código Único de Facturación Electrónica)
  - Numeración autorizada por DIAN
  - XML/UBL o cualquier formato requerido por la DIAN
  - Datos de responsabilidad fiscal del emisor (NIT, razón social, dirección del salón)
  - Desglose de impuestos (IVA, ICA, etc.) que deban aparecer en una factura
  - Leyenda de facturación electrónica
- **Historial de transacciones**: para conciliación interna y reportes operativos del salón.
- **Configuración de métodos de pago**: habilitación o deshabilitación de medios de pago disponibles.
- **Reportes de caja y movimientos**: sumas, conteos, promedios, sin desglose fiscal requerido por norma.

## 3. QUÉ INFORMACIÓN SERÍA CONVENIENTE ESTRUCTURAR DESDE FASE 1 PARA PERMITIR UNA FUTURA INTEGRACIÓN

Para que una futura integración con un proveedor tecnológico DIAN habilitado sea lo más fluida posible, GlowApp puede estructurar desde ahora los siguientes datos operativos (sin que ello implique asumir obligaciones fiscales):

- **Monto bruto de la transacción** (valor total pagado por el cliente).
- **Monto neto recibido por el salón** (después de eventual comisión, si corresponde).
- **Método de pago utilizado** (para aplicar reglas de facturación según medio).
- **Referencia externa única del PSP** (external_id) para idempotencia y trazabilidad.
- **Timestamp preciso** de la transacción.
- **Identificador del salón (tenant_id)** una vez definido.
- **Identificador del cliente** (si se almacena y con su consentimiento).
- **Lista de servicios/productos consumidos** con sus cantidades y precios unitarios (para posible desglose en factura).
- **Indicador de si la transacción requiere facturación electrónica** (pendiente de decisión futura basada en régimen del salón, monto, etc.).
- **Indicador de si el salón está obligado a facturar electrónicamente** (para futuras reglas de activación del adapter).

Estos datos se almacenan **sin campos fiscales** y **sin generar ningún documento que pueda confundirse con una factura electrónica**. Son meramente insumos operativos que un futuro adapter podría utilizar para generar la factura electrónica correspondiente, siempre que el salón lo autorice y el proveedor tecnológico DIAN lo habilite.

## 4. QUÉ INFORMACIÓN NO DEBE MANEJAR GLOWAPP EN FASE 1 PARA EVITAR ASUMIR OBLIGACIONES FISCALES

Para mantener la frontera clara, GlowApp **no debe**:

- Generar, almacenar o transmitir CUFE.
- Asignar numeración de factura autorizada por DIAN.
- Procesar o almacenar XML/UBL o cualquier formato requerido por la DIAN para facturación electrónica.
- Emitir documentos que incluyan leyendas de facturación electrónica.
- Almacenar datos de responsabilidad fiscal del salón (NIT, razón social, matrícula mercantil) como parte de un comprobante de pago (estos datos pueden estar en el perfil del salón para otros usos, pero no en el comprobante interno de pago).
- Realizar cálculos de impuestos que deban aparecer en una factura (IVA, retenciones, etc.) como parte del comprobante interno.
- Transmitir información directamente a la DIAN o a un tercero bajo el supuesto de que se está cumpliendo una obligación de facturación electrónica.
- Actuar como intermediario financiero que reciba fondos brutos para su posterior distribución sin una decisión explícita y autorizada al respecto.

## 5. RELACIÓN CON LA ARQUITECTURA FUTURA

La frontera fiscal se mantiene como una **capacidad futura** (FUTURE CAPABILITY) y **no como requisito de implementación inmediata**. La arquitectura actual permite:

- Una capa de abstracción (fiscal adapter) que permanece inactiva hasta que se decida activarla.
- La posibilidad de conectar, en el futuro, a un proveedor tecnológico DIAN habilitado mediante esa capa, sin modificar los dominios core de booking, crm, commerce o payment.
- El salón mantiene en todo momento la responsabilidad de decidir si y cuándo usar dicho adapter, asumiendo así sus propias obligaciones fiscales.

## 6. CONCLUSIÓN

En Fase 1, GlowApp:

✅ Maneja información operativa de pagos y servicios sin campos fiscales.  
✅ No asume responsabilidades de facturación electrónica ni de emisor fiscal.  
✅ Estructura datos útiles para una futura integración sin cruzar la frontera fiscal.  
✅ Deja la responsabilidad fiscal explícitamente en manos del salón.  
✅ Mantiene la posibilidad futura de integración con un proveedor DIAN mediante un adapter inactivo.

--- 
Fin del documento.