'use strict';

/**
 * backend/src/utils/ticketSla.js
 *
 * Plazos de PQRSF: SLA por prioridad y plazo legal de las solicitudes ARCO.
 *
 * Decisión D2 del Dueño: tramo estricto — EMERGENCIA 30 min · ALTA 2 h · MEDIA 8 h ·
 * BAJA 48 h, y "primera respuesta" = primer mensaje de un OPERADOR/AGENTE (el eco del
 * usuario no cuenta).
 *
 * PURO a propósito: no consulta la base, no llama a `Date.now()` y recibe siempre el
 * instante de referencia. Un plazo legal no debería depender de un reloj escondido, y
 * así se puede probar sin base de datos ni tiempo falso.
 */

/** Minutos de plazo por prioridad. */
const PLAZOS_MINUTOS = Object.freeze({
  EMERGENCIA: 30,
  ALTA: 120,
  MEDIA: 480,
  BAJA: 2880, // 48 h
});

const PRIORIDAD_POR_DEFECTO = 'MEDIA';

/**
 * Fracción del plazo a partir de la cual se avisa "por vencer" (0.25 = el último
 * cuarto). Es una decisión de producto, no un dato: cambiarla aquí la cambia a la vez
 * en la bandeja y en las métricas.
 */
const UMBRAL_POR_VENCER = 0.25;

/** Plazo legal de una solicitud ARCO (Ley 1581/2012): 15 días hábiles. */
const DIAS_HABILES_ARCO = 15;

const MINUTO_MS = 60000;
const DIA_MS = 86400000;

/** Colombia es UTC-5 todo el año (no tiene horario de verano), lo que permite
 *  razonar en "día colombiano" sin traerse una librería de zonas horarias. */
const OFFSET_COLOMBIA_MIN = -300;

/** Fecha cuyos getters UTC leen la hora de Colombia. */
const aColombia = (fecha) => new Date(new Date(fecha).getTime() + OFFSET_COLOMBIA_MIN * MINUTO_MS);
const desdeColombia = (fecha) => new Date(fecha.getTime() - OFFSET_COLOMBIA_MIN * MINUTO_MS);

const esFinDeSemana = (fechaColombia) => {
  const dow = fechaColombia.getUTCDay();
  return dow === 0 || dow === 6;
};

/** 'YYYY-MM-DD' en hora de Colombia. */
function claveDia(fecha) {
  return aColombia(fecha).toISOString().slice(0, 10);
}

/**
 * Plazo en minutos de una prioridad.
 * Una prioridad desconocida o ausente NO queda sin vigilar: cae a MEDIA.
 */
function minutosDe(prioridad) {
  return Object.prototype.hasOwnProperty.call(PLAZOS_MINUTOS, prioridad)
    ? PLAZOS_MINUTOS[prioridad]
    : PLAZOS_MINUTOS[PRIORIDAD_POR_DEFECTO];
}

/** Fecha límite de primera respuesta. */
function fechaLimite(prioridad, desde) {
  return new Date(new Date(desde).getTime() + minutosDe(prioridad) * MINUTO_MS);
}

/**
 * Situación del SLA.
 *   'respondido'  hay primera respuesta (el reloj se paró; ver `respondidoATiempo`)
 *   'vencido'     pasó la fecha límite sin respuesta
 *   'por_vencer'  queda menos del último cuarto del plazo
 *   'en_plazo'    el resto
 */
function estadoSla(prioridad, desde, ahora, primeraRespuestaEn = null) {
  if (primeraRespuestaEn) return 'respondido';
  const limite = fechaLimite(prioridad, desde).getTime();
  const t = new Date(ahora).getTime();
  if (t > limite) return 'vencido';
  return t >= limite - minutosDe(prioridad) * UMBRAL_POR_VENCER * MINUTO_MS ? 'por_vencer' : 'en_plazo';
}

/** ¿La primera respuesta llegó dentro del plazo? */
function respondidoATiempo(prioridad, desde, primeraRespuestaEn) {
  if (!primeraRespuestaEn) return null;
  return new Date(primeraRespuestaEn).getTime() <= fechaLimite(prioridad, desde).getTime();
}

/** Minutos entre la creación y la primera respuesta (métrica cruda). */
function minutosDeRespuesta(desde, primeraRespuestaEn) {
  if (!primeraRespuestaEn) return null;
  return (new Date(primeraRespuestaEn).getTime() - new Date(desde).getTime()) / MINUTO_MS;
}

/** Promedio en minutos (null si no hay datos, y redondeado a 1 decimal). */
function promedioMinutos(valores) {
  const validos = (valores || []).filter((v) => typeof v === 'number' && Number.isFinite(v));
  if (validos.length === 0) return null;
  return Math.round((validos.reduce((a, b) => a + b, 0) / validos.length) * 10) / 10;
}

/**
 * Suma días HÁBILES (lunes a viernes).
 *
 * `festivos` es la puerta que queda abierta: acepta 'YYYY-MM-DD' y los salta. Por
 * defecto va VACÍO, o sea que **no conoce los festivos colombianos**. Es una limitación
 * declarada, no un olvido: 15 días hábiles de la Ley 1581 calculados sin festivos
 * pueden quedarse cortos. Cuando exista una tabla de festivos, se le pasa aquí y el
 * cálculo —y su prueba— no cambian.
 */
function sumarDiasHabiles(desde, dias, festivos = []) {
  const noLaborables = new Set(festivos);
  const d = aColombia(desde);
  let restantes = dias;
  while (restantes > 0) {
    d.setUTCDate(d.getUTCDate() + 1);
    if (esFinDeSemana(d)) continue;
    if (noLaborables.has(d.toISOString().slice(0, 10))) continue;
    restantes -= 1;
  }
  return desdeColombia(d);
}

/** Fecha límite legal de una solicitud ARCO (Ley 1581/2012). */
function fechaLimiteArco(desde, festivos = []) {
  return sumarDiasHabiles(desde, DIAS_HABILES_ARCO, festivos);
}

module.exports = {
  PLAZOS_MINUTOS,
  PRIORIDAD_POR_DEFECTO,
  UMBRAL_POR_VENCER,
  DIAS_HABILES_ARCO,
  minutosDe,
  fechaLimite,
  estadoSla,
  respondidoATiempo,
  minutosDeRespuesta,
  promedioMinutos,
  sumarDiasHabiles,
  fechaLimiteArco,
  claveDia,
  // exportado para las pruebas: es la frontera entre "día colombiano" y UTC
  OFFSET_COLOMBIA_MIN,
  DIA_MS,
};
