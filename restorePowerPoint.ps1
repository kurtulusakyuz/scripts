$officeProcesses = Get-Process -Name "POWERPNT" -ErrorAction SilentlyContinue
if ($officeProcesses) {
    Write-Host "Acik olan PowerPoint kapatiliyor..." -ForegroundColor Yellow
    $officeProcesses | Stop-Process -Force
}
$officeVersions = @("14.0", "15.0", "16.0")
Write-Host "PowerPoint varsayilan grafik ve video ayarlari geri yukleniyor..." -ForegroundColor Cyan
foreach ($version in $officeVersions) {
    $graphicsPath = "HKCU:\Software\Microsoft\Office\$version\Common\Graphics"
    $powerPointPath = "HKCU:\Software\Microsoft\Office\$version\PowerPoint\Options"
    if (Test-Path $graphicsPath) {
        Remove-ItemProperty -Path $graphicsPath -Name "DisableHardwareAcceleration" -ErrorAction SilentlyContinue
    }
    if (Test-Path $powerPointPath) {
        Remove-ItemProperty -Path $powerPointPath -Name "DisableHardwareAcceleration" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $powerPointPath -Name "DisableMediaEngine" -ErrorAction SilentlyContinue
    }
}
Write-Host "Varsayilan ayarlar basariyla geri yuklendi!" -ForegroundColor Green
$wshShell = New-Object -ComObject WScript.Shell
$wshShell.Popup("PowerPoint varsayilan kayit defteri ayarlari geri yuklendi.", 0, "Geri Yukleme Tamamlandi", 64) | Out-Null