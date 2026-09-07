# Linuxino: Automatic Arduino Environment Setup on Linux

This project is called **Linuxino** and its goal is to automate the setup of the **Arduino** development environment on Linux distributions. It solves common problems such as the manual installation of dependencies, permission issues with device access, and the creation of **udev** rules to make it easier to interact with Arduino boards.

## Table of Contents
- [Linuxino: Automatic Arduino Environment Setup on Linux](#linuxino-automatic-arduino-environment-setup-on-linux)
  - [Table of Contents](#table-of-contents)
  - [Description](#description)
  - [Features](#features)
  - [Compatible Distributions](#compatible-distributions)
  - [Requirements](#requirements)
  - [Dependencies](#dependencies)
  - [Usage](#usage)
    - [Pre-Execution Steps](#pre-execution-steps)
    - [Execution](#execution)
    - [Expected Output](#expected-output)
    - [Applying Changes](#applying-changes)
  - [Script Changes](#script-changes)
    - [Package Installation](#package-installation)
    - [Dialout Group Access](#dialout-group-access)
    - [udev Rules Creation](#udev-rules-creation)
  - [Script Behavior](#script-behavior)
    - [Script Messages](#script-messages)
  - [Troubleshooting](#troubleshooting)
  - [Contributing](#contributing)
  - [License](#license)

## Description

This script automates the following tasks to configure an Arduino development environment on Linux:
- Installs essential dependencies like **gcc-avr**, **avr-libc**, **avrdude**, and **arduino-core**.
- Configures the current user to access serial devices (like Arduino boards) without needing manual permissions each time.
- Creates **udev** rules so that Arduino boards are automatically recognized by the system without requiring further adjustments.

This script is useful for anyone looking to avoid manual installation and specific configurations that can complicate using Arduino on Linux systems.

## Features

- **Multi-distribution support**: Works on Debian, Ubuntu, Arch Linux, openSUSE, and other distributions with compatible package managers.
- **Complete automation**: No manual configurations are needed as the script handles everything.
- **Clear messaging**: During execution, the script displays dynamic, user-friendly messages that indicate the progress of each task.
- **Error handling**: The script handles critical errors and provides clear feedback if something goes wrong during execution.

## Compatible Distributions

This script is compatible with the following Linux distributions:
- **Debian/Ubuntu** (and derivatives): Uses `apt-get` for package installation.
- **Arch Linux** (and derivatives like Manjaro): Uses `pacman` for package installation.
- **openSUSE**: Uses `zypper` for package installation.

For other distributions, it may be necessary to modify the script or manually install the dependencies.

## Requirements

- **Root access**: The script requires superuser permissions to install packages, modify user groups, and create udev rules.
- **Internet connection**: To download and install the required dependencies.

## Dependencies

The script will install the following dependencies:
- **gcc-avr**: AVR compiler.
- **avr-libc**: Standard AVR library for development.
- **avrdude**: Programming software for AVR microcontrollers.
- **arduino-core**: Essential tools for Arduino usage.
- **arduino**: The Arduino IDE (optional if using another tool).

## Usage

### Pre-Execution Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Guerra-666/Linuxino.git
   cd Linuxino
   ```

2. **Ensure you have root access**:
   You must run the script with superuser permissions (`sudo`) so that it can make all the necessary system changes.

### Execution

Run the script using `sudo`:

```bash
sudo ./Linuxino.sh
```

This command will begin the process of setting up the Arduino environment on your system.

### Expected Output

During execution, the script will display user-friendly messages about the tasks it is performing, for example:
- Detecting the Linux distribution.
- Installing the necessary dependencies.
- Configuring the `dialout` group to allow device access.
- Creating **udev** rules for automatic detection of Arduino boards.
- Reporting any errors or confirming that the setup was completed successfully.

### Applying Changes

Once the script finishes, you will need to log out and log back in for the changes related to the `dialout` group to take effect.

## Script Changes

### Package Installation

Depending on your Linux distribution, the script will automatically install the required packages using the corresponding package manager:

- For **Debian/Ubuntu**:
  ```bash
  apt-get update && apt-get Установить -y gcc-avr avr-libc avrdude arduino arduino-core
  ```
- For **Arch Linux**:
  ```bash
  pacman -Sy --noconfirm avr-gcc avr-libc avrdude arduino
  ```
- For **openSUSE**:
  ```bash
  zypper refresh && zypper Установить -y gcc-avr avr-libc avrdude arduino
  ```

### Dialout Group Access

The script adds the current user to the `dialout` group, allowing access to serial devices without additional permissions.

Command used:
```bash
usermod -aG dialout "$SUDO_USER"
```

This is important for interacting with boards like Arduino, as devices connected to serial ports (such as `/dev/ttyUSB0`) are usually associated with this group.

### udev Rules Creation

The **udev** rules created allow the system to automatically recognize Arduino boards connected to the USB port, assigning them the appropriate permissions.

The rules file is created in `/etc/udev/rules.d/99-arduino.rules` and includes entries like:
```bash
# Arduino Uno
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0043", MODE="0666", GROUP="dialout"
```

These rules ensure that Arduino boards have read and write permissions without requiring the user to manually adjust the device permissions.

## Script Behavior

During execution, the script:
- Detects the Linux distribution and installs the required packages.
- Adds the current user to the `dialout` group to allow communication with serial devices.
- Creates **udev** rules for Arduino boards to be automatically recognized when connected.

### Script Messages

The script displays dynamic, color-coded messages indicating the progress of each task:
- **Progress** messages are displayed in yellow.
- **Success** messages are displayed in green.
- **Error** messages are displayed in red, and the script stops if an error occurs.

## Troubleshooting

If the script fails or the changes do not take effect:
- Make sure you have logged out and back in after the script finishes so that the group changes take effect.
- If Arduino devices are not recognized, check that the **udev** rules were installed correctly in `/etc/udev/rules.d/`.
- Ensure that you are running the script with superuser permissions (using `sudo`).

## Contributing

Contributions are welcome. If you would like to improve the script or add support for other distributions, feel free to fork this repository and submit a pull request.

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT) - see the LICENSE file for details.

---
