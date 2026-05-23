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
TARGET_USER=""

# Determinar el usuario no-root para la configuración de grupos y ejecución de AUR helper
determine_target_user() {
    TARGET_USER="${SUDO_USER:-$USER}"
    if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
        # Alternativa para obtener el usuario original si se ejecuta bajo sudo pero SUDO_USER está vacío o es root
        local real_user=""
        real_user=$(logname 2>/dev/null || echo "$USER")
        if [ "$real_user" = "root" ]; then
            # Si sigue siendo root, verificar quién está logueado o los propietarios de /home
            real_user=$(who | awk '{print $1}' | head -n 1)
            if [ -z "$real_user" ] || [ "$real_user" = "root" ]; then
                real_user=$(ls -1d /home/* 2>/dev/null | grep -v "/home/shared" | head -n 1 | cut -d'/' -f3)
            fi
        fi
        TARGET_USER="${real_user:-root}"
    fi
    
    # Permitir introducción manual si el usuario sigue siendo root
    if [ "$TARGET_USER" = "root" ]; then
        warning_msg "No se pudo determinar el usuario no-root automáticamente."
        read -p "$(echo -e ${CYAN}Introduce el nombre del usuario:${NC} )" TARGET_USER || TARGET_USER="root"
    fi
    log "Usuario objetivo determinado: $TARGET_USER"
}

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
# Mensaje de error (con salida y diagnóstico detallado)
error_msg() {
    local message="$1"
    local line_num="${2:-Desconocido}"
    local failed_cmd="${3:-Desconocido}"
    
    # Desactivar el trap temporalmente para evitar recursión
    trap - ERR
    
    echo -e "\n${RED}${BOLD}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}${BOLD}║                     ERROR FATAL DETECTADO                                 ║${NC}"
    echo -e "${RED}${BOLD}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${RED}${BOLD}[✘] Mensaje:${NC} $message"
    
    if [[ "$line_num" != "Desconocido" ]]; then
        echo -e "${RED}${BOLD}[✘] Línea del script:${NC} $line_num"
    fi
    if [[ "$failed_cmd" != "Desconocido" ]]; then
        echo -e "${RED}${BOLD}[✘] Comando fallido:${NC} $failed_cmd"
    fi
    
    log "FATAL ERROR: $message (Línea: $line_num, Comando: $failed_cmd)"
    
    echo -e "\n${YELLOW}${BOLD}📄 Últimas 15 líneas del log (desde $LOG_FILE):${NC}"
    print_separator
    if [ -f "$LOG_FILE" ]; then
        tail -n 15 "$LOG_FILE" | sed 's/^/  /'
    else
        echo -e "  Archivo de log no encontrado."
    fi
    print_separator
    
    echo -e "\n${CYAN}${BOLD}💡 Sugerencias de solución de problemas:${NC}"
    if [[ "$failed_cmd" == *"pacman"* || "$failed_cmd" == *"apt"* || "$failed_cmd" == *"dnf"* || "$failed_cmd" == *"yum"* || "$failed_cmd" == *"zypper"* ]]; then
        echo -e "  1. Verifica tu conexión a Internet (ping google.com)."
        echo -e "  2. Asegúrate de que no haya otro gestor de paquetes ejecutándose (verifica archivos de bloqueo)."
        echo -e "  3. Si estás en Arch Linux, intenta ejecutar 'sudo pacman -Syu' primero para sincronizar bases de datos."
    elif [[ "$failed_cmd" == *"udevadm"* || "$failed_cmd" == *"/etc/udev/"* ]]; then
        echo -e "  1. Asegúrate de que la partición del sistema no esté montada como solo lectura."
        echo -e "  2. Verifica que el directorio /etc/udev/rules.d/ exista y tenga los permisos correctos."
    elif [[ "$failed_cmd" == *"usermod"* || "$failed_cmd" == *"groupadd"* ]]; then
        echo -e "  1. Verifica que el usuario '$TARGET_USER' y el grupo existan en el sistema."
        echo -e "  2. Comprueba si los archivos de base de datos de usuarios (como /etc/passwd o /etc/group) están bloqueados."
    else
        echo -e "  1. Asegúrate de estar ejecutando el script con privilegios de sudo (root)."
        echo -e "  2. Verifica que tengas suficiente espacio en disco."
        echo -e "  3. Revisa el log completo en: $LOG_FILE"
    fi
    
    echo -e "\n${RED}${BOLD}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}${BOLD}║  El script ha finalizado. Por favor, resuelve el problema y reinténtalo. ║${NC}"
    echo -e "${RED}${BOLD}╚═══════════════════════════════════════════════════════════════════════════╝${NC}\n"
    
    exit 1
}

# Atrapar errores inesperados de comandos
trap 'error_msg "Fallo inesperado de comando" "$LINENO" "$BASH_COMMAND"' ERR

#==============================================================================
# FUNCIONES DE VALIDACIÓN
#==============================================================================

# Verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verificar si un paquete está instalado en el sistema
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
    
    if ! read -p "$(echo -e ${CYAN}${BOLD}Seleccione una opción:${NC} )" selected; then
        selected="8"
    fi
    
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
            warning_msg "Error al instalar $pkg."
            echo -e "${RED}Contexto del error del gestor de paquetes:${NC}"
            tail -n 5 "$LOG_FILE" | sed 's/^/  /'
            echo "$pkg" >> "$ERROR_FILE"
        fi
    done
    
    echo
    
    # Verificar instalación del compilador o IDE de Arduino
    if command_exists arduino || command_exists arduino-cli; then
        ARDUINO_INSTALLED=true
        success_msg "Arduino CLI/IDE instalado correctamente"
    else
        warning_msg "El compilador o herramientas de Arduino no se instalaron correctamente"
    fi

    # Si detectamos Arch Linux, ofrecer instalar la interfaz gráfica desde el AUR
    if [ "$PACKAGE_MANAGER" = "pacman" ]; then
        echo
        info_msg "Se detectó Arch Linux. El IDE gráfico de Arduino v2 está disponible en el AUR como 'arduino-ide-bin'."
        local aur_helper=""
        if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ]; then
            if command_exists yay; then
                aur_helper="yay"
            elif command_exists paru; then
                aur_helper="paru"
            fi
        fi
        
        if [ -n "$aur_helper" ]; then
            if prompt_user "¿Deseas instalar 'arduino-ide-bin' desde el AUR usando $aur_helper?" "y"; then
                info_msg "Instalando 'arduino-ide-bin' desde el AUR usando $aur_helper. Por favor, espera..."
                if sudo -u "$TARGET_USER" "$aur_helper" -S --noconfirm arduino-ide-bin >> "$LOG_FILE" 2>&1; then
                    success_msg "Arduino IDE instalado con éxito desde el AUR"
                    ARDUINO_INSTALLED=true
                else
                    echo -e " ${RED}✘${NC}"
                    warning_msg "No se pudo instalar 'arduino-ide-bin' desde el AUR. Puedes intentar instalarlo manualmente: $aur_helper -S arduino-ide-bin"
                    echo "arduino-ide-bin" >> "$ERROR_FILE"
                fi
            fi
        else
            warning_msg "No se detectó un asistente de AUR (yay o paru), o el script no se ejecutó mediante sudo. Para instalar el IDE gráfico, ejecuta: yay -S arduino-ide-bin (como usuario normal)"
        fi
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
    
    # Usar el usuario no-root determinado globalmente
    local target_user="$TARGET_USER"
    
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
                systemctl stop brltty >> "$LOG_FILE" 2>&1 || warning_msg "No se pudo detener el servicio BRLTTY"
                
                info_msg "Deshabilitando servicio BRLTTY..."
                systemctl disable brltty >> "$LOG_FILE" 2>&1 || warning_msg "No se pudo deshabilitar el servicio BRLTTY"
                
                # Enmascarar el servicio para evitar que se inicie accidentalmente
                systemctl mask brltty >> "$LOG_FILE" 2>&1 || warning_msg "No se pudo enmascarar el servicio BRLTTY"
                
                success_msg "Intento de desactivación del servicio BRLTTY finalizado"
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
    
    # Verificar comandos/paquetes esenciales
    local components=("avr-gcc" "avr-libc" "avrdude")
    
    for comp in "${components[@]}"; do
        if command_exists "$comp" || package_is_installed "$comp"; then
            echo -e "  ${GREEN}✔${NC} $comp instalado"
        else
            echo -e "  ${RED}✘${NC} $comp NO instalado"
            all_ok=false
        fi
    done
    
    # Verificar grupo dialout
    if groups "$TARGET_USER" 2>/dev/null | grep -q "\bdialout\b"; then
        echo -e "  ${GREEN}✔${NC} Usuario '$TARGET_USER' en grupo dialout"
    else
        echo -e "  ${RED}✘${NC} Usuario '$TARGET_USER' NO está en grupo dialout"
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
                read -p "$(echo -e ${CYAN}Presiona ENTER para continuar...${NC})" || true
                ;;
            1)  # Solo dependencias
                check_internet
                install_dependencies
                read -p "$(echo -e ${CYAN}Presiona ENTER para continuar...${NC})" || true
                ;;
            2)  # Solo permisos
                configure_dialout
                read -p "$(echo -e ${CYAN}Presiona ENTER para continuar...${NC})" || true
                ;;
            3)  # Solo udev
                setup_udev_rules
                read -p "$(echo -e ${CYAN}Presiona ENTER para continuar...${NC})" || true
                ;;
            4)  # BRLTTY
                disable_brltty
                read -p "$(echo -e ${CYAN}Presiona ENTER para continuar...${NC})" || true
                ;;
            5)  # Detectar dispositivos
                detect_arduino_devices
                echo
                read -p "$(echo -e ${CYAN}Presiona ENTER para continuar...${NC})" || true
                ;;
            6)  # Verificar
                verify_installation
                echo
                read -p "$(echo -e ${CYAN}Presiona ENTER para continuar...${NC})" || true
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
    
    # Limpiar archivo de errores previo
    rm -f "$ERROR_FILE"
    
    # Determinar el usuario no-root objetivo
    determine_target_user
    
    # Verificaciones iniciales
    check_root
    detect_distro
    
    # Mostrar menú principal
    main_menu
}

# Ejecutar script
main "$@"
