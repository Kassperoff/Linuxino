

# Linuxino - Configuración Automática de Entorno Arduino en Linux

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

**Linuxino** es un script automatizado completo diseñado para simplificar la configuración del entorno de desarrollo de **Arduino** en múltiples distribuciones de **Linux**. Elimina la molestia de la instalación manual de dependencias, configuración de permisos y creación de reglas udev.

## ✨ Novedades en la Versión 2.0

- 🎨 **Hermosa Interfaz ASCII** con barras de progreso visuales
- 📋 **Sistema de Menú Interactivo** con 8 opciones diferentes
- 🔍 **Detección Automática de Dispositivos Arduino** 
- 📊 **Indicadores de Progreso en Tiempo Real** durante la instalación
- 📝 **Sistema de Registro Completo** para solución de problemas
- ✅ **Herramientas de Verificación de Instalación**
- 🌐 **Soporte Extendido de Distribuciones** (DNF, YUM, Portage)
- 🔧 **Ejecución Modular** - ejecuta tareas específicas sin instalación completa
- 🛡️ **Manejo Mejorado de Errores** con registros detallados

## Tabla de Contenidos
- [Descripción](#descripción)
- [Finalidad del Proyecto](#finalidad-del-proyecto)
- [Características](#características)
- [Distribuciones Compatibles](#distribuciones-compatibles)
- [Requisitos](#requisitos)
- [Dependencias](#dependencias)
- [Uso](#uso)
  - [Inicio Rápido](#inicio-rápido)
  - [Menú Interactivo](#menú-interactivo)
- [Qué Hace el Script](#qué-hace-el-script)
  - [Instalación de Paquetes](#instalación-de-paquetes)
  - [Configuración de Permisos](#configuración-de-permisos)
  - [Creación de Reglas udev](#creación-de-reglas-udev)
  - [Gestión de BRLTTY](#gestión-de-brltty)
- [Placas Arduino Soportadas](#placas-arduino-soportadas)
- [Solución de Problemas](#solución-de-problemas)
- [Contribuciones](#contribuciones)
- [Licencia](#licencia)

## Descripción

**Linuxino** es una poderosa herramienta de automatización que maneja la configuración completa del entorno de desarrollo Arduino en sistemas Linux. Resuelve los problemas más comunes que enfrentan los desarrolladores:

- 🔧 **Instalación automatizada de dependencias** para el toolchain AVR y Arduino IDE
- 🔐 **Configuración automática de permisos** para acceso a dispositivos serie
- 📡 **Creación inteligente de reglas udev** para reconocimiento automático de placas Arduino
- 🚫 **Resolución de conflictos con BRLTTY** para prevenir interferencias con dispositivos Arduino
- 🔍 **Detección de dispositivos** para verificar hardware Arduino conectado
- 📊 **Verificación de instalación** para asegurar que todo funcione correctamente

## Finalidad del Proyecto

El proyecto **Linuxino** fue creado para solventar los problemas más comunes que enfrentan los usuarios de Linux al configurar el entorno de desarrollo para Arduino:

- **Compatibilidad de dependencias**: Evita la búsqueda manual e instalación de paquetes necesarios
- **Permisos de acceso a dispositivos**: Configura automáticamente los permisos para acceder a dispositivos serie sin intervención manual
- **Creación de reglas udev**: El sistema reconoce y asigna permisos a las placas Arduino automáticamente cuando se conectan
- **Gestión de errores**: Sistema de logging completo con registros detallados para troubleshooting
- **Verificación**: Herramientas integradas para confirmar que la instalación fue exitosa

## Características

### Características Principales
- **🌍 Soporte multi-distribución**: Debian, Ubuntu, Fedora, Arch Linux, openSUSE, Gentoo y derivadas
- **🤖 Automatización completa**: Cero configuración manual requerida
- **🎨 Interfaz ASCII hermosa**: Menús y barras de progreso de aspecto profesional
- **📊 Retroalimentación en tiempo real**: Barras de progreso visuales durante la instalación de paquetes
- **📝 Registro completo**: Logs detallados guardados en `/tmp/` para troubleshooting
- **🔒 Manejo robusto de errores**: Degradación elegante con reportes de error detallados
- **🎯 Ejecución modular**: Ejecuta solo los componentes que necesites

### Características Avanzadas
- **Sistema de menú interactivo** con 8 modos operacionales diferentes
- **Detección automática de hardware** para placas Arduino conectadas
- **Gestión de múltiples grupos** (dialout, uucp, lock, tty)
- **Soporte extendido de placas** incluyendo clones con chips CH340, CP210x, PL2303
- **Creación automática de symlinks** para identificación más fácil de dispositivos
- **Verificación de conectividad a Internet** antes de intentar descargas
- **Herramientas de verificación de instalación** para confirmar configuración exitosa

## Distribuciones Compatibles

Linuxino detecta automáticamente tu distribución y usa el gestor de paquetes apropiado:

| Familia de Distribución | Gestor de Paquetes | Estado |
|--------------------------|-------------------|---------|
| Debian/Ubuntu/Mint | `apt-get` | ✅ Totalmente Soportado |
| Fedora | `dnf` | ✅ Totalmente Soportado |
| RHEL/CentOS | `yum` | ✅ Totalmente Soportado |
| Arch/Manjaro/EndeavourOS | `pacman` | ✅ Totalmente Soportado |
| openSUSE/SLES | `zypper` | ✅ Totalmente Soportado |
| Gentoo | `portage/emerge` | ✅ Totalmente Soportado |

Otras distribuciones pueden funcionar con instalación manual de dependencias.

## Requisitos

- ✅ **Acceso root/sudo**: Requerido para modificaciones del sistema
- ✅ **Conexión a Internet**: Para descargar paquetes (verificado automáticamente)
- ✅ **Distribución Linux moderna**: De la lista soportada arriba
- ✅ **Emulador de terminal**: Compatible con códigos de color ANSI para mejor experiencia

## Dependencias

El script instala automáticamente los siguientes paquetes (varía según distribución):

### Paquetes Esenciales
- **gcc-avr** / **avr-gcc**: Compilador cruzado AVR para desarrollo Arduino
- **avr-libc**: Biblioteca estándar C para microcontroladores AVR
- **avrdude**: Herramienta para subir código a placas Arduino
- **arduino**: El IDE oficial de Arduino

### Herramientas Adicionales (donde estén disponibles)
- **arduino-core**: Herramientas de desarrollo Arduino básicas
- **arduino-avr-core**: Definiciones de placas AVR para Arduino
- **binutils-avr**: Utilidades binarias AVR
- **gdb-avr**: Depurador GNU para AVR (soporte de debugging)

## Uso

### Inicio Rápido

1. **Clonar el repositorio**:
   ```bash
   git clone https://github.com/Guerra-666/Linuxino.git
   cd Linuxino
   ```

2. **Hacer el script ejecutable** (si es necesario):
   ```bash
   chmod +x Linuxino_ES.sh
   ```

3. **Ejecutar con sudo**:
   ```bash
   sudo ./Linuxino_ES.sh
   ```

### Menú Interactivo

Al ejecutar, verás un hermoso banner ASCII y un menú interactivo:

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                          MENÚ PRINCIPAL                                   ║
╚═══════════════════════════════════════════════════════════════════════════╝

  [1] Instalación completa (recomendado)
  [2] Instalar solo dependencias
  [3] Configurar solo permisos (dialout)
  [4] Configurar solo reglas udev
  [5] Desactivar BRLTTY
  [6] Detectar dispositivos Arduino
  [7] Verificar instalación
  [8] Salir
```

#### Opciones del Menú Explicadas

1. **Instalación completa** - Realiza todos los pasos de configuración automáticamente (recomendado para usuarios primerizos)
2. **Instalar solo dependencias** - Solo instala paquetes Arduino sin configurar permisos
3. **Configurar solo permisos** - Añade el usuario a dialout y grupos relacionados
4. **Configurar solo reglas udev** - Crea reglas para detección automática de Arduino
5. **Desactivar BRLTTY** - Detiene y enmascara el servicio BRLTTY si causa conflictos
6. **Detectar dispositivos Arduino** - Escanea y muestra placas Arduino conectadas
7. **Verificar instalación** - Comprueba si todo está instalado correctamente
8. **Salir** - Abandonar el script

### Aplicar Cambios

**Importante**: Después de la instalación, cierra sesión y vuelve a iniciarla para aplicar los cambios de membresía de grupo:

```bash
# O reinicia tu sistema
sudo reboot
```

## Qué Hace el Script

### Instalación de Paquetes

El script detecta tu distribución y usa el gestor de paquetes apropiado con comandos optimizados:

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

### Configuración de Permisos

El script añade tu usuario a múltiples grupos para acceso completo a dispositivos:

```bash
usermod -aG dialout $USER    # Grupo principal para dispositivos serie
usermod -aG uucp $USER       # Unix-to-Unix Copy (comunicación serie)
usermod -aG lock $USER       # Acceso a archivos de bloqueo
usermod -aG tty $USER        # Acceso a dispositivos TTY
```

### Creación de Reglas udev

Crea reglas udev completas en `/etc/udev/rules.d/99-arduino.rules` con soporte para:

- ✅ Arduino Uno (original y clones)
- ✅ Arduino Mega 2560
- ✅ Arduino Nano (variantes FTDI y CH340)
- ✅ Arduino Leonardo
- ✅ Arduino Micro
- ✅ Arduino Due
- ✅ Arduino Yún
- ✅ Arduino Robot Control/Motor
- ✅ Adaptadores serie genéricos (CP210x, PL2303, CH340)

Cada regla crea symlinks automáticos para identificación fácil:
```bash
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0043", 
MODE="0666", GROUP="dialout", SYMLINK+="arduino_uno"
```

### Gestión de BRLTTY

BRLTTY (servicio de pantalla braille) puede causar conflictos con Arduino. El script ofrece:
- Detener el servicio
- Deshabilitarlo del inicio automático
- Enmascararlo para prevenir activación accidental

## Placas Arduino Soportadas

Linuxino incluye reglas udev para:

| Tipo de Placa | Variantes de Chip | Symlink Creado |
|---------------|-------------------|----------------|
| Arduino Uno | Original, Rev3 | `/dev/arduino_uno` |
| Arduino Mega 2560 | Original, Rev3, Genuino | `/dev/arduino_mega` |
| Arduino Nano | FTDI, CH340 | `/dev/arduino_nano_*` |
| Arduino Leonardo | Todas las variantes | `/dev/arduino_leonardo` |
| Arduino Micro | Todas las variantes | `/dev/arduino_micro` |
| Arduino Due | Programming & Native | `/dev/arduino_due` |
| Arduino Yún | Todas las variantes | `/dev/arduino_yun` |

¡Además de soporte genérico para chips USB-to-Serial comunes!

## Solución de Problemas

### Problemas Comunes

**Problema**: Arduino no detectado después de la instalación
```bash
# Verificar si el dispositivo está conectado
lsusb | grep -i arduino

# Verificar si las reglas udev están cargadas
cat /etc/udev/rules.d/99-arduino.rules

# Recargar reglas manualmente
sudo udevadm control --reload-rules && sudo udevadm trigger
```

**Problema**: Permiso denegado al acceder a Arduino
```bash
# Verificar membresía de grupo
groups $USER | grep dialout

# Si no está en el grupo, necesitas cerrar sesión y volver a iniciar
```

**Problema**: BRLTTY sigue interfiriendo
```bash
# Verificar estado de BRLTTY
systemctl status brltty

# Enmascararlo manualmente
sudo systemctl mask brltty
```

### Logs y Diagnósticos

Todas las operaciones se registran en `/tmp/linuxino_YYYYMMDD_HHMMSS.log`

Ver el log:
```bash
cat /tmp/linuxino_*.log
```

Buscar errores:
```bash
grep ERROR /tmp/linuxino_*.log
```

### Obtener Ayuda

Si encuentras problemas:
1. Revisa el archivo de log en `/tmp/`
2. Ejecuta la opción de verificación desde el menú
3. Abre un issue en GitHub con el contenido del log

## Contribuciones

Las contribuciones son bienvenidas. Haz un **fork** del proyecto y envía un **pull request** si deseas mejorar el script.

## Licencia

Este proyecto está licenciado bajo la [MIT License](https://opensource.org/licenses/MIT) - consulta el archivo LICENSE para más detalles.

--- 

Este README incluye todos los detalles mencionados y ajusta la información para adaptarse al proyecto **Linuxino**.