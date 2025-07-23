# Hardware Integration Guide

## Required Hardware

### Core Components
- **Raspberry Pi 4** (4GB or 8GB recommended)
- **MicroSD Card** (32GB Class 10 minimum)
- **PiRacer Kit** (Waveshare PiRacer Pro)
- **ShanWan USB Gamepad** (or compatible)
- **0.91" OLED Display** (128x32, I2C interface)
- **Arduino Uno** (for speed sensor simulation)

### Optional Components
- **7" Touchscreen Display** (for Qt GUI)
- **Real CAN Transceiver** (MCP2515/TJA1050)
- **External Speakers** (for audio feedback)
- **Status LEDs** (for system indicators)

## Pin Configuration

### Raspberry Pi GPIO
```
Pin Layout (BCM numbering):
┌─────────────────────────────────────┐
│  3V3  │ 5V   │ GPIO2 │ 5V   │ GPIO3 │
│  GND  │ GPIO4│ GPIO14│ GND  │ GPIO15│
│ GPIO18│ GPIO24│ GND  │ GPIO25│GPIO8 │
│  GND  │ GPIO7│ GPIO1 │ GPIO12│ GND  │
│ GPIO16│ GPIO20│ GPIO21│ 3V3  │      │
└─────────────────────────────────────┘

Used Pins:
- GPIO2 (SDA): I2C Data for OLED
- GPIO3 (SCL): I2C Clock for OLED
- GPIO18: PiRacer Servo Control
- GPIO12: PiRacer Motor Control
- GPIO16: Status LED (optional)
```

### I2C Configuration
```bash
# Enable I2C interface
sudo raspi-config
# → Interface Options → I2C → Enable

# Verify I2C devices
i2cdetect -y 1
# Should show OLED at address 0x3C
```

## PiRacer Setup

### Physical Assembly
1. **Mount the Raspberry Pi** on the PiRacer chassis
2. **Connect the servo motor** to GPIO18 (PWM)
3. **Connect the drive motor** to GPIO12 (PWM)
4. **Install the camera module** (optional)
5. **Secure all connections** with proper standoffs

### PiRacer Library Installation
```bash
# Install PiRacer Python library
pip3 install piracer-py

# Test basic functionality
python3 -c "
from piracer.cars import PiRacerStandard
piracer = PiRacerStandard()
piracer.set_steering_percent(0.0)
piracer.set_throttle_percent(0.0)
print('PiRacer initialized successfully')
"
```

## CAN Bus Setup

### Virtual CAN (Development)
```bash
# Create virtual CAN interface
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0

# Verify interface
ip link show vcan0
```

### Real CAN (Production)
```bash
# Load CAN modules
sudo modprobe can
sudo modprobe can_raw
sudo modprobe mcp251x

# Configure CAN interface
sudo ip link set can0 up type can bitrate 500000
sudo ip link set up can0

# Test CAN communication
cansend can0 123#DEADBEEF
candump can0
```

### Arduino Speed Sensor
```cpp
// Arduino code for speed sensor simulation
#include <mcp_can.h>
#include <SPI.h>

const int SPI_CS_PIN = 9;
const int SPEED_SENSOR_PIN = 2;

MCP_CAN CAN(SPI_CS_PIN);
volatile unsigned long lastPulseTime = 0;
volatile unsigned long pulseInterval = 0;
unsigned long lastSendTime = 0;

void setup() {
  Serial.begin(115200);
  
  // Initialize CAN bus at 500Kbps
  while (CAN_OK != CAN.begin(CAN_500KBPS)) {
    Serial.println("CAN BUS Shield init fail");
    delay(100);
  }
  Serial.println("CAN BUS Shield init ok!");
  
  // Setup speed sensor interrupt
  pinMode(SPEED_SENSOR_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(SPEED_SENSOR_PIN), 
                  speedPulse, FALLING);
}

void speedPulse() {
  unsigned long currentTime = micros();
  if (currentTime - lastPulseTime > 1000) { // Debounce
    pulseInterval = currentTime - lastPulseTime;
    lastPulseTime = currentTime;
  }
}

void loop() {
  unsigned long currentTime = millis();
  
  // Send speed data every 100ms
  if (currentTime - lastSendTime >= 100) {
    float speed = calculateSpeed();
    sendSpeedData(speed);
    lastSendTime = currentTime;
  }
  
  delay(10);
}

float calculateSpeed() {
  if (pulseInterval == 0) return 0.0;
  
  // Convert pulse interval to speed (km/h)
  // Assuming wheel circumference = 0.2m, pulses per revolution = 1
  float frequency = 1000000.0 / pulseInterval; // Hz
  float speed = frequency * 0.2 * 3.6; // km/h
  
  return min(speed, 100.0); // Limit to 100 km/h
}

void sendSpeedData(float speed) {
  unsigned char data[8];
  
  // Pack speed data into CAN message
  unsigned int speedInt = (unsigned int)(speed * 10); // 0.1 km/h resolution
  data[0] = 0x01; // Message type: Speed
  data[1] = (speedInt >> 8) & 0xFF;
  data[2] = speedInt & 0xFF;
  data[3] = 0x00; // Reserved
  data[4] = 0x00; // Reserved
  data[5] = 0x00; // Reserved
  data[6] = 0x00; // Reserved
  data[7] = 0x00; // Checksum (simple XOR)
  
  for (int i = 0; i < 7; i++) {
    data[7] ^= data[i];
  }
  
  // Send CAN message
  CAN.sendMsgBuf(0x123, 0, 8, data);
}
```

## Display Configuration

### OLED Display (128x32)
```bash
# Install required libraries
pip3 install adafruit-circuitpython-ssd1306
pip3 install pillow

# Test OLED connection
python3 -c "
import board
import busio
from adafruit_ssd1306 import SSD1306_I2C

i2c = busio.I2C(board.SCL, board.SDA)
oled = SSD1306_I2C(128, 32, i2c, addr=0x3C)
oled.fill(0)
oled.show()
print('OLED initialized successfully')
"
```

### Touchscreen Display (Optional)
```bash
# Enable touchscreen support
sudo apt-get install xinput-calibrator

# Configure display rotation
sudo nano /boot/config.txt
# Add: display_rotate=2 (for 180° rotation)

# Test touchscreen
xinput_calibrator
```

## Gamepad Configuration

### ShanWan USB Gamepad
```bash
# Install joystick utilities
sudo apt-get install joystick

# Test gamepad recognition
ls /dev/input/js*
# Should show: /dev/input/js0

# Calibrate gamepad
jstest-gtk /dev/input/js0

# Test button mapping
jstest /dev/input/js0
```

### Input Mapping
```python
# Button mapping for ShanWan gamepad
BUTTON_MAP = {
    'A': 0,        # Throttle/Brake
    'B': 1,        # Emergency stop
    'X': 2,        # Gear up
    'Y': 3,        # Gear down
    'SELECT': 6,   # System menu
    'START': 7,    # System start/stop
    'LEFT_STICK': 8,
    'RIGHT_STICK': 9
}

AXIS_MAP = {
    'LEFT_X': 0,   # Steering
    'LEFT_Y': 1,   # Throttle (analog)
    'RIGHT_X': 3,  # Camera pan (future)
    'RIGHT_Y': 4   # Camera tilt (future)
}
```

## System Integration

### Service Configuration
```bash
# Create systemd service
sudo nano /etc/systemd/system/piracer-cluster.service

[Unit]
Description=PiRacer Instrument Cluster
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/DES_Instrument-Cluster
ExecStart=/usr/bin/python3 app/src/main.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target

# Enable service
sudo systemctl enable piracer-cluster.service
sudo systemctl start piracer-cluster.service
```

### Auto-start Configuration
```bash
# Add to /etc/rc.local (before exit 0)
# Start CAN interface
ip link set up vcan0 2>/dev/null || true

# Start instrument cluster
cd /home/pi/DES_Instrument-Cluster
python3 app/src/main.py &

exit 0
```

## Troubleshooting

### Common Issues

#### CAN Bus Not Working
```bash
# Check kernel modules
lsmod | grep can

# Verify interface status
ip link show can0

# Check for errors
dmesg | grep can
```

#### OLED Display Not Detected
```bash
# Enable I2C
sudo raspi-config

# Check I2C devices
i2cdetect -y 1

# Verify wiring
# SDA → GPIO2 (Pin 3)
# SCL → GPIO3 (Pin 5)
# VCC → 3.3V (Pin 1)
# GND → GND (Pin 6)
```

#### Gamepad Not Recognized
```bash
# Check USB devices
lsusb

# Verify input devices
ls -la /dev/input/

# Check permissions
sudo chmod 666 /dev/input/js0
```

#### PiRacer Motor Issues
```bash
# Check PWM permissions
sudo usermod -a -G gpio pi

# Test servo control
python3 -c "
from piracer.cars import PiRacerStandard
car = PiRacerStandard()
car.set_steering_percent(0.5)  # 50% right
"
```

### Performance Optimization

#### CPU Performance
```bash
# Set CPU governor to performance
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Increase GPU memory split
sudo raspi-config
# → Advanced Options → Memory Split → 128
```

#### Real-time Scheduling
```bash
# Enable real-time priority
sudo nano /etc/security/limits.conf
# Add: pi soft rtprio 99
#      pi hard rtprio 99

# Use in Python
import os
os.sched_setscheduler(0, os.SCHED_FIFO, os.sched_param(50))
```

## Safety Considerations

### Emergency Stops
- **Hardware E-Stop**: Physical button connected to GPIO
- **Software E-Stop**: Gamepad button (B)
- **Watchdog Timer**: Automatic shutdown on system hang
- **Speed Limiting**: Maximum 50% throttle by default

### Fail-Safe Mechanisms
- **Lost Communication**: Auto-stop on CAN timeout
- **Invalid Input**: Reject out-of-range commands
- **System Overload**: Graceful degradation of features
- **Power Loss**: Automatic configuration save
