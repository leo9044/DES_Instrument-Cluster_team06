"""
CAN Interface Module for PiRacer Instrument Cluster
Handles CAN bus communication for speed sensor data
"""

import can
import threading
import time
import struct
import subprocess
from typing import Optional, Dict, Any


class CANInterface:
    """CAN Bus Interface Class for PiRacer Speed Sensor Communication"""
    
    def __init__(self, interface: str = 'can0', bitrate: int = 500000):
        """
        Initialize CAN interface
        
        Args:
            interface: CAN interface name (default: can0)
            bitrate: CAN bus bitrate (default: 500000)
        """
        self.interface = interface
        self.bitrate = bitrate
        self.bus: Optional[can.Bus] = None
        self.is_running = False
        self.receive_thread: Optional[threading.Thread] = None
        
        # Speed sensor data storage
        self.speed_data = {
            'speed_kmh': 0.0,
            'rpm': 0,
            'timestamp': time.time()
        }
        
        # Lock for thread-safe data access
        self.data_lock = threading.Lock()
        
        # CAN message IDs (customize based on your speed sensor)
        self.SPEED_SENSOR_ID = 0x123  # Speed sensor CAN ID
        self.RPM_SENSOR_ID = 0x124    # RPM sensor CAN ID (optional)
        
    def setup_can_interface(self) -> bool:
        """
        Setup CAN interface using system commands
        
        Returns:
            bool: True if setup successful, False otherwise
        """
        try:
            # Check if this is a virtual CAN interface
            if self.interface.startswith('vcan'):
                # For virtual CAN, just check if interface exists and is up
                result = subprocess.run(['ip', 'link', 'show', self.interface], 
                                      capture_output=True, check=False)
                if result.returncode == 0:
                    print(f"Virtual CAN interface {self.interface} is available")
                    return True
                else:
                    print(f"Virtual CAN interface {self.interface} not found")
                    return False
            else:
                # For real CAN interfaces, configure bitrate
                # Bring down the interface if it exists
                subprocess.run(['sudo', 'ip', 'link', 'set', self.interface, 'down'], 
                             capture_output=True, check=False)
                
                # Configure CAN interface
                subprocess.run(['sudo', 'ip', 'link', 'set', self.interface, 'type', 'can', 
                              'bitrate', str(self.bitrate)], check=True)
                
                # Bring up the interface
                subprocess.run(['sudo', 'ip', 'link', 'set', self.interface, 'up'], check=True)
            
            print(f"CAN interface {self.interface} configured successfully")
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"Failed to setup CAN interface: {e}")
            return False
        except Exception as e:
            print(f"Error setting up CAN interface: {e}")
            return False
    
    def connect(self) -> bool:
        """
        Connect to CAN bus
        
        Returns:
            bool: True if connection successful, False otherwise
        """
        try:
            # Setup CAN interface first
            if not self.setup_can_interface():
                return False
            
            # Create CAN bus instance
            self.bus = can.Bus(interface='socketcan', 
                             channel=self.interface, 
                             receive_own_messages=True)
            
            print(f"Connected to CAN bus on {self.interface}")
            return True
            
        except Exception as e:
            print(f"Failed to connect to CAN bus: {e}")
            return False
    
    def disconnect(self):
        """Disconnect from CAN bus"""
        try:
            self.stop_receiving()
            if self.bus:
                self.bus.shutdown()
                self.bus = None
            print("Disconnected from CAN bus")
        except Exception as e:
            print(f"Error disconnecting from CAN bus: {e}")
    
    def start_receiving(self):
        """Start receiving CAN messages in a separate thread"""
        if self.is_running:
            return
        
        self.is_running = True
        self.receive_thread = threading.Thread(target=self._receive_messages)
        self.receive_thread.daemon = True
        self.receive_thread.start()
        print("Started CAN message receiving thread")
    
    def stop_receiving(self):
        """Stop receiving CAN messages"""
        self.is_running = False
        if self.receive_thread and self.receive_thread.is_alive():
            self.receive_thread.join(timeout=1.0)
        print("Stopped CAN message receiving")
    
    def _receive_messages(self):
        """Internal method to receive CAN messages (runs in separate thread)"""
        if not self.bus:
            print("CAN bus not connected")
            return
        
        while self.is_running:
            try:
                # Receive message with timeout
                message = self.bus.recv(timeout=1.0)
                if message:
                    self._process_message(message)
                    
            except Exception as e:
                if self.is_running:  # Only log errors if we're supposed to be running
                    print(f"Error receiving CAN message: {e}")
                time.sleep(0.1)
    
    def _process_message(self, message: can.Message):
        """
        Process received CAN message
        
        Args:
            message: Received CAN message
        """
        try:
            if message.arbitration_id == self.SPEED_SENSOR_ID:
                # Process speed data (customize based on your protocol)
                speed_kmh = self._parse_speed_data(message.data)
                
                with self.data_lock:
                    self.speed_data['speed_kmh'] = speed_kmh
                    self.speed_data['timestamp'] = time.time()
                
                print(f"Speed: {speed_kmh:.1f} km/h")
                
            elif message.arbitration_id == self.RPM_SENSOR_ID:
                # Process RPM data (optional)
                rpm = self._parse_rpm_data(message.data)
                
                with self.data_lock:
                    self.speed_data['rpm'] = rpm
                
                print(f"RPM: {rpm}")
                
        except Exception as e:
            print(f"Error processing CAN message: {e}")
    
    def _parse_speed_data(self, data: bytes) -> float:
        """
        Parse speed data from CAN message
        
        Args:
            data: Raw CAN message data bytes
            
        Returns:
            float: Speed in km/h
        """
        try:
            # Example: Assuming speed data is sent as float in first 4 bytes
            # Customize this based on your speed sensor protocol
            if len(data) >= 4:
                speed_raw = struct.unpack('<f', data[:4])[0]  # Little-endian float
                return max(0.0, speed_raw)  # Ensure non-negative speed
            else:
                # Alternative: speed as 2-byte integer (scaled)
                speed_raw = struct.unpack('<H', data[:2])[0]  # Little-endian uint16
                return speed_raw * 0.1  # Scale factor (adjust as needed)
                
        except Exception as e:
            print(f"Error parsing speed data: {e}")
            return 0.0
    
    def _parse_rpm_data(self, data: bytes) -> int:
        """
        Parse RPM data from CAN message
        
        Args:
            data: Raw CAN message data bytes
            
        Returns:
            int: RPM value
        """
        try:
            if len(data) >= 2:
                rpm_raw = struct.unpack('<H', data[:2])[0]  # Little-endian uint16
                return max(0, rpm_raw)
        except Exception as e:
            print(f"Error parsing RPM data: {e}")
            return 0
    
    def get_speed_data(self) -> Dict[str, Any]:
        """
        Get current speed data (thread-safe)
        
        Returns:
            dict: Speed data including speed_kmh, rpm, and timestamp
        """
        with self.data_lock:
            return self.speed_data.copy()
    
    def get_current_speed(self) -> float:
        """현재 속도만 반환 (간편 함수)"""
        with self.data_lock:
            return self.speed_data['speed_kmh']
    
    def is_connected(self) -> bool:
        """CAN 연결 상태 확인"""
        return self.bus is not None
    
    def send_message(self, can_id: int, data: bytes) -> bool:
        """
        Send CAN message (for testing purposes)
        
        Args:
            can_id: CAN message ID
            data: Message data bytes
            
        Returns:
            bool: True if sent successfully
        """
        try:
            if not self.bus:
                return False
            
            message = can.Message(arbitration_id=can_id, data=data, is_extended_id=False)
            self.bus.send(message)
            return True
            
        except Exception as e:
            print(f"Error sending CAN message: {e}")
            return False
    
    def send_test_speed_data(self, speed_kmh: float):
        """
        Send test speed data (for testing without actual sensor)
        
        Args:
            speed_kmh: Speed in km/h to send
        """
        try:
            # Pack speed as float
            data = struct.pack('<f', speed_kmh) + b'\x00' * 4  # Pad to 8 bytes
            self.send_message(self.SPEED_SENSOR_ID, data)
        except Exception as e:
            print(f"Error sending test speed data: {e}")


# Test/Demo functions
def demo_can_interface():
    """Demo function to test CAN interface"""
    can_interface = CANInterface()
    
    try:
        # Connect to CAN bus
        if not can_interface.connect():
            print("Failed to connect to CAN bus")
            return
        
        # Start receiving messages
        can_interface.start_receiving()
        
        print("CAN interface demo started. Press Ctrl+C to stop...")
        
        # Test sending some speed data
        test_speed = 0.0
        while True:
            # Send test speed data every 2 seconds
            can_interface.send_test_speed_data(test_speed)
            test_speed = (test_speed + 10) % 120  # Cycle 0-110 km/h
            
            # Print current speed data
            speed_data = can_interface.get_speed_data()
            print(f"Current data: {speed_data}")
            
            time.sleep(2)
            
    except KeyboardInterrupt:
        print("\nStopping CAN interface demo...")
    finally:
        can_interface.disconnect()


if __name__ == '__main__':
    demo_can_interface()
