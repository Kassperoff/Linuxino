#!/bin/bash

# Colors for messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No color

# Function to print success messages
success_msg() {
    echo -e "${GREEN}[✔] $1${NC}"
}

# Function to print progress messages
info_msg() {
    echo -e "${YELLOW}[➤] $1...${NC}"
}

# Function to print error messages
error_msg() {
    echo -e "${RED}[✘] $1${NC}"
    exit 1
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to ask for user confirmation
prompt_user() {
    read -p "$1 (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error_msg "Operation cancelled by the user."
    fi
}

# Función para desactivar BRLTTY si es necesario
disable_brltty() {
    info_msg "El servicio BRLTTY es para dispositivos de asistencia para personas con discapacidad visual (como terminales braille). A veces puede interferir con dispositivos Arduino."

    prompt_user "¿Disable BRLTTY to avoid conflicts with arduino?"
    
    if systemctl is-active --quiet brltty; then
        systemctl disable brltty && systemctl stop brltty
        success_msg "BRLTTY has been disable."
    else
        info_msg "BRLTTY are disable or its not installed."
    fi
}


# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error_msg "This script must be run as root"
fi

# Install dependencies
install_dependencies() {
    info_msg "Detecting Linux distribution"

    if command_exists apt-get; then
        info_msg "Installing dependencies on Debian/Ubuntu-based distributions"
        apt-get update && apt-get install -y gcc-avr avr-libc avrdude arduino arduino-core || error_msg "Error installing dependencies with apt-get"
    elif command_exists pacman; then
        info_msg "Installing dependencies on Arch Linux-based distributions"
        pacman -Sy --noconfirm avr-gcc avr-libc avrdude arduino || error_msg "Error installing dependencies with pacman"
    elif command_exists zypper; then
        info_msg "Installing dependencies on SUSE-based distributions"
        zypper refresh && zypper install -y gcc-avr avr-libc avrdude arduino || error_msg "Error installing dependencies with zypper"
    else
        error_msg "Unsupported package manager. Please install dependencies manually."
    fi
    success_msg "Dependencies successfully installed"
}

# Configure access to dialout group
configure_dialout() {
    info_msg "Configuring access to dialout group"
    
    if grep -q dialout /etc/group; then
        info_msg "Dialout group already exists"
    else
        prompt_user "Dialout group doesn't exist. Do you want to create it?"
        info_msg "Creating dialout group"
        groupadd dialout || error_msg "Error creating dialout group"
    fi

    prompt_user "Do you want to add the current user to the dialout group?"
    info_msg "Adding current user to dialout group"
    usermod -aG dialout "$SUDO_USER" || error_msg "Error adding user to dialout group"
    
    success_msg "User has been added to the dialout group"
}

# Create udev rules
setup_udev_rules() {
    info_msg "Creating udev rules for Arduino"

    cat <<EOF > /etc/udev/rules.d/99-arduino.rules
# Arduino Uno
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0043", MODE="0666", GROUP="dialout"
# Arduino Mega 2560
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0010", MODE="0666", GROUP="dialout"
# Arduino Nano
SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE="0666", GROUP="dialout"
EOF

    success_msg "Udev rules created for Arduino"
    
    info_msg "Reloading udev rules"
    udevadm control --reload-rules && udevadm trigger || error_msg "Error reloading udev rules"
    success_msg "Udev rules successfully reloaded"
}

# Main
info_msg "Starting Arduino setup on Linux"

prompt_user "Do you want to continue with dependency installation?"
install_dependencies

prompt_user "Do you want to configure access to the dialout group?"
configure_dialout

prompt_user "Do you want to create udev rules for Arduino?"
setup_udev_rules

#BRLTTY
disable_brltty

success_msg "Setup complete. To apply changes, log out and log back in."
