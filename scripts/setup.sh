#!/bin/bash
# PiRacer Instrument Cluster - Environment Setup Script

set -e

echo "🚗 PiRacer Instrument Cluster - Setup Script"
echo "============================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Raspberry Pi
check_platform() {
    print_status "Checking platform..."
    if [ -f /proc/device-tree/model ]; then
        MODEL=$(cat /proc/device-tree/model)
        if [[ $MODEL == *"Raspberry Pi"* ]]; then
            print_status "Running on Raspberry Pi: $MODEL"
        else
            print_warning "Not running on Raspberry Pi. Some features may not work."
        fi
    else
        print_warning "Cannot detect platform. Assuming desktop environment."
    fi
}

# Update system packages
update_system() {
    print_status "Updating system packages..."
    sudo apt update
    sudo apt upgrade -y
}

# Install system dependencies
install_system_deps() {
    print_status "Installing system dependencies..."
    sudo apt install -y \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        git \
        can-utils \
        i2c-tools \
        build-essential \
        cmake \
        pkg-config \
        libjpeg-dev \
        libpng-dev \
        libtiff-dev \
        libfreetype6-dev \
        libwebp-dev \
        libopenjp2-7-dev \
        liblcms2-dev \
        libharfbuzz-dev \
        libfribidi-dev
}

# Setup Python virtual environment
setup_venv() {
    print_status "Setting up Python virtual environment..."
    
    # Create virtual environment
    if [ ! -d "venv" ]; then
        python3 -m venv venv
        print_status "Virtual environment created"
    else
        print_status "Virtual environment already exists"
    fi
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install Python dependencies
    print_status "Installing Python dependencies..."
    pip install \
        piracer-py \
        python-can \
        pillow \
        pytest \
        pytest-cov \
        black \
        flake8
}

# Setup CAN interface
setup_can() {
    print_status "Setting up CAN interface..."
    
    # Load CAN modules
    sudo modprobe can
    sudo modprobe can_raw
    sudo modprobe can_bcm
    sudo modprobe vcan
    
    # Create virtual CAN interface for testing
    if ! ip link show vcan0 > /dev/null 2>&1; then
        sudo ip link add dev vcan0 type vcan
        sudo ip link set up vcan0
        print_status "Virtual CAN interface (vcan0) created"
    else
        print_status "Virtual CAN interface (vcan0) already exists"
    fi
}

# Enable I2C
enable_i2c() {
    print_status "Enabling I2C interface..."
    
    # Check if I2C is already enabled
    if lsmod | grep -q i2c_bcm2835; then
        print_status "I2C already enabled"
    else
        # Enable I2C in config
        if grep -q "^dtparam=i2c_arm=on" /boot/config.txt; then
            print_status "I2C already configured in /boot/config.txt"
        else
            echo "dtparam=i2c_arm=on" | sudo tee -a /boot/config.txt
            print_warning "I2C enabled. Reboot required for changes to take effect."
        fi
    fi
}

# Create necessary directories
create_directories() {
    print_status "Creating project directories..."
    mkdir -p logs
    mkdir -p data
    mkdir -p test_results
}

# Set permissions
set_permissions() {
    print_status "Setting file permissions..."
    chmod +x scripts/*.sh
    chmod +x app/src/main.py
}

# Main setup function
main() {
    echo ""
    print_status "Starting PiRacer Instrument Cluster setup..."
    echo ""
    
    check_platform
    update_system
    install_system_deps
    setup_venv
    setup_can
    enable_i2c
    create_directories
    set_permissions
    
    echo ""
    print_status "Setup completed successfully! 🎉"
    echo ""
    echo "Next steps:"
    echo "1. Activate virtual environment: source venv/bin/activate"
    echo "2. Test the installation: cd app/src && python main.py"
    echo "3. For real CAN interface, run: sudo scripts/can_setup.sh"
    echo ""
    print_warning "If I2C was just enabled, please reboot your Raspberry Pi."
}

# Run main function
main "$@"
