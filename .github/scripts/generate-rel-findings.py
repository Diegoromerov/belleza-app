import json

hallazgos = [
    {'id': 'FL-01', 'severity': 'P1', 'area': 'Flutter Release', 'file': '.github/workflows/ci.yml', 'line': 'N/A', 'evidence_cmd': "grep -n 'flutter build' .github/workflows/ci.yml || echo SIN_BUILD", 'impact': 'Sin pipeline build Android/iOS/web', 'proposed_fix': 'GitHub Actions + subosito/flutter-action + keystore via secrets', 'effort_h': 6},
    {'id': 'FL-02', 'severity': 'P1', 'area': 'Flutter Release', 'file': 'frontend/android/key.properties.example', 'line': 'N/A', 'evidence_cmd': 'cat frontend/android/key.properties.example', 'impact': 'Sin firma automatizada', 'proposed_fix': 'Keystore base64 en secrets; key.properties generado en CI', 'effort_h': 2},
]

for h in hallazgos:
    with open('.hermes/devops/HALLAZGO-{}.json'.format(h['id']), 'w') as out:
        json.dump(h, out, indent=2)

print("Generados {} hallazgos REL".format(len(hallazgos)))
