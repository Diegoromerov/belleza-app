import json
import os

os.makedirs('.hermes/devops', exist_ok=True)

hallazgos = [
    {'id': 'DATA-01', 'severity': 'P1', 'area': 'Datos/RLS', 'file': 'backend/migrations/058_enable_rls_policies.sql', 'line': '30,61-63', 'evidence_cmd': "cat backend/migrations/058_enable_rls_policies.sql | grep -A2 -B2 'ENABLE|FORCE|WITH CHECK'", 'impact': 'RLS inerte: ENABLE sin FORCE, sin WITH CHECK', 'proposed_fix': 'FORCE ROW LEVEL SECURITY; WITH CHECK; montar tenantContext', 'effort_h': 4},
    {'id': 'DATA-02', 'severity': 'P1', 'area': 'Datos/Migraciones', 'file': 'backend/src/config/db.js', 'line': '1623-1636', 'evidence_cmd': "cat backend/src/config/db.js | sed -n '1623,1636p'", 'impact': '2 runners migraciones, sin tracking unificado', 'proposed_fix': 'Un solo runner, tabla schema_migrations', 'effort_h': 4},
]

for h in hallazgos:
    with open('.hermes/devops/HALLAZGO-{}.json'.format(h['id']), 'w') as out:
        json.dump(h, out, indent=2)

print("Generados {} hallazgos DATA".format(len(hallazgos)))
