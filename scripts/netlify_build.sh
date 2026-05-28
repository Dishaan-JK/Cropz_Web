#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FRONTEND_DIR="$ROOT_DIR/frontend"

# Pin a Flutter SDK version that is known to satisfy this repo.
FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.9}"
FLUTTER_SDK_DIR="$HOME/flutter"

if [ ! -x "$FLUTTER_SDK_DIR/bin/flutter" ]; then
  rm -rf "$FLUTTER_SDK_DIR"
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_SDK_DIR"
fi

export PATH="$FLUTTER_SDK_DIR/bin:$PATH"
flutter config --enable-web >/dev/null

cd "$FRONTEND_DIR"
flutter pub get
flutter build web --release
