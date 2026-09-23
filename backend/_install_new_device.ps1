$ErrorActionPreference = "SilentlyContinue"
$adb = "C:\Users\Gokul\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$apk = "C:\ElderlyCareProject\elderly-care-project\flutter_app\build\app\outputs\flutter-apk\app-debug.apk"
$sn  = "10BE8D2TJS0026H"

"=== waiting up to 45s for USB debugging to be allowed on $sn ==="
$ready = $false
for($i = 0; $i -lt 22; $i++) {
    Start-Sleep -Seconds 2
    $out = (& $adb devices) | Select-Object -Skip 1
    $cur = $out | Where-Object { $_ -notmatch "^$" }
    $state = ($cur | Select-Object -First 1).ToString()
    $status = ""
    if ($state) { $parts = $state -split "\s+"; if($parts.Count -ge 2){ $status = $parts[1] } }
    "t+$([int]($i+1)*2)s -> $status"
    if ($status -eq "device") { $ready = $true; break }
    if ($status -eq "unauthorized") { "  >>> still unauthorized - press ALLOW on the phone if a popup is showing" }
}

if(-not $ready) { "NOT READY - aborting. The phone never authorized this PC."; exit 1 }

"=== READY - installing APK to $sn ==="
& $adb -s $sn install -r $apk

"=== setting reverse tunnels (Spring 8088 + FastAPI 8000) ==="
& $adb -s $sn reverse tcp:8088 tcp:8088
& $adb -s $sn reverse tcp:8000 tcp:8000
"--- reverse list ---"
& $adb -s $sn reverse --list

"=== done: launching app on $sn ==="
& $adb -s $sn shell am start -n com.elderlycare.flutter_app/.MainActivity
"ALL DONE"
