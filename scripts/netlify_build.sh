#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FRONTEND_DIR="$ROOT_DIR/frontend"

# Pin a Flutter SDK version that is known to satisfy this repo.
FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.9}"
FLUTTER_CACHE_DIR="${NETLIFY_CACHE_DIR:-${XDG_CACHE_HOME:-$ROOT_DIR/.netlify-cache}}"
FLUTTER_SDK_DIR="${FLUTTER_SDK_DIR:-$FLUTTER_CACHE_DIR/flutter-$FLUTTER_VERSION}"

if [ -x "$FLUTTER_SDK_DIR/bin/flutter" ]; then
  echo "Using Flutter SDK at $FLUTTER_SDK_DIR"
else
  echo "Installing Flutter $FLUTTER_VERSION at $FLUTTER_SDK_DIR"
  mkdir -p "$(dirname "$FLUTTER_SDK_DIR")"
  TEMP_FLUTTER_DIR="$(mktemp -d "$(dirname "$FLUTTER_SDK_DIR")/flutter-install.XXXXXX")"

  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$TEMP_FLUTTER_DIR"

  if [ -e "$FLUTTER_SDK_DIR" ]; then
    STALE_FLUTTER_DIR="$FLUTTER_SDK_DIR.stale.$(date +%s)"
    mv "$FLUTTER_SDK_DIR" "$STALE_FLUTTER_DIR"
    echo "Moved stale Flutter SDK directory to $STALE_FLUTTER_DIR"
  fi

  mv "$TEMP_FLUTTER_DIR" "$FLUTTER_SDK_DIR"
fi

export PATH="$FLUTTER_SDK_DIR/bin:$PATH"
flutter config --enable-web >/dev/null
flutter --version

cd "$FRONTEND_DIR"
flutter pub get
flutter build web --release
