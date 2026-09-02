# GIA-01-D — Design Decision Report

## 1. DECISIONES DE DISEÑO ARQUITECTÓNICO

### D-01: Ciclo de Vida Formal (Lifecycle States)
* `active`: El ciclo está en curso; el usuario ejecuta su rutina diaria.
* `reassessment_due`: El ciclo alcanzó un hito (día 15 o 30) y requiere nuevo escaneo.
* `completed`: El ciclo finalizó tras la medición final de 30 días.
* `abandoned`: El usuario decidió cancelar o reiniciar un ciclo antes de completarlo.

### D-02: Algoritmo de Cálculo de Deltas
Dado un score biométrico $S_t$ en el día $t$ y el baseline $S_0$:
$$\Delta_{\text{metric}} = S_t - S_0$$
* En métricas positivas (ej. `hydration`): $\Delta > 0$ representa **mejora**.
* En métricas inversas (ej. `wrinkles`, `spots`, `pores`): $\Delta < 0$ representa **mejora**.
* Atena genera una síntesis textual explicable evaluando si el usuario avanzó hacia el objetivo.

### D-03: Contrato de Rutas REST
* `POST /api/glow-cycle/create`: Inicia un ciclo asociando un escaneo inicial o usando el perfil existente.
* `GET /api/glow-cycle/active`: Obtiene el ciclo actualmente activo del usuario autenticado con su rutina y progreso.
* `POST /api/glow-cycle/:id/measurement`: Registra una nueva medición intermedia o final y calcula el delta.
* `POST /api/glow-cycle/:id/checkin`: Registra el cumplimiento diario de la rutina AM/PM.
* `POST /api/glow-cycle/:id/complete`: Cierra el ciclo actual y emite el resumen final.

## 2. ESTADO DEL GATE
🟢 **PASS**
