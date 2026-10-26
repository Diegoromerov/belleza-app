#!/usr/bin/env python3
"""Simulador de costo mensual para 500 personas en GlowApp sobre Railway.

Genera `informes/costo-500-usuarios-railway.xlsx` con:
  - Supuestos editables (3 escenarios: BAJO / BASE / ALTO)
  - Costos de IA por proveedor (YouCam, Gemini, DeepSeek)
  - Costos de infraestructura Railway por servicio
  - Resumen, sensibilidad y fuentes

Las celdas amarillas son entradas; el resto son fórmulas.
Ejecutar:  python scripts/simular_costo_500_usuarios.py
"""

from __future__ import annotations

import os
from openpyxl import Workbook
from openpyxl.chart import BarChart, LineChart, Reference
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.properties import PageSetupProperties
from openpyxl.worksheet.pagebreak import Break

OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "informes")
OUT_PATH = os.path.join(OUT_DIR, "costo-500-usuarios-railway.xlsx")

# ---------------------------------------------------------------------------
# Paleta y estilos
# ---------------------------------------------------------------------------
PLUM = "3B2A33"
ROSE = "C97B63"
SAND = "F7F3F0"
INPUT = "FFF2CC"
WHITE = "FFFFFF"
GREY = "6B5B63"

TITLE_FONT = Font(name="Calibri", size=16, bold=True, color=WHITE)
SUB_FONT = Font(name="Calibri", size=10, italic=True, color=GREY)
HEAD_FONT = Font(name="Calibri", size=11, bold=True, color=WHITE)
BODY_FONT = Font(name="Calibri", size=10)
BOLD_FONT = Font(name="Calibri", size=10, bold=True)
NOTE_FONT = Font(name="Calibri", size=9, color=GREY)

thin = Side(style="thin", color="D9CFC7")
BORDER = Border(left=thin, right=thin, top=thin, bottom=thin)

CUR = '"$"#,##0.00'
CUR0 = '"$"#,##0'
INT = '#,##0'
PCT = '0.0%'


def title(ws, text: str, span: str) -> None:
    ws.merge_cells(span)
    c = ws[span.split(":")[0]]
    c.value = text
    c.font = TITLE_FONT
    c.fill = PatternFill("solid", fgColor=PLUM)
    c.alignment = Alignment(vertical="center", horizontal="left", indent=1)
    ws.row_dimensions[c.row].height = 30


def subtitle(ws, text: str, span: str) -> None:
    ws.merge_cells(span)
    c = ws[span.split(":")[0]]
    c.value = text
    c.font = SUB_FONT
    c.alignment = Alignment(vertical="center", horizontal="left", indent=1, wrap_text=True)
    ws.row_dimensions[c.row].height = 28


def headers(ws, row: int, labels: list[str]) -> None:
    for i, label in enumerate(labels, start=1):
        c = ws.cell(row=row, column=i, value=label)
        c.font = HEAD_FONT
        c.fill = PatternFill("solid", fgColor=ROSE)
        c.alignment = Alignment(vertical="center", horizontal="center", wrap_text=True)
        c.border = BORDER
    ws.row_dimensions[row].height = 30


def widths(ws, spec: dict[str, int]) -> None:
    for col, w in spec.items():
        ws.column_dimensions[col].width = w


wb = Workbook()

# ===========================================================================
# SUPUESTOS
# ===========================================================================
ws = wb.active
ws.title = "Supuestos"
title(ws, "Supuestos de la simulación · 500 personas · GlowApp en Railway", "A1:F1")
subtitle(
    ws,
    "Celdas amarillas = entradas editables. Las columnas BAJO / BASE / ALTO son tres perfiles de uso. "
    "Todo lo demás del libro se recalcula a partir de aquí.",
    "A2:F2",
)
headers(ws, 3, ["Parámetro", "Unidad", "BAJO", "BASE", "ALTO", "Fuente / evidencia"])

# (row, etiqueta, unidad, [bajo, base, alto], formato, nota)
PARAMS = [
    (4, "Personas objetivo", "usuarios", [500, 500, 500], INT,
     "Caso solicitado: 500 personas."),
    (5, "% de esas personas activas en el mes", "%", [0.60, 1.00, 1.00], PCT,
     "Supuesto de producto; no hay telemetría en el repo."),
    (6, "Escaneos faciales por persona activa / mes", "escaneos", [1.0, 1.5, 2.5], '0.0',
     "Protocolo Día 1 + re-escaneo Día 15/30 (GIA-13-N)."),
    (7, "Acciones HD solicitadas por escaneo", "acciones", [16, 16, 16], INT,
     "backend/src/services/biometric/youcam.client.js: SKIN_ANALYSIS_ACTIONS (16)."),
    (8, "Unidades YouCam consumidas por escaneo", "unidades", [22, 22, 22], INT,
     "Tabla oficial: 13–16 concerns HD = 22 unidades."),
    (9, "Precio por unidad YouCam (suscripción)", "USD/unidad", [0.048, 0.048, 0.048], '0.000',
     "Plan suscripción 500+ unidades. PAYG = 0.055."),
    (10, "Mensajes al chat de IA por persona activa / mes", "mensajes", [4, 12, 30], INT,
     "Supuesto de engagement; el chat usa DeepSeek con RAG topK=5."),
    (11, "Tokens de entrada por mensaje de chat", "tokens", [4000, 4000, 4000], INT,
     "RAG topK=5 + catálogo de servicios cacheado + historial."),
    (12, "Tokens de salida por mensaje de chat", "tokens", [450, 450, 450], INT,
     "Respuesta conversacional típica."),
    (13, "Tokens de entrada · Gemini manos (imagen)", "tokens", [1100, 1100, 1100], INT,
     "Imagen normalizada + prompt corto (gemini.client.js, maxOutputTokens 256)."),
    (14, "Tokens de salida · Gemini manos", "tokens", [200, 200, 200], INT, "Salida JSON corta."),
    (15, "Tokens de entrada · DeepSeek recomendación", "tokens", [450, 450, 450], INT,
     "RECOMMENDATION_PROMPT (prompts.js)."),
    (16, "Tokens de salida · DeepSeek recomendación", "tokens", [700, 700, 700], INT,
     "max_tokens 800."),
    (17, "Tokens de entrada · DeepSeek matching VTO", "tokens", [300, 300, 300], INT,
     "Prompt de subtono (deepseek.client.js)."),
    (18, "Tokens de salida · DeepSeek matching VTO", "tokens", [250, 250, 250], INT,
     "max_tokens 400."),
    (19, "Precio Gemini 3.1 Flash-Lite · entrada", "USD/1M", [0.125, 0.125, 0.125], '0.000',
     "Google AI pricing (vigente hasta 31-dic-2026)."),
    (20, "Precio Gemini 3.1 Flash-Lite · salida", "USD/1M", [0.75, 0.75, 0.75], '0.000',
     "Google AI pricing."),
    (21, "Precio DeepSeek Flash · entrada (hora pico)", "USD/1M", [0.30, 0.30, 0.30], '0.00',
     "DeepSeek pricing; off-peak = mitad."),
    (22, "Precio DeepSeek Flash · salida (hora pico)", "USD/1M", [1.20, 1.20, 1.20], '0.00',
     "DeepSeek pricing; off-peak = mitad."),
    (23, "Análisis de forma facial por persona / mes", "llamadas", [0.5, 0.5, 0.5], '0.0',
     "designsController.js (Gemini visión sobre foto)."),
    (24, "Tokens de entrada · forma facial", "tokens", [1200, 1200, 1200], INT, "Imagen + prompt."),
    (25, "Tokens de salida · forma facial", "tokens", [300, 300, 300], INT, "JSON/texto corto."),
    (26, "Factor de costo del entorno staging", "% de prod", [0.5, 0.5, 0.5], PCT,
     "railway.yml declara environments.staging clonado de production."),
    (27, "Servicios varios (dominio, R2, Sentry)", "USD/mes", [5, 5, 5], CUR0,
     "Cloudflare R2 + Sentry free + dominio."),
    (28, "Railway · precio vCPU", "USD/vCPU/mes", [20, 20, 20], CUR0, "railway.com/pricing"),
    (29, "Railway · precio RAM", "USD/GB/mes", [10, 10, 10], CUR0, "railway.com/pricing"),
    (30, "Railway · precio volumen", "USD/GB/mes", [0.15, 0.15, 0.15], '0.00', "railway.com/pricing"),
    (31, "Railway · precio egress", "USD/GB", [0.05, 0.05, 0.05], '0.00', "railway.com/pricing"),
    (32, "Plan Railway Pro (incluye USD 20 de uso)", "USD/mes", [20, 20, 20], CUR0,
     "El plan se paga con el uso; se toma el mayor entre plan y uso."),
    (33, "TRM COP/USD", "COP por USD", [3158.43, 3158.43, 3158.43], '#,##0.00',
     "TRM vigente 24–26 oct 2026 (Superfinanciera). Editable."),
]

for row, label, unit, values, fmt, note in PARAMS:
    ws.cell(row=row, column=1, value=label).font = BODY_FONT
    ws.cell(row=row, column=2, value=unit).font = NOTE_FONT
    ws.cell(row=row, column=2).alignment = Alignment(horizontal="center")
    for i, v in enumerate(values, start=3):
        c = ws.cell(row=row, column=i, value=v)
        c.font = BOLD_FONT
        c.number_format = fmt
        c.fill = PatternFill("solid", fgColor=INPUT)
        c.alignment = Alignment(horizontal="center")
        c.border = BORDER
    n = ws.cell(row=row, column=6, value=note)
    n.font = NOTE_FONT
    n.alignment = Alignment(wrap_text=True, vertical="center", horizontal="left", indent=1)

widths(ws, {"A": 46, "B": 14, "C": 11, "D": 11, "E": 11, "F": 62})
ws.freeze_panes = "A4"

# ===========================================================================
# COSTOS IA
# ===========================================================================
ai = wb.create_sheet("Costos IA")
title(ai, "Costos de IA y APIs externas", "A1:F1")
subtitle(
    ai,
    "YouCam se cobra por unidad (22 unidades por escaneo HD de 16 acciones). Gemini y DeepSeek se cobran por token. "
    "Ver hoja Supuestos para editar.",
    "A2:F2",
)
headers(ai, 3, ["Concepto", "Detalle", "BAJO", "BASE", "ALTO", "Nota"])

IA_ROWS = [
    (4, "Escaneos faciales / mes", "personas activas × escaneos", "=Supuestos!{c}$4*Supuestos!{c}$5*Supuestos!{c}$6", INT,
     "Volumen que dispara el costo."),
    (5, "Unidades YouCam / mes", "escaneos × 22 unidades", "={c}4*Supuestos!{c}$8", INT,
     "13–16 concerns en HD."),
    (6, "YouCam · análisis facial (16 HD)", "unidades × precio unidad", "={c}5*Supuestos!{c}$9", CUR,
     "Rubro dominante."),
    (7, "Gemini · diagnóstico de manos", "escaneos × (in·p_in + out·p_out)", "={c}4*(Supuestos!{c}$13*Supuestos!{c}$19+Supuestos!{c}$14*Supuestos!{c}$20)/1000000", CUR,
     "Visión, salida corta."),
    (8, "DeepSeek · recomendación", "escaneos × tokens", "={c}4*(Supuestos!{c}$15*Supuestos!{c}$21+Supuestos!{c}$16*Supuestos!{c}$22)/1000000", CUR,
     "Rutina AM/PM."),
    (9, "DeepSeek · matching de tonos VTO", "escaneos × tokens", "={c}4*(Supuestos!{c}$17*Supuestos!{c}$21+Supuestos!{c}$18*Supuestos!{c}$22)/1000000", CUR,
     "Paleta por subtono."),
    (10, "DeepSeek · chat asistente (RAG)", "mensajes × tokens", "=Supuestos!{c}$4*Supuestos!{c}$5*Supuestos!{c}$10*(Supuestos!{c}$11*Supuestos!{c}$21+Supuestos!{c}$12*Supuestos!{c}$22)/1000000", CUR,
     "Crece con engagement."),
    (11, "Gemini · análisis de forma facial", "llamadas × tokens", "=Supuestos!{c}$4*Supuestos!{c}$5*Supuestos!{c}$23*(Supuestos!{c}$24*Supuestos!{c}$19+Supuestos!{c}$25*Supuestos!{c}$20)/1000000", CUR,
     "Módulo de diseños."),
    (12, "TOTAL IA / mes", "suma", "=SUM({c}6:{c}11)", CUR, "Solo APIs de IA."),
    (13, "Costo IA por escaneo", "total ÷ escaneos", "={c}12/{c}4", CUR, "Margen unitario."),
    (14, "Costo IA por persona activa", "total ÷ activos", "={c}12/(Supuestos!{c}$4*Supuestos!{c}$5)", CUR, ""),
    (15, "Personas activas / mes", "personas × % activos", "=Supuestos!{c}$4*Supuestos!{c}$5", INT, ""),
]

for row, label, detail, formula, fmt, note in IA_ROWS:
    ai.cell(row=row, column=1, value=label).font = BOLD_FONT if row in (12, 13) else BODY_FONT
    ai.cell(row=row, column=2, value=detail).font = NOTE_FONT
    for col in ("C", "D", "E"):
        c = ai[f"{col}{row}"]
        c.value = formula.format(c=col)
        c.number_format = fmt
        c.font = BOLD_FONT if row in (12, 13) else BODY_FONT
        c.border = BORDER
        c.fill = PatternFill("solid", fgColor=SAND)
    n = ai.cell(row=row, column=6, value=note)
    n.font = NOTE_FONT
    n.alignment = Alignment(wrap_text=True, vertical="center", horizontal="left", indent=1)

for col in ("C", "D", "E"):
    ai[f"{col}6"].font = Font(name="Calibri", size=10, bold=True, color="9B3A2E")
    ai[f"{col}12"].fill = PatternFill("solid", fgColor="EADFD8")

widths(ai, {"A": 34, "B": 34, "C": 14, "D": 14, "E": 14, "F": 40})
ai.freeze_panes = "A4"

# ===========================================================================
# INFRAESTRUCTURA RAILWAY
# ===========================================================================
inf = wb.create_sheet("Infra Railway")
title(inf, "Infraestructura Railway · consumo mensual estimado", "A1:I1")
subtitle(
    inf,
    "Railway cobra por segundo: CPU, RAM y volumen. Los valores de vCPU/RAM son promedios mensuales supuestos "
    "(no hay métricas históricas en el repo). Ajuste la columna B/D/F con las métricas reales del dashboard.",
    "A2:I2",
)
headers(inf, 3, ["Servicio", "vCPU prom.", "Costo CPU", "RAM GB prom.", "Costo RAM", "Volumen GB", "Costo volumen", "Subtotal", "Nota"])

SERVICES = [
    (4, "API Node/Express (backend)", 0.25, 0.60, 0, "Dockerfile.prod, Sequelize + sharp."),
    (5, "ai-worker FastAPI (Pillow/numpy)", 0.10, 0.30, 0, "Procesa imágenes en CPU, sin GPU."),
    (6, "PostgreSQL 16 + pgvector", 0.25, 1.00, 12, "BD + embeddings + índices HNSW."),
    (7, "Redis 7", 0.05, 0.25, 0, "Caché y colas."),
    (8, "Frontend Flutter Web (nginx)", 0.05, 0.20, 0, "Build estático servido por nginx."),
    (9, "Admin dashboard", 0.05, 0.20, 0, "Uso interno esporádico."),
]

for row, name, vcpu, ram, vol, note in SERVICES:
    inf.cell(row=row, column=1, value=name).font = BODY_FONT
    inf.cell(row=row, column=2, value=vcpu).number_format = '0.00'
    inf.cell(row=row, column=3, value=f"=B{row}*Supuestos!$C$28").number_format = CUR
    inf.cell(row=row, column=4, value=ram).number_format = '0.00'
    inf.cell(row=row, column=5, value=f"=D{row}*Supuestos!$C$29").number_format = CUR
    inf.cell(row=row, column=6, value=vol).number_format = INT
    inf.cell(row=row, column=7, value=f"=F{row}*Supuestos!$C$30").number_format = CUR
    inf.cell(row=row, column=8, value=f"=C{row}+E{row}+G{row}").number_format = CUR
    inf.cell(row=row, column=9, value=note).font = NOTE_FONT
    inf.cell(row=row, column=9).alignment = Alignment(wrap_text=True, vertical="center", horizontal="left", indent=1)
    for col in range(1, 9):
        inf.cell(row=row, column=col).border = BORDER
        inf.cell(row=row, column=col).fill = PatternFill("solid", fgColor=SAND)

inf["A10"] = "TOTAL SERVICIOS"
inf["H10"] = "=SUM(H4:H9)"
inf["A11"] = "Egress (API + estáticos, 40 GB/mes)"
inf["H11"] = "=40*Supuestos!$C$31"
inf["A12"] = "SUBTOTAL PRODUCCIÓN"
inf["H12"] = "=H10+H11"
inf["A13"] = "Staging (clon de producción)"
inf["H13"] = "=H12*Supuestos!$C$26"
inf["A14"] = "Varios (dominio, R2, Sentry)"
inf["H14"] = "=Supuestos!$C$27"
inf["A15"] = "TOTAL INFRAESTRUCTURA / mes"
inf["H15"] = "=H12+H13+H14"

for r in (10, 12, 13, 14, 15):
    inf[f"A{r}"].font = BOLD_FONT
    for col in ("A", "H"):
        inf[f"{col}{r}"].border = BORDER
        inf[f"{col}{r}"].fill = PatternFill("solid", fgColor="EADFD8")
    inf[f"H{r}"].number_format = CUR
    inf[f"H{r}"].font = BOLD_FONT

inf["H11"].number_format = CUR
inf["H11"].font = BOLD_FONT
inf["H11"].border = BORDER
inf["H11"].fill = PatternFill("solid", fgColor=SAND)

inf["A17"] = "Supuestos de tamaño por servicio"
inf["A17"].font = HEAD_FONT
inf["A17"].fill = PatternFill("solid", fgColor=PLUM)
inf.merge_cells("A17:I17")
inf["A18"] = ("Los promedios de vCPU/RAM son estimaciones de dimensionamiento para 500 usuarios activos al mes, "
              "no lecturas del dashboard de Railway. Con 500 usuarios el consumo es mayormente línea base (contenedores "
              "encendidos), por eso el costo de infraestructura es casi fijo y no escala 1:1 con las personas.")
inf.merge_cells("A18:I19")
inf["A18"].font = NOTE_FONT
inf["A18"].alignment = Alignment(wrap_text=True, vertical="top")

widths(inf, {"A": 34, "B": 11, "C": 12, "D": 12, "E": 12, "F": 12, "G": 14, "H": 13, "I": 40})
inf.freeze_panes = "A4"

# ===========================================================================
# RESUMEN
# ===========================================================================
res = wb.create_sheet("Resumen", 0)
title(res, "Costo mensual estimado · 500 personas en GlowApp sobre Railway", "A1:E1")
subtitle(
    res,
    "Escenario BASE: 500 personas activas, 1,5 escaneos/mes cada una, chat moderado. "
    "Cifras en USD, mes calendario, impuestos no incluidos.",
    "A2:E2",
)
headers(res, 3, ["Métrica", "BAJO", "BASE", "ALTO", "Nota"])

RES_ROWS = [
    (4, "Personas activas / mes", "='Costos IA'!{s}15", INT, "Personas objetivo × % activos."),
    (5, "Escaneos faciales / mes", "='Costos IA'!{s}4", INT, ""),
    (6, "Costo de IA y APIs", "='Costos IA'!{s}12", CUR, "YouCam + Gemini + DeepSeek."),
    (7, "Infraestructura Railway", "='Infra Railway'!$H$15", CUR, "Casi fija; no escala con usuarios."),
    (8, "TOTAL MENSUAL", "={d}6+{d}7", CUR, ""),
    (9, "Costo por persona activa", "={d}8/{d}4", CUR, ""),
    (10, "Costo por persona (500)", "={d}8/Supuestos!$C$4", CUR, "Referencia del caso solicitado."),
    (11, "% del costo que es IA", "={d}6/{d}8", PCT, ""),
    (12, "% del costo que es Railway", "={d}7/{d}8", PCT, ""),
    (13, "YouCam (dentro de IA)", "='Costos IA'!{s}6", CUR, "Un solo proveedor concentra el gasto."),
    (14, "Unidades YouCam / mes", "='Costos IA'!{s}5", INT, ""),
    (15, "Costo IA por escaneo", "='Costos IA'!{s}13", CUR, "Margen unitario."),
]

for row, label, formula, fmt, note in RES_ROWS:
    c1 = res.cell(row=row, column=1, value=label)
    c1.font = BOLD_FONT if row in (8, 9) else BODY_FONT
    for dest, src in zip(["B", "C", "D"], ["C", "D", "E"]):
        c = res[f"{dest}{row}"]
        c.value = formula.format(d=dest, s=src)
        c.number_format = fmt
        c.font = BOLD_FONT if row in (8, 9) else BODY_FONT
        c.border = BORDER
        c.fill = PatternFill("solid", fgColor=SAND)
        c.alignment = Alignment(horizontal="center")
    n = res.cell(row=row, column=5, value=note)
    n.font = NOTE_FONT
    n.alignment = Alignment(wrap_text=True, vertical="center", horizontal="left", indent=1)

for col in "BCD":
    res[f"{col}8"].font = Font(name="Calibri", size=12, bold=True, color="9B3A2E")
    res[f"{col}8"].fill = PatternFill("solid", fgColor="EADFD8")

# Gráfico de barras apiladas
chart = BarChart()
chart.type = "col"
chart.grouping = "stacked"
chart.overlap = 100
chart.title = "Costo mensual por componente (USD)"
chart.y_axis.title = "USD / mes"
chart.x_axis.title = "Escenario"
data = Reference(res, min_col=1, max_col=4, min_row=6, max_row=7)
cats = Reference(res, min_col=2, max_col=4, min_row=3, max_row=3)
chart.add_data(data, titles_from_data=True, from_rows=True)
chart.set_categories(cats)
chart.height = 7.5
chart.width = 17
chart.legend.position = "b"
chart.series[0].graphicalProperties.solidFill = ROSE
chart.series[1].graphicalProperties.solidFill = PLUM
res.row_breaks.append(Break(id=17))
res.add_chart(chart, "A18")

res["A36"] = "Lectura rápida"
res["A36"].font = HEAD_FONT
res["A36"].fill = PatternFill("solid", fgColor=PLUM)
res.merge_cells("A36:E36")
res["A37"] = (
    "1) El costo lo manda YouCam, no Railway: un escaneo HD de 16 acciones consume 22 unidades (~USD 1,06). "
    "2) La infraestructura es casi fija (~USD 70/mes) porque los contenedores están encendidos aunque no haya tráfico. "
    "3) El documento GIA-14-I estima USD 0,04 por persona/mes (~USD 20 para 500): eso no cubre ni la infraestructura ni un solo escaneo."
)
res.merge_cells("A37:E40")
res["A37"].font = Font(name="Calibri", size=10)
res["A37"].alignment = Alignment(wrap_text=True, vertical="top")
for r in range(37, 41):
    res.row_dimensions[r].height = 16

widths(res, {"A": 38, "B": 15, "C": 15, "D": 15, "E": 42})

# ===========================================================================
# RESUMEN EN PESOS COLOMBIANOS
# ===========================================================================
cop = wb.create_sheet("Resumen COP", 1)
title(cop, "Costo mensual en pesos colombianos (COP)", "A1:E1")
subtitle(
    cop,
    "Conversión a la TRM vigente del 24–26 de octubre de 2026: $3.158,43 COP/USD (Superfinanciera). "
    "Los proveedores facturan en USD; la TRM cambia la lectura local y el riesgo cambiario, no la factura.",
    "A2:E2",
)
headers(cop, 4, ["Métrica", "BAJO", "BASE", "ALTO", "Nota"])

COP_ROWS = [
    (5, "TRM usada (COP por USD)", "=Supuestos!$C$33", '#,##0.00',
     "Editable en Supuestos (fila 33)."),
    (6, "TOTAL MENSUAL (COP)", "='Resumen'!{d}8*{d}$5", '"$"#,##0',
     "Costo total del mes."),
    (7, "IA y APIs (COP)", "='Resumen'!{d}6*{d}$5", '"$"#,##0', "92 % del total en BASE."),
    (8, "Railway (COP)", "='Resumen'!{d}7*{d}$5", '"$"#,##0', "Casi fijo."),
    (9, "YouCam (COP)", "='Resumen'!{d}13*{d}$5", '"$"#,##0', "Dentro de IA."),
    (10, "Costo por persona activa (COP)", "='Resumen'!{d}9*{d}$5", '"$"#,##0', "Mensual."),
    (11, "Costo por persona / 500 (COP)", "='Resumen'!{d}10*{d}$5", '"$"#,##0', "Mensual."),
    (12, "Costo por escaneo (COP)", "='Resumen'!{d}15*{d}$5", '"$"#,##0', "Variable dominante."),
    (13, "Costo por escaneo (USD)", "='Resumen'!{d}15", CUR, "Referencia."),
]

for row, label, formula, fmt, note in COP_ROWS:
    c1 = cop.cell(row=row, column=1, value=label)
    c1.font = BOLD_FONT if row in (6, 10) else BODY_FONT
    for dest in ("B", "C", "D"):
        c = cop[f"{dest}{row}"]
        c.value = formula.format(d=dest)
        c.number_format = fmt
        c.font = BOLD_FONT if row in (6, 10) else BODY_FONT
        c.border = BORDER
        c.fill = PatternFill("solid", fgColor=SAND)
        c.alignment = Alignment(horizontal="right")
    n = cop.cell(row=row, column=5, value=note)
    n.font = NOTE_FONT
    n.alignment = Alignment(wrap_text=True, vertical="center", horizontal="left", indent=1)

for dest in ("B", "C", "D"):
    cop[f"{dest}6"].font = Font(name="Calibri", size=12, bold=True, color="9B3A2E")
    cop[f"{dest}6"].fill = PatternFill("solid", fgColor="EADFD8")

cop["A16"] = "Sensibilidad a la TRM (escenario BASE)"
cop["A16"].font = HEAD_FONT
cop["A16"].fill = PatternFill("solid", fgColor=PLUM)
cop.merge_cells("A16:E16")
headers(cop, 17, ["Escenario de TRM", "TRM (COP/USD)", "Total BASE (COP)", "Variación", ""])
for i, (label, factor) in enumerate([
    ("TRM 10 % más baja", 0.90),
    ("TRM vigente", 1.00),
    ("TRM 10 % más alta", 1.10),
], start=18):
    cop.cell(row=i, column=1, value=label).font = BODY_FONT
    cop.cell(row=i, column=2, value=f"=$C$5*{factor}").number_format = '#,##0.00'
    cop.cell(row=i, column=3, value=f"='Resumen'!$C$8*B{i}").number_format = '"$"#,##0'
    cop.cell(row=i, column=4, value=f"=C{i}/$C$19-1").number_format = PCT
    for col in range(1, 5):
        cop.cell(row=i, column=col).border = BORDER
        cop.cell(row=i, column=col).fill = PatternFill("solid", fgColor=SAND)

cop["A23"] = (
    "La TRM no altera el costo en USD: si el ingreso es en pesos y la factura en dólares, una devaluación del 10 % "
    "sube el costo en COP 10 % con el mismo consumo. El punto medio de la banda (USD 875) equivale a "
    "≈ $2,76 millones COP/mes."
)
cop.merge_cells("A23:E25")
cop["A23"].font = NOTE_FONT
cop["A23"].alignment = Alignment(wrap_text=True, vertical="top")

widths(cop, {"A": 38, "B": 16, "C": 16, "D": 16, "E": 40})

# ===========================================================================
# SENSIBILIDAD
# ===========================================================================
sens = wb.create_sheet("Sensibilidad")
title(sens, "Sensibilidad · qué mueve el costo", "A1:E1")
subtitle(sens, "Cada tabla aísla una palanca manteniendo el resto en el escenario BASE.", "A2:E2")

sens["A3"] = "A. Unidades YouCam por escaneo (precio 0,048/unidad, 750 escaneos/mes)"
sens["A3"].font = HEAD_FONT
sens["A3"].fill = PatternFill("solid", fgColor=PLUM)
sens.merge_cells("A3:E3")
headers(sens, 4, ["Configuración", "Unidades", "USD / escaneo", "USD / mes (solo YouCam)", "Ahorro vs actual"])

UNITS = [
    ("1–4 concerns (SD)", 9),
    ("5–8 concerns (SD)", 12),
    ("9–12 concerns (SD)", 14),
    ("13–16 concerns (SD)", 16),
    ("13–16 concerns (HD) — actual", 22),
    ("16 acciones HD + reintentos", 30),
]
for i, (label, units) in enumerate(UNITS, start=5):
    sens.cell(row=i, column=1, value=label).font = BODY_FONT
    sens.cell(row=i, column=2, value=units).number_format = INT
    sens.cell(row=i, column=3, value=f"=B{i}*Supuestos!$C$9").number_format = CUR
    sens.cell(row=i, column=4, value=f"=C{i}*'Costos IA'!$D$4").number_format = CUR
    sens.cell(row=i, column=5, value=f"=1-D{i}/$D$9").number_format = PCT
    for col in range(1, 6):
        sens.cell(row=i, column=col).border = BORDER
        sens.cell(row=i, column=col).fill = PatternFill("solid", fgColor=SAND)
sens["A5"].font = BOLD_FONT
sens["A9"].font = Font(name="Calibri", size=10, bold=True, color="9B3A2E")

sens["A12"] = "B. Escaneos por mes (resto en BASE)"
sens["A12"].font = HEAD_FONT
sens["A12"].fill = PatternFill("solid", fgColor=PLUM)
sens.merge_cells("A12:E12")
headers(sens, 13, ["Escaneos / mes", "Costo variable IA", "Chat + forma facial", "Infraestructura", "TOTAL"])

for i, scans in enumerate([250, 500, 750, 1000, 1500, 2000], start=14):
    sens.cell(row=i, column=1, value=scans).number_format = INT
    sens.cell(row=i, column=2, value=f"=A{i}*('Costos IA'!$D$6+'Costos IA'!$D$7+'Costos IA'!$D$8+'Costos IA'!$D$9)/'Costos IA'!$D$4").number_format = CUR
    sens.cell(row=i, column=3, value="='Costos IA'!$D$10+'Costos IA'!$D$11").number_format = CUR
    sens.cell(row=i, column=4, value="='Infra Railway'!$H$15").number_format = CUR
    sens.cell(row=i, column=5, value=f"=B{i}+C{i}+D{i}").number_format = CUR
    for col in range(1, 6):
        sens.cell(row=i, column=col).border = BORDER
        sens.cell(row=i, column=col).fill = PatternFill("solid", fgColor=SAND)

sens["A21"] = "C. Mensajes de chat por persona activa / mes"
sens["A21"].font = HEAD_FONT
sens["A21"].fill = PatternFill("solid", fgColor=PLUM)
sens.merge_cells("A21:E21")
headers(sens, 22, ["Mensajes / persona", "Costo chat / mes", "Resto IA", "Infraestructura", "TOTAL"])

for i, msgs in enumerate([0, 12, 30, 60], start=23):
    sens.cell(row=i, column=1, value=msgs).number_format = INT
    sens.cell(row=i, column=2, value=f"=A{i}*'Costos IA'!$D$15*(Supuestos!$C$11*Supuestos!$C$21+Supuestos!$C$12*Supuestos!$C$22)/1000000").number_format = CUR
    sens.cell(row=i, column=3, value="='Costos IA'!$D$6+'Costos IA'!$D$7+'Costos IA'!$D$8+'Costos IA'!$D$9+'Costos IA'!$D$11").number_format = CUR
    sens.cell(row=i, column=4, value="='Infra Railway'!$H$15").number_format = CUR
    sens.cell(row=i, column=5, value=f"=B{i}+C{i}+D{i}").number_format = CUR
    for col in range(1, 6):
        sens.cell(row=i, column=col).border = BORDER
        sens.cell(row=i, column=col).fill = PatternFill("solid", fgColor=SAND)

sens["A28"] = "D. Precio unitario YouCam (22 unidades × 750 escaneos)"
sens["A28"].font = HEAD_FONT
sens["A28"].fill = PatternFill("solid", fgColor=PLUM)
sens.merge_cells("A28:E28")
headers(sens, 29, ["Modalidad", "USD / unidad", "USD / mes", "Diferencia", ""])
for i, (label, price) in enumerate([
    ("Suscripción 10.000+ unidades", 0.046),
    ("Suscripción 500+ unidades", 0.048),
    ("Pay-as-you-go", 0.055),
], start=30):
    sens.cell(row=i, column=1, value=label).font = BODY_FONT
    sens.cell(row=i, column=2, value=price).number_format = '0.000'
    sens.cell(row=i, column=3, value=f"=B{i}*22*'Costos IA'!$D$4").number_format = CUR
    sens.cell(row=i, column=4, value=f"=C{i}-$C$31").number_format = CUR
    for col in range(1, 5):
        sens.cell(row=i, column=col).border = BORDER
        sens.cell(row=i, column=col).fill = PatternFill("solid", fgColor=SAND)

widths(sens, {"A": 36, "B": 18, "C": 18, "D": 18, "E": 20})

line = LineChart()
line.title = "Costo total vs escaneos por mes"
line.y_axis.title = "USD / mes"
line.x_axis.title = "Escaneos / mes"
line_data = Reference(sens, min_col=5, min_row=13, max_row=19)
line_cats = Reference(sens, min_col=1, min_row=14, max_row=19)
line.add_data(line_data, titles_from_data=True)
line.set_categories(line_cats)
line.height = 8
line.width = 13
line.series[0].graphicalProperties.line.solidFill = ROSE
line.series[0].graphicalProperties.line.width = 28000
sens.add_chart(line, "G13")

# ===========================================================================
# FUENTES
# ===========================================================================
src = wb.create_sheet("Fuentes")
title(src, "Fuentes, evidencia y límites del modelo", "A1:C1")
subtitle(src, "Precios consultados el 25-oct-2026. Los precios de nube y de API cambian: revalidar antes de decidir.", "A2:C2")
headers(src, 3, ["Tema", "Referencia", "Qué aporta"])

SOURCES = [
    ("Railway · precios", "https://railway.com/pricing", "CPU USD 20/vCPU-mes, RAM USD 10/GB-mes, volumen USD 0,15/GB-mes, egress USD 0,05/GB, Pro USD 20 con USD 20 de uso incluido."),
    ("YouCam API · precios", "https://yce.perfectcorp.com/ai-api/api-pricing", "Suscripción USD 0,048/unidad (500+), PAYG USD 0,055. 13–16 concerns: 22 unidades en HD."),
    ("Gemini API · precios", "https://ai.google.dev/gemini-api/docs/pricing", "Gemini 3.1 Flash-Lite: USD 0,125 / 1M entrada y USD 0,75 / 1M salida (hasta 31-dic-2026)."),
    ("DeepSeek API · precios", "https://api-docs.deepseek.com/quick_start/pricing", "deepseek-flash: USD 0,30 / 1M entrada y USD 1,20 / 1M salida en hora pico; mitad en off-peak."),
    ("TRM Colombia", "https://www.larepublica.co/indicadores-economicos/mercado-cambiario/dolar", "TRM 24–26 oct 2026: $3.158,43 COP/USD (fuente Superfinanciera)."),
    ("Topología Railway", "railway.yml", "Servicios pgvector-db, redis, ai-worker, backend + entorno staging clonado."),
    ("Escaneo facial", "backend/src/services/biometric/orchestrator.js", "Orden real: YouCam (rostro) + Gemini (manos) + DeepSeek (recomendación y VTO)."),
    ("16 acciones HD", "backend/src/services/biometric/youcam.client.js", "SKIN_ANALYSIS_ACTIONS: 16 acciones HD, HD y SD no se mezclan."),
    ("Chat con RAG", "backend/src/config/ragConfig.js", "topK = 5 documentos por consulta; contexto de servicios cacheado."),
    ("Afirmación a contrastar", "GIA-14-I-REAL-COST.md", "Estima USD 0,04/persona/mes (YouCam 2 llamadas ≈ USD 0,02). No cuadra con 22 unidades por escaneo."),
]
for i, (topic, ref, what) in enumerate(SOURCES, start=4):
    src.cell(row=i, column=1, value=topic).font = BOLD_FONT
    src.cell(row=i, column=2, value=ref).font = Font(name="Calibri", size=10, color="1F5C99", underline="single")
    if ref.startswith("http"):
        src.cell(row=i, column=2).hyperlink = ref
    src.cell(row=i, column=3, value=what).font = BODY_FONT
    for col in range(1, 4):
        src.cell(row=i, column=col).alignment = Alignment(wrap_text=True, vertical="top")
        src.cell(row=i, column=col).border = BORDER

src["A16"] = "Límites"
src["A16"].font = HEAD_FONT
src["A16"].fill = PatternFill("solid", fgColor=PLUM)
src.merge_cells("A16:C16")
src["A17"] = (
    "No incluye impuestos, comisiones de pasarela de pago, Firebase/Google Analytics, correo transaccional, "
    "builds de CI, egreso de video ni costos de soporte. Los promedios de vCPU/RAM de Railway son supuestos de "
    "dimensionamiento: reemplácelos por las métricas reales del dashboard para convertir esta simulación en un pronóstico."
)
src.merge_cells("A17:C20")
src["A17"].font = NOTE_FONT
src["A17"].alignment = Alignment(wrap_text=True, vertical="top")

widths(src, {"A": 28, "B": 52, "C": 78})

# Impresión: horizontal y ajustado al ancho de una página
for sheet in wb.worksheets:
    sheet.page_setup.orientation = "landscape"
    sheet.page_setup.paperSize = sheet.PAPERSIZE_A4
    sheet.sheet_properties.pageSetUpPr = PageSetupProperties(fitToPage=True)
    sheet.page_setup.fitToWidth = 1
    sheet.page_setup.fitToHeight = 0
    sheet.print_options.horizontalCentered = True
    sheet.page_margins.left = 0.4
    sheet.page_margins.right = 0.4
    sheet.page_margins.top = 0.5
    sheet.page_margins.bottom = 0.5

os.makedirs(OUT_DIR, exist_ok=True)
wb.save(OUT_PATH)
print(f"OK -> {OUT_PATH}")

