# Linuxino: Automatic Arduino Environment Setup on Linux

```
╔═══════════════════════════════════════════════════════════════════════════╗
║   ██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗██╗███╗   ██╗ ██████╗            ║
║   ██║     ██║████╗  ██║██║   ██║╚██╗██╔╝██║████╗  ██║██╔═══██╗           ║
║   ██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝ ██║██╔██╗ ██║██║   ██║           ║
║   ██║     ██║██║╚██╗██║██║   ██║ ██╔██╗ ██║██║╚██╗██║██║   ██║           ║
║   ███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗██║██║ ╚████║╚██████╔╝           ║
║   ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝            ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

**Linuxino** is a comprehensive automated script designed to simplify and streamline the setup of the **Arduino** development environment across multiple **Linux** distributions. It eliminates the hassle of manual dependency installation, permission configuration, and udev rules setup.

## ✨ What's New in Version 2.0

- 🎨 **Beautiful ASCII Interface** with visual progress bars
- 📋 **Interactive Menu System** with 8 different options
- 🔍 **Automatic Arduino Device Detection** 
- 📊 **Real-time Progress Indicators** during installation
- 📝 **Comprehensive Logging System** for troubleshooting
- ✅ **Installation Verification** tools
- 🌐 **Extended Distribution Support** (DNF, YUM, Portage)
- 🔧 **Modular Execution** - run specific tasks without full installation
- 🛡️ **Enhanced Error Handling** with detailed logs

## Table of Contents
- [Description](#description)
- [Features](#features)
- [Compatible Distributions](#compatible-distributions)
- [Requirements](#requirements)
- [Dependencies](#dependencies)
- [Usage](#usage)
  - [Quick Start](#quick-start)
  - [Interactive Menu](#interactive-menu)
- [What the Script Does](#what-the-script-does)
  - [Package Installation](#package-installation)
  - [Permissions Configuration](#permissions-configuration)
  - [udev Rules Creation](#udev-rules-creation)
  - [BRLTTY Management](#brltty-management)
- [Supported Arduino Boards](#supported-arduino-boards)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Description

**Linuxino** is a powerful automation tool that handles the complete Arduino development environment setup on Linux systems. It tackles the most common issues developers face:

- 🔧 **Automated dependency installation** for AVR toolchain and Arduino IDE
- 🔐 **Automatic permission configuration** for serial device access
- 📡 **Smart udev rules creation** for automatic Arduino board recognition
- 🚫 **BRLTTY conflict resolution** to prevent interference with Arduino devices
- 🔍 **Device detection** to verify connected Arduino hardware
- 📊 **Installation verification** to ensure everything works correctly

## Features

### Core Features
- **🌍 Multi-distribution support**: Debian, Ubuntu, Fedora, Arch Linux, openSUSE, Gentoo, and derivatives
- **🤖 Full automation**: Zero manual configuration required
- **🎨 Beautiful ASCII interface**: Professional-looking menus and progress indicators
- **📊 Real-time feedback**: Visual progress bars during package installation
- **📝 Comprehensive logging**: Detailed logs saved to `/tmp/` for troubleshooting
- **🔒 Robust error handling**: Graceful degradation with detailed error reporting
- **🎯 Modular execution**: Run only the components you need

### Advanced Features
- **Interactive menu system** with 8 different operational modes
- **Automatic hardware detection** for connected Arduino devices
- **Multiple group management** (dialout, uucp, lock, tty)
- **Extended board support** including clones with CH340, CP210x, PL2303 chips
- **Automatic symlink creation** for easier device identification
- **Internet connectivity check** before attempting downloads
- **Installation verification tools** to confirm successful setup

## Compatible Distributions

Linuxino automatically detects your distribution and uses the appropriate package manager:

| Distribution Family | Package Manager | Status |
|---------------------|----------------|---------|
| Debian/Ubuntu/Mint | `apt-get` | ✅ Fully Supported |
| Fedora | `dnf` | ✅ Fully Supported |
| RHEL/CentOS | `yum` | ✅ Fully Supported |
| Arch/Manjaro/EndeavourOS | `pacman` | ✅ Fully Supported |
| openSUSE/SLES | `zypper` | ✅ Fully Supported |
| Gentoo | `portage/emerge` | ✅ Fully Supported |

Other distributions may work with manual dependency installation.

## Requirements

- ✅ **Root/sudo access**: Required for system modifications
- ✅ **Internet connection**: For downloading packages (checked automatically)
- ✅ **Modern Linux distribution**: From the supported list above
- ✅ **Terminal emulator**: Supporting ANSI color codes for best experience

## Dependencies

The script automatically installs the following packages (varies by distribution):

### Essential Packages
- **gcc-avr** / **avr-gcc**: AVR cross-compiler for Arduino development
- **avr-libc**: Standard C library for AVR microcontrollers
- **avrdude**: Tool for uploading code to Arduino boards
- **arduino**: The official Arduino IDE

### Additional Tools (where available)
- **arduino-core**: Core Arduino development tools
- **arduino-avr-core**: AVR board definitions for Arduino
- **binutils-avr**: AVR binary utilities
- **gdb-avr**: GNU debugger for AVR (debugging support)

## Usage

### Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Guerra-666/Linuxino.git
   cd Linuxino
   ```

2. **Make the script executable** (if needed):
   ```bash
   chmod +x Linuxino.sh
   ```

3. **Run with sudo**:
   ```bash
   sudo ./Linuxino.sh
   ```

### Interactive Menu

Upon running, you'll see a beautiful ASCII banner and interactive menu:

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                          MAIN MENU                                        ║
╚═══════════════════════════════════════════════════════════════════════════╝

  [1] Complete installation (recommended)
  [2] Install dependencies only
  [3] Configure permissions only (dialout)
  [4] Configure udev rules only
  [5] Disable BRLTTY
  [6] Detect Arduino devices
  [7] Verify installation
  [8] Exit
```

#### Menu Options Explained

1. **Complete installation** - Performs all setup steps automatically (recommended for first-time users)
2. **Install dependencies only** - Only installs Arduino packages without configuring permissions
3. **Configure permissions only** - Adds user to dialout and related groups
4. **Configure udev rules only** - Creates rules for automatic Arduino detection
5. **Disable BRLTTY** - Stops and masks the BRLTTY service if it's causing conflicts
6. **Detect Arduino devices** - Scans and displays connected Arduino boards
7. **Verify installation** - Checks if everything is properly installed
8. **Exit** - Quit the script

### Applying Changes

**Important**: After installation, log out and log back in to apply group membership changes:

```bash
# Or reboot your system
sudo reboot
```

## What the Script Does

### Package Installation

The script detects your distribution and uses the appropriate package manager with optimized commands:

**APT (Debian/Ubuntu)**:
```bash
apt-get update
apt-get install -y gcc-avr avr-libc avrdude arduino arduino-core binutils-avr gdb-avr
```

**Pacman (Arch Linux)**:
```bash
pacman -Sy --noconfirm avr-gcc avr-libc avrdude arduino arduino-avr-core
```

**DNF (Fedora)**:
```bash
dnf install -y avr-gcc avr-libc avrdude arduino
```

**Zypper (openSUSE)**:
```bash
zypper refresh && zypper install -y gcc-avr avr-libc avrdude arduino
```

**Portage (Gentoo)**:
```bash
emerge cross-avr/gcc cross-avr/avr-libc cross-avr/avrdude
```

### Permissions Configuration

The script adds your user to multiple groups for comprehensive device access:

```bash
usermod -aG dialout $USER    # Primary group for serial devices
usermod -aG uucp $USER       # Unix-to-Unix Copy (serial communication)
usermod -aG lock $USER       # Lock file access
usermod -aG tty $USER        # TTY device access
```

### udev Rules Creation

Creates comprehensive udev rules at `/etc/udev/rules.d/99-arduino.rules` with support for:

- ✅ Arduino Uno (original and clones)
- ✅ Arduino Mega 2560
- ✅ Arduino Nano (FTDI and CH340 variants)
- ✅ Arduino Leonardo
- ✅ Arduino Micro
- ✅ Arduino Due
- ✅ Arduino Yún
- ✅ Arduino Robot Control/Motor
- ✅ Generic serial adapters (CP210x, PL2303, CH340)

Each rule creates automatic symlinks for easy identification:
```bash
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0043", 
MODE="0666", GROUP="dialout", SYMLINK+="arduino_uno"
```

### BRLTTY Management

BRLTTY (braille display service) can conflict with Arduino. The script offers to:
- Stop the service
- Disable it from auto-starting
- Mask it to prevent accidental activation

## Supported Arduino Boards

Linuxino includes udev rules for:

| Board Type | Chip Variants | Symlink Created |
|------------|---------------|-----------------|
| Arduino Uno | Original, Rev3 | `/dev/arduino_uno` |
| Arduino Mega 2560 | Original, Rev3, Genuino | `/dev/arduino_mega` |
| Arduino Nano | FTDI, CH340 | `/dev/arduino_nano_*` |
| Arduino Leonardo | All variants | `/dev/arduino_leonardo` |
| Arduino Micro | All variants | `/dev/arduino_micro` |
| Arduino Due | Programming & Native | `/dev/arduino_due` |
| Arduino Yún | All variants | `/dev/arduino_yun` |

Plus generic support for common USB-to-Serial chips!

## Troubleshooting

### Common Issues

**Issue**: Arduino not detected after installation
```bash
# Check if device is connected
lsusb | grep -i arduino

# Check if udev rules are loaded
cat /etc/udev/rules.d/99-arduino.rules

# Reload rules manually
sudo udevadm control --reload-rules && sudo udevadm trigger
```

**Issue**: Permission denied when accessing Arduino
```bash
# Verify group membership
groups $USER | grep dialout

# If not in group, you need to log out and back in
```

**Issue**: BRLTTY keeps interfering
```bash
# Verify BRLTTY status
systemctl status brltty

# Manually mask it
sudo systemctl mask brltty
```

### Logs and Diagnostics

All operations are logged to `/tmp/linuxino_YYYYMMDD_HHMMSS.log`

View the log:
```bash
cat /tmp/linuxino_*.log
```

Check for errors:
```bash
grep ERROR /tmp/linuxino_*.log
```

### Getting Help

If you encounter issues:
1. Check the log file in `/tmp/`
2. Run the verification option from the menu
3. Open an issue on GitHub with the log contents

## Contributing

Contributions are welcome. If you would like to improve the script or add support for other distributions, feel free to fork this repository and submit a pull request.

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT) - see the LICENSE file for details.

---
