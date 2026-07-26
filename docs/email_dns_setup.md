# 📧 Configuración DNS de Correos Transaccionales (SPF, DKIM y DMARC)

Este documento contiene las instrucciones y registros DNS obligatorios para la entrega segura y sin spam de los correos transaccionales de **GlowApp** (citas, recibos y códigos OTP de recuperación).

---

## 🛡️ Registros DNS Requeridos en tu Proveedor de Dominio (p. ej. Cloudflare, GoDaddy, Namecheap)

Sustituye `glowapp.com` por tu dominio de producción oficial.

### 1. Registro SPF (Sender Policy Framework)
Permite a los servidores de Resend o SendGrid enviar correos en nombre de tu dominio.

- **Tipo:** `TXT`
- **Nombre / Host:** `@` (o `glowapp.com.`)
- **Valor / Contenido:**
  - Para **Resend**: `v=spf1 include:amazonses.com ~all`
  - Para **SendGrid**: `v=spf1 include:sendgrid.net ~all`
- **TTL:** `3600` (o Auto)

---

### 2. Registro DKIM (DomainKeys Identified Mail)
Firma digitalmente los correos para evitar suplantaciones de identidad.

#### Para Resend (3 registros CNAME):
| Tipo | Nombre / Host | Valor / Target |
| :--- | :--- | :--- |
| `CNAME` | `resend._domainkey` | `dkim.resend.com` |
| `CNAME` | `bounces` | `feedback-smtp.us-east-1.amazonses.com` |

#### Para SendGrid (2 registros CNAME):
| Tipo | Nombre / Host | Valor / Target |
| :--- | :--- | :--- |
| `CNAME` | `s1._domainkey` | `s1.domainkey.sendgrid.net` |
| `CNAME` | `s2._domainkey` | `s2.domainkey.sendgrid.net` |

---

### 3. Registro DMARC (Domain-based Message Authentication, Reporting & Conformance)
Define las políticas de seguridad si un correo falla las validaciones de SPF o DKIM.

- **Tipo:** `TXT`
- **Nombre / Host:** `_dmarc` (o `_dmarc.glowapp.com.`)
- **Valor / Contenido:** `v=DMARC1; p=quarantine; rua=mailto:dmarc-reports@glowapp.com; pct=100;`
- **TTL:** `3600`

---

## ⚙️ Variables de Entorno Backend (`.env`)

```env
# Configuración de Proveedor de Correo Transaccional
RESEND_API_KEY=re_123456789_tu_resend_api_key
SENDGRID_API_KEY=SG.tu_sendgrid_api_key
EMAIL_FROM=soporte@glowapp.com
EMAIL_FROM_NAME=GlowApp Support
```
