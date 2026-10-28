# Phase 5: Firebase & CI/CD — Secrets Required

This document lists all GitHub Secrets needed for the monorepo CI/CD workflows.

## Firebase Projects

| Project | Purpose | Console URL |
|---------|---------|-------------|
| `glowapp-client` | Client app (end-users) | https://console.firebase.google.com/project/glowapp-client |
| `glowapp-provider` | Provider app (salons/owners) | https://console.firebase.google.com/project/glowapp-provider |

---

## Required GitHub Secrets

### For `glowapp-client` (Client App)

| Secret Name | Value | Where to Get |
|-------------|-------|--------------|
| `CLIENT_FIREBASE_API_KEY` | Web API Key | Project Settings → General → Web API Key |
| `CLIENT_FIREBASE_PROJECT_ID` | Project ID | Project Settings → General → Project ID |
| `CLIENT_FIREBASE_MESSAGING_SENDER_ID` | Sender ID | Project Settings → Cloud Messaging → Sender ID |
| `CLIENT_FIREBASE_STORAGE_BUCKET` | Storage Bucket | Project Settings → General → Storage Bucket |
| `CLIENT_FIREBASE_WEB_APP_ID` | Web App ID | Project Settings → General → Your apps → Web app (starts with `1:...:web:...`) |
| `CLIENT_FIREBASE_ANDROID_APP_ID` | Android App ID | Project Settings → General → Your apps → Android app (starts with `1:...:android:...`) |
| `CLIENT_FIREBASE_IOS_APP_ID` | iOS App ID | Project Settings → General → Your apps → iOS app (starts with `1:...:ios:...`) |
| `CLIENT_FIREBASE_SERVICE_ACCOUNT` | Service Account JSON | Project Settings → Service Accounts → Generate New Private Key |

### For `glowapp-provider` (Provider App)

| Secret Name | Value | Where to Get |
|-------------|-------|--------------|
| `PROVIDER_FIREBASE_API_KEY` | Web API Key | Project Settings → General → Web API Key |
| `PROVIDER_FIREBASE_PROJECT_ID` | Project ID | Project Settings → General → Project ID |
| `PROVIDER_FIREBASE_MESSAGING_SENDER_ID` | Sender ID | Project Settings → Cloud Messaging → Sender ID |
| `PROVIDER_FIREBASE_STORAGE_BUCKET` | Storage Bucket | Project Settings → General → Storage Bucket |
| `PROVIDER_FIREBASE_WEB_APP_ID` | Web App ID | Project Settings → General → Your apps → Web app |
| `PROVIDER_FIREBASE_ANDROID_APP_ID` | Android App ID | Project Settings → General → Your apps → Android app |
| `PROVIDER_FIREBASE_IOS_APP_ID` | iOS App ID | Project Settings → General → Your apps → iOS app |
| `PROVIDER_FIREBASE_SERVICE_ACCOUNT` | Service Account JSON | Project Settings → Service Accounts → Generate New Private Key |

---

## Android Signing Secrets (for Play Store releases)

| Secret Name | Value |
|-------------|-------|
| `CLIENT_KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` |
| `CLIENT_KEYSTORE_PASSWORD` | Keystore password |
| `CLIENT_KEY_ALIAS` | Key alias |
| `CLIENT_KEY_PASSWORD` | Key password |
| `PROVIDER_KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` |
| `PROVIDER_KEYSTORE_PASSWORD` | Keystore password |
| `PROVIDER_KEY_ALIAS` | Key alias |
| `PROVIDER_KEY_PASSWORD` | Key password |

---

## iOS Signing Secrets (for App Store Connect)

| Secret Name | Value |
|-------------|-------|
| `CLIENT_IOS_CERTIFICATE_BASE64` | `base64 -w0 ios_distribution.p12` |
| `CLIENT_IOS_CERTIFICATE_PASSWORD` | P12 password |
| `CLIENT_IOS_PROVISIONING_PROFILE_BASE64` | `base64 -w0 glowapp_client.mobileprovision` |
| `PROVIDER_IOS_CERTIFICATE_BASE64` | `base64 -w0 ios_distribution.p12` |
| `PROVIDER_IOS_CERTIFICATE_PASSWORD` | P12 password |
| `PROVIDER_IOS_PROVISIONING_PROFILE_BASE64` | `base64 -w0 glowapp_provider.mobileprovision` |

---

## App Store Connect / Play Console Secrets

| Secret Name | Value |
|-------------|-------|
| `PLAY_CONSOLE_SERVICE_ACCOUNT` | Service Account JSON (Google Play Console) |
| `APP_STORE_CONNECT_API_KEY_ID` | API Key ID |
| `APP_STORE_CONNECT_API_ISSUER_ID` | Issuer ID |
| `APP_STORE_CONNECT_API_KEY_BASE64` | `base64 -w0 AuthKey_XXXXXXXXXX.p8` |

---

## Backend / API Secrets (if needed in CI)

| Secret Name | Value |
|-------------|-------|
| `API_BASE_URL` | `https://api.glowapp.com` (staging/prod) |
| `JWT_SECRET` | Backend JWT secret (for test env only) |

---

## How to Add Secrets

1. Go to GitHub repo → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add each secret from the tables above
4. For Service Account JSON: copy the **entire JSON file content** as the secret value

---

## Workflow Triggers

| Workflow | Trigger | Action |
|----------|---------|--------|
| `monorepo-ci.yml` | Push to `main`, `staging`, `feat/**` | CI: analyze, test, build web/android |
| `monorepo-ci.yml` | PR to `main`, `staging` | CI: analyze, test |
| `monorepo-ci.yml` | Push to `main` / `staging` | CD: Deploy web to Firebase Hosting |

---

## Local Testing (before pushing)

```bash
# Build client web with local config
cd apps/glow_client
flutter build web --release \
  --dart-define=FIREBASE_API_KEY=your_key \
  --dart-define=FIREBASE_PROJECT_ID=your_project_id \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=your_sender_id \
  --dart-define=FIREBASE_STORAGE_BUCKET=your_bucket \
  --dart-define=FIREBASE_WEB_APP_ID=your_web_app_id \
  --dart-define=APP_AUDIENCE=client

# Build provider web
cd ../glow_provider
flutter build web --release \
  --dart-define=FIREBASE_API_KEY=your_key \
  --dart-define=FIREBASE_PROJECT_ID=your_project_id \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=your_sender_id \
  --dart-define=FIREBASE_STORAGE_BUCKET=your_bucket \
  --dart-define=FIREBASE_WEB_APP_ID=your_web_app_id \
  --dart-define=APP_AUDIENCE=provider
```

---

## Next Steps After Secrets Configured

1. Push to `feat/split-client-provider-apps` → CI runs
2. Verify CI passes (analyze, test, build)
3. Merge to `main` → CD deploys to Firebase Hosting
4. Verify deployed URLs:
   - Client: `https://glowapp-client.web.app` (or custom domain)
   - Provider: `https://glowapp-provider.web.app` (or custom domain)
5. Configure custom domains in Firebase Hosting if needed
6. Proceed to **Phase 6**: Backend Middleware (`requireAnyRole` + `X-App-Audience` validation)