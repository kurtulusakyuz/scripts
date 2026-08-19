#!/bin/bash
set -e
echo "Optimized for Ubuntu 24.04 LTS"
read -r -p "Do you want to proceed with the installation? (y/n): " userChoice < /dev/tty
if [[ "$userChoice" != "y" && "$userChoice" != "Y" ]]; then
    echo "Installation aborted by user."
    exit 0
fi
sudo apt-get update -qq
sudo apt-get install -y -qq locales software-properties-common curl gnupg lsb-release git python3-pip build-essential cmake
sudo locale-gen en_US en_US.UTF-8 > /dev/null 2>&1
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8
sudo add-apt-repository universe -y > /dev/null 2>&1
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
sudo curl -sSL https://packages.osrfoundation.org/gazebo.gpg -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null
sudo apt-get update -qq
sudo apt-get install -y -qq ros-jazzy-desktop ros-dev-tools python3-colcon-common-extensions python3-rosdep gz-harmonic ros-jazzy-ros-gz
sudo rosdep init > /dev/null 2>&1 || true
rosdep update -q
baseWorkDir="$HOME/ardupilot_sim"
ardupilotDir="$baseWorkDir/ardupilot"
ardupilotGazeboDir="$baseWorkDir/ardupilot_gazebo"
sitlModelsDir="$baseWorkDir/SITL_Models"
mkdir -p "$baseWorkDir"
if [ ! -d "$ardupilotDir" ]; then
    git clone --recurse-submodules -q https://github.com/ArduPilot/ardupilot.git "$ardupilotDir"
fi
cd "$ardupilotDir"
USER=root Tools/environment_install/install-prereqs-ubuntu.sh -y > /dev/null 2>&1 || Tools/environment_install/install-prereqs-ubuntu.sh -y > /dev/null 2>&1
if [ ! -d "$ardupilotGazeboDir" ]; then
    git clone -q https://github.com/ArduPilot/ardupilot_gazebo.git "$ardupilotGazeboDir"
fi
mkdir -p "$ardupilotGazeboDir/build"
cd "$ardupilotGazeboDir/build"
cmake .. -DGZ_VERSION=harmonic > /dev/null 2>&1
make -j$(nproc) > /dev/null 2>&1
sudo make install > /dev/null 2>&1
if [ ! -d "$sitlModelsDir" ]; then
    git clone -q https://github.com/ArduPilot/SITL_Models.git "$sitlModelsDir"
fi
applyShellConfig() {
    local targetRc="$1"
    local shellExt="$2"
    if [ -f "$targetRc" ]; then
        if ! grep -q "ros/jazzy" "$targetRc"; then
            echo "" >> "$targetRc"
            echo "source /opt/ros/jazzy/setup.$shellExt" >> "$targetRc"
            echo "export PATH=\$HOME/ardupilot_sim/ardupilot/Tools/autotest:\$PATH" >> "$targetRc"
            echo "export PATH=/usr/lib/ccache:\$PATH" >> "$targetRc"
            echo "export GZ_VERSION=harmonic" >> "$targetRc"
            echo "export GZ_SIM_SYSTEM_PLUGIN_PATH=\$HOME/ardupilot_sim/ardupilot_gazebo/build:\$GZ_SIM_SYSTEM_PLUGIN_PATH" >> "$targetRc"
            echo "export GZ_SIM_RESOURCE_PATH=\$HOME/ardupilot_sim/SITL_Models/Gazebo/models:\$HOME/ardupilot_sim/SITL_Models/Gazebo/worlds:\$GZ_SIM_RESOURCE_PATH" >> "$targetRc"
        fi
    fi
}
applyShellConfig "$HOME/.bashrc" "bash"
applyShellConfig "$HOME/.zshrc" "zsh"
echo "Installation completed successfully."