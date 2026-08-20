$registryPaths = @(
    "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Configuration",
    "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Connectivity",
    "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\ScaleFactors"
)
foreach ($targetPath in $registryPaths) {
    if (Test-Path $targetPath) {
        Get-ChildItem -Path $targetPath -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}
pnputil.exe /scan-devices > $null 2>&1
$dwmProcess = Get-Process -Name "dwm" -ErrorAction SilentlyContinue
if ($dwmProcess) {
    $dwmProcess | Stop-Process -Force -ErrorAction SilentlyContinue
}
Start-Process -FilePath "$env:windir\System32\DisplaySwitch.exe" -ArgumentList "/clone" -WindowStyle Hidden -ErrorAction SilentlyContinue