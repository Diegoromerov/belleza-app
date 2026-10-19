import json

hallazgos = [
    {'id': 'SUP-01', 'severity': 'P2', 'area': 'Supply Chain/Deps', 'file': 'backend/package.json', 'line': 'N/A', 'evidence_cmd': 'cd backend && npm audit --json', 'impact': 'Sin automatizacion actualizaciones npm/pub/pip', 'proposed_fix': 'dependabot.yml + buddy-bot (MIT) + syft (MIT) SBOM', 'effort_h': 2},
    {'id': 'SC-03', 'severity': 'P1', 'area': 'Supply Chain/Exposicion', 'file': 'backend/package.json', 'line': 'N/A', 'evidence_cmd': "grep -r 'express-status-monitor' backend/src/", 'impact': '/status sin auth', 'proposed_fix': 'Proteger /status con auth', 'effort_h': 0.5},
    {'id': 'SC-04', 'severity': 'P1', 'area': 'Supply Chain/Exposicion', 'file': 'backend/package.json', 'line': 'N/A', 'evidence_cmd': "grep -r 'swagger-ui-express' backend/src/", 'impact': '/api-docs sin auth en prod', 'proposed_fix': 'Proteger /api-docs con auth', 'effort_h': 0.5},
    {'id': 'HIG-01', 'severity': 'P1', 'area': 'Higiene', 'file': 'backend/public/main.dart.js', 'line': 'N/A', 'evidence_cmd': 'ls -la backend/public/main.dart.js', 'impact': 'Build web versionado en backend', 'proposed_fix': 'Mover a CI artifact, .gitignore backend/public/', 'effort_h': 2},
    {'id': 'HIG-02', 'severity': 'P1', 'area': 'Higiene', 'file': 'LICENSE', 'line': 'N/A', 'evidence_cmd': 'ls -la LICENSE* 2>/dev/null || echo SIN_LICENSE', 'impact': 'Sin LICENSE en raiz', 'proposed_fix': 'Anadir MIT license', 'effort_h': 0.5},
]

for h in hallazgos:
    with open('.hermes/devops/HALLAZGO-{}.json'.format(h['id']), 'w') as out:
        json.dump(h, out, indent=2)

print("Generados {} hallazgos SUP".format(len(hallazgos)))
