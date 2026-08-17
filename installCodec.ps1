$securityProtocol = [Net.ServicePointManager]::SecurityProtocol
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Write-Host "Guncel indirme baglantisi araniyor..." -ForegroundColor Cyan
$targetUrl = "https://codecguide.com/download_k-lite_codec_pack_standard.htm"
$pageContent = curl $targetUrl -UseBasicParsing
$downloadUrl = $pageContent.Links | Where-Object { $_.href -match "https://files.*\.codecguide\.com/K-Lite_Codec_Pack_.*_Standard\.exe" } | Select-Object -First 1 -ExpandProperty href
$tempFolder = $env:TEMP
$installerPath = "$tempFolder\kLiteStandard.exe"
Write-Host "Dosya indiriliyor..." -ForegroundColor Yellow
curl -Uri $downloadUrl -OutFile $installerPath
Write-Host "Sessiz kurulum yapiliyor, lutfen bekleyin..." -ForegroundColor Yellow
Start-Process -FilePath $installerPath -ArgumentList "/verysilent", "/norestart" -Wait -NoNewWindow
Remove-Item -Path $installerPath -Force
[Net.ServicePointManager]::SecurityProtocol = $securityProtocol
Write-Host "Kurulum basariyla tamamlandi!" -ForegroundColor Green
$wshShell = New-Object -ComObject WScript.Shell
$wshShell.Popup("K-Lite Codec Pack Standard basariyla kuruldu.", 0, "Kurulum Tamamlandi", 64) | Out-Null