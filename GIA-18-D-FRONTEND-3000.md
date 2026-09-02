# GIA-18-D — FRONTEND ON PORT 3000

## Serving Method
- Command: `python -m http.server 3000 --directory frontend/build/web`
- Build directory: C:\beauty-app\frontend\build\web

## Verification
- GET http://localhost:3000 → Status 200, Content-Length 4789
- Content: Flutter web app HTML with base href="/"

## Flutter Web Assets Present
- index.html, flutter.js, flutter_bootstrap.js, canvaskit/, main.dart.js

## Backend API Connection
ApiService (frontend/lib/services/api_service.dart) probes http://localhost:8080/api/health

## CORS Configuration
Backend defaultOrigins includes http://localhost:3000 and http://127.0.0.1:3000
