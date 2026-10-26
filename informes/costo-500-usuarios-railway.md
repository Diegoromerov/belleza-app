# Costo mensual de 500 personas usando GlowApp sobre Railway

**Fecha del cálculo:** 25 de octubre de 2026 · **Moneda base:** USD · **Conversión:** COP a TRM $3.158,43 · **Impuestos no incluidos**

## Resultado

| Escenario | Personas activas | Escaneos/mes | IA y APIs | Railway | **Total/mes (USD)** | **Total/mes (COP)** | Por persona activa |
|---|---:|---:|---:|---:|---:|---:|---:|
| BAJO — 60 % activas, 1 escaneo | 300 | 300 | $319,44 | $71,45 | **$390,89** | **$1.234.599** | $4.115 |
| **BASE — 500 activas, 1,5 escaneos** | **500** | **750** | **$803,77** | **$71,45** | **$875,22** | **$2.764.331** | **$5.529** |
| ALTO — 500 activas, 2,5 escaneos | 500 | 1.250 | $1.348,26 | $71,45 | **$1.419,71** | **$4.484.053** | $8.968 |

Lectura: **≈ USD 875/mes ≈ $2,76 millones COP/mes** como cifra central para 500 personas activas, con una banda de **USD 390 – 1.420** ($1,23 – $4,48 millones COP). El 92 % de ese costo son APIs de IA, y dentro de ellas **YouCam concentra USD 792 (≈ $2,50 millones COP, 90 % del total)**. Railway es solo USD 71 (≈ $225.670 COP, 8 %).

## TRM usada

| Dato | Valor |
|---|---|
| TRM vigente 24–26 de octubre de 2026 | **$3.158,43 COP por USD** |
| Fuente | Superfinanciera, publicada por [La República](https://www.larepublica.co/indicadores-economicos/mercado-cambiario/dolar) y contrastada con [Wilkinsonpc](https://dolar.wilkinsonpc.com.co/2026-10-25) |
| TRM anterior (23-oct) | $3.185,01 (variación diaria −0,83 %) |

La TRM es la tasa oficial del día y cambia a diario. Como los cuatro proveedores facturan en USD, **la TRM no altera la factura**: solo cambia su lectura en pesos. Si el ingreso es en COP y el costo en USD, una devaluación del 10 % sube el costo en pesos 10 % con el mismo consumo (ver sensibilidad abajo).

### Detalle en pesos (escenario BASE)

| Concepto | USD/mes | COP/mes |
|---|---:|---:|
| YouCam | $792,00 | $2.501.477 |
| Gemini + DeepSeek (resto de IA) | $11,77 | $37.184 |
| **Total IA** | **$803,77** | **$2.538.661** |
| Railway (producción + staging + varios) | $71,45 | $225.670 |
| **Total** | **$875,22** | **$2.764.331** |
| Costo por persona activa | $1,75 | $5.529 |
| Costo por persona (500) | $1,75 | $5.529 |
| Costo por escaneo | $1,07 | $3.385 |

### Sensibilidad a la TRM (BASE)

| TRM | Total/mes (COP) | Variación |
|---|---:|---:|
| $2.842,59 (−10 %) | $2.487.898 | −10,0 % |
| **$3.158,43 (vigente)** | **$2.764.331** | — |
| $3.474,27 (+10 %) | $3.040.764 | +10,0 % |


## Cómo se construyó

La topología no se inventó: sale de [railway.yml](../railway.yml), que declara cuatro servicios (`pgvector-db`, `redis`, `ai-worker`, `backend`) y un entorno `staging` clonado de producción. El frontend Flutter Web se sirve como build estático con nginx y el admin dashboard es un contenedor pequeño.

El flujo de un escaneo se leyó de [orchestrator.js](../backend/src/services/biometric/orchestrator.js): YouCam mide el rostro, Gemini analiza las manos, DeepSeek genera la recomendación y el matching de tonos VTO. El chat usa DeepSeek con RAG de `topK = 5` ([ragConfig.js](../backend/src/config/ragConfig.js)).

### Costos unitarios usados

| Concepto | Precio | Fuente |
|---|---|---|
| YouCam · análisis facial 16 acciones HD | **22 unidades × USD 0,048 = USD 1,056 por escaneo** | [Perfect Corp · pricing](https://yce.perfectcorp.com/ai-api/api-pricing): 13–16 concerns = 22 unidades en HD. Las 16 acciones están en [youcam.client.js](../backend/src/services/biometric/youcam.client.js) (`SKIN_ANALYSIS_ACTIONS`). |
| YouCam · pay-as-you-go | USD 0,055/unidad (USD 1,21 por escaneo) | Misma página. |
| Gemini 3.1 Flash-Lite | USD 0,125 / 1M entrada · USD 0,75 / 1M salida | [Google AI · pricing](https://ai.google.dev/gemini-api/docs/pricing) (vigente hasta 31-dic-2026). |
| DeepSeek Flash | USD 0,30 / 1M entrada · USD 1,20 / 1M salida (hora pico; off-peak = mitad) | [DeepSeek · pricing](https://api-docs.deepseek.com/quick_start/pricing). |
| Railway | USD 20/vCPU-mes · USD 10/GB-mes de RAM · USD 0,15/GB-mes de volumen · USD 0,05/GB de egress · plan Pro USD 20 con USD 20 de uso incluido | [railway.com/pricing](https://railway.com/pricing). |

Con eso, cada escaneo cuesta **USD 1,072**: 1,056 de YouCam + 0,016 de Gemini/DeepSeek. El chat cuesta **USD 0,00174 por mensaje** (4.000 tokens de entrada con RAG + 450 de salida).

### Infraestructura Railway (escenario BASE)

| Servicio | vCPU prom. | RAM GB | Volumen GB | Subtotal/mes |
|---|---:|---:|---:|---:|
| API Node/Express | 0,25 | 0,60 | — | $11,00 |
| ai-worker FastAPI (Pillow/numpy, sin GPU) | 0,10 | 0,30 | — | $5,00 |
| PostgreSQL 16 + pgvector | 0,25 | 1,00 | 12 | $16,80 |
| Redis 7 | 0,05 | 0,25 | — | $3,50 |
| Frontend Flutter Web (nginx) | 0,05 | 0,20 | — | $3,00 |
| Admin dashboard | 0,05 | 0,20 | — | $3,00 |
| Egress (40 GB) | — | — | — | $2,00 |
| **Producción** | | | | **$44,30** |
| Staging (clon de producción) | | | | $22,15 |
| Varios (dominio, R2, Sentry) | | | | $5,00 |
| **Total infraestructura** | | | | **$71,45** |

Nota: el volumen de 12 GB ya obliga a plan **Pro**; Hobby limita los volúmenes a 5 GB. Los promedios de vCPU/RAM son supuestos de dimensionamiento, no lecturas del dashboard: reemplácelos por métricas reales y el modelo se vuelve un pronóstico.

## Por qué el costo no lo manda Railway

Con 500 personas los contenedores están encendidos casi todo el mes y el consumo es **línea base**, no tráfico. Por eso la infraestructura cuesta prácticamente lo mismo con 300 que con 500 personas activas ($71,45 en los tres escenarios) y solo crece con el egress o si se agrandan los servicios.

El gasto real es **por uso de IA**: cada escaneo cuesta ~USD 1,07 y cada escaneo adicional se paga completo. Pasar de 300 a 1.250 escaneos multiplica la factura por 3,6 aunque la infraestructura no se mueva.

## Contraste con las cifras del repo

[GIA-14-I-REAL-COST.md](../GIA-14-I-REAL-COST.md) estima **USD 0,04 por persona/mes** (≈ USD 20 para 500) y **USD 0,02 por llamada a YouCam**.

Eso no se sostiene con el precio público: 22 unidades × USD 0,048 = **USD 1,056 por escaneo**, es decir ~50 veces la cifra del documento. Aun con la infraestructura gratis, 500 personas con un solo escaneo al mes ya cuestan ~USD 530.

Posibles explicaciones (hipótesis a validar, no hechos): un contrato enterprise con precio por debajo de lista, una tarifa por tarea en vez de por unidad, o unidades gratuitas de un plan inicial. La forma de resolverlo es una sola: **mirar la factura real de Perfect Corp** y dividirla entre los escaneos del período.

## Palancas de reducción

| Palanca | Efecto en el escenario BASE | Ahorro |
|---|---|---|
| Analizar solo las 6 métricas que usa la UI (1–4 concerns, SD) | YouCam baja de 22 a 9 unidades → USD 0,43/escaneo | **−USD 468/mes (−53 %)** |
| Bajar a 5–8 concerns en SD (12 unidades) | USD 0,576/escaneo | −USD 360/mes (−41 %) |
| Mantener 16 concerns pero en SD (16 unidades) | USD 0,768/escaneo | −USD 216/mes (−25 %) |
| Reutilizar escaneos por huella de imagen (ya existe en Y-F5) | Cada escaneo evitado ahorra USD 1,06; con 20 % de reutilización | −USD 158/mes |
| Apagar staging o moverlo a un plan sin costo | Elimina el clon | −USD 22/mes |
| Limitar el chat (12 mensajes/persona) | Ya incluido en BASE; 60 mensajes solo suman USD 42 | Bajo |
| Comprar unidades por volumen (10.000+) | USD 0,046/unidad | −USD 33/mes |
| Pagar pay-as-you-go en vez de suscripción | USD 0,055/unidad | **+USD 115/mes** |

La palanca grande es **cuántas acciones HD se piden**, no la nube. Si el producto necesita la serie temporal de 16 métricas para los deltas, el costo es el actual; si solo se muestran 6, se está pagando 2,4 veces de más.

## Sensibilidad

| Escaneos/mes | Costo variable IA | Chat + forma facial | Infra | **Total** |
|---:|---:|---:|---:|---:|
| 250 | $264,41 | $10,53 | $71,45 | **$346,40** |
| 500 | $528,83 | $10,53 | $71,45 | **$610,81** |
| 750 | $793,24 | $10,53 | $71,45 | **$875,22** |
| 1.000 | $1.057,65 | $10,53 | $71,45 | **$1.139,64** |
| 1.500 | $1.586,48 | $10,53 | $71,45 | **$1.668,46** |
| 2.000 | $2.115,31 | $10,53 | $71,45 | **$2.197,29** |

El costo por escaneo es esencialmente plano (~USD 1,07 ≈ $3.385 COP), así que la factura escala lineal con el uso. Con un precio de suscripción de USD 9,90 (~$31.268 COP), el margen bruto en BASE sería ~82 %.

## Supuestos y límites

- **"500 personas"** se interpreta como 500 usuarias registradas; en BASE todas están activas. Si solo el 60 % lo está, el total baja a USD 391.
- Los promedios de vCPU/RAM son estimaciones; el rango real puede mover la infraestructura ±30 %.
- No incluye impuestos, comisión de pasarela de pago, Firebase/GA, correo transaccional, builds de CI, egreso de video ni soporte.
- Las unidades de YouCam se compran en bloques y caducan a los 60 días; el redondeo por bloques agrega ~1–2 % sobre el cálculo teórico.
- El chat se modeló con 4.000 tokens de entrada; historiales largos o RAG con más documentos suben ese número.
- Precios consultados el 25-oct-2026; Gemini 3.1 Flash-Lite tiene precio promocional hasta el 31-dic-2026.
- La TRM usada es la vigente del 24–26 de octubre de 2026 ($3.158,43). Para otro período hay que usar la TRM de ese mes; el libro la recalcula cambiando una sola celda.

## Actualizar el modelo

El libro [costo-500-usuarios-railway.xlsx](costo-500-usuarios-railway.xlsx) tiene las entradas en amarillo: personas, % activas, escaneos, unidades por escaneo, precios, tokens y **TRM (Supuestos, fila 33)**. Todo lo demás son fórmulas y se recalcula al editar; la hoja **Resumen COP** traduce el resultado a pesos. El generador es [simular_costo_500_usuarios.py](../scripts/simular_costo_500_usuarios.py).

Pasos para convertirlo en pronóstico: (1) exportar del dashboard de Railway el uso real de CPU/RAM por servicio; (2) sacar de la factura de Perfect Corp las unidades y el precio efectivo; (3) contar escaneos y mensajes reales de un mes; (4) reemplazar esos tres bloques en el libro.
