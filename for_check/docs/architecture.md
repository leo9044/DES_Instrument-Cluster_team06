# System Architecture

## Overview

The PiRacer Instrument Cluster follows a modular, layered architecture designed for real-time embedded systems.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     User Interface Layer                    │
├─────────────────────────────────────────────────────────────┤
│  OLED Display    │    Qt GUI (Future)   │   Web Interface  │
│  (128x32)        │    (800x480)         │   (Remote)       │
└─────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────┐
│                   Application Layer                         │
├─────────────────────────────────────────────────────────────┤
│                  Main Controller                            │
│              (main.py - Orchestrator)                       │
└─────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────┐
│                    Service Layer                            │
├─────────────────────────────────────────────────────────────┤
│  Vehicle Control │  CAN Interface  │  Display Control      │
│  - Gamepad Input │  - Speed Data   │  - OLED Management    │
│  - Gear System   │  - Message Parse│  - Status Display     │
│  - Safety Limits │  - Threading    │  - Error Handling     │
└─────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────┐
│                   Hardware Layer                            │
├─────────────────────────────────────────────────────────────┤
│  PiRacer HW      │  CAN Bus        │  ShanWan Gamepad      │
│  - Servo Motor   │  - Speed Sensor │  - USB Interface      │
│  - Steering      │  - Arduino      │  - Input Events       │
│  - I2C Display   │  - MCP2515      │  - Button Mapping     │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### Main Controller (`main.py`)
- **Role**: System orchestrator and lifecycle manager
- **Responsibilities**:
  - Module initialization and configuration
  - Main event loop execution (100Hz)
  - Error handling and recovery
  - Resource cleanup
  - Performance monitoring

### Vehicle Controller (`vehicle_controller.py`)
- **Role**: Direct hardware interface for vehicle control
- **Responsibilities**:
  - Gamepad input processing
  - Gear state management (P/R/N/D)
  - Safety limit enforcement
  - PiRacer servo/motor control
  - Real-time response (<5ms latency)

### CAN Interface (`can_interface.py`)
- **Role**: Communication with speed sensors via CAN bus
- **Responsibilities**:
  - CAN bus initialization and management
  - Message parsing and validation
  - Thread-safe data access
  - Error detection and recovery
  - Support for both real and virtual CAN

### Display Controller (`display_controller.py`)
- **Role**: Visual output management across multiple displays
- **Responsibilities**:
  - OLED display management (current)
  - Qt GUI integration (future)
  - Layout and rendering
  - Status indication
  - Error message display

### Gamepad Interface (`gamepads.py`)
- **Role**: Human-machine interface for vehicle control
- **Responsibilities**:
  - USB HID device management
  - Button and analog input processing
  - Input mapping and scaling
  - Event generation

## Data Flow

### Control Flow
```
Gamepad Input → Vehicle Controller → PiRacer Hardware
     ↓
Main Controller ← Status Feedback ← Hardware Sensors
     ↓
Display Controller → OLED/GUI → User Feedback
```

### Speed Data Flow
```
Speed Sensor → Arduino → CAN Bus → CAN Interface → Main Controller
                                                           ↓
                                           Display Controller → Speed Display
```

## Threading Model

The system uses a multi-threaded approach for real-time performance:

- **Main Thread**: Control loop (100Hz)
- **CAN Receive Thread**: Message processing (background)
- **Display Thread**: UI updates (2Hz)
- **Future: GUI Thread**: Qt event loop

## Error Handling

### Error Categories
1. **Hardware Errors**: Sensor failures, communication timeouts
2. **Software Errors**: Module crashes, memory issues
3. **Configuration Errors**: Invalid settings, missing files
4. **User Errors**: Invalid input, unsafe operations

### Recovery Strategies
- **Graceful Degradation**: Continue operation with reduced functionality
- **Automatic Retry**: Reconnect failed components
- **Safe Mode**: Disable dangerous operations
- **User Notification**: Clear error messages and status indicators

## Performance Requirements

### Real-time Constraints
- **Control Loop**: 10ms maximum cycle time
- **Input Latency**: <5ms gamepad to actuator
- **CAN Response**: <50ms message processing
- **Display Update**: <500ms user feedback

### Resource Limits
- **CPU Usage**: <50% on Raspberry Pi 4
- **Memory Usage**: <128MB total
- **Disk I/O**: Minimal (logging only)
- **Network**: CAN bus only (no TCP/IP)

## Security Considerations

### Safety Features
- **Input Validation**: All user inputs sanitized
- **Range Limiting**: Speed and steering constraints
- **Emergency Stop**: Immediate halt capability
- **Watchdog**: Automatic system recovery

### Access Control
- **Local Only**: No remote access by default
- **File Permissions**: Restricted system access
- **Hardware Access**: Controlled GPIO/I2C usage

## Scalability

### Horizontal Scaling
- **Multiple Displays**: Support for additional screens
- **Sensor Expansion**: Additional CAN devices
- **Control Interfaces**: Multiple input devices

### Vertical Scaling
- **Processing Power**: Optimized for Raspberry Pi 4+
- **Memory Efficiency**: Minimal resource usage
- **Storage**: Configurable logging and data retention

## Technology Stack

### Core Technologies
- **Python 3.8+**: Main application language
- **Linux**: Raspberry Pi OS (Debian-based)
- **CAN Utils**: Kernel-level CAN support
- **PIL/Pillow**: Image processing for OLED

### Future Technologies
- **Qt 6**: Professional GUI framework
- **SQLite**: Local data storage
- **gRPC**: Remote monitoring protocol
- **Docker**: Containerized deployment
