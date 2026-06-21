# Cropz Web Rebuild

Minimal working rebuild with:
- Web app in `frontend/` with route-based preview on `/{cardId}`
- Hosted API route at `/api/cards/{cardId}`
- Local API service in `backend/` for development or standalone hosting

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
- Action: `Open in App`
  - Tries `cropzcard://card/{id}`
  - If unavailable, shows: `Cropz Card not installed.`
- Help page support form at `/help`
  - Sends submitted reports through `/api/error-requests`
  - Opens a prefilled support email draft to `cropzsupport@gmail.com`
  - Uses web compose or the local mail app flow, depending on device support

## Run
### 1) Local API
```bash
cd backend
PB_BASE_URL=https://cropzcard.pockethost.io \
PB_CARDS_COLLECTION=cards \
go run .
```
The local service listens on `:8080` by default.

Optional env vars:
- `PB_BASE_URL` (default: `https://cropzcard.pockethost.io`)
- `PB_CARDS_COLLECTION` (default: `cards`)
- `PB_AUTH_TOKEN` (optional bearer token if your source data is protected)
- `ADDR` (default: `:8080`)

### 2) Local site
```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port 5173
```

Open:
- `http://localhost:5173/<shared_record_id>`
- Example: `http://localhost:5173/RECORD_ID_FROM_APP_SHARE_LINK`

For local development against a separately running API, set:
```bash
flutter run -d chrome --web-port 5173 --dart-define=API_BASE=http://localhost:8080
```

By default the site calls the same origin at `/api/cards/{cardId}`, which is the intended production setup.

## Hosted Deployment
This repo is wired for a single hosted deployment:

- The site is built from `frontend/`
- The card API is served by [`netlify/functions/cards.mjs`](/run/media/dishaan/G/cropz_web/netlify/functions/cards.mjs)
- Requests to `/api/cards/{cardId}` are handled by the deployed function

### Add these files
- [`netlify.toml`](/run/media/dishaan/G/cropz_web/netlify.toml)
- [`scripts/netlify_build.sh`](/run/media/dishaan/G/cropz_web/scripts/netlify_build.sh)
- [`netlify/functions/cards.mjs`](/run/media/dishaan/G/cropz_web/netlify/functions/cards.mjs)

### Build settings
- Build command: `./scripts/netlify_build.sh`
- Publish directory: `frontend/build/web`
- Functions directory: `netlify/functions`

### Environment variables
Set these in your hosting dashboard:
- `PB_BASE_URL=https://cropzcard.pockethost.io`
- `PB_CARDS_COLLECTION=cards`
- `PB_ERROR_REQUESTS_COLLECTION=Error Requests`
- `PB_AUTH_TOKEN` if the source collection is protected
- `FLUTTER_VERSION=3.41.9` if you want to keep the web build pinned

### Routing
- `/api/cards/{cardId}` is served by the function
- `/api/error-requests` is served by the support form function
- All other routes fall back to `/index.html` so path-based routing works

### Result
With this setup, `cropzcard.com` can serve the site and API routes from one deployment.

## Check commands
```bash
cd backend && go build ./...
cd frontend && flutter analyze
```
