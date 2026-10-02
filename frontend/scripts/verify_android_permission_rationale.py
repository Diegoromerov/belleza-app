#!/usr/bin/env python3
"""FIX-FLUTTER-02 (P1) — Static contract verifier: Android permission rationale.

Hallazgo original: `frontend/android/app/src/main/AndroidManifest.xml:3-6`
declara permisos peligrosos (ACCESS_FINE_LOCATION / ACCESS_COARSE_LOCATION /
RECORD_AUDIO) SIN `android:description` y sin rationale en la UI.

Este verificador es *estático y sin dependencias* (solo stdlib de Python): no
necesita `flutter pub get`, ni node_modules, ni build Android. Revisa tres
contratos sobre el árbol de `frontend/`:

  1. Todo permiso peligroso DECLARADO en el AndroidManifest principal debe
     llevar `android:description="@string/<key>"` (rationale visible por el SO
     y exigible por Play Store para permisos sensibles).
  2. Toda referencia `@string/<key>` usada en un `android:description` debe
     estar definida en `android/app/src/main/res/values/strings.xml`.
  3. Debe existir rationale EXPLÍCITO EN UI antes de pedir el permiso:
     `lib/services/permission_rationale_service.dart` con un mensaje por
     permiso, invocado desde las pantallas que solicitan ubicación y micrófono.

Uso:
    python frontend/scripts/verify_android_permission_rationale.py [--root RUTA]
    (RUTA por defecto: el directorio `frontend/` que contiene este script)

Salida: 0 si todos los checks pasan (VERDE), 1 si alguno falla (ROJO).
"""
from __future__ import annotations

import argparse
import os
import re
import sys

# Permisos considerados "peligrosos" por Android y que por tanto requieren
# justificación (android:description + rationale en UI).
DANGEROUS_PERMISSIONS = {
    "android.permission.CAMERA",
    "android.permission.RECORD_AUDIO",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.ACCESS_BACKGROUND_LOCATION",
}

# Permisos que la app realmente usa y que este hallazgo obliga a justificar.
REQUIRED_JUSTIFIED = {
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.RECORD_AUDIO",
}

MANIFEST_REL = "android/app/src/main/AndroidManifest.xml"
STRINGS_REL = "android/app/src/main/res/values/strings.xml"
RATIONALE_SERVICE_REL = "lib/services/permission_rationale_service.dart"
# (archivo, permiso que debe justificar, token de invocación del diálogo)
UI_RATIONALE_CALLSITES = (
    ("lib/screens/auth/onboarding_screen.dart", "Permission.location"),
    ("lib/widgets/voice_input.dart", "Permission.microphone"),
)

_USES_PERMISSION_RE = re.compile(r"<uses-permission\b[^>]*?/?>", re.DOTALL)
_ATTR_NAME_RE = re.compile(r'android:name\s*=\s*"([^"]+)"')
_ATTR_DESC_RE = re.compile(r'android:description\s*=\s*"([^"]+)"')
_STRING_REF_RE = re.compile(r'^@string/([^"/]+)$')
_STRING_DEF_RE = r'<string\s+name\s*=\s*"%s"\s*>'

failures: list[str] = []
checks = 0


def _read_normalized(path: str) -> str:
    """Lee un archivo como texto con finales de línea normalizados (CRLF-safe)."""
    with open(path, "r", encoding="utf-8", errors="replace") as handle:
        return handle.read().replace("\r\n", "\n").replace("\r", "\n")


def _record(label: str, ok: bool, detail: str = "") -> None:
    global checks
    checks += 1
    if ok:
        print(f"PASS  {label}")
    else:
        print(f"FAIL  {label}")
        if detail:
            print(f"      {detail}")
        failures.append(label)


def parse_uses_permissions(manifest_text: str) -> list[tuple[str, str | None]]:
    """Devuelve lista de (permiso, description_ref|None) del manifiesto."""
    result: list[tuple[str, str | None]] = []
    for element in _USES_PERMISSION_RE.findall(manifest_text):
        name_match = _ATTR_NAME_RE.search(element)
        if not name_match:
            continue
        desc_match = _ATTR_DESC_RE.search(element)
        result.append((name_match.group(1), desc_match.group(1) if desc_match else None))
    return result


def check_manifest(root: str) -> None:
    manifest_path = os.path.join(root, MANIFEST_REL)
    if not os.path.isfile(manifest_path):
        _record(f"manifiesto principal existe ({MANIFEST_REL})", False, manifest_path)
        return
    _record(f"manifiesto principal existe ({MANIFEST_REL})", True)

    declared = parse_uses_permissions(_read_normalized(manifest_path))
    by_name = {name: desc for name, desc in declared}

    missing_required = sorted(REQUIRED_JUSTIFIED - set(by_name))
    _record(
        "permisos peligrosos del hallazgo declarados en el manifiesto",
        not missing_required,
        f"ausentes: {', '.join(missing_required)}",
    )

    # Contrato 1: todo permiso peligroso declarado lleva android:description.
    for name, desc in sorted(by_name.items()):
        if name not in DANGEROUS_PERMISSIONS:
            continue
        _record(
            f"{name} declara android:description",
            bool(desc),
            "permiso peligroso sin android:description (P1 Play Store)",
        )

    # Contrato 2: cada @string referenciado está definido en strings.xml.
    refs = set()
    for name, desc in by_name.items():
        if name not in DANGEROUS_PERMISSIONS or not desc:
            continue
        ref_match = _STRING_REF_RE.match(desc)
        if ref_match:
            refs.add(ref_match.group(1))

    strings_path = os.path.join(root, STRINGS_REL)
    if not os.path.isfile(strings_path):
        _record(f"strings.xml existe ({STRINGS_REL})", False, strings_path)
        return
    _record(f"strings.xml existe ({STRINGS_REL})", True)

    if not refs:
        _record("algún permiso peligroso referencia @string/…", False,
                "ninguna description de permiso peligroso referencia un string resource")
        return
    _record("algún permiso peligroso referencia @string/…", True)

    strings_text = _read_normalized(strings_path)
    for key in sorted(refs):
        _record(
            f"@string/{key} definido en strings.xml",
            re.search(_STRING_DEF_RE % re.escape(key), strings_text) is not None,
            f"falta <string name=\"{key}\"> en {STRINGS_REL}",
        )


def check_ui_rationale(root: str) -> None:
    # Contrato 3: rationale explícito en UI antes del prompt del SO.
    service_path = os.path.join(root, RATIONALE_SERVICE_REL)
    if not os.path.isfile(service_path):
        _record(f"servicio de rationale existe ({RATIONALE_SERVICE_REL})", False, service_path)
        return
    _record(f"servicio de rationale existe ({RATIONALE_SERVICE_REL})", True)

    service_text = _read_normalized(service_path)
    for token, label in (
        ("Permission.location", "ubicación"),
        ("Permission.microphone", "micrófono"),
    ):
        _record(
            f"rationale definido para {label}",
            token in service_text,
            f"{RATIONALE_SERVICE_REL} no contempla {token}",
        )
    _record(
        "el servicio expone showRationaleDialog",
        "showRationaleDialog" in service_text,
        "no se encontró el diálogo de rationale",
    )

    for rel, token in UI_RATIONALE_CALLSITES:
        path = os.path.join(root, rel)
        if not os.path.isfile(path):
            _record(f"call site de rationale en {rel}", False, path)
            continue
        text = _read_normalized(path)
        ok = "showRationaleDialog" in text and token in text
        _record(
            f"{rel} invoca el rationale antes de {token}",
            ok,
            f"no se encontró showRationaleDialog(..., {token})",
        )


def main() -> int:
    default_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    parser = argparse.ArgumentParser(description="FIX-FLUTTER-02 static verifier")
    parser.add_argument("--root", default=default_root,
                        help="Directorio frontend/ a verificar")
    args = parser.parse_args()
    root = os.path.abspath(args.root)

    print("== FIX-FLUTTER-02 — verificación estática de rationale de permisos Android ==")
    print(f"root: {root}")
    if not os.path.isdir(root):
        print(f"FAIL  el root no existe: {root}")
        return 1

    check_manifest(root)
    check_ui_rationale(root)

    print("-" * 72)
    if failures:
        print(f"RESULTADO: ROJO — {len(failures)} check(s) fallaron de {checks}")
        for item in failures:
            print(f"  - {item}")
        return 1
    print(f"RESULTADO: VERDE — {checks} checks OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
