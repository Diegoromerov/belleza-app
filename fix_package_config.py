import json, os

with open('.dart_tool/package_config.json', 'r') as f:
    d = json.load(f)

for p in d['packages']:
    if p['name'] == 'glow_core':
        abs_path = os.path.abspath('../../packages/glow_core')
        p['rootUri'] = 'file://' + abs_path.replace('\\', '/')

with open('.dart_tool/package_config.json', 'w') as f:
    json.dump(d, f, indent=2)

for p in d['packages']:
    if 'glow' in p['name']:
        print(json.dumps(p, indent=2))