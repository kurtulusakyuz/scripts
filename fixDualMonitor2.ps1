pnputil.exe /scan-devices > $null 2>&1
$dwmProcess = Get-Process -Name "dwm" -ErrorAction SilentlyContinue
if ($dwmProcess) {
    $dwmProcess | Stop-Process -Force -ErrorAction SilentlyContinue
}
Start-Process -FilePath "$env:windir\System32\DisplaySwitch.exe" -ArgumentList "/clone" -WindowStyle Hidden -ErrorAction SilentlyContinue