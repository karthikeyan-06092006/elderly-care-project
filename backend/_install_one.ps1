$ErrorActionPreference = "Continue"
$adb = "C:\Users\Gokul\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$apk = "C:\ElderlyCareProject\elderly-care-project\flutter_app\build\app\outputs\flutter-apk\app-debug.apk"

"Serial is confirmed by the machine. Waiting for a phone to be plugged in + authorized (up to 60s)..."
$device = $null
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 2
    $out = & $adb devices
    $dev = $out | Select-Object -Skip 1 | Where-Object { $_ -match "^\S+\s+device\s*$" } | ForEach-Object { ($_ -split "\s+")[0] }
    if ($dev) {
        $device = $dev | Select-Object -First 1
        "t+$([int](($i+1)*2))s -> connected: $device"
        break
    }
}

if (-not $device) {
    "NO DEVICE FOUND. Please plug in ONE phone, allow USB debugging (tap Allow), then run this again."
    exit 1
}

"=== device: $device ==="
"All phones:"
& $adb devices

"`n=== installing freshly built APK (Wi-Fi LAN fix included) ==="
& $adb -s $device install -r $apk

"`n=== set USB tunnels (both backends) ==="
& $adb -s $device reverse tcp:8088 tcp:8088
& $adb -s $device reverse tcp:8000 tcp:8000
& $adb -s $device reverse --list

"`n=== launching app ==="
& $adb -s $device shell am start -n com.example.flutter_app/.MainActivity
Start-Sleep -Seconds 5
$p = & $adb -s $device shell pidof com.example.flutter_app
"app running PID=$p"

"`n=== sanity: PC reachable over LAN via its Wi-Fi IP? ==="
$wifiIP = "10.58.18.246"
try {
    $r = Invoke-WebRequest "http://$wifiIP/api/auth/health" -UseBasicParsing -TimeoutSec 5
    "PC over LAN :8088 -> HTTP $($r.StatusCode) (good, phone can reach without USB)"
} catch {
    "PC over LAN :8088 -> FAILED: $($_.Exception.Message) (phone may still need USB tunnel)"
}

"`n=== INSTALL COMPLETE. You may now unplug the phone from USB. ==="
"After unplug: the app keeps working over Wi-Fi (candidate 10.58.18.246:8088) as long as this PC stays on."
"DONE"