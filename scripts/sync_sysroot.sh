#!/bin/bash

# ==========================================
# Sysroot Synchronization Script
# ==========================================

set -e

# Load configuration file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Force sync option
FORCE_SYNC=false
if [[ "$1" == "--force" ]]; then
    FORCE_SYNC=true
    shift
fi

log_info "Starting Raspberry Pi sysroot synchronization"
log_info "Raspberry Pi: $RPI_USER@$RPI_IP"

# ==========================================
# Check SSH connection
# ==========================================
log_info "Checking SSH connection..."

if check_ssh_connection; then
    log_success "SSH connection confirmed"
else
    log_error "Could not connect to Raspberry Pi via SSH."
    echo ""
    echo "Troubleshooting:"
    echo "  1. Ensure the Raspberry Pi is turned on and connected to the network"
    echo "  2. Check the IP address: ping $RPI_IP"
    echo "  3. Enable the SSH service: sudo systemctl enable ssh"
    echo "  4. Register SSH key: ssh-copy-id $RPI_USER@$RPI_IP"
    exit 1
fi

# ==========================================
# Install Qt5 packages on Raspberry Pi
# ==========================================
log_info "Installing Qt5 packages on Raspberry Pi..."

# Convert package array to a string
PACKAGES_STR=$(printf " %s" "${RPI_PACKAGES[@]}")

ssh "$RPI_USER@$RPI_IP" bash << EOF
set -e

echo "Updating package list..."
sudo apt update -qq

echo "Installing Qt5 packages..."
sudo apt install -y$PACKAGES_STR

echo "Qt5 package installation complete!"
EOF

if [[ $? -eq 0 ]]; then
    log_success "Qt5 package installation complete"
else
    log_error "Failed to install packages on Raspberry Pi"
    exit 1
fi

# ==========================================
# Create sysroot directory structure
# ==========================================
log_info "Creating sysroot directory structure..."

mkdir -p "$SYSROOT_DIR"/{lib,usr/{include,lib,local},opt}

if [[ ! -w "$SYSROOT_DIR" ]]; then
    log_error "No write permissions for sysroot directory: $SYSROOT_DIR"
    exit 1
fi

# ==========================================
# Synchronize system files
# ==========================================
log_info "Synchronizing system files..."

RSYNC_OPTIONS="-avz --delete"
if [[ "$FORCE_SYNC" == "true" ]]; then
    RSYNC_OPTIONS="$RSYNC_OPTIONS --force"
fi

# List of directories to sync
SYNC_DIRS=(
    "/lib"
    "/usr/include"  
    "/usr/lib"
    "/usr/local"
    "/opt"
)

for dir in "${SYNC_DIRS[@]}"; do
    log_info "Syncing: $dir"
    
    if rsync $RSYNC_OPTIONS --rsync-path="sudo rsync" \
        "$RPI_USER@$RPI_IP:$dir" "$SYSROOT_DIR$(dirname "$dir")/"; then
        log_success "Complete: $dir"
    else
        log_warning "Failed: $dir (continuing)"
    fi
done

log_success "Sysroot synchronization complete"

# ==========================================
# Verify Qt5 libraries
# ==========================================
log_info "Verifying Qt5 libraries..."

LIB_PATH="$SYSROOT_DIR/usr/lib/aarch64-linux-gnu"
MISSING_LIBS=()

for lib in "${QT5_LIBS[@]}"; do
    if check_file_exists "$LIB_PATH/$lib"; then
        log_success "$lib"
    else
        log_warning "$lib (missing)"
        MISSING_LIBS+=("$lib")
    fi
done

# ==========================================
# Verification results and next steps
# ==========================================
echo ""
if [[ ${#MISSING_LIBS[@]} -eq 0 ]]; then
    log_success "All Qt5 libraries verified!"
else
    log_warning "${#MISSING_LIBS[@]} libraries missing:"
    for lib in "${MISSING_LIBS[@]}"; do
        echo "  - $lib"
    done
    echo ""
    echo "Troubleshooting:"
    echo "  1. Reinstall the corresponding packages on the Raspberry Pi"
    echo "  2. Resync with the --force option: $0 --force"
fi

echo ""
log_success "Ready for cross-compilation!"
echo ""
echo "Next steps:"
echo "  ./build_project.sh <project_path>"
echo ""
echo "Or build manually:"
echo "  mkdir -p $BUILD_DIR && cd $BUILD_DIR"
echo "  cmake -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_FILE <project_path>"
echo "  make -j$MAKE_JOBS"
