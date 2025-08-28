#!/bin/bash

# ==============================================
# Qt5 Cross-Compilation Configuration File
# ==============================================

# 🎯 Raspberry Pi Connection Info
RPI_IP="192.168.86.38"
RPI_USER="team06"

# 📁 Build Path Settings
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$HOME/rpi-build"
SYSROOT_DIR="$PROJECT_ROOT/sysroot"
TOOLCHAIN_FILE="$PROJECT_ROOT/toolchain-rpi.cmake"

# 🔧 Cross-Compiler
CROSS_COMPILER_PREFIX="aarch64-linux-gnu"
CROSS_GCC="${CROSS_COMPILER_PREFIX}-gcc-11"
CROSS_GXX="${CROSS_COMPILER_PREFIX}-g++-11"

# 📦 Required Package Lists
HOST_PACKAGES=(
    "cmake"
    "gcc-11-aarch64-linux-gnu"
    "g++-11-aarch64-linux-gnu"
    "qtbase5-dev"
    "qtdeclarative5-dev"
    "qtquickcontrols2-5-dev"
    "qtserialport5-dev"
    "qtnetworkauth5-dev"
    "libqt5dbus5-dev"
    "rsync"
)

RPI_PACKAGES=(
    "qt5-default"
    "qml-module-qtquick-controls2"
    "qtdeclarative5-dev"
    "libqt5serialport5-dev"
    "libqt5network5-dev"
    "libqt5sql5-dev"
    "libqt5dbus5-dev"
)

# 🔍 Qt5 Libraries to Verify
QT5_LIBS=(
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
    "libQt5Qml.so.5"
    "libQt5Quick.so.5"
    "libQt5SerialPort.so.5"
    "libQt5Network.so.5"
    "libQt5DBus.so.5"
)

# 🚀 Build Options
MAKE_JOBS=$(nproc)
CMAKE_BUILD_TYPE="Release"

# 🌈 Color Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 📝 Log Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 🔍 Verification Functions
check_ssh_connection() {
    if ssh -o ConnectTimeout=5 "$RPI_USER@$RPI_IP" "echo 'SSH OK'" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

check_host_package() {
    dpkg -l | grep -q "^ii  $1 " >/dev/null 2>&1
}

check_file_exists() {
    test -f "$1"
}
