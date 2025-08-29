#!/bin/bash

# Super simple deployment script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Move to the build directory
cd "$BUILD_DIR"

# Find and transfer the ARM64 executable
EXECUTABLE=$(find . -maxdepth 1 -type f -executable -not -name "*.so*" -exec file {} \; | grep "ARM aarch64" | head -1 | cut -d: -f1)
[[ -z "$EXECUTABLE" ]] && { echo "❌ Executable not found"; exit 1; }

APP_NAME=$(basename "$EXECUTABLE")
scp "$EXECUTABLE" "$RPI_USER@$RPI_IP:~/"
