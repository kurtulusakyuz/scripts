#!/bin/bash
set -e
echo "These apps and modules will be installed:"
echo " - Charles Proxy"
echo " - Waydroid"
echo " - waydroid_script: GApps, Magisk, libndk, Widevine, libhoudini"
echo " - Magisk Modules: LSPosed Zygisk, AlwaysTrustUserCerts, CertFixer, BetterKnownInstalled, Charles System Cert"
echo " - Xposed APKs: CorePatch, WaydroidNetworkSpoof"
echo ""
read -r -p "Do you want to proceed with the installation? (y/n): " userChoice < /dev/tty
if [[ "$userChoice" != "y" && "$userChoice" != "Y" ]]; then
    echo "Installation aborted by user."
    exit 0
fi
echo "Installing system dependencies and APT repositories..."
sudo apt-get update -qq
sudo apt-get install -y -qq curl wget ca-certificates software-properties-common git python3 python3-pip python3-venv adb lzip sqlite3 zip unzip openssl gpg iproute2
wget -qO - https://www.charlesproxy.com/packages/apt/PublicKey | sudo gpg --dearmor --yes -o /usr/share/keyrings/charles-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/charles-archive-keyring.gpg] https://www.charlesproxy.com/packages/apt/ charles-proxy main" | sudo tee /etc/apt/sources.list.d/charles.list > /dev/null
sudo curl -s https://repo.waydro.id/waydroid.gpg -o /usr/share/keyrings/waydroid-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/waydroid-archive-keyring.gpg] http://repo.waydro.id/ noble main" | sudo tee /etc/apt/sources.list.d/waydroid.list > /dev/null
sudo apt-get update -qq
sudo apt-get install -y -qq charles-proxy waydroid
echo "Launching Charles Proxy temporarily to generate Root CA..."
charles > /dev/null 2>&1 &
charlesPid=$!
charlesCertSource="$HOME/.charles/ca/charles-proxy-ssl-ca.pem"
loopWaitCount=0
while [ ! -f "$charlesCertSource" ] && [ $loopWaitCount -lt 15 ]; do
    sleep 1
    loopWaitCount=$((loopWaitCount + 1))
done
kill "$charlesPid" > /dev/null 2>&1 || pkill -f charles || true
detectCharlesPort() {
    local detectedPort=""
    if [ -f "$HOME/.charles.config" ]; then
        detectedPort=$(grep -oP '(?<=<port>)\d+(?=</port>)' "$HOME/.charles.config" | head -n 1)
    fi
    if [ -z "$detectedPort" ]; then
        detectedPort=$(ss -tlpn 2>/dev/null | grep -i "charles" | grep -oP '(?<=:)\d+(?=\s)' | head -n 1)
    fi
    if [ -z "$detectedPort" ]; then
        detectedPort="8888"
    fi
    echo "$detectedPort"
}
charlesProxyPort=$(detectCharlesPort)
echo "Detected Charles Proxy Port: $charlesProxyPort"
sudo waydroid init -s VANILLA -f
sudo systemctl restart waydroid-container
waitForContainerActive() {
    local maxWaitSeconds=30
    local elapsedSeconds=0
    while [ "$elapsedSeconds" -lt "$maxWaitSeconds" ]; do
        if systemctl is-active --quiet waydroid-container; then
            echo "waydroid-container service is active."
            return 0
        fi
        sleep 2
        elapsedSeconds=$((elapsedSeconds + 2))
    done
    echo "Warning: waydroid-container service did not become active in time."
    return 1
}
waitForContainerActive
workDir="$HOME/waydroid_workspace"
waydroidScriptDir="$workDir/waydroid_script"
modulesDir="$workDir/modules"
charlesModuleDir="$workDir/charles_module"
mkdir -p "$workDir" "$modulesDir" "$charlesModuleDir"
if [ ! -d "$waydroidScriptDir" ]; then
    git clone -q https://github.com/casualsnek/waydroid_script.git "$waydroidScriptDir"
fi
cd "$waydroidScriptDir"
python3 -m venv venv
./venv/bin/pip install -q -r requirements.txt
sudo ./venv/bin/python3 main.py install gapps
sudo ./venv/bin/python3 main.py install magisk
sudo ./venv/bin/python3 main.py install libndk
sudo ./venv/bin/python3 main.py install widevine
sudo ./venv/bin/python3 main.py install libhoudini
lsposedZip="$modulesDir/lsposedZygisk.zip"
curl -sSL "https://github.com/LSPosed/LSPosed/releases/download/v1.9.2/LSPosed-v1.9.2-7024-zygisk-release.zip" -o "$lsposedZip"
trustCertsZip="$modulesDir/alwaysTrustUserCerts.zip"
curl -sSL "https://github.com/NVISOsecurity/MagiskTrustUserCerts/releases/latest/download/AlwaysTrustUserCerts_v1.3.zip" -o "$trustCertsZip"
certFixerZip="$modulesDir/certFixer.zip"
curl -sSL "https://github.com/pwnlogs/cert-fixer/releases/download/v1.1/Cert-Fixer.zip" -o "$certFixerZip"
betterKnownZip="$modulesDir/betterKnownInstalled.zip"
curl -sSL "https://github.com/Pixel-Props/BetterKnownInstalled/releases/download/1500/BetterKnownInstalled-v1.5.0.zip" -o "$betterKnownZip"
corePatchApk="$modulesDir/corePatch.apk"
curl -sSL "https://github.com/LSPosed/CorePatch/releases/download/4.9/app-release.apk" -o "$corePatchApk"
waydroidSpoofApk="$modulesDir/waydroidNetworkSpoof.apk"
curl -sSL "https://github.com/arkaroy14/waydroid_network_spoof/releases/download/20260317-1.2.0/WaydroidNetworkSpoof-v1.2.0.apk" -o "$waydroidSpoofApk"
charlesModuleZip="$modulesDir/charlesSystemCert.zip"
if [ -f "$charlesCertSource" ]; then
    echo "Creating Charles Root CA Magisk Module (charles system cert)..."
    certHash=$(openssl x509 -inform PEM -subject_hash_old -in "$charlesCertSource" | head -n 1)
    mkdir -p "$charlesModuleDir/system/etc/security/cacerts"
    cp "$charlesCertSource" "$charlesModuleDir/system/etc/security/cacerts/${certHash}.0"
    printf "id=charles_system_cert\nname=Charles System Cert\nversion=1.0\nversionCode=1\nauthor=Script\ndescription=Charles Root CA system trust certificate module\n" > "$charlesModuleDir/module.prop"
    (cd "$charlesModuleDir" && zip -q -r "$charlesModuleZip" .)
fi
echo "Starting Waydroid session and waiting for Android boot completion..."
waydroid session start &
waitForWaydroidBoot() {
    local timeoutSeconds=90
    local elapsedSeconds=0
    while [ "$elapsedSeconds" -lt "$timeoutSeconds" ]; do
        local isBooted
        isBooted=$(waydroid shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)
        if [ "$isBooted" = "1" ]; then
            echo "Android boot completed successfully."
            return 0
        fi
        sleep 3
        elapsedSeconds=$((elapsedSeconds + 3))
    done
    echo "Warning: Boot verification timed out. Proceeding with caution..."
    return 1
}
waitForWaydroidBoot
installMagiskModule() {
    local targetModule="$1"
    local moduleName="$2"
    if [ -f "$targetModule" ]; then
        echo "Installing Magisk module: $moduleName..."
        waydroid shell magisk --install-module "$targetModule"
    fi
}
installMagiskModule "$lsposedZip" "LSPosed (Zygisk)"
installMagiskModule "$trustCertsZip" "AlwaysTrustUserCerts"
installMagiskModule "$certFixerZip" "Cert-Fixer"
installMagiskModule "$betterKnownZip" "BetterKnownInstalled"
installMagiskModule "$charlesModuleZip" "Charles System Cert"
if [ -f "$corePatchApk" ]; then
    echo "Installing Xposed APK: CorePatch..."
    waydroid app install "$corePatchApk"
fi
if [ -f "$waydroidSpoofApk" ]; then
    echo "Installing Xposed APK: WaydroidNetworkSpoof..."
    waydroid app install "$waydroidSpoofApk"
fi
hostGatewayIp="192.168.240.1"
echo "Configuring Android global HTTP proxy to ${hostGatewayIp}:${charlesProxyPort}..."
waydroid shell settings put global http_proxy "${hostGatewayIp}:${charlesProxyPort}"
echo ""
echo "=========================================================================="
echo "Waydroid, Magisk modules, Xposed mods and Charles Proxy configured successfully!"
echo "Please restart Waydroid (waydroid session stop) for all modules to activate."
echo "=========================================================================="