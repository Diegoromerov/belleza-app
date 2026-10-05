#!/usr/bin/env python3
import re, os, sys

patterns = [
    (r'ghp_[A-Za-z0-9]{36}', 'GitHub PAT'),
    (r'sk-[A-Za-z0-9]{48}', 'OpenAI API Key'),
    (r'nvapi-[A-Za-z0-9]{40,}', 'NVIDIA API Key'),
    (r'postgres://[^:\s]+:[^@\s]+@[^/\s]+:\d+/[^\s]+', 'Postgres URL with password'),
    (r'mongodb://[^:\s]+:[^@\s]+@[^/\s]+:\d+/[^\s]+', 'MongoDB URL with password'),
    (r'redis://[^:\s]+:[^@\s]+@[^/\s]+:\d+/[^\s]+', 'Redis URL with password'),
    (r'(?i)(api[_-]?key|secret|password|token)\s*[:=]\s*[\'"]?[A-Za-z0-9_\-]{20,}[\'"]?', 'Generic secret'),
    (r'(?i)JWT_SECRET\s*[:=]\s*[\'"]?[A-Za-z0-9_\-]{20,}[\'"]?', 'JWT Secret'),
    (r'(?i)ENCRYPTION_KEY\s*[:=]\s*[\'"]?[A-Za-z0-9_\-]{20,}[\'"]?', 'Encryption Key'),
]

def scan_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        for pattern, name in patterns:
            for match in re.finditer(pattern, content):
                line_num = content[:match.start()].count('\n') + 1
                matched = match.group()[:120]
                print(f'{filepath}:{line_num}: [{name}] {matched}')
    except Exception:
        pass

# Scan all files
for root, dirs, files in os.walk('.'):
    dirs[:] = [d for d in dirs if d not in ('.git', 'node_modules', '__pycache__', '.cache')]
    for f in files:
        if not f.endswith(('.png', '.jpg', '.jpeg', '.gif', '.ico', '.svg', '.woff', '.woff2', '.ttf', '.eot', '.pdf', '.zip', '.tar', '.gz', '.exe', '.dll', '.so', '.dylib', '.class', '.pyc', '.lock')):
            scan_file(os.path.join(root, f))