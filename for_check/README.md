# 🚗 PiRacer Instrument Cluster

**A Real-time Digital Dashboard for PiRacer Vehicle**

[![Python](https://img.shields.io/badge/Python-3.8+-blue.svg)](https://python.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Raspberry%20Pi-red.svg)](https://raspberrypi.org)

## 📋 Overview

This project implements a comprehensive instrument cluster system for the PiRacer AI Kit, featuring:

- **Real-time Speed Monitoring** via CAN bus communication
- **Gamepad-controlled Vehicle System** with gear management (P/R/N/D)
- **OLED Display Interface** with status indicators
- **Modular Architecture** ready for Qt GUI integration
- **Performance Optimized** for embedded real-time control

## 🎯 Features

### ✅ Core Functionality
- [x] **Vehicle Control System** - Direct PiRacer hardware control
- [x] **CAN Bus Communication** - Speed sensor data acquisition  
- [x] **Gamepad Integration** - ShanWan controller support
- [x] **Display Management** - OLED status display
- [x] **Gear System** - Automotive-style transmission (P/R/N/D)

### 🚧 Planned Features
- [ ] **Qt GUI Dashboard** - Professional instrument cluster UI
- [ ] **Data Logging** - Trip data and diagnostics
- [ ] **Advanced Filtering** - Kalman filter for smooth data
- [ ] **Wireless Communication** - Remote monitoring capabilities

## 🏗️ System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Gamepad       │────│  Main Controller│────│   CAN Interface │
│   (ShanWan)     │    │   (main.py)     │    │  (Speed Sensor) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                               │
                    ┌──────────┼──────────┐
                    │                     │
            ┌─────────────────┐    ┌─────────────────┐
            │ Vehicle Control │    │ Display Control │
            │  (PiRacer HW)   │    │ (OLED + Qt GUI) │
            └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- **Hardware**: Raspberry Pi 4B + PiRacer AI Kit + ShanWan Gamepad
- **OS**: Raspberry Pi OS (64-bit recommended)
- **Python**: 3.8+ with pip

### Installation

1. **Clone Repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/DES_Instrument-Cluster.git
   cd DES_Instrument-Cluster
   ```

2. **Setup Environment**
   ```bash
   chmod +x scripts/setup.sh
   ./scripts/setup.sh
   ```

3. **Configure CAN Interface**
   ```bash
   sudo modprobe can
   sudo ip link add dev vcan0 type vcan
   sudo ip link set up vcan0
   ```

4. **Run Application**
   ```bash
   cd app/src
   python main.py
   ```

## 📁 Project Structure

```
DES_Instrument-Cluster/
├── README.md              # Main project documentation
├── LICENSE                # MIT License
├── .gitignore            # Git ignore rules
│
├── docs/                 # Documentation & Diagrams
│   ├── architecture.md   # System design documentation
│   ├── hardware_setup.md # Hardware connection guide
│   └── images/           # Screenshots & diagrams
│
├── hardware/             # Hardware Documentation
│   ├── wiring_diagram.png
│   └── can_setup.md
│
├── app/                  # Main Application
│   ├── src/              # Source code
│   │   ├── main.py              # Main controller
│   │   ├── vehicle_controller.py # PiRacer control
│   │   ├── can_interface.py     # CAN communication
│   │   ├── display_controller.py # Display management
│   │   └── gamepads.py          # Gamepad interface
│   └── include/          # Header files (for future C++)
│
├── test/                 # Test Cases
│   ├── unit_tests/       # Unit tests
│   └── integration_tests/ # System tests
│
├── scripts/              # Automation Scripts
│   ├── setup.sh          # Environment setup
│   └── can_setup.sh      # CAN interface configuration
│
├── config/               # Configuration Files
│   ├── can_config.ini    # CAN bus settings
│   └── display_config.ini # Display settings
│
└── resources/            # GUI Resources
    ├── icons/            # Application icons
    ├── fonts/            # Custom fonts
    └── images/           # UI images
```

## 🛠️ Development

### Core Modules

#### 🎮 Vehicle Controller (`vehicle_controller.py`)
- **Purpose**: Direct PiRacer hardware control
- **Key Features**: Gamepad input processing, gear system, safety limits
- **Hardware**: Interfaces with PiRacer servo/motor controllers

#### 📡 CAN Interface (`can_interface.py`)  
- **Purpose**: Real-time speed data acquisition
- **Key Features**: Thread-safe CAN communication, data parsing
- **Protocol**: Standard CAN 2.0B with 500kbps bitrate

#### 🖥️ Display Controller (`display_controller.py`)
- **Purpose**: Visual output management
- **Current**: OLED display (128x32)
- **Future**: Qt-based GUI dashboard

#### 🎯 Main Controller (`main.py`)
- **Purpose**: System integration and coordination
- **Key Features**: Module lifecycle, error handling, performance optimization

## 📊 Performance Metrics

- **Control Loop**: 100Hz (10ms cycle time)
- **CAN Update Rate**: 20Hz (50ms interval) 
- **Display Refresh**: 2Hz (500ms interval)
- **Input Latency**: <5ms (gamepad to actuator)

## 🔧 Configuration

### CAN Bus Setup
```bash
# Setup virtual CAN for testing
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0

# Setup real CAN interface
sudo ip link set can0 type can bitrate 500000
sudo ip link set up can0
```

### Gamepad Mapping
- **Left Stick X**: Steering control
- **Right Stick Y**: Throttle control
- **A Button**: Drive (D)
- **B Button**: Park (P)
- **X Button**: Neutral (N)
- **Y Button**: Reverse (R)

## 🧪 Testing

```bash
# Run unit tests
python -m pytest test/unit_tests/

# Run integration tests  
python -m pytest test/integration_tests/

# Run specific module test
cd app/src
python vehicle_controller.py
```

## 📈 Roadmap

### Phase 1: Core System ✅
- [x] Basic vehicle control
- [x] CAN communication
- [x] OLED display
- [x] Gamepad integration

### Phase 2: Professional GUI 🚧
- [ ] Qt-based dashboard
- [ ] Custom gauge widgets
- [ ] Professional styling
- [ ] Multi-display support

### Phase 3: Advanced Features 📋
- [ ] Data logging system
- [ ] Diagnostic interface
- [ ] Remote monitoring
- [ ] Performance analytics

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **PiRacer Team** - Hardware platform and Python library
- **Team4 & Team7** - Reference implementations and inspiration
- **Lagavulin9** - C++ PiRacer implementation reference

## 📞 Contact

- **Project Repository**: [GitHub Link]
- **Documentation**: [Wiki Link]
- **Issues**: [GitHub Issues]

---

**⚡ Built with passion for embedded systems and automotive technology**
