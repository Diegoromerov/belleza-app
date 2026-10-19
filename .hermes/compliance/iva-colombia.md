# IVA en Colombia — qué exige la norma y cómo quedó configurado

Fecha: 2026-10-10. Alcance: el IVA de las reservas de servicios de belleza
cobradas a través de la plataforma, y el IVA que cobra la pasarela.

**Esto no es una asesoría tributaria.** Lo que sigue es la lectura de la norma
vigente y de la documentación de Wompi, con la fuente citada en cada afirmación.
Las dos decisiones que le corresponden al contador están marcadas como
**DECISIÓN PENDIENTE** al final.

---

## 1. Qué exige la norma

### 1.1 Los tratamientos de belleza SÍ están gravados al 19%

El artículo 476, numeral 1, del Estatuto Tributario excluye del IVA los
«servicios médicos, odontológicos, hospitalarios, clínicos y de laboratorio, para
la salud humana». Un servicio de peluquería o de estética **no es** un servicio de
salud humana, y además la norma cierra la puerta explícitamente: el mismo numeral
exceptúa de esa exclusión, en su literal a), «**los tratamientos de belleza**».

Es decir: están gravados a la tarifa general del **19%** (art. 468 E.T.). No son
un servicio excluido, y no hay margen para tratarlos como tal. La DIAN lo ha
precisado en el mismo sentido: los tratamientos de belleza y las cirugías
estéticas están sujetos al impuesto sobre las ventas.

### 1.2 No todo prestador es responsable de IVA

El parágrafo 3 del artículo 437 del E.T. (modificado por la Ley 2010 de 2019)
exceptúa de la responsabilidad del IVA a quien no supere **3.500 UVT** de
ingresos brutos, entre otras condiciones. Un prestador en esa situación **no
causa IVA**: no hay impuesto que cobrar ni que facturar.

Consecuencia para el modelo de datos: la condición es **del prestador**, no de la
plataforma ni del cliente, y hay que poder representarla por prestador.

### 1.3 El IVA se DISCRIMINA, no se suma

El precio que el prestador publica en la plataforma es el precio **final al
consumidor**, y el Estatuto del Consumidor exige que el precio exhibido incluya
los impuestos. Por lo tanto, cuando el prestador es responsable:

- **no** se le suma un 19% al precio (eso cambiaría lo que paga el cliente),
- el IVA **se separa del total**: `base gravable + IVA = total`.

Esa separación es justamente lo que la factura necesita para desglosar el
impuesto. El cliente paga exactamente el precio que vio.

---

## 2. Qué dice Wompi

Wompi cobra IVA del 19% **únicamente sobre el valor de su comisión** —no sobre el
monto de la transacción—. Esto es lo que dice su propia documentación:

> «el IVA del 19% se calcula únicamente sobre el valor de la comisión»
> — Wompi, guía de cuenta empresarial

En la misma línea, su centro de soporte: «Wompi cobra el IVA correspondiente al
19%, el cual es liquidado sobre el valor de la comisión generada».

**Tarifas publicadas** (plan vigente): 2,65% + $700 + IVA; se suma 1,44% cuando
el cliente paga con tarjeta débito, crédito o PSE. PCOL: 4,43% + $700 + IVA.

Esto **confirma** que en el backend el IVA sobre la tarifa transaccional se aplica
sobre la comisión y no sobre el monto: el cálculo del código coincide con lo que
Wompi liquida.

### 2.1 Discrepancia de tarifas — REVISAR, requiere tu confirmación

El código calcula la tarifa transaccional de la reserva como **$900 + 2,89% +
IVA**. Las tarifas publicadas por Wompi hoy son **$700 + 2,65% + IVA** (más 1,44%
si es tarjeta o PSE).

No lo cambié: es **precio**, y no me corresponde alterar lo que se le cobra al
cliente por una diferencia que puede venir de un plan o de una tarifa negociada.
Si el plan del comercio es el publicado, el código está pasando al cliente un
costo mayor que el real.

---

## 3. Qué hacía la plataforma antes

El cliente (`wompi_payment_sheet.dart`) **sumaba** un 19% «Impuestos (IVA 19%)» al
total, y el backend **nunca** lo cobraba ni lo registraba. Resultado: el usuario
veía un precio y se le cobraba otro (hallazgo W4). Se quitó de la interfaz para
que el precio mostrado fuera verdad, y esta configuración lo pone donde
corresponde: en el servidor, que es el único que calcula montos.

---

## 4. Qué quedó configurado

| Pieza | Qué hace |
|---|---|
| `migrations/086_add_iva_configuration.sql` | `usuarios.responsable_iva` (default `false`) + `usuarios.tarifa_iva` (default 0.19) + `bookings.subtotal_base`, `iva_valor`, `tarifa_iva_aplicada` congelados al crear la reserva. Con CHECK de rango 0–1 y rollback. |
| `src/utils/iva.js` | `discriminarIva(total, tarifa)` → `{ subtotalBase, ivaValor, tarifaAplicada }`. Garantiza `base + IVA = total`. |
| `src/controllers/bookingController.js` | Lee la condición **de la cuenta del prestador** (nunca del request), discrimina y persiste el desglose. |
| `src/tests/iva.test.js` | 9 pruebas: el invariante `base + IVA = total`, que el precio al consumidor no sube, que un no responsable no causa IVA, y los casos límite de redondeo. |

**El default `responsable_iva = false` es deliberado**: ningún precio existente
cambia hasta que un prestador declare su condición. La migración es reversible y
no mueve dinero.

Verificación: 086 aplicada contra un Postgres real (columnas, constraint,
idempotencia, rollback → todo en verde).

---

## 5. Decisiones tomadas (2026-10-10)

1. **Los precios son FINALES** → se discriminan. El consumidor ve el valor final
   desglosado en valor + IVA (`wompi_payment_sheet.dart` muestra «Valor / IVA
   (n%) / total», con el porcentaje derivado de los montos, no escrito fijo). El
   total que se cobra no cambia: se hace visible el impuesto que ya estaba
   incluido.
2. **Todos los prestadores se tratan como responsables de IVA** → `responsable_iva`
   tiene default `true`, así que el IVA aplica a todos por defecto (decisión de
   negocio). OJO con la distinción: que el servicio sea gravado (art. 476) **no**
   convierte por sí solo al prestador en responsable (art. 437 par. 3, que es por
   ingresos). Un prestador que declare ser no responsable (RUT, responsabilidad
   48/49) se corrige marcándolo en `false`, y entonces base = total e IVA = 0. La
   plataforma debería capturar esa responsabilidad del RUT al afiliar al prestador.
3. **Tarifa de Wompi confirmada**: 2,65% + $700 + IVA (+1,44% si es tarjeta o
   PSE). Se corrigieron las constantes del código (eran $900 + 2,89%). El recargo
   por medio de pago no se incluye en la cifra guardada porque el medio se elige
   en el checkout. `tarifa_reserva` hoy **no se lee en ningún flujo**, así que la
   corrección no mueve dinero.

Pendiente para el contador: **emitir la factura** con el formato que exija la
DIAN. El desglose ya se persiste congelado en cada reserva, que es el insumo.

---

## Fuentes

1. Estatuto Tributario, art. 476 num. 1 lit. a) — tratamientos de belleza
   exceptuados de la exclusión: https://actualicese.com/estatutotributario/476-2/
2. Ley 2010 de 2019, art. 437 par. 3 — no responsables de IVA (< 3.500 UVT):
   http://secretariasenado.gov.co/senado/basedoc/ley_2010_2019.html
3. DIAN — tratamientos de belleza y cirugías estéticas sujetos al IVA:
   https://www.ambitojuridico.com/noticias/tributario/tributario-y-contable/tratamientos-de-belleza-y-cirugias-esteticas-estan
4. Wompi — qué impuesto cobra la pasarela (IVA sólo sobre la comisión):
   https://soporte.wompi.co/hc/es-419/articles/1500009288841
5. Wompi — planes y tarifas (2,65% + $700 + IVA):
   https://wompi.com/es/co/planes-tarifas
6. Wompi — cuenta empresarial (IVA sólo sobre la comisión; +1,44% tarjetas/PSE):
   https://wompi.co/assets/downloadble/crear_cuenta_empresarial.pdf
