#!/bin/bash

#==============================================================================
# LINUXINO - Configurador Automático de Entorno Arduino para Linux
# Versión: 2.0
# Autor: Guerra-666
# Licencia: MIT
#==============================================================================

set -o pipefail

#==============================================================================
# CONFIGURACIÓN DE COLORES Y ESTILOS
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
# VARIABLES GLOBALES
#==============================================================================
readonly SCRIPT_VERSION="2.0"
readonly LOG_FILE="/tmp/linuxino_$(date +%Y%m%d_%H%M%S).log"
readonly ERROR_FILE="/tmp/linuxino_errors.txt"
DISTRO_NAME=""
PACKAGE_MANAGER=""
ARDUINO_INSTALLED=false

#==============================================================================
# FUNCIONES DE INTERFAZ ASCII
#==============================================================================

# Banner principal del script
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
║              Configurador Automático de Entorno Arduino                  ║
║                         Versión: 2.0                                     ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Separador visual
print_separator() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
}

# Box para mensajes importantes
print_box() {
    local message="$1"
    local color="${2:-$CYAN}"
    echo -e "${color}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${color}║ ${BOLD}${message}${NC}"
    echo -e "${color}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Barra de progreso
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
# FUNCIONES DE LOGGING Y MENSAJES
#==============================================================================

# Logging a archivo
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# Mensaje de éxito
success_msg() {
    echo -e "${GREEN}${BOLD}[✔]${NC} ${GREEN}$1${NC}"
    log "SUCCESS: $1"
}

# Mensaje de información
info_msg() {
    echo -e "${YELLOW}${BOLD}[➤]${NC} ${YELLOW}$1${NC}"
    log "INFO: $1"
}

# Mensaje de advertencia
warning_msg() {
    echo -e "${MAGENTA}${BOLD}[⚠]${NC} ${MAGENTA}$1${NC}"
    log "WARNING: $1"
}

# Mensaje de error (sin salir)
error_msg_soft() {
    echo -e "${RED}${BOLD}[✘]${NC} ${RED}$1${NC}"
    log "ERROR: $1"
}

# Mensaje de error (con salida)
error_msg() {
    echo -e "${RED}${BOLD}[✘]${NC} ${RED}$1${NC}"
    log "FATAL ERROR: $1"
    echo -e "\n${RED}${BOLD}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}${BOLD}║  El script ha finalizado con errores. Revisa el log: ${LOG_FILE}${NC}"
    echo -e "${RED}${BOLD}╚═══════════════════════════════════════════════════════════════════════════╝${NC}\n"
    exit 1
}

#==============================================================================
# FUNCIONES DE VALIDACIÓN
#==============================================================================

# Verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verificar acceso root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_msg "Este script debe ejecutarse con privilegios de root (sudo)"
    fi
    success_msg "Privilegios de administrador verificados"
}

# Verificar conexión a Internet
check_internet() {
    info_msg "Verificando conexión a Internet..."
    if ping -c 1 -W 3 8.8.8.8 &>/dev/null || ping -c 1 -W 3 1.1.1.1 &>/dev/null; then
        success_msg "Conexión a Internet verificada"
        return 0
    else
        warning_msg "No se detectó conexión a Internet. Algunas funciones pueden fallar"
        return 1
    fi
}

#==============================================================================
# FUNCIONES DE INTERACCIÓN CON USUARIO
#==============================================================================

# Solicitar confirmación al usuario
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

# Mostrar menú interactivo
show_menu() {
    local -n menu_items=$1
    local title="$2"
    local selected=0
    
    print_box "$title" "$CYAN"
    echo
    
    for i in "${!menu_items[@]}"; do
        echo -e "${YELLOW}  [$((i+1))]${NC} ${menu_items[$i]}"
    done
    
    echo
    read -p "$(echo -e ${CYAN}${BOLD}Seleccione una opción:${NC} )" selected
    
    if [[ "$selected" =~ ^[0-9]+$ ]] && [ "$selected" -ge 1 ] && [ "$selected" -le "${#menu_items[@]}" ]; then
        return $((selected - 1))
    else
        return 255
    fi
}

#==============================================================================
# DETECCIÓN DE SISTEMA
#==============================================================================

# Detectar distribución de Linux
detect_distro() {
    info_msg "Detectando distribución de Linux..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_NAME="$NAME"
        
        if command_exists apt-get; then
            PACKAGE_MANAGER="apt"
            success_msg "Distribución detectada: $DISTRO_NAME (APT)"
        elif command_exists dnf; then
            PACKAGE_MANAGER="dnf"
            success_msg "Distribución detectada: $DISTRO_NAME (DNF)"
        elif command_exists yum; then
            PACKAGE_MANAGER="yum"
            success_msg "Distribución detectada: $DISTRO_NAME (YUM)"
        elif command_exists pacman; then
            PACKAGE_MANAGER="pacman"
            success_msg "Distribución detectada: $DISTRO_NAME (Pacman)"
        elif command_exists zypper; then
            PACKAGE_MANAGER="zypper"
            success_msg "Distribución detectada: $DISTRO_NAME (Zypper)"
        elif command_exists emerge; then
            PACKAGE_MANAGER="portage"
            success_msg "Distribución detectada: $DISTRO_NAME (Portage)"
        else
            error_msg "Gestor de paquetes no soportado. Por favor, instala las dependencias manualmente."
        fi
    else
        error_msg "No se pudo detectar la distribución de Linux"
    fi
}

# Detectar dispositivos Arduino conectados
detect_arduino_devices() {
    info_msg "Buscando dispositivos Arduino conectados..."
    
    local devices=$(lsusb | grep -iE "arduino|2341|0403:6001|1a86:7523|10c4:ea60" || true)
    
    if [ -n "$devices" ]; then
        echo -e "\n${GREEN}${BOLD}Dispositivos detectados:${NC}"
        echo "$devices" | while IFS= read -r line; do
            echo -e "  ${CYAN}●${NC} $line"
        done
        echo
        return 0
    else
        warning_msg "No se detectaron dispositivos Arduino conectados"
        return 1
    fi
}

#==============================================================================
# INSTALACIÓN DE DEPENDENCIAS
#==============================================================================

# Instalar dependencias según el gestor de paquetes
install_dependencies() {
    print_separator
    print_box "INSTALACIÓN DE DEPENDENCIAS ARDUINO" "$YELLOW"
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
            packages="avr-gcc avr-libc avrdude arduino arduino-avr-core"
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
            error_msg "Gestor de paquetes no soportado: $PACKAGE_MANAGER"
            ;;
    esac
    
    info_msg "Actualizando repositorios..."
    if eval "$update_cmd" >> "$LOG_FILE" 2>&1; then
        success_msg "Repositorios actualizados"
    else
        warning_msg "No se pudieron actualizar los repositorios"
    fi
    
    echo
    info_msg "Instalando paquetes: $packages"
    echo
    
    local pkg_array=($packages)
    local total=${#pkg_array[@]}
    local current=0
    
    for pkg in ${pkg_array[@]}; do
        current=$((current + 1))
        show_progress $current $total
        echo -ne " Instalando: ${pkg}..."
        
        if eval "$install_cmd $pkg" >> "$LOG_FILE" 2>&1; then
            echo -e " ${GREEN}✔${NC}"
        else
            echo -e " ${RED}✘${NC}"
            warning_msg "Error al instalar $pkg (continúa con el siguiente paquete)"
            echo "$pkg" >> "$ERROR_FILE"
        fi
    done
    
    echo
    
    # Verificar instalación de Arduino
    if command_exists arduino; then
        ARDUINO_INSTALLED=true
        success_msg "Arduino IDE instalado correctamente"
    else
        warning_msg "Arduino IDE no se instaló correctamente"
    fi
    
    success_msg "Proceso de instalación de dependencias completado"
}

#==============================================================================
# CONFIGURACIÓN DE PERMISOS
#==============================================================================

# Configurar grupo dialout
configure_dialout() {
    print_separator
    print_box "CONFIGURACIÓN DE PERMISOS DE DISPOSITIVOS" "$YELLOW"
    echo
    
    info_msg "Verificando grupo dialout..."
    
    if getent group dialout > /dev/null 2>&1; then
        success_msg "El grupo dialout existe"
    else
        info_msg "Creando grupo dialout..."
        if groupadd dialout >> "$LOG_FILE" 2>&1; then
            success_msg "Grupo dialout creado"
        else
            error_msg "Error al crear el grupo dialout"
        fi
    fi
    
    # Determinar el usuario correcto
    local target_user="${SUDO_USER:-$USER}"
    
    if [ -z "$target_user" ] || [ "$target_user" = "root" ]; then
        warning_msg "No se pudo determinar el usuario no-root automáticamente"
        read -p "$(echo -e ${CYAN}Introduce el nombre del usuario:${NC} )" target_user
    fi
    
    info_msg "Verificando si el usuario '$target_user' está en el grupo dialout..."
    
    if groups "$target_user" | grep -q "\bdialout\b"; then
        success_msg "El usuario '$target_user' ya está en el grupo dialout"
    else
        info_msg "Añadiendo usuario '$target_user' al grupo dialout..."
        if usermod -aG dialout "$target_user" >> "$LOG_FILE" 2>&1; then
            success_msg "Usuario '$target_user' añadido al grupo dialout"
        else
            error_msg "Error al añadir el usuario al grupo dialout"
        fi
    fi
    
    # Añadir también a otros grupos relacionados
    for group in uucp lock tty; do
        if getent group "$group" > /dev/null 2>&1; then
            if ! groups "$target_user" | grep -q "\b$group\b"; then
                info_msg "Añadiendo usuario '$target_user' al grupo $group..."
                usermod -aG "$group" "$target_user" >> "$LOG_FILE" 2>&1 || true
            fi
        fi
    done
    
    success_msg "Configuración de permisos completada"
}

#==============================================================================
# CONFIGURACIÓN DE REGLAS UDEV
#==============================================================================

# Crear reglas udev para Arduino
setup_udev_rules() {
    print_separator
    print_box "CONFIGURACIÓN DE REGLAS UDEV" "$YELLOW"
    echo
    
    local udev_file="/etc/udev/rules.d/99-arduino.rules"
    
    info_msg "Creando reglas udev para dispositivos Arduino..."
    
    cat > "$udev_file" << 'EOF'
#==============================================================================
# Reglas UDEV para Dispositivos Arduino
# Generado por Linuxino
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

# Adaptadores seriales genéricos (CP210x, PL2303, etc.)
SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666", GROUP="dialout"
SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", MODE="0666", GROUP="dialout"

EOF

    if [ -f "$udev_file" ]; then
        success_msg "Archivo de reglas udev creado: $udev_file"
    else
        error_msg "Error al crear el archivo de reglas udev"
    fi
    
    info_msg "Recargando reglas udev..."
    if udevadm control --reload-rules >> "$LOG_FILE" 2>&1 && udevadm trigger >> "$LOG_FILE" 2>&1; then
        success_msg "Reglas udev recargadas correctamente"
    else
        error_msg_soft "Error al recargar las reglas udev"
        warning_msg "Intenta reiniciar el sistema para aplicar los cambios"
    fi
}

#==============================================================================
# DESACTIVACIÓN DE BRLTTY
#==============================================================================

# Desactivar servicio BRLTTY
disable_brltty() {
    print_separator
    print_box "GESTIÓN DEL SERVICIO BRLTTY" "$YELLOW"
    echo
    
    info_msg "BRLTTY es un servicio para terminales braille (accesibilidad visual)"
    info_msg "Puede interferir con dispositivos Arduino en algunos sistemas"
    echo
    
    if ! command_exists systemctl; then
        warning_msg "Systemctl no disponible, omitiendo verificación de BRLTTY"
        return 0
    fi
    
    if systemctl list-unit-files | grep -q brltty; then
        if systemctl is-active --quiet brltty; then
            warning_msg "El servicio BRLTTY está activo"
            
            if prompt_user "¿Desactivar BRLTTY para evitar conflictos con Arduino?" "n"; then
                info_msg "Deteniendo servicio BRLTTY..."
                systemctl stop brltty >> "$LOG_FILE" 2>&1
                
                info_msg "Deshabilitando servicio BRLTTY..."
                systemctl disable brltty >> "$LOG_FILE" 2>&1
                
                # Enmascarar el servicio para evitar que se inicie accidentalmente
                systemctl mask brltty >> "$LOG_FILE" 2>&1
                
                success_msg "BRLTTY ha sido desactivado y enmascarado"
            else
                info_msg "BRLTTY permanece activo (puede causar conflictos)"
            fi
        else
            success_msg "BRLTTY está inactivo"
        fi
    else
        success_msg "BRLTTY no está instalado en el sistema"
    fi
}

#==============================================================================
# VERIFICACIÓN Y DIAGNÓSTICO
#==============================================================================

# Verificar instalación completa
verify_installation() {
    print_separator
    print_box "VERIFICACIÓN DE INSTALACIÓN" "$CYAN"
    echo
    
    local all_ok=true
    
    # Verificar comandos esenciales
    local commands=("avr-gcc" "avr-libc" "avrdude")
    
    for cmd in "${commands[@]}"; do
        if command_exists "$cmd" || dpkg -l | grep -q "$cmd" 2>/dev/null || rpm -qa | grep -q "$cmd" 2>/dev/null; then
            echo -e "  ${GREEN}✔${NC} $cmd instalado"
        else
            echo -e "  ${RED}✘${NC} $cmd NO instalado"
            all_ok=false
        fi
    done
    
    # Verificar grupo dialout
    if groups "$SUDO_USER" 2>/dev/null | grep -q "\bdialout\b"; then
        echo -e "  ${GREEN}✔${NC} Usuario en grupo dialout"
    else
        echo -e "  ${RED}✘${NC} Usuario NO está en grupo dialout"
        all_ok=false
    fi
    
    # Verificar reglas udev
    if [ -f "/etc/udev/rules.d/99-arduino.rules" ]; then
        echo -e "  ${GREEN}✔${NC} Reglas udev configuradas"
    else
        echo -e "  ${RED}✘${NC} Reglas udev NO configuradas"
        all_ok=false
    fi
    
    echo
    
    if $all_ok; then
        success_msg "Todas las verificaciones pasaron correctamente"
    else
        warning_msg "Algunas verificaciones fallaron. Revisa el log: $LOG_FILE"
    fi
}

# Mostrar resumen final
show_summary() {
    print_separator
    print_box "RESUMEN DE CONFIGURACIÓN" "$GREEN"
    echo
    
    echo -e "${BOLD}Sistema:${NC}"
    echo -e "  Distribución: ${CYAN}$DISTRO_NAME${NC}"
    echo -e "  Gestor de paquetes: ${CYAN}$PACKAGE_MANAGER${NC}"
    echo
    
    echo -e "${BOLD}Instalación:${NC}"
    if $ARDUINO_INSTALLED; then
        echo -e "  Arduino IDE: ${GREEN}✔ Instalado${NC}"
    else
        echo -e "  Arduino IDE: ${RED}✘ No instalado${NC}"
    fi
    echo
    
    echo -e "${BOLD}Archivos generados:${NC}"
    echo -e "  Log: ${CYAN}$LOG_FILE${NC}"
    if [ -f "$ERROR_FILE" ]; then
        echo -e "  Errores: ${YELLOW}$ERROR_FILE${NC}"
    fi
    echo
    
    detect_arduino_devices
    
    print_separator
}

#==============================================================================
# MENÚ PRINCIPAL
#==============================================================================

# Mostrar menú de opciones
main_menu() {
    local options=(
        "Instalación completa (recomendado)"
        "Instalar solo dependencias"
        "Configurar solo permisos (dialout)"
        "Configurar solo reglas udev"
        "Desactivar BRLTTY"
        "Detectar dispositivos Arduino"
        "Verificar instalación"
        "Salir"
    )
    
    while true; do
        show_banner
        echo -e "${CYAN}${BOLD}Distribución detectada:${NC} $DISTRO_NAME ($PACKAGE_MANAGER)"
        echo
        
        show_menu options "MENÚ PRINCIPAL"
        local choice=$?
        
        case $choice in
            0)  # Instalación completa
                check_internet
                install_dependencies
                configure_dialout
                setup_udev_rules
                disable_brltty
                verify_installation
                show_summary
                
                echo
                print_box "¡CONFIGURACIÓN COMPLETADA!" "$GREEN"
                warning_msg "IMPORTANTE: Cierra sesión y vuelve a iniciarla para aplicar todos los cambios"
                echo
                read -p "$(echo -e ${CYAN}Presiona ENTER para continuar...${NC})"
                ;;
            1)  # Solo dependencias
                check_internet
                install_dependencies
                read -p "$(echo -e ${CYAN}Presiona ENTER para continuar...${NC})"
                ;;
            2)  # Solo permisos
                configure_dialout
                read -p "$(echo -e ${CYAN}Presiona ENTER para continuar...${NC})"
                ;;
            3)  # Solo udev
                setup_udev_rules
                read -p "$(echo -e ${CYAN}Presiona ENTER para continuar...${NC})"
                ;;
            4)  # BRLTTY
                disable_brltty
                read -p "$(echo -e ${CYAN}Presiona ENTER para continuar...${NC})"
                ;;
            5)  # Detectar dispositivos
                detect_arduino_devices
                echo
                read -p "$(echo -e ${CYAN}Presiona ENTER para continuar...${NC})"
                ;;
            6)  # Verificar
                verify_installation
                echo
                read -p "$(echo -e ${CYAN}Presiona ENTER para continuar...${NC})"
                ;;
            7|255)  # Salir
                print_box "¡Hasta pronto!" "$CYAN"
                exit 0
                ;;
        esac
    done
}

#==============================================================================
# FUNCIÓN PRINCIPAL
#==============================================================================

main() {
    # Inicializar log
    echo "=== LINUXINO LOG - $(date) ===" > "$LOG_FILE"
    
    # Verificaciones iniciales
    check_root
    detect_distro
    
    # Mostrar menú principal
    main_menu
}

# Ejecutar script
main "$@"
