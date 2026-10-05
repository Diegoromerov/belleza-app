import json
import os
import sys

os.makedirs('.hermes/devops', exist_ok=True)

findings = []
if os.path.exists('gitleaks-report.json'):
    try:
        with open('gitleaks-report.json') as f:
            findings = json.load(f)
    except Exception as e:
        print("Error leyendo gitleaks-report.json:", e)

real_findings = [f for f in findings if isinstance(f, dict) and 'allowlist' not in f.get('RuleID', '')]

for i, f in enumerate(real_findings):
    file_path = f.get('File', '')
    line_num = f.get('StartLine', f.get('Line', 0))
    rule_id = f.get('RuleID', '')
    hallazgo = {
        'id': 'SEC-{:02d}'.format(i+1),
        'severity': 'P0',
        'area': 'Secretos/Historial',
        'file': file_path,
        'line': line_num,
        'evidence_cmd': 'gitleaks detect --source . --config .gitleaks.toml',
        'impact': 'Credencial detectada: {} en {}:{}'.format(rule_id, file_path, line_num),
        'proposed_fix': 'Rotar secreto en proveedor; purgar historial con BFG/git-filter-repo',
        'effort_h': 2
    }
    with open('.hermes/devops/HALLAZGO-SEC-{:02d}.json'.format(i+1), 'w') as out:
        json.dump(hallazgo, out, indent=2)

print("Generados {} hallazgos SEC".format(len(real_findings)))

