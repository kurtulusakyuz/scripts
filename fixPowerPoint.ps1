$officeProcesses = Get-Process -Name "POWERPNT" -ErrorAction SilentlyContinue
if ($officeProcesses) {
    Write-Host "Acik olan PowerPoint kapatiliyor..." -ForegroundColor Yellow
    $officeProcesses | Stop-Process -Force
}
$officeVersions = @("14.0", "15.0", "16.0")
Write-Host "PowerPoint video ve grafik ayarlari yapilandiriliyor..." -ForegroundColor Cyan
foreach ($version in $officeVersions) {
    $graphicsPath = "HKCU:\Software\Microsoft\Office\$version\Common\Graphics"
    $powerPointPath = "HKCU:\Software\Microsoft\Office\$version\PowerPoint\Options"
    if (!(Test-Path $graphicsPath)) {
        New-Item -Path $graphicsPath -Force | Out-Null
    }
    if (!(Test-Path $powerPointPath)) {
        New-Item -Path $powerPointPath -Force | Out-Null
    }
    Set-ItemProperty -Path $graphicsPath -Name "DisableHardwareAcceleration" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $powerPointPath -Name "DisableHardwareAcceleration" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $powerPointPath -Name "DisableMediaEngine" -Value 1 -Type DWord -Force
}
$tempPowerPointFiles = Get-ChildItem -Path $env:TEMP -Filter "*ppt*" -Recurse -ErrorAction SilentlyContinue
if ($tempPowerPointFiles) {
    Write-Host "Gecici PowerPoint onbellegi temizleniyor..." -ForegroundColor Yellow
    $tempPowerPointFiles | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "PowerPoint video optimizasyonu tamamlandi!" -ForegroundColor Green
$wshShell = New-Object -ComObject WScript.Shell
$wshShell.Popup("PowerPoint video ve grafik ayarlari basariyla onarildi.", 0, "Onarim Tamamlandi", 64) | Out-Null