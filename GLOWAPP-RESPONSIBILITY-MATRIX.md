# GLOWAPP-RESPONSIBILITY-MATRIX

| Actividad           | GlowApp | Salón | PSP | Proveedor futuro |
| ------------------- | ------- | ----- | --- | ---------------- |
| Agenda              | ENCARGADO (operativo) | RESPONSABLE (del servicio) | NO APLICA | NO APLICA |
| Datos cliente       | ENCARGADO (almacena y gestiona) | RESPONSABLE (titular de la relación) | NO APLICA | NO APLICA |
| Pago                | ENCARGADO (registra transacción) | RESPONSABLE (recibe fondos del cliente) | RESPONSABLE (procesa movimiento de fondos) | NO APLICA |
| Comprobante interno | RESPONSABLE (genera registro de pago) | ENCARGADO (utiliza para conciliación) | ENCARGADO (proporciona reference) | NO APLICA |
| Factura fiscal      | NO APLICA (fase 1) | RESPONSABLE (obligado a emitir si corresponde) | ENCARGADO (puede proporcionar datos de pago) | PROVEEDOR (si se integra en futuro) |
| Datos personales    | ENCARGADO (almacena datos de usuarios, clientes, empleados) | RESPONSABLE (titular sobre sus propios datos y de sus empleados) | ENCARGADO (maneja datos de pago necesarios para transacción) | NO APLICA |
| IA/RAG              | ENCARGADO (almacena conocimiento y ejecuta inferencia) | RESPONSABLE (titular de los datos que pueden alimentar el conocimiento) | NO APLICA | NO APLICA |
| Marketing           | ENCARGADO (envía comunicaciones si se activa) | RESPONSABLE (autoriza uso de su marca y datos para promociones) | NO APLICA | NO APLICA |
| Comisión            | RESPONSABLE (define y retira su ingreso) | ENCARGADO (paga la comisión si corresponde) | ENCARGADO (facilita movimiento según modelo) | NO APLICA |

**Leyenda**:
- RESPONSABLE: actor que asume la obligación jurídica principal según la norma aplicable.
- ENCARGADO: actor que trata los datos o ejecuta la actividad por cuenta del responsable.
- INTERMEDIARIO: actor que facilita una transacción entre otras partes sin asumir responsabilidad principal.
- PROVEEDOR: actor que ofrece un servicio o tecnología específica bajo contrato.
- NO APLICA: la actividad no involucra a dicho actor en el contexto descrito.
- POR DEFINIR: no se pudo determinar jurídicamente en esta fase; se requiere revisión externa.

**Notas**:
- Esta matriz se basa en el rol operativo actual de GlowApp como SaaS B2B para salones, evidencia interna de código y esquema, y las decisiones documentadas en el DECISION-REGISTER.
- Las asignaciones de RESPONSABLE/ENCARGADO/etc. están sujetas a validación jurídica externa y pueden cambiar según la determinación del rol de GlowApp (responsable vs encargado) en cada contexto.
- En fase 1, GlowApp no actúa como facturador electrónico ni como proveedor tecnológico DIAN.
- La columna "Proveedor futuro" se refiere a un potencial proveedor tecnológico de facturación electrónica DIAN habilitado.