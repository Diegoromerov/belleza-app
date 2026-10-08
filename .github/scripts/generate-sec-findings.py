import json
import sys

with open('gitleaks-report.json') as f:
    findings = json.load(f)

real_findings = [f for f in findings if 'allowlist' not in f.get('RuleID', '')]

for i, f in enumerate(real_findings):
    hallazgo = {
        'id': 'SEC-{:02d}'.format(i+1),
        'severity': 'P0',
        'area': 'Secretos/Historial',
        'file': f['File'],
        'line': f['Line'],
        'evidence_cmd': 'gitleaks detect --source . --config .gitleaks.toml',
        'impact': 'Credencial detectada: {} en {}:{}'.format(f['RuleID'], f['File'], f['Line']),
        'proposed_fix': 'Rotar secreto en proveedor; purgar historial con BFG/git-filter-repo',
        'effort_h': 2
    }
    with open('.hermes/devops/HALLAZGO-SEC-{:02d}.json'.format(i+1), 'w') as out:
        json.dump(hallazgo, out, indent=2)

print("Generados {} hallazgos SEC".format(len(real_findings)))
