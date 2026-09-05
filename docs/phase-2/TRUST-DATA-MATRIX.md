# GLOWAPP PHASE 2 — TRUST DATA MATRIX

## 1. PII Classification & Data Protection

| ENTITY / FIELD | DATA CLASSIFICATION | STORAGE LOCATION | ACCESS CONTROL | RETENTION PERIOD |
| :--- | :--- | :--- | :--- | :--- |
| KYC Identity Document | RESTRICTED PII | Encrypted S3 / Storage | Admin KYC Role Only | 7 Years (Legal) |
| Bank Account Number | CONFIDENTIAL FINANCIAL | Encrypted DB / Vault | Financial Admin Only | Active Account |
| Safety Incident Report | CONFIDENTIAL SAFETY | PostgreSQL Encrypted | Safety Lead Only | 5 Years |
