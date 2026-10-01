#!/usr/bin/env python3
"""verify_platform_permissions.py

Verifica que la app Flutter (GlowApp) declare las declaraciones de permisos
nativas requeridas por los plugins en uso:

  - image_picker  -> camara + galeria
  - camera        -> camara
  - geolocator    -> ubicacion
  - permission_handler / grabacion -> microfono

Hallazgo P0 (auditoria Flutter): beauty-scan usa camara/galeria pero Info.plist
de iOS no declaraba NSCameraUsageDescription / NSPhotoLibraryUsageDescription,
lo que provoca CRASH en iOS al solicitar el permiso, y AndroidManifest.xml no
declaraba android.permission.CAMERA ni acceso a media.

Test-first: rojo antes del fix, verde despues.

Uso:  python3 frontend/scripts/verify_platform_permissions.py
Exit: 0 = todo OK, 1 = faltan declaraciones.
"""
import plistlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
IOS_PLIST = ROOT / "frontend" / "ios" / "Runner" / "Info.plist"
ANDROID_MANIFEST = ROOT / "frontend" / "android" / "app" / "src" / "main" / "AndroidManifest.xml"

# --- iOS: claves de uso obligatorias (>=20 chars de descripcion significativa) ---
REQUIRED_PLIST_KEYS = {
    "NSCameraUsageDescription": "camara (beauty-scan / fotos de perfil)",
    "NSPhotoLibraryUsageDescription": "galeria (fotos de perfil / portafolio)",
    "NSLocationWhenInUseUsageDescription": "ubicacion (proveedores cercanos)",
    "NSMicrophoneUsageDescription": "microfono (videollamadas / notas de voz)",
}

# --- Android: permisos obligatorios ---
REQUIRED_ANDROID_PERMISSIONS = {
    "android.permission.CAMERA": "camara (beauty-scan)",
    "android.permission.ACCESS_FINE_LOCATION": "ubicacion precisa",
    "android.permission.ACCESS_COARSE_LOCATION": "ubicacion aproximada",
    "android.permission.RECORD_AUDIO": "microfono",
}
# Media: al menos una de las variantes debe estar declarada
ANDROID_MEDIA_PERMISSIONS = {
    "android.permission.READ_MEDIA_IMAGES",   # API 33+
    "android.permission.READ_EXTERNAL_STORAGE",  # legacy
}

failures = []
passes = []


def check_ios():
    print("== iOS Info.plist ==")
    if not IOS_PLIST.exists():
        failures.append(f"Info.plist no encontrado: {IOS_PLIST}")
        print(f"  FAIL: no existe {IOS_PLIST}")
        return
    with open(IOS_PLIST, "rb") as fh:
        data = plistlib.load(fh)
    for key, purpose in REQUIRED_PLIST_KEYS.items():
        if key not in data:
            failures.append(f"iOS falta {key} ({purpose})")
            print(f"  FAIL: falta {key}  ({purpose})")
        elif not str(data[key]).strip() or len(str(data[key]).strip()) < 20:
            failures.append(f"iOS {key} vacia o demasiado corta")
            print(f"  FAIL: {key} vacia/insuficiente")
        else:
            passes.append(f"iOS {key}")
            print(f"  PASS: {key} -> {data[key]}")


def check_android():
    print("== Android AndroidManifest.xml ==")
    if not ANDROID_MANIFEST.exists():
        failures.append(f"AndroidManifest.xml no encontrado: {ANDROID_MANIFEST}")
        print(f"  FAIL: no existe {ANDROID_MANIFEST}")
        return
    text = ANDROID_MANIFEST.read_text(encoding="utf-8")
    declared = set(re.findall(r'<uses-permission[^>]*android:name="([^"]+)"', text))
    for perm, purpose in REQUIRED_ANDROID_PERMISSIONS.items():
        if perm in declared:
            passes.append(f"Android {perm}")
            print(f"  PASS: {perm}")
        else:
            failures.append(f"Android falta {perm} ({purpose})")
            print(f"  FAIL: falta {perm}  ({purpose})")
    if declared & ANDROID_MEDIA_PERMISSIONS:
        hit = declared & ANDROID_MEDIA_PERMISSIONS
        passes.append(f"Android media {sorted(hit)}")
        print(f"  PASS: media -> {sorted(hit)}")
    else:
        failures.append("Android falta permiso de media (READ_MEDIA_IMAGES/READ_EXTERNAL_STORAGE)")
        print("  FAIL: falta permiso de media (galeria)")


def main():
    check_ios()
    check_android()
    print()
    print(f"PASS: {len(passes)}  FAIL: {len(failures)}")
    if failures:
        print("VERDICT: ROJO - declaraciones de permisos faltantes:")
        for item in failures:
            print(f"  - {item}")
        return 1
    print("VERDICT: VERDE - todas las declaraciones nativas presentes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
