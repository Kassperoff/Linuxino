#!/bin/bash

#==============================================================================
# LINUXINO - Automatic Arduino Environment Setup for Linux
# Version: 2.0
# Author: Guerra-666
# License: MIT
#==============================================================================

set -o pipefail

#==============================================================================
# COLOR AND STYLE CONFIGURATION
#==============================================================================
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

#==============================================================================
# GLOBAL VARIABLES
#==============================================================================
readonly SCRIPT_VERSION="2.0"
readonly LOG_FILE="/tmp/linuxino_$(date +%Y%m%d_%H%M%S).log"
readonly ERROR_FILE="/tmp/linuxino_errors.txt"
DISTRO_NAME=""
PACKAGE_MANAGER=""
ARDUINO_INSTALLED=false
TARGET_USER=""

# Determine the non-root user for group configuration and AUR helper execution
determine_target_user() {
    TARGET_USER="${SUDO_USER:-$USER}"
    if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
        # Fallback to get original user if running in sudo but SUDO_USER is root or empty
        local real_user=""
        real_user=$(logname 2>/dev/null || echo "$USER")
        if [ "$real_user" = "root" ]; then
            # If still root, check who is logged in or home directory owners
            real_user=$(who | awk '{print $1}' | head -n 1)
            if [ -z "$real_user" ] || [ "$real_user" = "root" ]; then
                real_user=$(ls -1d /home/* 2>/dev/null | grep -v "/home/shared" | head -n 1 | cut -d'/' -f3)
            fi
        fi
        TARGET_USER="${real_user:-root}"
    fi
    
    # Allow manual override if target user is still root
    if [ "$TARGET_USER" = "root" ]; then
        warning_msg "Could not automatically determine non-root user."
        read -p "$(echo -e ${CYAN}Enter username:${NC} )" TARGET_USER || TARGET_USER="root"
    fi
    log "Target user determined: $TARGET_USER"
}

#==============================================================================
# ASCII INTERFACE FUNCTIONS
#==============================================================================

# Main script banner
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║   ██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗██╗███╗   ██╗ ██████╗            ║
║   ██║     ██║████╗  ██║██║   ██║╚██╗██╔╝██║████╗  ██║██╔═══██╗           ║
║   ██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝ ██║██╔██╗ ██║██║   ██║           ║
║   ██║     ██║██║╚██╗██║██║   ██║ ██╔██╗ ██║██║╚██╗██║██║   ██║           ║
║   ███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗██║██║ ╚████║╚██████╔╝           ║
║   ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝            ║
║                                                                           ║
║              Automatic Arduino Environment Setup                         ║
║                         Version: 2.0                                     ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Visual separator
print_separator() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
}

# Box for important messages
print_box() {
    local message="$1"
    local color="${2:-$CYAN}"
    echo -e "${color}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${color}║ ${BOLD}${message}${NC}"
    echo -e "${color}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Progress bar
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))
    
    printf "\r${CYAN}[${NC}"
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "${CYAN}] ${BOLD}%3d%%${NC}" $percentage
}

#==============================================================================
# LOGGING AND MESSAGING FUNCTIONS
#==============================================================================

# Log to file
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# Success message
success_msg() {
    echo -e "${GREEN}${BOLD}[✔]${NC} ${GREEN}$1${NC}"
    log "SUCCESS: $1"
}

# Info message
info_msg() {
    echo -e "${YELLOW}${BOLD}[➤]${NC} ${YELLOW}$1${NC}"
    log "INFO: $1"
}

# Warning message
warning_msg() {
    echo -e "${MAGENTA}${BOLD}[⚠]${NC} ${MAGENTA}$1${NC}"
    log "WARNING: $1"
}

# Error message (without exit)
error_msg_soft() {
    echo -e "${RED}${BOLD}[✘]${NC} ${RED}$1${NC}"
    log "ERROR: $1"
}

# Error message (with exit)
# Error message (with exit and diagnostics)
error_msg() {
    local message="$1"
    local line_num="${2:-Unknown}"
    local failed_cmd="${3:-Unknown}"
    
    # Deactivate the trap temporarily to prevent recursion
    trap - ERR
    
    echo -e "\n${RED}${BOLD}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}${BOLD}║                     FATAL ERROR DETECTED                                  ║${NC}"
    echo -e "${RED}${BOLD}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${RED}${BOLD}[✘] Message:${NC} $message"
    
    if [[ "$line_num" != "Unknown" ]]; then
        echo -e "${RED}${BOLD}[✘] Line Number in Script:${NC} $line_num"
    fi
    if [[ "$failed_cmd" != "Unknown" ]]; then
        echo -e "${RED}${BOLD}[✘] Failed Command:${NC} $failed_cmd"
    fi
    
    log "FATAL ERROR: $message (Line: $line_num, Command: $failed_cmd)"
    
    echo -e "\n${YELLOW}${BOLD}📄 Last 15 log entries (from $LOG_FILE):${NC}"
    print_separator
    if [ -f "$LOG_FILE" ]; then
        tail -n 15 "$LOG_FILE" | sed 's/^/  /'
    else
        echo -e "  Log file not found."
    fi
    print_separator
    
    echo -e "\n${CYAN}${BOLD}💡 Troubleshooting Suggestions:${NC}"
    if [[ "$failed_cmd" == *"pacman"* || "$failed_cmd" == *"apt"* || "$failed_cmd" == *"dnf"* || "$failed_cmd" == *"yum"* || "$failed_cmd" == *"zypper"* ]]; then
        echo -e "  1. Verify your Internet connection (ping google.com)."
        echo -e "  2. Ensure no other package manager or GUI software center is running (checks for lock files)."
        echo -e "  3. If on Arch Linux, try running 'sudo pacman -Syu' first to sync the database."
    elif [[ "$failed_cmd" == *"udevadm"* || "$failed_cmd" == *"/etc/udev/"* ]]; then
        echo -e "  1. Ensure the system partition is not mounted read-only."
        echo -e "  2. Check if the directory /etc/udev/rules.d/ exists and has correct permissions."
    elif [[ "$failed_cmd" == *"usermod"* || "$failed_cmd" == *"groupadd"* ]]; then
        echo -e "  1. Verify that user '$TARGET_USER' and group exist on the system."
        echo -e "  2. Check if user database files like /etc/passwd or /etc/group are locked or read-only."
    else
        echo -e "  1. Make sure you are running the script with sudo privileges (root)."
        echo -e "  2. Ensure you have enough disk space."
        echo -e "  3. Review the complete log for more details at: $LOG_FILE"
    fi
    
    echo -e "\n${RED}${BOLD}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}${BOLD}║  Script terminated. Please resolve the issue and try again.               ║${NC}"
    echo -e "${RED}${BOLD}╚═══════════════════════════════════════════════════════════════════════════╝${NC}\n"
    
    exit 1
}

# Trap unexpected command errors
trap 'error_msg "Unexpected command failure" "$LINENO" "$BASH_COMMAND"' ERR

#==============================================================================
# VALIDATION FUNCTIONS
#==============================================================================

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if a package is installed on the system
package_is_installed() {
    local pkg="$1"
    case "$PACKAGE_MANAGER" in
        apt)
            dpkg -l | grep -q "\b${pkg}\b" 2>/dev/null
            ;;
        dnf|yum)
            rpm -q "$pkg" >/dev/null 2>&1
            ;;
        pacman)
            pacman -Qs "^${pkg}$" >/dev/null 2>&1
            ;;
        zypper)
            rpm -q "$pkg" >/dev/null 2>&1
            ;;
        portage)
            equery list "$pkg" >/dev/null 2>&1
            ;;
        *)
            false
            ;;
    esac
}

# Check root access
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_msg "This script must be run with root privileges (sudo)"
    fi
    success_msg "Administrator privileges verified"
}

# Check Internet connection
check_internet() {
    info_msg "Checking Internet connection..."
    if ping -c 1 -W 3 8.8.8.8 &>/dev/null || ping -c 1 -W 3 1.1.1.1 &>/dev/null; then
        success_msg "Internet connection verified"
        return 0
    else
        warning_msg "No Internet connection detected. Some functions may fail"
        return 1
    fi
}

#==============================================================================
# USER INTERACTION FUNCTIONS
#==============================================================================

# Request user confirmation
prompt_user() {
    local message="$1"
    local default="${2:-y}"
    
    if [[ "$default" == "y" ]]; then
        read -p "$(echo -e ${CYAN}${BOLD}[?]${NC} ${message} ${BOLD}[Y/n]:${NC} )" -n 1 -r
    else
        read -p "$(echo -e ${CYAN}${BOLD}[?]${NC} ${message} ${BOLD}[y/N]:${NC} )" -n 1 -r
    fi
    
    echo
    
    if [[ -z "$REPLY" ]]; then
        REPLY="$default"
    fi
    
    if [[ ! $REPLY =~ ^[YySs]$ ]]; then
        return 1
    fi
    return 0
}

# Show interactive menu
show_menu() {
    local -n menu_items=$1
    local title="$2"
    local selected=0
    
    print_box "$title" "$CYAN"
    echo
    
    for i in "${!menu_items[@]}"; do
        echo -e "${YELLOW}  [$((i+1))]${NC} ${menu_items[$i]}"
    done
    
    if ! read -p "$(echo -e ${CYAN}${BOLD}Select an option:${NC} )" selected; then
        selected="8"
    fi
    
    if [[ "$selected" =~ ^[0-9]+$ ]] && [ "$selected" -ge 1 ] && [ "$selected" -le "${#menu_items[@]}" ]; then
        return $((selected - 1))
    else
        return 255
    fi
}

#==============================================================================
# SYSTEM DETECTION
#==============================================================================

# Detect Linux distribution
detect_distro() {
    info_msg "Detecting Linux distribution..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_NAME="$NAME"
        
        if command_exists apt-get; then
            PACKAGE_MANAGER="apt"
            success_msg "Distribution detected: $DISTRO_NAME (APT)"
        elif command_exists dnf; then
            PACKAGE_MANAGER="dnf"
            success_msg "Distribution detected: $DISTRO_NAME (DNF)"
        elif command_exists yum; then
            PACKAGE_MANAGER="yum"
            success_msg "Distribution detected: $DISTRO_NAME (YUM)"
        elif command_exists pacman; then
            PACKAGE_MANAGER="pacman"
            success_msg "Distribution detected: $DISTRO_NAME (Pacman)"
        elif command_exists zypper; then
            PACKAGE_MANAGER="zypper"
            success_msg "Distribution detected: $DISTRO_NAME (Zypper)"
        elif command_exists emerge; then
            PACKAGE_MANAGER="portage"
            success_msg "Distribution detected: $DISTRO_NAME (Portage)"
        else
            error_msg "Unsupported package manager. Please install dependencies manually."
        fi
    else
        error_msg "Unable to detect Linux distribution"
    fi
}

# Detect connected Arduino devices
detect_arduino_devices() {
    info_msg "Searching for connected Arduino devices..."
    
    local devices=$(lsusb | grep -iE "arduino|2341|0403:6001|1a86:7523|10c4:ea60" || true)
    
    if [ -n "$devices" ]; then
        echo -e "\n${GREEN}${BOLD}Devices detected:${NC}"
        echo "$devices" | while IFS= read -r line; do
            echo -e "  ${CYAN}●${NC} $line"
        done
        echo
        return 0
    else
        warning_msg "No Arduino devices detected"
        return 1
    fi
}

#==============================================================================
# DEPENDENCY INSTALLATION
#==============================================================================

# Install dependencies according to package manager
install_dependencies() {
    print_separator
    print_box "ARDUINO DEPENDENCIES INSTALLATION" "$YELLOW"
    echo
    
    local packages=""
    local install_cmd=""
    local update_cmd=""
    
    case "$PACKAGE_MANAGER" in
        apt)
            update_cmd="apt-get update"
            install_cmd="apt-get install -y"
            packages="gcc-avr avr-libc avrdude arduino arduino-core binutils-avr gdb-avr"
            ;;
        dnf)
            update_cmd="dnf check-update || true"
            install_cmd="dnf install -y"
            packages="avr-gcc avr-libc avrdude arduino"
            ;;
        yum)
            update_cmd="yum check-update || true"
            install_cmd="yum install -y"
            packages="avr-gcc avr-libc avrdude arduino"
            ;;
        pacman)
            update_cmd="pacman -Sy"
            install_cmd="pacman -S --noconfirm"
            packages="avr-gcc avr-libc avrdude arduino-cli"
            ;;
        zypper)
            update_cmd="zypper refresh"
            install_cmd="zypper install -y"
            packages="gcc-avr avr-libc avrdude arduino"
            ;;
        portage)
            update_cmd="emerge --sync"
            install_cmd="emerge"
            packages="cross-avr/gcc cross-avr/avr-libc cross-avr/avrdude"
            ;;
        *)
            error_msg "Unsupported package manager: $PACKAGE_MANAGER"
            ;;
    esac
    
    info_msg "Updating repositories..."
    if eval "$update_cmd" >> "$LOG_FILE" 2>&1; then
        success_msg "Repositories updated"
    else
        warning_msg "Could not update repositories"
    fi
    
    echo
    info_msg "Installing packages: $packages"
    echo
    
    local pkg_array=($packages)
    local total=${#pkg_array[@]}
    local current=0
    
    for pkg in ${pkg_array[@]}; do
        current=$((current + 1))
        show_progress $current $total
        echo -ne " Installing: ${pkg}..."
        
        if eval "$install_cmd $pkg" >> "$LOG_FILE" 2>&1; then
            echo -e " ${GREEN}✔${NC}"
        else
            echo -e " ${RED}✘${NC}"
            warning_msg "Error installing $pkg."
            echo -e "${RED}Package Manager Error Context:${NC}"
            tail -n 5 "$LOG_FILE" | sed 's/^/  /'
            echo "$pkg" >> "$ERROR_FILE"
        fi
    done
    
    echo
    
    # Verify Arduino toolchain or IDE installation
    if command_exists arduino || command_exists arduino-cli; then
        ARDUINO_INSTALLED=true
        success_msg "Arduino CLI/IDE installed successfully"
    else
        warning_msg "Arduino compiler/toolchain was not installed correctly"
    fi

    # If on Arch Linux, offer to install graphical IDE from AUR if yay/paru is available
    if [ "$PACKAGE_MANAGER" = "pacman" ]; then
        echo
        info_msg "Arch Linux detected. The graphical Arduino IDE v2 is available in the AUR as 'arduino-ide-bin'."
        local aur_helper=""
        if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ]; then
            if command_exists yay; then
                aur_helper="yay"
            elif command_exists paru; then
                aur_helper="paru"
            fi
        fi
        
        if [ -n "$aur_helper" ]; then
            if prompt_user "Do you want to install 'arduino-ide-bin' from the AUR using $aur_helper?" "y"; then
                info_msg "Installing 'arduino-ide-bin' from AUR via $aur_helper. Please wait..."
                if sudo -u "$TARGET_USER" "$aur_helper" -S --noconfirm arduino-ide-bin >> "$LOG_FILE" 2>&1; then
                    success_msg "Arduino IDE installed successfully from AUR"
                    ARDUINO_INSTALLED=true
                else
                    echo -e " ${RED}✘${NC}"
                    warning_msg "Failed to install 'arduino-ide-bin' from AUR. You can try installing it manually: $aur_helper -S arduino-ide-bin"
                    echo "arduino-ide-bin" >> "$ERROR_FILE"
                fi
            fi
        else
            warning_msg "No AUR helper (yay or paru) detected, or script not run via sudo. To install the graphical IDE, run: yay -S arduino-ide-bin (as non-root user)"
        fi
    fi
    
    success_msg "Dependency installation process completed"
}

#==============================================================================
# PERMISSIONS CONFIGURATION
#==============================================================================

# Configure dialout group
configure_dialout() {
    print_separator
    print_box "DEVICE PERMISSIONS CONFIGURATION" "$YELLOW"
    echo
    
    info_msg "Checking dialout group..."
    
    if getent group dialout > /dev/null 2>&1; then
        success_msg "Dialout group exists"
    else
        info_msg "Creating dialout group..."
        if groupadd dialout >> "$LOG_FILE" 2>&1; then
            success_msg "Dialout group created"
        else
            error_msg "Error creating dialout group"
        fi
    fi
    
    # Use the globally determined target non-root user
    local target_user="$TARGET_USER"
    
    info_msg "Checking if user '$target_user' is in dialout group..."
    
    if groups "$target_user" | grep -q "\bdialout\b"; then
        success_msg "User '$target_user' is already in dialout group"
    else
        info_msg "Adding user '$target_user' to dialout group..."
        if usermod -aG dialout "$target_user" >> "$LOG_FILE" 2>&1; then
            success_msg "User '$target_user' added to dialout group"
        else
            error_msg "Error adding user to dialout group"
        fi
    fi
    
    # Add to other related groups
    for group in uucp lock tty; do
        if getent group "$group" > /dev/null 2>&1; then
            if ! groups "$target_user" | grep -q "\b$group\b"; then
                info_msg "Adding user '$target_user' to $group group..."
                usermod -aG "$group" "$target_user" >> "$LOG_FILE" 2>&1 || true
            fi
        fi
    done
    
    success_msg "Permissions configuration completed"
}

#==============================================================================
# UDEV RULES CONFIGURATION
#==============================================================================

# Create udev rules for Arduino
setup_udev_rules() {
    print_separator
    print_box "UDEV RULES CONFIGURATION" "$YELLOW"
    echo
    
    local udev_file="/etc/udev/rules.d/99-arduino.rules"
    
    info_msg "Creating udev rules for Arduino devices..."
    
    cat > "$udev_file" << 'EOF'
#==============================================================================
# UDEV Rules for Arduino Devices
# Generated by Linuxino
#==============================================================================

# Arduino Uno
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0043", MODE="0666", GROUP="dialout", SYMLINK+="arduino_uno"

# Arduino Uno (Rev3)
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0001", MODE="0666", GROUP="dialout", SYMLINK+="arduino_uno_rev3"

# Arduino Mega 2560
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0010", MODE="0666", GROUP="dialout", SYMLINK+="arduino_mega"
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0042", MODE="0666", GROUP="dialout", SYMLINK+="arduino_mega_rev3"

# Arduino Nano (FTDI)
SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE="0666", GROUP="dialout", SYMLINK+="arduino_nano_ftdi"

# Arduino Nano (CH340)
SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0666", GROUP="dialout", SYMLINK+="arduino_nano_ch340"

# Arduino Leonardo
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="8036", MODE="0666", GROUP="dialout", SYMLINK+="arduino_leonardo"
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0036", MODE="0666", GROUP="dialout", SYMLINK+="arduino_leonardo_bootloader"

# Arduino Micro
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="8037", MODE="0666", GROUP="dialout", SYMLINK+="arduino_micro"
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0037", MODE="0666", GROUP="dialout", SYMLINK+="arduino_micro_bootloader"

# Arduino Due
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="003d", MODE="0666", GROUP="dialout", SYMLINK+="arduino_due_programming"
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="003e", MODE="0666", GROUP="dialout", SYMLINK+="arduino_due"

# Arduino Yún
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0041", MODE="0666", GROUP="dialout", SYMLINK+="arduino_yun"
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="8041", MODE="0666", GROUP="dialout", SYMLINK+="arduino_yun_bootloader"

# Arduino Robot Control
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0038", MODE="0666", GROUP="dialout", SYMLINK+="arduino_robot_control"
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="8038", MODE="0666", GROUP="dialout", SYMLINK+="arduino_robot_control_bootloader"

# Arduino Robot Motor
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0039", MODE="0666", GROUP="dialout", SYMLINK+="arduino_robot_motor"
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="8039", MODE="0666", GROUP="dialout", SYMLINK+="arduino_robot_motor_bootloader"

# Arduino Genuino Mega 2560
SUBSYSTEM=="tty", ATTRS{idVendor}=="2a03", ATTRS{idProduct}=="0010", MODE="0666", GROUP="dialout", SYMLINK+="arduino_genuino_mega"
SUBSYSTEM=="tty", ATTRS{idVendor}=="2a03", ATTRS{idProduct}=="0042", MODE="0666", GROUP="dialout", SYMLINK+="arduino_genuino_mega_rev3"

# Arduino Genuino Uno
SUBSYSTEM=="tty", ATTRS{idVendor}=="2a03", ATTRS{idProduct}=="0043", MODE="0666", GROUP="dialout", SYMLINK+="arduino_genuino_uno"
SUBSYSTEM=="tty", ATTRS{idVendor}=="2a03", ATTRS{idProduct}=="0001", MODE="0666", GROUP="dialout", SYMLINK+="arduino_genuino_uno_rev3"

# Generic serial adapters (CP210x, PL2303, etc.)
SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666", GROUP="dialout"
SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", MODE="0666", GROUP="dialout"

EOF

    if [ -f "$udev_file" ]; then
        success_msg "Udev rules file created: $udev_file"
    else
        error_msg "Error creating udev rules file"
    fi
    
    info_msg "Reloading udev rules..."
    if udevadm control --reload-rules >> "$LOG_FILE" 2>&1 && udevadm trigger >> "$LOG_FILE" 2>&1; then
        success_msg "Udev rules reloaded successfully"
    else
        error_msg_soft "Error reloading udev rules"
        warning_msg "Try restarting the system to apply changes"
    fi
}

#==============================================================================
# BRLTTY DEACTIVATION
#==============================================================================

# Disable BRLTTY service
disable_brltty() {
    print_separator
    print_box "BRLTTY SERVICE MANAGEMENT" "$YELLOW"
    echo
    
    info_msg "BRLTTY is a service for braille terminals (visual accessibility)"
    info_msg "It may interfere with Arduino devices on some systems"
    echo
    
    if ! command_exists systemctl; then
        warning_msg "Systemctl not available, skipping BRLTTY check"
        return 0
    fi
    
    if systemctl list-unit-files | grep -q brltty; then
        if systemctl is-active --quiet brltty; then
            warning_msg "BRLTTY service is active"
            
            if prompt_user "Disable BRLTTY to avoid conflicts with Arduino?" "n"; then
                info_msg "Stopping BRLTTY service..."
                systemctl stop brltty >> "$LOG_FILE" 2>&1 || warning_msg "Could not stop BRLTTY service"
                
                info_msg "Disabling BRLTTY service..."
                systemctl disable brltty >> "$LOG_FILE" 2>&1 || warning_msg "Could not disable BRLTTY service"
                
                # Mask the service to prevent accidental start
                systemctl mask brltty >> "$LOG_FILE" 2>&1 || warning_msg "Could not mask BRLTTY service"
                
                success_msg "BRLTTY service deactivation attempted"
            else
                info_msg "BRLTTY remains active (may cause conflicts)"
            fi
        else
            success_msg "BRLTTY is inactive"
        fi
    else
        success_msg "BRLTTY is not installed on the system"
    fi
}

#==============================================================================
# VERIFICATION AND DIAGNOSTICS
#==============================================================================

# Verify complete installation
verify_installation() {
    print_separator
    print_box "INSTALLATION VERIFICATION" "$CYAN"
    echo
    
    local all_ok=true
    
    # Check essential commands/packages
    local components=("avr-gcc" "avr-libc" "avrdude")
    
    for comp in "${components[@]}"; do
        if command_exists "$comp" || package_is_installed "$comp"; then
            echo -e "  ${GREEN}✔${NC} $comp installed"
        else
            echo -e "  ${RED}✘${NC} $comp NOT installed"
            all_ok=false
        fi
    done
    
    # Check dialout group
    if groups "$TARGET_USER" 2>/dev/null | grep -q "\bdialout\b"; then
        echo -e "  ${GREEN}✔${NC} User '$TARGET_USER' in dialout group"
    else
        echo -e "  ${RED}✘${NC} User '$TARGET_USER' NOT in dialout group"
        all_ok=false
    fi
    
    # Check udev rules
    if [ -f "/etc/udev/rules.d/99-arduino.rules" ]; then
        echo -e "  ${GREEN}✔${NC} Udev rules configured"
    else
        echo -e "  ${RED}✘${NC} Udev rules NOT configured"
        all_ok=false
    fi
    
    echo
    
    if $all_ok; then
        success_msg "All checks passed successfully"
    else
        warning_msg "Some checks failed. Review the log: $LOG_FILE"
    fi
}

# Show final summary
show_summary() {
    print_separator
    print_box "CONFIGURATION SUMMARY" "$GREEN"
    echo
    
    echo -e "${BOLD}System:${NC}"
    echo -e "  Distribution: ${CYAN}$DISTRO_NAME${NC}"
    echo -e "  Package manager: ${CYAN}$PACKAGE_MANAGER${NC}"
    echo
    
    echo -e "${BOLD}Installation:${NC}"
    if $ARDUINO_INSTALLED; then
        echo -e "  Arduino IDE: ${GREEN}✔ Installed${NC}"
    else
        echo -e "  Arduino IDE: ${RED}✘ Not installed${NC}"
    fi
    echo
    
    echo -e "${BOLD}Generated files:${NC}"
    echo -e "  Log: ${CYAN}$LOG_FILE${NC}"
    if [ -f "$ERROR_FILE" ]; then
        echo -e "  Errors: ${YELLOW}$ERROR_FILE${NC}"
    fi
    echo
    
    detect_arduino_devices
    
    print_separator
}

#==============================================================================
# MAIN MENU
#==============================================================================

# Show options menu
main_menu() {
    local options=(
        "Complete installation (recommended)"
        "Install dependencies only"
        "Configure permissions only (dialout)"
        "Configure udev rules only"
        "Disable BRLTTY"
        "Detect Arduino devices"
        "Verify installation"
        "Exit"
    )
    
    while true; do
        show_banner
        echo -e "${CYAN}${BOLD}Detected distribution:${NC} $DISTRO_NAME ($PACKAGE_MANAGER)"
        echo
        
        show_menu options "MAIN MENU"
        local choice=$?
        
        case $choice in
            0)  # Complete installation
                check_internet
                install_dependencies
                configure_dialout
                setup_udev_rules
                disable_brltty
                verify_installation
                show_summary
                
                echo
                print_box "CONFIGURATION COMPLETED!" "$GREEN"
                warning_msg "IMPORTANT: Log out and log back in to apply all changes"
                echo
                read -p "$(echo -e ${CYAN}Press ENTER to continue...${NC})" || true
                ;;
            1)  # Dependencies only
                check_internet
                install_dependencies
                read -p "$(echo -e ${CYAN}Press ENTER to continue...${NC})" || true
                ;;
            2)  # Permissions only
                configure_dialout
                read -p "$(echo -e ${CYAN}Press ENTER to continue...${NC})" || true
                ;;
            3)  # Udev only
                setup_udev_rules
                read -p "$(echo -e ${CYAN}Press ENTER to continue...${NC})" || true
                ;;
            4)  # BRLTTY
                disable_brltty
                read -p "$(echo -e ${CYAN}Press ENTER to continue...${NC})" || true
                ;;
            5)  # Detect devices
                detect_arduino_devices
                echo
                read -p "$(echo -e ${CYAN}Press ENTER to continue...${NC})" || true
                ;;
            6)  # Verify
                verify_installation
                echo
                read -p "$(echo -e ${CYAN}Press ENTER to continue...${NC})" || true
                ;;
            7|255)  # Exit
                print_box "See you soon!" "$CYAN"
                exit 0
                ;;
        esac
    done
}

#==============================================================================
# MAIN FUNCTION
#==============================================================================

main() {
    # Initialize log
    echo "=== LINUXINO LOG - $(date) ===" > "$LOG_FILE"
    
    # Clean up previous error file
    rm -f "$ERROR_FILE"
    
    # Determine the target non-root user
    determine_target_user
    
    # Initial checks
    check_root
    detect_distro
    
    # Show main menu
    main_menu
}

# Run script
main "$@"
