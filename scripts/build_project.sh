#!/bin/bash

# ==========================================
# Project Build Script
# ==========================================

set -e

# Load configuration file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# ==========================================
# Check usage
# ==========================================
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <project_path> [build_type]"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/qt5/project"
    echo "  $0 /path/to/qt5/project Debug"
    echo "  $0 /path/to/qt5/project Release"
    echo ""
    echo "Build types: Debug, Release, RelWithDebInfo (Default: $CMAKE_BUILD_TYPE)"
    exit 1
fi

PROJECT_PATH="$1"
BUILD_TYPE="${2:-$CMAKE_BUILD_TYPE}"

# ==========================================
# Validate project path
# ==========================================
if [[ ! -d "$PROJECT_PATH" ]]; then
    log_error "Project directory does not exist: $PROJECT_PATH"
    exit 1
fi

# Check for CMakeLists.txt or .pro file
if [[ ! -f "$PROJECT_PATH/CMakeLists.txt" && ! -f "$PROJECT_PATH"/*.pro ]]; then
    log_error "Could not find CMakeLists.txt or .pro file in: $PROJECT_PATH"
    exit 1
fi

PROJECT_NAME=$(basename "$PROJECT_PATH")
log_info "Starting project build: $PROJECT_NAME"

# ==========================================
# Check build environment
# ==========================================
log_info "Checking build environment..."

# Check for toolchain file
if [[ ! -f "$TOOLCHAIN_FILE" ]]; then
    log_error "Toolchain file not found: $TOOLCHAIN_FILE"
    exit 1
fi

# Check for sysroot
if [[ ! -d "$SYSROOT_DIR" ]]; then
    log_error "Sysroot directory not found: $SYSROOT_DIR"
    echo "Please run ./sync_sysroot.sh first."
    exit 1
fi

# Check for cross-compiler
if ! command -v "$CROSS_GCC" >/dev/null 2>&1; then
    log_error "Cross-compiler not found: $CROSS_GCC"
    echo "Please run ./setup_host.sh first."
    exit 1
fi

log_success "Build environment check complete"

# ==========================================
# Prepare build directory
# ==========================================
log_info "Preparing build directory..."

PROJECT_BUILD_DIR="$BUILD_DIR/$PROJECT_NAME"
mkdir -p "$PROJECT_BUILD_DIR"
cd "$PROJECT_BUILD_DIR"

# Clean up previous build files (optional)
if [[ -f "CMakeCache.txt" ]]; then
    log_info "Cleaning up existing CMake cache..."
    rm -f CMakeCache.txt
    rm -rf CMakeFiles/
fi

# ==========================================
# Configure CMake
# ==========================================
log_info "Configuring CMake..."
echo "  Project: $PROJECT_PATH"
echo "  Build Type: $BUILD_TYPE"
echo "  Toolchain: $TOOLCHAIN_FILE"

CMAKE_ARGS=(
    "-DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_FILE"
    "-DCMAKE_BUILD_TYPE=$BUILD_TYPE"
    "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"  # IDE support
)

if cmake "${CMAKE_ARGS[@]}" "$PROJECT_PATH"; then
    log_success "CMake configuration complete"
else
    log_error "CMake configuration failed"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Delete CMakeCache.txt and try again"
    echo "  2. Verify that Qt5 packages are installed correctly"
    echo "  3. Check the sysroot synchronization status"
    exit 1
fi

# ==========================================
# Run Build
# ==========================================
log_info "Running build... (Parallel jobs: $MAKE_JOBS)"

START_TIME=$(date +%s)

if make -j"$MAKE_JOBS"; then
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    log_success "Build complete! (Duration: ${DURATION}s)"
else
    log_error "Build failed"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Use 'make VERBOSE=1' for detailed error messages"
    echo "  2. Check dependency libraries"
    echo "  3. Check disk space and memory"
    exit 1
fi

# ==========================================
# Analyze Results
# ==========================================
log_info "Analyzing build results..."

# Find executables
EXECUTABLES=$(find . -maxdepth 1 -type f -executable -not -name "*.so*")

if [[ -n "$EXECUTABLES" ]]; then
    echo ""
    log_success "Generated executables:"
    
    for exe in $EXECUTABLES; do
        if [[ -f "$exe" ]]; then
            SIZE=$(du -h "$exe" | cut -f1)
            ARCH=$(file "$exe" | grep -o "ARM aarch64\|x86-64\|x86_64" || echo "Unknown")
            
            echo "  📁 $(basename "$exe")"
            echo "      Size: $SIZE"
            echo "      Architecture: $ARCH"
            echo "      Path: $(pwd)/$exe"
            echo ""
        fi
    done
    
    # Additional info for the first executable
    FIRST_EXE=$(echo "$EXECUTABLES" | head -n1)
    if [[ -f "$FIRST_EXE" ]]; then
        log_info "Executable details:"
        file "$FIRST_EXE"
        echo ""
        
        log_info "Dynamic library dependencies:"
        if command -v readelf >/dev/null 2>&1; then
            readelf -d "$FIRST_EXE" | grep NEEDED | head -10
        else
            echo "readelf command not found."
        fi
    fi
else
    log_warning "No executables found."
    echo "This might be a library-only build or the build did not complete successfully."
fi

# ==========================================
# Next Steps
# ==========================================
echo ""
log_success "Build process complete!"
echo ""
echo "Next steps:"
echo "  1. Transfer to Raspberry Pi:"
echo "     scp $(basename "$FIRST_EXE") $RPI_USER@$RPI_IP:~/"
echo ""
echo "  2. Execute on Raspberry Pi:"
echo "     ssh $RPI_USER@$RPI_IP './$(basename "$FIRST_EXE")'"
echo ""
echo "  3. Or use the deployment script:"
echo "     ./deploy.sh $(basename "$FIRST_EXE")"
echo ""
echo "Build location: $PROJECT_BUILD_DIR"
