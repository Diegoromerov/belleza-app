# VTO Dataset & Visual Regression Testing Infrastructure

## 📦 Especificación del Dataset Sintético (Virtual Try-On)

Herramientas y especificación para la recolección de muestras sintéticas sin datos PII (Información de Identificación Personal) para el motor de prueba de labiales, sombreado y mallas 3D.

### Estructura de Muestras
```
tools/vto-dataset/
├── README.md
├── samples/
│   ├── synthetic_face_mesh_01.png
│   ├── synthetic_face_mesh_02.png
```

---

## 📸 Configuración de CI para Regresión Visual

Integración recomendada para GitHub Actions (`.github/workflows/pr.yml`):

```yaml
  visual-regression:
    needs: build-and-test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Percy Visual Snapshot Check
        run: npx percy snapshot ./snapshots
```
