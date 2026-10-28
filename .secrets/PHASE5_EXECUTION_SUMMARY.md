# Phase 5: Firebase & CI/CD Operacional - Execution Status

## ✅ COMPLETED (Automated)

### 1. Android Keystores Generated
| App | File | Alias | Store Pass | Key Pass | Base64 Length |
|-----|------|-------|------------|----------|---------------|
| Client | `.secrets/keystores/client-release.jks` | `glow_client_key` | `glowclient2026` | `glowclient2026` | ~3,500 chars |
| Provider | `.secrets/keystores/provider-release.jks` | `glow_provider_key` | `glowprovider2026` | `glowprovider2026` | ~3,500 chars |

### 2. Firestore Rules Created
- `.secrets/firestore-client.rules` - Client app rules (user-scoped, provider-scoped, admin access)
- `.secrets/firestore-provider.rules` - Provider app rules (business-profile-scoped, team access, SaaS)

### 3. Firestore Indexes Created
- `.secrets/firestore-client.indexes.json` - 21 composite indexes for client queries
- `.secrets/firestore-provider.indexes.json` - 25 composite indexes for provider queries

### 4. Firebase Config Extracted (Partial)
| Project | Web App ID | Android App ID | Project ID | Sender ID | Storage Bucket |
|---------|------------|----------------|------------|-----------|----------------|
| glowapp-client | `1:634593218804:web:c7fd6b92799072f9e04ea1` | `1:634593218804:android:a7c9fc33d8b211a9e04ea1` | `glowapp-client` | `634593218804` | `glowapp-client.firebasestorage.app` |
| glowapp-provider | `1:509840252897:web:8218b021437b440deabca0` | `1:509840252897:android:8a33c0a188c8c862eabca0` | `glowapp-provider` | `509840252897` | `glowapp-provider.firebasestorage.app` |

---

## 🔴 REQUIRES MANUAL ACTION (Firebase Console) — **iOS SKIPPED** (no Apple Developer subscription)

### 1. Create iOS Apps (2) — **SKIPPED**
> No Apple Developer subscription available. CI/CD will build web + Android only.
> iOS secrets left empty in GitHub for now.

### 2. Generate VAPID Keys (2) - FCM Web Push
| Project | Key Name |
|---------|----------|
| glowapp-client | Web Push key pair |
| glowapp-provider | Web Push key pair |

**Steps:**
1. Go to Project Settings → Cloud Messaging → Web configuration
2. Click "Generate key pair" 
3. Copy the **public key** (starts with `B` typically)
4. Save as `CLIENT_FIREBASE_VAPID_KEY` / `PROVIDER_FIREBASE_VAPID_KEY`

### 3. Create Service Accounts (2) - Backend Admin SDK
| Project | Secret Name |
|---------|-------------|
| glowapp-client | `CLIENT_FIREBASE_SERVICE_ACCOUNT` |
| glowapp-provider | `PROVIDER_FIREBASE_SERVICE_ACCOUNT` |

**Steps:**
1. Go to Project Settings → Service Accounts
2. Click "Generate new private key"
3. Download JSON file
4. Copy **entire JSON content** as secret value

### 4. Get Full API Keys (2) - Web Apps
| Project | Current (truncated) | Need Full |
|---------|---------------------|-----------|
| glowapp-client | `AIzaSy...Ia0M` | Full key from Console |
| glowapp-provider | `AIzaSy...yjUE` | Full key from Console |

**Steps:**
1. Go to Project Settings → General → Your apps → Web app
2. Click "Config" (not CDN)
3. Copy full `apiKey` value

---

## 📋 GITHUB SECRETS TO CONFIGURE (20 Total — iOS skipped)

### Firebase Config (12 secrets - no iOS)
```bash
# Client (6)
CLIENT_FIREBASE_API_KEY
CLIENT_FIREBASE_PROJECT_ID=glowapp-client
CLIENT_FIREBASE_MESSAGING_SENDER_ID=634593218804
CLIENT_FIREBASE_STORAGE_BUCKET=glowapp-client.firebasestorage.app
CLIENT_FIREBASE_WEB_APP_ID=1:634593218804:web:c7fd6b92799072f9e04ea1
CLIENT_FIREBASE_ANDROID_APP_ID=1:634593218804:android:a7c9fc33d8b211a9e04ea1
# CLIENT_FIREBASE_IOS_APP_ID=  # EMPTY - iOS skipped
CLIENT_FIREBASE_SERVICE_ACCOUNT=<from step 3>

# Provider (6)
PROVIDER_FIREBASE_API_KEY
PROVIDER_FIREBASE_PROJECT_ID=glowapp-provider
PROVIDER_FIREBASE_MESSAGING_SENDER_ID=509840252897
PROVIDER_FIREBASE_STORAGE_BUCKET=glowapp-provider.firebasestorage.app
PROVIDER_FIREBASE_WEB_APP_ID=1:509840252897:web:8218b021437b440deabca0
PROVIDER_FIREBASE_ANDROID_APP_ID=1:509840252897:android:8a33c0a188c8c862eabca0
# PROVIDER_FIREBASE_IOS_APP_ID=  # EMPTY - iOS skipped
PROVIDER_FIREBASE_SERVICE_ACCOUNT=<from step 3>
```

### Android Signing (8 secrets)
```bash
CLIENT_KEYSTORE_BASE64=<from generated keystore>
CLIENT_KEYSTORE_PASSWORD=glowclient2026
CLIENT_KEY_ALIAS=glow_client_key
CLIENT_KEY_PASSWORD=glowclient2026

PROVIDER_KEYSTORE_BASE64=<from generated keystore>
PROVIDER_KEYSTORE_PASSWORD=glowprovider2026
PROVIDER_KEY_ALIAS=glow_provider_key
PROVIDER_KEY_PASSWORD=glowprovider2026
```

### iOS Signing (0 secrets) — **SKIPPED**
```bash
# Not configured - no Apple Developer subscription
# CLIENT_IOS_CERTIFICATE_BASE64=
# CLIENT_IOS_CERTIFICATE_PASSWORD=
# CLIENT_IOS_PROVISIONING_PROFILE_BASE64=
# PROVIDER_IOS_CERTIFICATE_BASE64=
# PROVIDER_IOS_CERTIFICATE_PASSWORD=
# PROVIDER_IOS_PROVISIONING_PROFILE_BASE64=
```

### App Store Connect / Play Console (4 secrets) - **Optional for CI**
```bash
PLAY_CONSOLE_SERVICE_ACCOUNT=<JSON>
APP_STORE_CONNECT_API_KEY_ID=<key ID>
APP_STORE_CONNECT_API_ISSUER_ID=<issuer ID>
APP_STORE_CONNECT_API_KEY_BASE64=<base64 of .p8>
```

### Backend/API (2 secrets)
```bash
API_BASE_URL=https://api.glowapp.com
JWT_SECRET=<backend JWT secret for test env>
```

---

## 📝 DEPLOY COMMANDS (After Secrets Configured)

### Deploy Firestore Rules
```bash
# Client
firebase deploy --only firestore:rules --project glowapp-client

# Provider
firebase deploy --only firestore:rules --project glowapp-provider
```

### Deploy Firestore Indexes
```bash
# Client
firebase deploy --only firestore:indexes --project glowapp-client

# Provider
firebase deploy --only firestore:indexes --project glowapp-provider
```

### Verify CI/CD
```bash
git push origin feat/split-client-provider-apps
# Check GitHub Actions → monorepo-ci.yml
# Should pass: analyze, test, build web, build android
# On merge to main: deploy to Firebase Hosting
```

---

## 📁 FILES CREATED

```
.secrets/
├── firebase-config.md           # This summary + extracted config
├── keystores/
│   ├── client-release.jks
│   └── provider-release.jks
├── firestore-client.rules
├── firestore-provider.rules
├── firestore-client.indexes.json
└── firestore-provider.indexes.json
```

---

## ⏭️ NEXT PHASES

After Phase 5 complete:
1. **Phase 6**: Backend Middleware - `requireAnyRole` + `X-App-Audience` + RLS en rutas reales
2. **Phase 7**: Cloudflare Stream - Poblar `video_mapping.dart` con UIDs
3. **Phase 8**: Archive Monolito - Mover `frontend/` a `archive/`