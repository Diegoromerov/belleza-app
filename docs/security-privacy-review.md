# Revisión de Seguridad y Privacidad — Hub Biométrico

Checklist mínima:

- [ ] Validar cumplimiento Ley 1581 (Colombia) y GDPR (si aplica)
- [ ] Asegurar consentimiento auditable: registrar IP, user-agent, versión de política
- [ ] Revisar retención y eliminación de imágenes (no almacenar en crudo)
- [ ] Derecho al olvido: endpoints para revocar y borrar perfiles
- [ ] Revisión de logs y anonimización en producción
- [ ] Revisión de almacenamiento de claves y uso de secret manager (no .env en prod)
- [ ] Pen testing básico en endpoints /biometric/* y /consent
- [ ] Documentar SLA y fallbacks cuando APIs externas fallan

Notas: completar con evidencia (capturas, políticas legales y aprobaciones).