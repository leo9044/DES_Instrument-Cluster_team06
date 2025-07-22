#!/usr/bin/env python3
"""
CAN Test Script for PiRacer Instrument Cluster
Tests CAN communication by sending simulated speed data
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import time
import random
from src.can_interface import CANInterface

def test_can_communication():
    """Test CAN communication with simulated speed data"""
    print("=== CAN Communication Test ===")
    
    # Use virtual CAN interface for testing
    can_interface = CANInterface(interface='vcan0')
    
    try:
        # Connect to CAN bus
        print("Connecting to CAN bus...")
        if not can_interface.connect():
            print("❌ Failed to connect to CAN bus")
            print("Make sure:")
            print("1. CAN hardware is connected")
            print("2. CAN interface is configured")
            print("3. Running with sudo privileges")
            return False
        
        print("✅ Connected to CAN bus successfully")
        
        # Start receiving messages
        print("Starting message reception...")
        can_interface.start_receiving()
        print("✅ Message reception started")
        
        # Test 1: Send static speed data
        print("\n--- Test 1: Static Speed Data ---")
        test_speeds = [0.0, 25.5, 50.0, 75.2, 100.0]
        
        for speed in test_speeds:
            print(f"Sending speed: {speed} km/h")
            can_interface.send_test_speed_data(speed)
            time.sleep(1)
            
            # Read back the data
            speed_data = can_interface.get_speed_data()
            print(f"Received: {speed_data['speed_kmh']:.1f} km/h")
            time.sleep(1)
        
        # Test 2: Dynamic speed simulation
        print("\n--- Test 2: Dynamic Speed Simulation ---")
        print("Simulating driving scenario for 30 seconds...")
        
        start_time = time.time()
        speed = 0.0
        direction = 1
        
        while time.time() - start_time < 30:
            # Simulate acceleration and deceleration
            speed += direction * random.uniform(0.5, 3.0)
            
            if speed >= 120:
                direction = -1  # Start decelerating
            elif speed <= 0:
                speed = 0
                direction = 1  # Start accelerating
            
            # Send speed data
            can_interface.send_test_speed_data(speed)
            
            # Read and display current data
            speed_data = can_interface.get_speed_data()
            print(f"Speed: {speed_data['speed_kmh']:.1f} km/h | "
                  f"Age: {time.time() - speed_data['timestamp']:.1f}s")
            
            time.sleep(0.5)
        
        print("\n✅ CAN communication test completed successfully!")
        return True
        
    except KeyboardInterrupt:
        print("\n⏹️ Test interrupted by user")
        return True
    except Exception as e:
        print(f"❌ Test failed with error: {e}")
        return False
    finally:
        # Clean up
        print("\nCleaning up...")
        can_interface.disconnect()
        print("✅ Test cleanup completed")


def check_can_interface():
    """Check if CAN interface is available and configured"""
    print("=== CAN Interface Check ===")
    
    import subprocess
    
    try:
        # Check if can-utils is installed
        result = subprocess.run(['which', 'candump'], capture_output=True, text=True)
        if result.returncode != 0:
            print("❌ can-utils not installed")
            print("Install with: sudo apt-get install can-utils")
            return False
        print("✅ can-utils installed")
        
        # Check available CAN interfaces
        result = subprocess.run(['ip', 'link', 'show'], capture_output=True, text=True)
        can_interfaces = []
        
        for line in result.stdout.split('\n'):
            if 'can' in line.lower() and ':' in line:
                interface = line.split(':')[1].strip().split('@')[0]
                can_interfaces.append(interface)
        
        if can_interfaces:
            print(f"✅ Found CAN interfaces: {', '.join(can_interfaces)}")
        else:
            print("⚠️ No CAN interfaces found")
            print("Available interfaces might include: can0, vcan0")
        
        # Check if virtual CAN is available
        result = subprocess.run(['lsmod'], capture_output=True, text=True)
        if 'vcan' in result.stdout:
            print("✅ Virtual CAN (vcan) module loaded")
        else:
            print("⚠️ Virtual CAN module not loaded")
            print("Load with: sudo modprobe vcan")
        
        return True
        
    except Exception as e:
        print(f"❌ Interface check failed: {e}")
        return False


def setup_virtual_can():
    """Setup virtual CAN interface for testing"""
    print("=== Setting up Virtual CAN for Testing ===")
    
    import subprocess
    
    try:
        # Load vcan module
        print("Loading vcan module...")
        subprocess.run(['sudo', 'modprobe', 'vcan'], check=True)
        print("✅ vcan module loaded")
        
        # Create virtual CAN interface
        print("Creating vcan0 interface...")
        subprocess.run(['sudo', 'ip', 'link', 'add', 'dev', 'vcan0', 'type', 'vcan'], 
                      capture_output=True, check=False)  # Don't fail if already exists
        
        # Bring up the interface
        subprocess.run(['sudo', 'ip', 'link', 'set', 'up', 'vcan0'], check=True)
        print("✅ vcan0 interface created and brought up")
        
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to setup virtual CAN: {e}")
        return False
    except Exception as e:
        print(f"❌ Setup error: {e}")
        return False


def main():
    """Main test function"""
    print("🚗 PiRacer Instrument Cluster - CAN Test Suite")
    print("=" * 50)
    
    # Step 1: Check CAN interface availability
    if not check_can_interface():
        print("\n❌ CAN interface check failed")
        return
    
    # Step 2: Setup virtual CAN for testing (if no hardware available)
    print(f"\n{'='*50}")
    setup_virtual_can()
    
    # Step 3: Test CAN communication
    print(f"\n{'='*50}")
    
    if test_can_communication():
        print("\n🎉 All tests passed! CAN communication is working.")
        print("\nNext steps:")
        print("1. Connect your actual CAN hardware")
        print("2. Modify CAN message IDs in can_interface.py to match your sensor")
        print("3. Run the integrated controller: python3 controller_with_can.py")
    else:
        print("\n⚠️ Some tests failed. Check your CAN setup.")


if __name__ == '__main__':
    main()
