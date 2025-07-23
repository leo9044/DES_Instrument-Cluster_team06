#!/bin/bash
# CAN Interface Setup Script for PiRacer

set -e

echo "📡 CAN Interface Setup for PiRacer"
echo "=================================="

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Setup real CAN interface
setup_real_can() {
    local interface=${1:-can0}
    local bitrate=${2:-500000}
    
    print_status "Setting up real CAN interface: $interface"
    
    # Bring down interface if it exists
    if ip link show $interface > /dev/null 2>&1; then
        sudo ip link set $interface down
    fi
    
    # Configure CAN interface
    sudo ip link set $interface type can bitrate $bitrate
    sudo ip link set $interface up
    
    print_status "CAN interface $interface configured (bitrate: $bitrate)"
}

# Setup virtual CAN interface  
setup_virtual_can() {
    local interface=${1:-vcan0}
    
    print_status "Setting up virtual CAN interface: $interface"
    
    # Load vcan module
    sudo modprobe vcan
    
    # Remove interface if it exists
    if ip link show $interface > /dev/null 2>&1; then
        sudo ip link delete $interface
    fi
    
    # Create virtual CAN interface
    sudo ip link add dev $interface type vcan
    sudo ip link set up $interface
    
    print_status "Virtual CAN interface $interface created"
}

# Show CAN interfaces
show_can_interfaces() {
    print_status "Available CAN interfaces:"
    ip link show | grep can || print_warning "No CAN interfaces found"
}

# Test CAN interface
test_can_interface() {
    local interface=${1:-vcan0}
    
    print_status "Testing CAN interface: $interface"
    
    # Send test message
    cansend $interface 123#DEADBEEF
    
    # Listen for messages (background)
    timeout 2 candump $interface &
    
    # Send another test message
    sleep 0.5
    cansend $interface 456#CAFEBABE
    
    wait
    print_status "CAN test completed"
}

# Main function
main() {
    case ${1:-help} in
        "real")
            setup_real_can ${2:-can0} ${3:-500000}
            ;;
        "virtual") 
            setup_virtual_can ${2:-vcan0}
            ;;
        "test")
            test_can_interface ${2:-vcan0}
            ;;
        "show")
            show_can_interfaces
            ;;
        "help"|*)
            echo "Usage: $0 [command] [interface] [bitrate]"
            echo ""
            echo "Commands:"
            echo "  real [interface] [bitrate]  - Setup real CAN interface (default: can0 500000)"
            echo "  virtual [interface]         - Setup virtual CAN interface (default: vcan0)"  
            echo "  test [interface]           - Test CAN interface (default: vcan0)"
            echo "  show                       - Show available CAN interfaces"
            echo "  help                       - Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 virtual                 - Create vcan0"
            echo "  $0 real can0 500000       - Setup can0 with 500kbps"
            echo "  $0 test vcan0             - Test vcan0 interface"
            ;;
    esac
}

main "$@"
