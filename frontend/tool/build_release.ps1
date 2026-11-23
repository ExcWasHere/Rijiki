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
#   $env:API_BASE_URL = "https://rijiki-backend.excellchriatian12.workers.dev"
#   $env:GOOGLE_SERVER_CLIENT_ID = "xxxx.apps.googleusercontent.com"
#   powershell -NoProfile -File tool/build_release.ps1
#
#   atau cukup: powershell -NoProfile -File tool/build_release.ps1
#   (nilai diambil dari env/dev.json)

$ErrorActionPreference = 'Stop'

$projectRoot = Join-Path $PSScriptRoot '..'
$devJson = Join-Path $projectRoot 'env/dev.json'

$apiBaseUrl = $env:API_BASE_URL
$clientId = $env:GOOGLE_SERVER_CLIENT_ID
$useFile = $false

if ([string]::IsNullOrWhiteSpace($apiBaseUrl) -or [string]::IsNullOrWhiteSpace($clientId)) {
    if (Test-Path $devJson) {
        Write-Host "Membaca konfigurasi dari env/dev.json"
        $useFile = $true
    }
}

if (-not $useFile) {
    if ([string]::IsNullOrWhiteSpace($apiBaseUrl)) {
        Write-Error 'API_BASE_URL wajib diisi (contoh: https://rijiki-backend.excellchriatian12.workers.dev). Build release dibatalkan.'
        exit 1
    }
    if ([string]::IsNullOrWhiteSpace($clientId)) {
        Write-Error 'GOOGLE_SERVER_CLIENT_ID wajib diisi (Web client ID OAuth Google). Build release dibatalkan.'
        exit 1
    }
    if (-not $apiBaseUrl.StartsWith('https://')) {
        Write-Error "API_BASE_URL harus https:// untuk build release (sekarang: $apiBaseUrl)."
        exit 1
    }
}

Push-Location $projectRoot
try {
    if ($useFile) {
        # --dart-define-from-file membaca JSON dan meneruskan tiap key sebagai
        # dart-define. Ini yang membuat env/dev.json benar-benar terpakai.
        & flutter build apk --release --dart-define-from-file=env/dev.json
    }
    else {
        & flutter build apk --release `
            "--dart-define=API_BASE_URL=$apiBaseUrl" `
            "--dart-define=GOOGLE_SERVER_CLIENT_ID=$clientId"
    }

    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
finally {
    Pop-Location
}
