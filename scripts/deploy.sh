#!/bin/bash

# ==========================================
# Raspberry Pi Deployment Script
# ==========================================

set -e

# Load configuration file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# ==========================================
# Check usage
# ==========================================
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <executable_name> [remote_path]"
    echo ""
    echo "Examples:"
    echo "  $0 MyApp"
    echo "  $0 MyApp /home/pi/apps/"
    echo "  $0 build/MyApp ~/test/"
    echo ""
    echo "Current settings:"
    echo "  Raspberry Pi: $RPI_USER@$RPI_IP"
    echo "  Build directory: $BUILD_DIR"
    exit 1
fi

APP_NAME="$1"
REMOTE_PATH="${2:-~/}"

# ==========================================
# Find executable path
# ==========================================
log_info "Searching for executable: $APP_NAME"

# Possible executable paths
POSSIBLE_PATHS=(
    "$APP_NAME"                         # Direct path
    "./$APP_NAME"                       # Current directory
    "$BUILD_DIR/$APP_NAME"              # Build root
    "$BUILD_DIR/*/$(basename "$APP_NAME")" # Project subdirectory
)

EXECUTABLE=""
for path in "${POSSIBLE_PATHS[@]}"; do
    # Wildcard expansion
    for expanded_path in $path; do
        if [[ -f "$expanded_path" && -x "$expanded_path" ]]; then
            EXECUTABLE="$expanded_path"
            break 2
        fi
    done
done

if [[ -z "$EXECUTABLE" ]]; then
    log_error "Executable not found: $APP_NAME"
    echo ""
    echo "Searched the following locations:"
    for path in "${POSSIBLE_PATHS[@]}"; do
        echo "  - $path"
    done
    echo ""
    echo "Troubleshooting:"
    echo "  1. Provide the full path to the executable"
    echo "  2. Ensure the build was completed successfully"
    echo "  3. Check if you are in the correct directory"
    exit 1
fi

log_success "Executable found: $EXECUTABLE"

# ==========================================
# Check executable information
# ==========================================
log_info "Checking executable information..."

FILE_SIZE=$(du -h "$EXECUTABLE" | cut -f1)
FILE_INFO=$(file "$EXECUTABLE")

echo "  File: $(basename "$EXECUTABLE")"
echo "  Size: $FILE_SIZE"
echo "  Info: $FILE_INFO"

# Check for ARM64 architecture
if echo "$FILE_INFO" | grep -q "ARM aarch64"; then
    log_success "Correct ARM64 architecture confirmed"
elif echo "$FILE_INFO" | grep -q "x86\|x64"; then
    log_error "Incorrect architecture: x86/x64 (ARM64 is required)"
    echo "It seems the cross-compilation was not successful."
    exit 1
else
    log_warning "Could not determine architecture."
fi

# ==========================================
# Check SSH connection
# ==========================================
log_info "Checking connection to Raspberry Pi..."

if check_ssh_connection; then
    log_success "SSH connection confirmed"
else
    log_error "Could not connect to Raspberry Pi: $RPI_USER@$RPI_IP"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check network connection: ping $RPI_IP"
    echo "  2. Check the status of the SSH service"
    echo "  3. Verify user authentication"
    exit 1
fi

# ==========================================
# Prepare remote directory
# ==========================================
if [[ "$REMOTE_PATH" != *"/" && "$REMOTE_PATH" != "~" ]]; then
    # If a filename is specified instead of a directory
    REMOTE_DIR=$(dirname "$REMOTE_PATH")
    REMOTE_FILE=$(basename "$REMOTE_PATH")
else
    # If a directory is specified
    REMOTE_DIR="$REMOTE_PATH"
    REMOTE_FILE=$(basename "$EXECUTABLE")
fi

log_info "Preparing remote directory: $REMOTE_DIR"

# Create remote directory
if ssh "$RPI_USER@$RPI_IP" "mkdir -p '$REMOTE_DIR'"; then
    log_success "Remote directory is ready"
else
    log_error "Failed to create remote directory: $REMOTE_DIR"
    exit 1
fi

# ==========================================
# File Transfer
# ==========================================
log_info "Transferring file..."
echo "  Local: $EXECUTABLE"
echo "  Remote: $RPI_USER@$RPI_IP:$REMOTE_DIR/$REMOTE_FILE"

START_TIME=$(date +%s)

if scp "$EXECUTABLE" "$RPI_USER@$RPI_IP:$REMOTE_DIR/$REMOTE_FILE"; then
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    log_success "File transfer complete! (Duration: ${DURATION}s)"
else
    log_error "File transfer failed"
    exit 1
fi

# ==========================================
# Set Execute Permissions
# ==========================================
log_info "Setting execute permissions..."

if ssh "$RPI_USER@$RPI_IP" "chmod +x '$REMOTE_DIR/$REMOTE_FILE'"; then
    log_success "Execute permissions set"
else
    log_warning "Failed to set execute permissions (continuing)"
fi

# ==========================================
# Check Dependencies (Optional)
# ==========================================
log_info "Checking library dependencies..."

ssh "$RPI_USER@$RPI_IP" bash << EOF
cd '$REMOTE_DIR'

echo "Executable info:"
file '$REMOTE_FILE'

echo ""
echo "Dependency libraries:"
if command -v ldd >/dev/null 2>&1; then
    ldd '$REMOTE_FILE' | head -10
else
    echo "ldd command is not available."
fi

echo ""
echo "Checking for missing libraries..."
MISSING=\$(ldd '$REMOTE_FILE' 2>/dev/null | grep "not found" || true)
if [[ -n "\$MISSING" ]]; then
    echo "⚠️  Missing libraries found:"
    echo "\$MISSING"
    echo ""
    echo "Solution:"
    echo "  sudo apt update && sudo apt install qt5-default"
else
    echo "✅ All dependencies are satisfied."
fi
EOF

# ==========================================
# Suggest Execution Test
# ==========================================
echo ""
log_success "Deployment complete!"
echo ""
echo "Next steps:"
echo "  1. Connect via SSH and run:"
echo "     ssh $RPI_USER@$RPI_IP"
echo "     cd $REMOTE_DIR && ./$REMOTE_FILE"
echo ""
echo "  2. Run directly via remote command:"
echo "     ssh $RPI_USER@$RPI_IP 'cd $REMOTE_DIR && ./$REMOTE_FILE'"
echo ""
echo "  3. Run in the background:"
echo "     ssh $RPI_USER@$RPI_IP 'cd $REMOTE_DIR && nohup ./$REMOTE_FILE > app.log 2>&1 &'"
echo ""

# Suggest execution test
read -p "Would you like to run a remote test now? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Running remote test..."
    echo "You can stop it with Ctrl+C."
    echo ""
    
    ssh -t "$RPI_USER@$RPI_IP" "cd '$REMOTE_DIR' && ./'$REMOTE_FILE'"
else
    log_info "Skipping execution test."
fi

echo ""
log_success "Deployment process complete!"
