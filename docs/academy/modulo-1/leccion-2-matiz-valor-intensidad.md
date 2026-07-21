# Módulo 1 — Fundamentos de la Teoría del Color
## Lección 2: Las tres propiedades del color aplicadas — Matiz, Valor e Intensidad (Saturación/Croma)

---

### 1. Introducción: Todo color se define por tres coordenadas

Al igual que una posición GPS necesita **latitud, longitud y altitud**, todo color perceptible se define inequívocamente por **tres atributos fundamentales**:

| Atributo | Nombre técnico | Qué responde | Eje en modelos perceptuales |
|----------|----------------|--------------|----------------------------|
| **Matiz (Hue)** | *Hue / Matiz / Tono* | "¿Qué color es?" (rojo, azul, verde...) | Ángulo en círculo (0–360°) |
| **Valor (Luminosidad/Claridad)** | *Value / Lightness / L\* / Brillo* | "¿Qué tan claro u oscuro es?" | Eje vertical (negro ↔ blanco) |
| **Intensidad (Saturación/Croma)** | *Saturation / Chroma / C\* / Pureza* | "Qué tan puro/vivo vs. apagado/grisáceo es?" | Radio desde eje acromático |

> **En el salón**: Un tinte no es "rubio" (solo matiz). Es **"rubio ceniza nivel 8, saturación media"** = matiz ceniza + valor 8 (claro) + intensidad media. Las tres coordenadas son indispensables para formular, comunicar y replicar.

---

### 2. MATIZ (Hue) — La identidad cromática

#### 2.1 Definición física y perceptual
El **matiz** es la cualidad que nos permite clasificar un color como "rojo", "azul", "amarillo", "naranja", etc. Corresponde a la **longitud de onda dominante** en el estímulo luminoso (o la mezcla de longitudes de onda que el cerebro interpreta como un tono unitario).

- En modelo **HSV/HSL**: ángulo **H (0–360°)**.
- En **CIE L\*a\*b\***: combinado en **a\* (rojo–verde) y b\* (amarillo–azul)** → *hab = arctan(b\*/a\*)*.
- En **círculo de Itten (12 tonos)**: 30° por sector.

#### 2.2 Matiz en colorimetría capilar: el sistema de numeración internacional (ICC)

| Nivel (profundidad) | 1 Negro | 2 Negro muy oscuro | 3 Castaño oscuro | 4 Castaño medio | 5 Castaño claro | 6 Rubio oscuro | 7 Rubio medio | 8 Rubio claro | 9 Rubio muy claro | 10 Rubio platino |
|---------------------|---------|-------------------|------------------|-----------------|-----------------|----------------|---------------|---------------|-------------------|------------------|
| **Valor (L\*) aprox.** | ~15 | ~20 | ~25 | ~35 | ~45 | ~55 | ~65 | ~75 | ~85 | ~95 |

> **El matiz se expresa como REFLEJO (segundo y tercer dígito)**:  
> **Ej.: 7.31** = Nivel 7 (rubio medio) + **Reflejo principal .3 (dorado)** + **Reflejo secundario .1 (ceniza)**.

#### 2.3 Tabla de reflejos estándar (matiz) — equivalencia Itten / ICC / Marcas

| Código ICC | Nombre clásico | Matiz Itten (aprox.) | Tono visual | Uso típico |
|------------|----------------|----------------------|-------------|------------|
| **.0** | Natural / Neutro | Ninguno (base pura) | Sin reflejo visible | Cobertura canas, base |
| **.1** | Ceniza / Ahumado | **Azul-Verde (270–300°)** | Frío, grisáceo | Neutralizar naranja/rojo |
| **.2** | Irisado / Perla / Mate | **Azul-Violeta / Violeta (240–270°)** | Frío, "perla" | Neutralizar amarillo/naranja |
| **.3** | Dorado / Gold | **Amarillo-Naranja / Amarillo (30–60°)** | Cálido, sol | Aportar calidez, "efecto sol" |
| **.4** | Cobrizo / Copper | **Rojo-Naranja / Naranja (60–90°)** | Cálido, cobrizo | Rojos cobrizos, calor intenso |
| **.5** | Caoba / Mahogany | **Rojo-Violeta / Rojo (330–30°)** | Cálido-rojizo, violáceo | Rojos profundos, moda |
| **.6** | Rojo / Red | **Rojo puro (0/360°)** | Rojo intenso | Rojo moda, fantasía |
| **.7** | Violeta / Irisado intenso | **Violeta / Azul-Violeta (270°)** | Frío, violeta | Neutralizar amarillo fuerte |
| **.8** | Azul / Blue | **Azul (240°)** | Muy frío | Corrección extrema, fantasía |
| **.9** | Verde / Mate / Ceniza verde | **Verde / Azul-Verde (150–180°)** | Frío, verdoso | Neutralizar rojo intenso |

> **Regla**: El **primer dígito del reflejo (.1–.9) es el dominante**; el segundo (si existe) matiza al primero.  
> **Ej.: .31** = Dorado principal + toque ceniza → "dorado frío" / "dorado perlado".

#### 2.4 Matiz y diagnóstico: preguntas clave
- ¿El cabello virgen tiene **fondo de aclaración cálido** (naranja/amarillo) o **frío**?
- ¿El cliente quiere **calidez** (dorado, cobrizo) o **frío** (ceniza, perla, violeta)?
- ¿Hay **reflejos no deseados**? → Identificar matiz → buscar complementario (Lección 4).

---

### 3. VALOR (Lightness / Value / Luminosidad / Nivel) — La profundidad

#### 3.1 Definición
El **valor** es la **cantidad de luz que un color refleja** (o emite). Es el eje **blanco ↔ negro**. En colorimetría capilar se llama **NIVEL (1–10)**.

| Concepto | Definición | Escala |
|----------|------------|--------|
| **Value (Munsell)** | 0 = negro absoluto, 10 = blanco absoluto | 0–10 |
| **L\* (CIE Lab)** | 0 = negro, 100 = blanco perfecto | 0–100 |
| **Nivel ICC (capilar)** | 1 = negro, 10 = rubio platino | 1–10 |

> **Conversión aproximada**: `L* ≈ Nivel × 10` (linealización grosera; real es curva).

#### 3.2 Valor en la práctica: fondo de aclaración y nivel objetivo

| Nivel natural | Fondo de aclaración típico (sin decolorar) | Fondo tras decoloración (1 pasada) | Fondo tras decoloración (2 pasadas) |
|---------------|-------------------------------------------|-----------------------------------|------------------------------------|
| 1–2 (Negro) | Rojo muy oscuro | Naranja-rojo | Amarillo-naranja |
| 3–4 (Castaño oscuro/medio) | Rojo-naranja | Naranja | Amarillo-naranja |
| 5–6 (Castaño claro/Rubio oscuro) | Naranja | Amarillo-naranja | Amarillo pálido |
| 7–8 (Rubio medio/claro) | Amarillo-naranja | Amarillo pálido | Amarillo muy pálido |
| 9–10 (Rubio muy claro/Platino) | Amarillo pálido | Amarillo muy pálido | Blanco/Plata |

> **Clave**: **El valor determina qué matizadores funcionan**. Un matizador .1 (ceniza) en nivel 6 (naranja) no neutraliza igual que en nivel 9 (amarillo). El **fondo de aclaración** = valor residual + matiz residual.

#### 3.3 Valor y cobertura de canas
- **Canas = valor 10 (blanco), saturación 0**.
- Cobertura total requiere **pigmento suficiente (valor bajo) + tiempo + oxidante adecuado**.
- Regla práctica: **Nivel objetivo ≤ Nivel natural + 2–3 niveles** sin decolorar. Más = decoloración previa.

#### 3.4 Ejercicio: Escala de grises y valor del cabello
1. Imprime escala de grises 10 pasos (Munsell / Niveles ICC).
2. Coloca mechones de cabello (virgen, teñido, decolorado) junto a la escala.
3. Asigna **número de nivel** a cada mechón.
4. Verifica con **espectrofotómetro** (si disponible) → L\* real.

---

### 4. INTENSIDAD / SATURACIÓN / CROMA — La pureza del color

#### 4.1 Tres términos, matices distintos

| Término | Definición precisa | Contexto |
|---------|-------------------|----------|
| **Saturación (Saturation / S en HSV/HSL)** | Pureza del color respecto a su brillo propio. 0% = gris (mismo valor), 100% = color puro. | Pantallas, modelos digitales |
| **Croma (Chroma / C\* en CIE L\*C\*h)** | Distancia desde el eje acromático (gris neutro de mismo L\*). "Qué tan alejado del gris". | Ciencia del color, control calidad |
| **Intensidad / Pureza** | Término coloquial en salón: "qué tan vivo/cargado se ve el reflejo". | Comunicación profesional |

> **En el salón**: **"Saturación alta" = reflejo fuerte, visible, "cargado". "Saturación baja" = reflejo sutil, "perla", "ahumado", "neutro".**

#### 4.2 Saturación en tintes: concentración de pigmento y base

| Factor | Efecto en saturación final |
|--------|---------------------------|
| **Concentración de pigmento en tubo** | Mayor % pigmento → mayor saturación potencial |
| **Volumen de oxidante (10/20/30/40 vol)** | Mayor vol. → mayor aclaración + mayor desarrollo de pigmento → **más saturación** (hasta límite) |
| **Tiempo de exposición** | Más tiempo → más desarrollo → más saturación (hasta meseta) |
| **Porosidad del cabello** | Alta porosidad → absorbe más pigmento → **saturación aparente mayor** (y riesgo de "chupar" matiz) |
| **Base de aclaración (fondo)** | Fondo cálido (naranja/amarillo) **"contamina"** matiz frío → **baja saturación aparente del matiz deseado** |
| **Blanco/canas** | Canas = lienzo blanco → **máxima saturación aparente** del matiz aplicado |

#### 4.3 Saturación y neutralización (puente a Lección 4)

> **Ley fundamental**: **Añadir el complementario reduce saturación (croma) → gris/neutro**.
> - Matizador .1 (cenaza/azul-verde) + fondo naranja → **neutralización** → saturación del naranja ↓, matiz → gris/neutro.
> - **Exceso de matizador** → **saturación del complementario** → viraje (ej. demasiado .1 → verde/azulado).

#### 4.4 Tabla práctica: Saturación objetivo por servicio

| Servicio | Saturación objetivo (C\* aprox.) | Reflejo típico | Notas |
|----------|----------------------------------|----------------|-------|
| Cobertura canas natural | Baja–Media (C\* 10–25) | .0, .01, .03 | Neutro, "invisible" |
| Rubio "natural" / "beige" | Media (C\* 20–35) | .03, .13, .31 | Dorado sutil + ceniza |
| Rubio "plata" / "platinum" | Muy baja (C\* 5–15) | .1, .11, .21 | Ceniza/violeta casi neutro |
| Cobrizo intenso / Rojo moda | Alta (C\* 40–60+) | .44, .46, .66 | Máxima pureza de reflejo |
| Matización (corrector) | Controlada (C\* 10–30) | .1, .2, .7 | Solo neutralizar, no "teñir" |
| Fantasía / Pastel | Media–Alta (C\* 30–50) | .8, .9, mezclas custom | Base nivel 9–10 obligatoria |

#### 4.5 Ejercicio: Dilución progresiva de matizador (curva de saturación)
1. Toma 10g de matizador .1 (ceniza) + 20g oxidante 10 vol.
2. Prepara 5 mezclas diluyendo con base .0 (neutra): 100%, 75%, 50%, 25%, 10% matizador.
3. Aplica en mechones nivel 9 (amarillo pálido) mismo tiempo.
4. Observa: **saturación del violeta/azul** vs. **neutralización del amarillo**.
5. Registra punto de **neutralización óptima** (amarillo gone, sin viraje azul/verde).

---

### 5. Los tres atributos integrados: Espacios de color perceptuales

#### 5.1 HSV / HSB (Hue, Saturation, Value/Brightness)
- **H (0–360°)** = Matiz
- **S (0–100%)** = Saturación
- **V/B (0–100%)** = Valor/Brillo
- **Uso**: Selectores de color en software, diseño digital.

#### 5.2 HSL (Hue, Saturation, Lightness)
- **L (0–100%)** = Luminosidad (0=negro, 50=color puro, 100=blanco)
- Diferencia clave: en HSL, **saturación 100% en L=50** = color puro; en HSV, **S=100% en V=100** = color puro.
- **Uso**: CSS, diseño web.

#### 5.3 CIE L\*C\*h° (Lightness, Chroma, Hue angle) — **Estándar científico**
- **L\*** (0–100) = Luminosidad perceptual (no lineal, ponderada por visión humana)
- **C\*** (0–∞) = Croma (distancia al eje neutro)
- **h°** (0–360°) = Matiz angular
- **Ventaja**: **Perceptualmente uniforme** → ΔE (diferencia de color) tiene sentido visual.
- **Uso**: Espectrofotometría, control calidad, formulación precisa, I+D marcas.

> **En salón de alta gama**: Algunos sistemas (ColorID, Wella Koleston Perfect Me+, L'Oréal Dialight) usan **L\*C\*h internamente** para calcular formulación.

#### 5.4 Tabla de equivalencia aproximada (Capilar ↔ CIE L\*C\*h)

| Nivel ICC | L\* aprox. | Matiz (.1 ceniza) | h° aprox. | C\* target (saturación media) |
|-----------|------------|-------------------|-----------|-------------------------------|
| 5 | 45 | .1 | 200° (azul-verde) | 15–25 |
| 7 | 65 | .1 | 200° | 20–30 |
| 9 | 85 | .1 | 200° | 10–20 |
| 7 | 65 | .3 (dorado) | 80° (amarillo-naranja) | 25–35 |
| 9 | 85 | .3 | 80° | 20–30 |
| 6 | 55 | .4 (cobre) | 40° (naranja) | 30–45 |

---

### 6. Comunicación profesional: El lenguaje de las tres coordenadas

> **Mal**: "Quiero un rubio ceniza."  
> **Bien**: "Nivel 8 (valor), matiz .1 ceniza (h°≈200°), saturación media-baja (C\*≈15) — efecto 'plata suave', sin viraje verde."

> **Mal**: "Matiza el naranja."  
> **Bien**: "Fondo nivel 6 (naranja fuerte, h°≈40°, C\*≈40). Aplicar .1 (h°≈200°) diluido 1:3 en base .0, oxidante 5 vol, 10 min. Objetivo: neutralizar naranja a neutro (C\*<10), sin sobre-matrizar."

#### 6.1 Ficha técnica de formulación (plantilla)

```
SERVICIO: ________________________
CLIENTE: ________________________
FECHA: ________________________

DIAGNÓSTICO:
- Nivel natural: ___  |  Fondo de aclaración actual: ___ (matiz: ____)
- % Canas: ___  |  Porosidad: Baja / Media / Alta
- Objetivo visual: ________________________________________

FORMULACIÓN OBJETIVO (3 coordenadas):
- NIVEL (Valor/L*): ____
- MATIZ (Hue/h° + código ICC): ____  →  Reflejo principal: .__  Secundario: .__
- SATURACIÓN/CROMA (Intensidad): Baja / Media / Alta  →  C* target: ____

MEZCLA:
- Tubo(s): ____g de ____ (reflejo ____) + ____g de ____ (reflejo ____)
- Oxidante: ____ vol (___%)  →  Proporción 1:___
- Aditivos: ____ (booster, bond builder, etc.)

TIEMPO: ____ min  |  TÉCNICA: ____ (raíces, global, mechas, airtouch, etc.)
CONTROL: Check visual cada ____ min  |  Objetivo de neutralización: ____
```

---

### 7. Ejercicios integrados de la Lección 2

#### Ejercicio A: Triada de coordenadas — Identifica en 10 fotos
Dado un set de 10 fotos de cabello (natural, teñido, decolorado, matizado, con canas, fantasía), completa para cada una:
| Foto | Nivel (1–10) | Matiz dominante (código .X) | Saturación (Baja/Media/Alta) | h° estimado | C\* estimado |
|------|--------------|----------------------------|------------------------------|-------------|--------------|

#### Ejercicio B: Formulación inversa
Te dan: "Rubio nivel 9, reflejo perla/irisado suave, casi neutro, sin amarillo".
- Escribe formulación completa (tubos, oxidante, proporción, tiempo).
- Justifica cada decisión con las 3 coordenadas.

#### Ejercicio C: Curva de saturación vs. fondo
En mechones nivel 6 (naranja), 7 (amarillo-naranja), 8 (amarillo), 9 (amarillo pálido):
- Aplica mismo matizador .2 (irisado/violeta) misma dilución.
- Registra: ¿En qué nivel neutraliza óptimo? ¿En qué nivel vira violeta?
- Explica con **matiz (h°), valor (L\*), saturación (C\*)**.

---

### 8. Referencias y fuentes consultadas (Lección 2)

1. **Wikipedia — Teoría del color** — Atributos del color: Matiz, Luminosidad/Valor, Saturación/Croma; modelos HSV, HSL, CIE Lab/LCh. https://es.wikipedia.org/wiki/Teor%C3%ADa_del_color
2. **Wikipedia — Color del pelo** — Escala Fischer-Saller, niveles de profundidad, genética del color. https://es.wikipedia.org/wiki/Color_del_pelo
3. **Arte con Benicio — 7 contrastes de Itten** — Contraste de luminosidad (valor), contraste de cualidad (saturación), contraste de cantidad. https://arteconbenicio.com/color/los-7-contrastes-de-colores-de-johannes-itten/
4. **Diseñando Valor — Itten** — Rueda de 12 tonos, contrastes aplicados a imagen personal. https://desegnidivaler.wixsite.com/imagenpersonal/post/colorimetr%C3%ADa-teor%C3%ADa-del-color-de-johannes-itten
5. **Wella Professionals — Ciencia de la estructura del cabello** — Porosidad, absorción de pigmento, estructura cortical. https://www.wella.com/latam/la-ciencia-detras-de-la-estructura-fisica-del-cabello
6. **L'Oréal Professionnel — Colorimetría profesional** — Sistema ICC, reflejos, neutralización, diagnóstico. https://www.lorealprofessionnel.es/consejos-profesionales-colorimetria-del-pelo
7. **Munsell Color System** — Value (0–10), Chroma, Hue — base perceptual para escalas de nivel. https://munsell.com/
8. **CIE 1976 L\*a\*b\* / L\*C\*h°** — Estándar internacional de medición de color (ISO 11664-4).
9. **Pantone / NCS / RAL** — Sistemas de especificación de color industrial (referencia cruzada).

---

### 9. Resumen clave para examen / autoevaluación

| Atributo | Qué es | En salón | Herramienta clave |
|----------|--------|----------|-------------------|
| **Matiz (Hue)** | Identidad del color (rojo, azul, dorado...) | Reflejo .1–.9 (ICC) | Círculo de Itten 12 tonos, códigos ICC |
| **Valor (Lightness/Level)** | Claridad/oscuridad (blanco ↔ negro) | Nivel 1–10, Fondo de aclaración | Escala ICC, espectrofotómetro (L\*) |
| **Intensidad (Saturación/Croma)** | Pureza/viveza vs. grisáceo | "Cargado", "sutil", "perla", "neutro" | Dilución matizador, oxidante vol., tiempo, porosidad |

**Fórmula mental**: `COLOR FINAL = NIVEL (valor) + REFLEJO (matiz) + FUERZA (saturación)`

> **Próxima lección**: **Lección 3 — La química del color: Proporciones de Eumelanina y Feomelanina.** Bajamos al nivel molecular: cómo la biología crea el color natural y cómo la química lo modifica.

---

> **Nota didáctica**: Esta lección puenteará la teoría (Lección 1–2) con la práctica bioquímica (Lección 3) y la neutralización aplicada (Lección 4). Domina las 3 coordenadas: son tu **GPS de formulación**.