# Plan de Rollback para Migración de Secretos

## 🔄 Procedimiento de Reversión

En caso de fallo en la lectura de secretos desde AWS Secrets Manager o el SecretProvider configurado en producción/staging:

1. **Cambiar la Variable de Entorno**:
   - Ajustar `SECRET_PROVIDER=env` en el servicio/contenedor afectado.
2. **Restablecer el fallback local**:
   - Asegurar que `.env` contenga las claves `JWT_SECRET`, `WOMPI_WEBHOOK_SECRET` y `KYC_WEBHOOK_SECRET`.
3. **Reiniciar el Servicio**:
   - Ejecutar `docker compose restart backend`.
