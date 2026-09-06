# 🖥️ Session Model — Comportamiento Multipestaña y Multidispositivo

## Comportamiento de Sesión
- **Múltiples Pestañas:** Todas las pestañas comparten el token activo mediante `localStorage`. Al desloguearse en una pestaña, las demás se sincronizan limpiamente.
- **Multidispositivo:** Se permiten múltiples logins simultáneos. Si se cambia la contraseña, las demás sesiones se invalidan al requerir reautenticación tras la expiración del token de 7 días.
- **Fail-Closed Redis:** Si Redis no se encuentra disponible durante la validación de la lista negra de tokens, `authMiddleware` responde `HTTP 503` previniendo la reutilización de sesiones revocadas.
