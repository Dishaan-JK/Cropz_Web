# Cropz Web Handoff

The web preview for Cropz Card is broken because the frontend is still calling a placeholder API host.

## Symptom

Opening a card in the browser shows:

```text
Unable to load card
ClientException: NetworkError when attempting to fetch resource, uri=https://api.example.com/api/cards/<cardId>
```

## Root Cause

The Flutter web frontend is building the preview request from a placeholder `API_BASE` value instead of using the real deployment origin or a relative API path.

## Relevant Files

- `/run/media/dishaan/G/cropz_web/frontend/lib/main.dart`
- `/run/media/dishaan/G/cropz_web/backend/main.go`
- `/run/media/dishaan/G/cropz_web/README.md`

## What I Found

- `cropz_web/frontend/lib/main.dart`
  - `_fetchCard(cardId)` uses:
    - `const String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:8080')`
    - then calls `'$apiBase/api/cards/$cardId'`
- `cropz_web/backend/main.go`
  - serves `GET /api/cards/{cardId}`
  - backend itself is fine and proxies to PocketBase via `PB_BASE_URL`
- The deployed web app should not depend on a placeholder host like `api.example.com`.

## Intended Behavior

- Preview route is `/{cardId}`
- Fetch the card by ID from the URL path
- "Open in App" should try `cropzcard://card/{id}`
- If the app is not installed, show `Cropz Card not installed.`

## Recommended Fix

- In the Flutter web frontend, stop relying on a placeholder `API_BASE` for production.
- Default to same-origin or relative API calls:
  - `Uri.base.origin` or `/api/cards/$cardId`
- Keep `API_BASE` only as an explicit dev override if needed.
- Update the README/build notes so deployment does not require setting a fake `api.example.com`.

## Important

- Do not change the mobile app repo for this issue.
- The bug is in the separate `cropz_web` workspace.
- The placeholder host is the root cause, not the PocketBase data.
