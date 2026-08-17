[Net.ServicePointManager]::SecurityProtocol = 3072
$webClient = New-Object System.Net.WebClient
Write-Host "Guncel indirme baglantisi araniyor..." -ForegroundColor Cyan
$targetUrl = "https://codecguide.com/download_k-lite_codec_pack_standard.htm"
$htmlContent = $webClient.DownloadString($targetUrl)
$regexPattern = 'https://files\d*\.codecguide\.com/K-Lite_Codec_Pack_\d+_Standard\.exe'
if ($htmlContent -match $regexPattern) {
    $downloadUrl = $matches[0]
}
$tempFolder = [System.IO.Path]::GetTempPath()
$installerPath = Join-Path $tempFolder "kLiteStandard.exe"
Write-Host "Dosya indiriliyor..." -ForegroundColor Yellow
$webClient.DownloadFile($downloadUrl, $installerPath)
Write-Host "Sessiz kurulum yapiliyor, lutfen bekleyin..." -ForegroundColor Yellow
$process = Start-Process -FilePath $installerPath -ArgumentList "/verysilent /norestart" -Wait -PassThru -NoNewWindow
Remove-Item -Path $installerPath -Force
Write-Host "Kurulum basariyla tamamlandi!" -ForegroundColor Green
$wshShell = New-Object -ComObject WScript.Shell
$wshShell.Popup("K-Lite Codec Pack Standard basariyla kuruldu.", 0, "Kurulum Tamamlandi", 64) | Out-Null