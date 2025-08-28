#!/bin/bash

# ==========================================
# Host System Environment Setup Script
# ==========================================

set -e  # Exit immediately if a command exits with a non-zero status.

# Load configuration file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

log_info "Starting Qt5 cross-compilation host setup"

# ==========================================
# System Update
# ==========================================
log_info "Updating system package list..."
sudo apt update -qq

# ==========================================
# Install Required Packages
# ==========================================
log_info "Installing required packages..."

for package in "${HOST_PACKAGES[@]}"; do
    if check_host_package "$package"; then
        log_success "$package is already installed"
    else
        log_info "Installing $package..."
        sudo apt install -y "$package"
        
        if check_host_package "$package"; then
            log_success "$package installation complete"
        else
            log_error "$package installation failed"
            exit 1
        fi
    fi
done

# ==========================================
# Check Cross-Compiler
# ==========================================
log_info "Checking cross-compiler..."

if command -v "$CROSS_GCC" >/dev/null 2>&1; then
    VERSION=$("$CROSS_GCC" --version | head -n1)
    log_success "Cross-compiler found: $VERSION"
else
    log_error "Cross-compiler not found: $CROSS_GCC"
    exit 1
fi

if command -v "$CROSS_GXX" >/dev/null 2>&1; then
    VERSION=$("$CROSS_GXX" --version | head -n1)
    log_success "Cross C++ compiler found: $VERSION"
else
    log_error "Cross C++ compiler not found: $CROSS_GXX"
    exit 1
fi

# ==========================================
# Create Directory Structure
# ==========================================
log_info "Creating directory structure..."

mkdir -p "$(dirname "$SYSROOT_DIR")"
mkdir -p "$BUILD_DIR"

# Set Permissions
if [[ "$SYSROOT_DIR" == /home/* ]]; then
    # If under home directory, use standard user permissions
    mkdir -p "$SYSROOT_DIR"
    chmod 755 "$SYSROOT_DIR"
else
    # If a system directory, sudo is required
    sudo mkdir -p "$SYSROOT_DIR"
    sudo chown "$USER:$USER" "$SYSROOT_DIR"
fi

log_success "Directory created: $SYSROOT_DIR"
log_success "Build directory: $BUILD_DIR"

# ==========================================
# Verify Qt5 Installation
# ==========================================
log_info "Verifying Qt5 installation..."

if command -v qmake >/dev/null 2>&1; then
    QT_VERSION=$(qmake -version | grep "Qt version" | cut -d' ' -f4)
    log_success "Qt5 version: $QT_VERSION"
else
    log_error "Qt5 not found. Please check the qtbase5-dev package."
    exit 1
fi

# ==========================================
# Verify CMake Version
# ==========================================
if command -v cmake >/dev/null 2>&1; then
    CMAKE_VERSION=$(cmake --version | head -n1 | cut -d' ' -f3)
    log_success "CMake version: $CMAKE_VERSION"
else
    log_error "CMake not found."
    exit 1
fi

# ==========================================
# Completion Message
# ==========================================
echo ""
log_success "Host environment setup complete!"
echo ""
echo "Next steps:"
echo "  1. Set the Raspberry Pi IP and user info in config.sh"
echo "  2. Run ./sync_sysroot.sh to synchronize the sysroot"
echo "  3. Run ./build_project.sh <project_path> to build"
echo ""
echo "Configured paths:"
echo "  Sysroot: $SYSROOT_DIR"
echo "  Build: $BUILD_DIR"
echo "  Toolchain: $TOOLCHAIN_FILE"
