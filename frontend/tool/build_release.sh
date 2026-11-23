#!/usr/bin/env bash
# Build APK release dengan konfigurasi wajib.
#
# Kenapa ada skrip ini: build release menolak jalan bila API_BASE_URL bukan
# https atau GOOGLE_SERVER_CLIENT_ID kosong (lihat guard di lib/main.dart).
# Skrip ini memastikan kedua nilai itu terisi sebelum Gradle dipanggil,
# sehingga kegagalan muncul sebagai pesan jelas, bukan StateError saat app
# dibuka.
#
# Sumber nilai, berurutan:
#   1. environment variable (paling eksplisit, aman untuk CI)
#   2. frontend/env/dev.json (lokal; /env sudah gitignored)
#
# Pemakaian:
#   API_BASE_URL=https://... GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com \
#     ./tool/build_release.sh
#
#   atau cukup: ./tool/build_release.sh
#   (nilai diambil dari env/dev.json)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEV_JSON="$PROJECT_ROOT/env/dev.json"

API_BASE_URL="${API_BASE_URL:-}"
GOOGLE_SERVER_CLIENT_ID="${GOOGLE_SERVER_CLIENT_ID:-}"
USE_FILE=0

if [ -z "$API_BASE_URL" ] || [ -z "$GOOGLE_SERVER_CLIENT_ID" ]; then
  if [ -f "$DEV_JSON" ]; then
    echo "Membaca konfigurasi dari env/dev.json"
    USE_FILE=1
  fi
fi

if [ "$USE_FILE" -eq 0 ]; then
  if [ -z "$API_BASE_URL" ]; then
    echo "API_BASE_URL wajib diisi (contoh: https://rijiki-backend.excellchriatian12.workers.dev). Build release dibatalkan." >&2
    exit 1
  fi
  if [ -z "$GOOGLE_SERVER_CLIENT_ID" ]; then
    echo "GOOGLE_SERVER_CLIENT_ID wajib diisi (Web client ID OAuth Google). Build release dibatalkan." >&2
    exit 1
  fi
  case "$API_BASE_URL" in
    https://*) ;;
    *)
      echo "API_BASE_URL harus https:// untuk build release (sekarang: $API_BASE_URL)." >&2
      exit 1
      ;;
  esac
fi

cd "$PROJECT_ROOT"

if [ "$USE_FILE" -eq 1 ]; then
  # --dart-define-from-file membaca JSON dan meneruskan tiap key sebagai
  # dart-define. Ini yang membuat env/dev.json benar-benar terpakai.
  exec flutter build apk --release --dart-define-from-file=env/dev.json
fi

exec flutter build apk --release \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=GOOGLE_SERVER_CLIENT_ID="$GOOGLE_SERVER_CLIENT_ID"
