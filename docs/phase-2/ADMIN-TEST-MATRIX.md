# GLOWAPP PHASE 2 — ADMIN TEST MATRIX

## 1. Validation & Test Catalog

| TEST NAME | TARGET SCREEN | ROLE | EXPECTED RESULT | STATUS |
| :--- | :--- | :--- | :--- | :--- |
| Admin Login to Dashboard | `/(auth)/login` -> `/(dashboard)/page.tsx` | ADMIN | Successful session & Operations dashboard render | PASS |
| Academy Course Creation | `/(dashboard)/admin/academia/nuevo` | ADMIN | Course creation form submit & DB persistence | PASS |
| VTO Configuration Save | `/(dashboard)/admin/vto/page.tsx` | ADMIN | Virtual Try-On configuration save & notification | PASS |
| Dispute Resolution Flow | `disputes_list.dart` | ADMIN | Dispute status updated & audit log entry created | PASS |
