import json
import os

os.makedirs('.hermes/devops', exist_ok=True)

hallazgos = [
    {'id': 'OBS-01', 'severity': 'P1', 'area': 'Observabilidad/Health', 'file': 'backend/src/index.js', 'line': '420-431', 'evidence_cmd': "cat backend/src/index.js | sed -n '420,431p'", 'impact': '/api/health hace setval (write) y miente 200 OK', 'proposed_fix': 'Separar /healthz y /ready; proteger /status, /api-docs', 'effort_h': 1},
    {'id': 'OBS-02', 'severity': 'P1', 'area': 'Observabilidad', 'file': 'backend/monitoring/', 'line': 'N/A', 'evidence_cmd': "ls -la backend/monitoring/ && cat backend/monitoring/prometheus.yml", 'impact': 'Config lista pero no desplegada en prod', 'proposed_fix': 'Desplegar Prometheus+Alertmanager (Grafana Cloud)', 'effort_h': 4},
]

for h in hallazgos:
    with open('.hermes/devops/HALLAZGO-{}.json'.format(h['id']), 'w') as out:
        json.dump(h, out, indent=2)

print("Generados {} hallazgos OBS".format(len(hallazgos)))
