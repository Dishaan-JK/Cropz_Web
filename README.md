# Cropz Web Rebuild

Minimal working rebuild with:
- Flutter web frontend (`frontend/`) with route-based preview on `/{cardId}`
- Netlify Function API at `/api/cards/{cardId}` for hosted deployments
- Go backend (`backend/`) kept for local development or standalone hosting

## Features
- Shared preview route: `/{cardId}`
- Backend fetch via `GET /api/cards/{cardId}`
- Preview UI sections:
  - Header/profile card
  - Digital business card
  - Business
  - License Info
  - Bank Accounts
  - Address
- Header title centered: `Cropz Card`, logo at top corner
- Light/Dark theme toggle in the top bar
- Action: `Open in App`
  - Tries `cropzcard://card/{id}`
  - If unavailable, shows: `Cropz Card not installed.`

## Run
### 1) Local backend
```bash
cd backend
PB_BASE_URL=https://cropzcard.pockethost.io \
PB_CARDS_COLLECTION=cards \
go run .
```
Backend listens on `:8080` by default.

Optional env vars:
- `PB_BASE_URL` (default: `https://cropzcard.pockethost.io`)
- `PB_CARDS_COLLECTION` (default: `cards`)
- `PB_AUTH_TOKEN` (optional bearer token if your collection is protected)
- `ADDR` (default: `:8080`)

### 2) Frontend (web)
```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port 5173
```

Open:
- `http://localhost:5173/<pocketbase_record_id>`
- Example: `http://localhost:5173/RECORD_ID_FROM_APP_SHARE_LINK`

For local development against a separately running backend, set:
```bash
flutter run -d chrome --web-port 5173 --dart-define=API_BASE=http://localhost:8080
```

By default the frontend calls the same origin at `/api/cards/{cardId}`, which is the intended production setup.

## Netlify Setup
This repo is now wired for a single Netlify deployment:

- The Flutter site is built from `frontend/`
- The card API is served by [`netlify/functions/cards.mjs`](/run/media/dishaan/G/cropz_web/netlify/functions/cards.mjs)
- Requests to `/api/cards/{cardId}` are handled by the Netlify Function

### Add these files
- [`netlify.toml`](/run/media/dishaan/G/cropz_web/netlify.toml)
- [`scripts/netlify_build.sh`](/run/media/dishaan/G/cropz_web/scripts/netlify_build.sh)
- [`netlify/functions/cards.mjs`](/run/media/dishaan/G/cropz_web/netlify/functions/cards.mjs)

### Netlify build settings
- Build command: `./scripts/netlify_build.sh`
- Publish directory: `frontend/build/web`
- Functions directory: `netlify/functions`

### Netlify environment variables
Set these in Site settings > Environment variables:
- `PB_BASE_URL=https://cropzcard.pockethost.io`
- `PB_CARDS_COLLECTION=cards`
- `PB_AUTH_TOKEN` if your PocketBase collection is protected
- `FLUTTER_VERSION=3.41.9` if you want to keep the build pinned

### Netlify routing
- `/api/cards/{cardId}` is served by the function
- All other routes fall back to `/index.html` so Flutter path routing works

### Result
With this setup, `cropzcard.com` does not need a separate public API server. Netlify serves the frontend and the function acts as the API layer.

## Check commands
```bash
cd backend && go build ./...
cd frontend && flutter analyze
```
