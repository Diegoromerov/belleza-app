import json

hallazgos = [
    {'id': 'CICD-01', 'severity': 'P0', 'area': 'CI/CD', 'file': '.github/workflows/rag-evaluation.yml', 'line': '27', 'evidence_cmd': "grep -n 'RAILWAY_DATABASE_URL' .github/workflows/rag-evaluation.yml", 'impact': 'Workflow escribe en BD prod', 'proposed_fix': 'Usar service container efimero', 'effort_h': 2},
    {'id': 'CICD-02', 'severity': 'P0', 'area': 'CI/CD', 'file': '.github/workflows/rag-evaluation.yml', 'line': '32-34', 'evidence_cmd': "cat .github/workflows/rag-evaluation.yml | sed -n '32,34p'", 'impact': 'Modelo EOL nv-embedqa-e5-v5', 'proposed_fix': 'Migrar a nemotron-3-embed-1b', 'effort_h': 4},
    {'id': 'CICD-03', 'severity': 'P1', 'area': 'CI/CD', 'file': '.github/workflows/ci.yml', 'line': '38', 'evidence_cmd': "cat .github/workflows/ci.yml | sed -n '38p'", 'impact': 'JWT_SECRET en workflow (CI-only)', 'proposed_fix': 'Documentar CI-only', 'effort_h': 0.5},
]

for h in hallazgos:
    with open('.hermes/devops/HALLAZGO-{}.json'.format(h['id']), 'w') as out:
        json.dump(h, out, indent=2)

print("Generados {} hallazgos CICD".format(len(hallazgos)))
