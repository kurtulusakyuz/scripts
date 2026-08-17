$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation"
Write-Host "Dual-boot saat uyusmazligi duzeltiliyor (UTC BIOS modu)..." -ForegroundColor Cyan
Set-ItemProperty -Path $regPath -Name "RealTimeIsUniversal" -Value 1 -Type DWord -Force
Start-Service -Name "w32time" -ErrorAction SilentlyContinue
w32tm /resync /force | Out-Null
Write-Host "Saat ayari basariyla yapilandirildi!" -ForegroundColor Green
$wshShell = New-Object -ComObject WScript.Shell
$wshShell.Popup("Dual-boot saat senkronizasyonu ayarlandi. BIOS saati artik UTC olarak okunacak.", 0, "Saat Ayari Tamamlandi", 64) | Out-Null