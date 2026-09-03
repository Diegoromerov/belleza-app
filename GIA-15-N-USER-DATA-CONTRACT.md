# GIA-15-N — User Data Contract Report

## 1. CONTRATO Y GOBERNANZA DE DATOS DE USUARIO
* **Identidad:** `userId` anonimizado a través de tokens JWT y UUIDs de ciclo.
* **Biometría:** Cero almacenamiento permanente de imágenes faciales/manos. Las fotos son analizadas en memoria y descartadas inmediatamente tras el cálculo de scores.
* **Longitudinalidad:** Scores numéricos y deltas inmutables protegidos con cifrado AES-256-GCM.
* **Logs Operacionales:** Cero volcado de credenciales, passwords o identificadores biométricos en Winston Logger.

## 2. ESTADO DEL GATE
🟢 **PASS**
