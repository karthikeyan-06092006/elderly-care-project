$ErrorActionPreference = "Continue"
$adb = "C:\Users\Gokul\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$apk = "C:\ElderlyCareProject\elderly-care-project\flutter_app\build\app\outputs\flutter-apk\app-debug.apk"

"=== 1. adb devices ==="
& $adb devices

$serials = @()
(& $adb devices) | Select-Object -Skip 1 | ForEach-Object {
    if ($_ -match "^(\S+)\s+device\s*$") { $serials += $Matches[1] }
}
$serialList = $serials -join "', '"
"serials = '$serialList'"

"=== 2. install + tunnels + launch per device ==="
foreach ($sn in $serials) {
    "--- $sn ---"
    & $adb -s $sn install -r $apk
    & $adb -s $sn reverse tcp:8088 tcp:8088
    & $adb -s $sn reverse tcp:8000 tcp:8000
    & $adb -s $sn shell am start -n com.example.flutter_app/.MainActivity
    Start-Sleep -Seconds 4
    $p = & $adb -s $sn shell pidof com.example.flutter_app
    "  running PID=$p"
}

"=== 3. Windows Firewall inbound rules for 8088/8000 (LAN mode) ==="
$fw = "C:\Windows\System32\netsh.exe"
foreach ($p in 8088, 8000) {
    & $fw advfirewall firewall delete rule name="ElderlyCare-$p" 2>&1 | Out-Null
    $r = & $fw advfirewall firewall add rule name="ElderlyCare-$p" dir=in action=allow protocol=TCP localport=$p profile=any 2>&1
    "port $p -> $($r | Select-Object -Last 1)"
}

"=== 4. does Spring actually LISTEN on 0.0.0.0:8088 (needed for LAN) or only 127.0.0.1? ==="
$line = netstat -ano | Select-String ":8088" | Select-Object -First 1
"8088 -> $line"
$line2 = netstat -ano | Select-String ":8000" | Select-Object -First 1
"8000 -> $line2"
"DONE"