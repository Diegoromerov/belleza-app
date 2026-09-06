# GLOWAPP PHASE 2 — REFERRAL ARCHITECTURE

## 1. Referral State Machine
`REFERRAL_CREATED` → `REFERRAL_ACCEPTED` → `FIRST_ACTION` → `QUALIFIED` → `REWARDED`

## 2. Anti-Fraud Rules
- Self-referrals blocked via IP, device fingerprint, and phone number checks.
- Double-reward prevention enforced via unique database constraints on `referred_user_id`.
