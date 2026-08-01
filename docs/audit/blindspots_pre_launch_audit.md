# Auditoría de Puntos Ciegos Pre-Lanzamiento (Operational, Human & Trust Blindspots) — GlowApp

**Proyecto:** GlowApp (Marketplace de Servicios de Belleza en Bogotá)  
**Perspectiva:** Asesor de Lanzamiento 360°, Operador de Marketplaces de Dos Lados & Devil's Advocate  
**Fecha:** 31 de Julio de 2026  
**Ubicación:** `/docs/audit/blindspots_pre_launch_audit.md`

---

## 🧭 METODOLOGÍA & ENFOQUE DE LA AUDITORÍA
Esta auditoría **NO** analiza código, seguridad formal de API ni políticas legales de texto plano (ya validadas). Explora el **espacio entre categorías**: lo que ocurre en el mundo físico y operativo en Bogotá el **Día 1** con usuarios y estilistas reales, donde la tecnología interactúa con personas y dinero real a domicilio.

---

## 1. 📲 EL DÍA 1 CON PROVEEDORAS REALES (Mundo Físico & Conexión)

- 🔴 **Race Conditions de Agenda y Conexión Inestable**: En Bogotá, los sótanos o zonas de salones en sectores como Chapinero o Cedritos sufren caídas de señal. Si una proveedora pierde internet durante la cita y el cliente entrega el PIN OTP:
  - ¿La app permite guardar la verificación del OTP de forma local/offline en el dispositivo de la prestadora y sincronizar en background cuando recupere señal?
  - Si no, ¿el prestador debe retener al cliente en la puerta hasta recuperar internet para que no pierda el dinero de la cita?
- 🔴 **Perfiles de Prestadora Incompletos y "Visibles"**: Si una estilista se registra, pero no ha subido foto de portada ni su portafolio de trabajos reales:
  - ¿El sistema la oculta automáticamente del mapa interactivo principal o la muestra como un marcador vacío dañando la percepción del marketplace?
- 🟡 **Verificación de Identidad para Servicio a Domicilio**: El pago Wompi valida la tarjeta del cliente, pero al entrar a la vivienda del cliente:
  - ¿Hay validación con Cédula de Ciudadanía colombiana en background (cruce de antecedentes) para las proveedoras que ofrecen domicilio privado, o solo se valida un correo/teléfono al registrarse?

---

## 2. 👥 EL DÍA 1 CON CLIENTES REALES (Experiencia del Consumidor)

- 🔴 **Estado Vacío Sin Oferta Cercana (Geolocalización Bogotá)**: Si una usuaria abre la app desde Fontibón o Suba y no hay prestadoras activas en un radio de 5 km:
  - ¿La app le muestra una pantalla en blanco o le ofrece una pantalla de reserva programada a domicilio con Concierge WhatsApp pre-atendido?
- 🔴 **Fallo de Backend con Pago Aprobado en Wompi**: Si Wompi procesa el cobro a la tarjeta del cliente pero la conexión de red falla antes de registrar el `booking` en PostgreSQL:
  - ¿Existe un job automático de conciliación que detecte la transacción huérfana de Wompi, cree la cita y notifique al cliente por SMS/WhatsApp en menos de 3 minutos sin que el cliente tenga que reclamar?
- 🟡 **Gestión de Mala Experiencia Pre-Equipo de Soporte**: El día 1, si un servicio queda mal realizado o el tinte mancha una prenda del cliente:
  - ¿Existe una línea de atención prioritaria inmediata (no un ticket que responda en 48 horas) para desactivar el escalamiento en redes sociales?

---

## 3. 🚨 SOPORTE Y OPERACIONES (El Playbook Humano)

- 🔴 **Sábado 9:00 PM - Incidente en Servicio a Domicilio**: Si una estilista llega a una dirección a las 8:30 PM y la persona que atiende está en estado de alicoramiento o genera un ambiente inseguro:
  - ¿Cuál es el protocolo operativo del prestador para cancelar de emergencia en la app sin perder el costo del traslado? ¿Quién atiende la llamada de pánico del prestador?
- 🔴 **Monitoreo Activo de las Primeras 72 Horas**:
  - ¿Hay un turno asignado para monitorear el dashboard en vivo durante las primeras 72 horas para intervenir manualmente cualquier cita en estado `PENDIENTE_PAGO` o `ESPERANDO_OTP` trabada por más de 30 minutos?
- 🟡 **Estilista No Llega (No-Show Físico)**: Si la prestadora no se presenta al domicilio del cliente 15 minutos después de la hora pactada:
  - ¿Hay un sistema de reasignación exprés o la app automáticamente cancela, reembolsa al 100% y entrega un bono de compensación al cliente?

---

## 4. 💵 DINERO Y CONCILIACIÓN (Flujo Financiero Real)

- 🔴 **Retención Tributaria Colombiana (ReteFuente / ReteICA / ReteIVA)**:
  - Al procesar el retiro del saldo a la cuenta de ahorros o Nequi de la proveedora, ¿el backend liquida y descuenta automáticamente los porcentajes tributarios colombianos (ReteFuente 4%, ReteICA 0.414%), enviándole un comprobante legible para su declaración?
- 🔴 **Escenario de Saldo Negativo por Reembolsos**: Si un cliente exige reembolso total por un servicio defectuoso después de que la proveedora retiró sus ganancias a su cuenta Nequi:
  - ¿La Wallet de la proveedora queda en saldo negativo automáticamente congelando sus próximas citas, o el marketplace asume la pérdida patrimonial?
- 🟡 **Mínimo de Retiro y Comisión Wompi Payout**: Wompi cobra una tarifa fija por cada transferencia ACH/Nequi de salida.
  - ¿El mínimo de retiro ($50.000 COP) absorbe este costo o se le cobra una tarifa transparente al prestador al solicitar el retiro a demanda?

---

## 5. 🛡️ CONFIANZA Y SEGURIDAD PERCIBIDA

- 🔴 **Sello de Verificación Visible para el Cliente**: Para que una mujer en Bogotá acepte a una estilista desconocida en su casa a las 7:00 AM:
  - ¿La ficha de la proveedora muestra un badge dorado de *"Verificación de Antecedentes y Cédula Validada por GlowApp"*?
- 🟡 **Primera Impresión Orgánica (Google / Redes Sociales)**: Si un cliente busca *"GlowApp Bogotá"* en Google antes de colocar la tarjeta:
  - ¿Encuentra una landing page corporativa oficial con términos de intermediación claros y enlace a soporte, o un dominio de desarrollo/vacío?

---

## 6. 📊 CAPACIDAD REAL VS. CAPACIDAD ASUMIDA

- 🔴 **Densidad de Oferta Verificada para el Día 1**:
  - ¿Cuántas proveedoras reales en Bogotá están capacitadas, con cuenta bancaria configurada y listas para recibir citas hoy mismo? (Si son menos de 10 en zonas concentradas como Zona T/Chicó, el marketplace puede fallar por falta de cobertura).
- 🟡 **Prueba de Usuario 100% Ajeno (Unblind Test)**:
  - ¿Se probó la app con una persona ajena al equipo (sin explicarle nada) para observar si comprende el mecanismo del PIN OTP para liberar el pago al finalizar?

---

## 7. ⚖️ LO LEGAL-OPERATIVO DE SENTIDO COMÚN

- 🔴 **Cláusula de Intermediación vs. Relación Laboral**:
  - ¿Los términos de uso dejan 100% claro que GlowApp es una plataforma tecnológica de intermediación (marketplace) y no una empresa empleadora de las estilistas, eximiendo al marketplace de responsabilidad por accidentes de trabajo o insumos de las proveedoras?
- 🟡 **Póliza / Fondo de Garantía de Daños**: Si un tratamiento capilar causa una reacción alérgica:
  - ¿Existe un disclaimer que exige a la proveedora realizar la prueba de sensibilidad previa, y establece que la responsabilidad civil profesional recae sobre la prestadora del servicio?

---

## 8. 📈 MÉTRICAS DE "ÉXITO O FALLO" DEL DÍA 1

- 🔴 **Métrica Clave de Retención (Drop-off Tracking)**:
  - ¿Existe métrica para identificar qué porcentaje de clientes abre la app, selecciona un servicio y abandona en la pantalla de pago o en la pre-selección de fecha?
- 🟡 **Criterio de Evaluación Semana 1**:
  - **Éxito**: $\ge 15$ citas completadas exitosamente con OTP ingresado sin disputas abrumadoras.
  - **Alarma Operativa**: $\ge 20\%$ de disputas o cancelaciones por no-show de proveedoras.

---

## 9. 🔄 REVERSIBILIDAD & FEATURE FLAGS OPERATIVOS

- 🔴 **Feature Flag de Emergencia por Módulo**:
  - Si el pasarela de Wompi experimenta una caída técnica a nivel nacional, ¿existe un interruptor remoto en el backend para cambiar la app a modo *"Reserva Directa con Pago en Servicio/WhatsApp"* sin tener que publicar una nueva versión de Flutter en tiendas?
- 🟡 **Plan B si la Demanda es Cero el Día 1**:
  - Si en las primeras 24 horas no hay reservas orgánicas, ¿existe un plan operativo para realizar citas de prueba controladas entre socias/amigos para validar toda la cadena financiera real?

---

## 📋 LAS 10 PREGUNTAS QUE SE HARÁ EL PRIMER USUARIO REAL MAÑANA

1. *¿Quién es esta persona que va a venir a mi casa y cómo sé que es segura?*
2. *¿Por qué me piden un código PIN OTP de 6 dígitos al finalizar el servicio?*
3. *¿El dinero ya se descontó de mi tarjeta o se cobra cuando termine la cita?*
4. *¿Qué pasa si la estilista no llega a la hora acordada a mi dirección en Bogotá?*
5. *¿Puedo cambiar o reprogramar la cita directamente desde la app si me surge una reunión?*
6. *¿Qué ocurre si el resultado del peinado o tinte no fue el que pedí? ¿Dónde me quejo?*
7. *¿El precio que me muestra la app incluye todos los impuestos y productos de belleza?*
8. *¿Puedo hablar por chat o WhatsApp directamente con la estilista antes de que llegue?*
9. *¿Qué garantía tengo si pago y la aplicación se traba o pierde conexión?*
10. *¿GlowApp es una empresa registrada en Colombia que me respalde si algo sale mal?*
