#!/bin/bash

# Colores para los mensajes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # Sin color

# Función para imprimir mensajes de éxito
success_msg() {
    echo -e "${GREEN}[✔] $1${NC}"
}

# Función para imprimir mensajes de progreso
info_msg() {
    echo -e "${YELLOW}[➤] $1...${NC}"
}

# Función para imprimir mensajes de error
error_msg() {
    echo -e "${RED}[✘] $1${NC}"
    exit 1
}

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Función para pedir confirmación al usuario
prompt_user() {
    read -p "$1 (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error_msg "Operación cancelada por el usuario."
    fi
}

# Función para desactivar BRLTTY si es necesario
disable_brltty() {
    info_msg "El servicio BRLTTY es para dispositivos de asistencia para personas con discapacidad visual (como terminales braille). A veces puede interferir con dispositivos Arduino."

    prompt_user "¿Desea desactivar el servicio BRLTTY para evitar conflictos?"
    
    if systemctl is-active --quiet brltty; then
        systemctl disable brltty && systemctl stop brltty
        success_msg "BRLTTY ha sido deshabilitado."
    else
        info_msg "BRLTTY ya está deshabilitado o no está instalado."
    fi
}

# Verificar si se tiene acceso root
if [[ $EUID -ne 0 ]]; then
   error_msg "Este script debe ejecutarse como root"
fi

# Instalar dependencias
install_dependencies() {
    info_msg "Detectando distribución de Linux"

    if command_exists apt-get; then
        info_msg "Instalando dependencias en distribuciones basadas en Debian/Ubuntu"
        apt-get update && apt-get install -y gcc-avr avr-libc avrdude arduino arduino-core || error_msg "Error al instalar dependencias con apt-get"
    elif command_exists pacman; then
        info_msg "Instalando dependencias en distribuciones basadas en Arch Linux"
        pacman -Sy --noconfirm avr-gcc avr-libc avrdude arduino || error_msg "Error al instalar dependencias con pacman"
    elif command_exists zypper; then
        info_msg "Instalando dependencias en distribuciones basadas en SUSE"
        zypper refresh && zypper install -y gcc-avr avr-libc avrdude arduino || error_msg "Error al instalar dependencias con zypper"
    else
        error_msg "Gestor de paquetes no soportado. Instala manualmente las dependencias."
    fi
    success_msg "Dependencias instaladas correctamente"
}

# Configurar el acceso al grupo dialout
configure_dialout() {
    info_msg "Configurando acceso al grupo dialout"
    
    if grep -q dialout /etc/group; then
        info_msg "El grupo dialout ya existe"
    else
        prompt_user "El grupo dialout no existe. ¿Desea crearlo?"
        info_msg "Creando grupo dialout"
        groupadd dialout || error_msg "Error al crear el grupo dialout"
    fi

    prompt_user "¿Desea añadir el usuario actual al grupo dialout?"
    info_msg "Añadiendo al usuario actual al grupo dialout"
    usermod -aG dialout "$SUDO_USER" || error_msg "Error al añadir el usuario al grupo dialout"
    
    success_msg "El usuario ha sido añadido al grupo dialout"
}

# Crear las reglas udev
setup_udev_rules() {
    info_msg "Creando reglas udev para Arduino"

    cat <<EOF > /etc/udev/rules.d/99-arduino.rules
# Arduino Uno
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0043", MODE="0666", GROUP="dialout"
# Arduino Mega 2560
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0010", MODE="0666", GROUP="dialout"
# Arduino Nano
SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE="0666", GROUP="dialout"
EOF

    success_msg "Reglas udev creadas para Arduino"
    
    info_msg "Recargando reglas udev"
    udevadm control --reload-rules && udevadm trigger || error_msg "Error al recargar las reglas udev"
    success_msg "Reglas udev recargadas correctamente"
}

# Main
info_msg "Iniciando configuración de Arduino en Linux"

prompt_user "¿Desea continuar con la instalación de dependencias?"
install_dependencies

prompt_user "¿Desea configurar el acceso al grupo dialout?"
configure_dialout

prompt_user "¿Desea crear las reglas udev para Arduino?"
setup_udev_rules

# Preguntar si deshabilitar BRLTTY
disable_brltty

success_msg "Configuración completada. Para aplicar los cambios, cierra sesión y vuelve a iniciarla."
