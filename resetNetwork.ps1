Write-Host "DNS onbellegi temizleniyor..." -ForegroundColor Cyan
ipconfig /flushdns | Out-Null
Write-Host "Winsock katalogu sifirlaniyor..." -ForegroundColor Cyan
netsh winsock reset | Out-Null
Write-Host "TCP/IP protokolu sifirlaniyor..." -ForegroundColor Cyan
netsh int ip reset | Out-Null
netsh int ipv6 reset | Out-Null
Write-Host "ARP onbellegi temizleniyor..." -ForegroundColor Cyan
netsh interface ip delete arpcache | Out-Null
Write-Host "Ag ayarlari basariyla sifirlandi!" -ForegroundColor Green
$wshShell = New-Object -ComObject WScript.Shell
$wshShell.Popup("Ag ve DNS protokolleri sifirlandi. Degisikliklerin tam gecerli olmasi icin bilgisayari yeniden baslatmaniz onerilir.", 0, "Ag Sifirlama Tamamlandi", 64) | Out-Null