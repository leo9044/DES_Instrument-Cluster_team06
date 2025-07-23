# Development Guide

## Getting Started

### Prerequisites
- Python 3.8+ installed
- Git version control
- VS Code or PyCharm (recommended)
- Basic understanding of Python and embedded systems
- Raspberry Pi 4 with Raspberry Pi OS

### Development Environment Setup

#### 1. Clone the Repository
```bash
git clone https://github.com/your-username/DES_Instrument-Cluster.git
cd DES_Instrument-Cluster
```

#### 2. Create Virtual Environment
```bash
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate     # Windows
```

#### 3. Install Dependencies
```bash
pip install -r requirements.txt

# For development dependencies
pip install -r requirements-dev.txt
```

#### 4. Setup Hardware Simulation
```bash
# Run setup script
chmod +x scripts/setup.sh
./scripts/setup.sh

# Configure virtual CAN
chmod +x scripts/can_setup.sh
./scripts/can_setup.sh
```

## Code Style and Standards

### Python Coding Standards
We follow PEP 8 with some project-specific modifications:

```python
# Good example
class VehicleController:
    """Controls PiRacer vehicle hardware with safety limits."""
    
    def __init__(self, max_speed: float = 0.5):
        """Initialize vehicle controller.
        
        Args:
            max_speed: Maximum throttle percentage (0.0-1.0)
        """
        self._max_speed = max_speed
        self._current_gear = GearState.PARK
        self._piracer = PiRacerStandard()
    
    def set_throttle(self, throttle: float) -> bool:
        """Set vehicle throttle with safety checks.
        
        Args:
            throttle: Throttle percentage (-1.0 to 1.0)
            
        Returns:
            True if throttle was set successfully
        """
        if not self._is_safe_to_drive():
            return False
            
        limited_throttle = self._apply_limits(throttle)
        self._piracer.set_throttle_percent(limited_throttle)
        return True
```

### Type Hints
All functions must include type hints:

```python
from typing import Optional, Dict, List, Tuple
from dataclasses import dataclass

@dataclass
class SpeedData:
    """Container for speed sensor data."""
    speed_kmh: float
    timestamp: float
    sensor_id: int
    is_valid: bool = True

def process_can_message(
    msg_id: int, 
    data: bytes
) -> Optional[SpeedData]:
    """Process incoming CAN message."""
    pass
```

### Documentation Standards
Use Google-style docstrings:

```python
def calculate_steering_angle(gamepad_input: float, 
                           current_speed: float) -> float:
    """Calculate steering angle with speed-dependent sensitivity.
    
    Args:
        gamepad_input: Raw gamepad input (-1.0 to 1.0)
        current_speed: Current vehicle speed in km/h
        
    Returns:
        Calculated steering angle in degrees
        
    Raises:
        ValueError: If gamepad input is out of range
        
    Example:
        >>> calculate_steering_angle(0.5, 20.0)
        15.3
    """
    if not -1.0 <= gamepad_input <= 1.0:
        raise ValueError("Gamepad input must be between -1.0 and 1.0")
    
    # Speed-dependent sensitivity curve
    sensitivity = max(0.3, 1.0 - (current_speed / 50.0))
    return gamepad_input * 30.0 * sensitivity
```

## Project Structure

### Module Organization
```
app/src/
├── main.py                 # Application entry point
├── vehicle_controller.py   # Hardware control layer
├── can_interface.py       # CAN communication
├── display_controller.py  # Display management
└── gamepads.py           # Input handling
```

### Configuration Management
```python
# config/can_config.ini
[CAN]
interface = vcan0
bitrate = 500000
timeout = 1.0
message_id = 0x123

[DISPLAY]
width = 128
height = 32
i2c_address = 0x3C
refresh_rate = 2
```

## Testing Strategy

### Unit Tests
```python
# test/test_vehicle_controller.py
import unittest
from unittest.mock import Mock, patch
from app.src.vehicle_controller import VehicleController, GearState

class TestVehicleController(unittest.TestCase):
    
    def setUp(self):
        """Set up test fixtures."""
        with patch('app.src.vehicle_controller.PiRacerStandard'):
            self.controller = VehicleController()
    
    def test_gear_change_from_park(self):
        """Test gear changes from park position."""
        # Test valid gear change
        result = self.controller.change_gear('D')
        self.assertTrue(result)
        self.assertEqual(self.controller.current_gear, GearState.DRIVE)
        
        # Test invalid gear change
        result = self.controller.change_gear('X')
        self.assertFalse(result)
        self.assertEqual(self.controller.current_gear, GearState.DRIVE)
    
    def test_safety_limits(self):
        """Test throttle safety limiting."""
        # Test normal throttle
        result = self.controller.set_throttle(0.3)
        self.assertTrue(result)
        
        # Test excessive throttle
        with patch.object(self.controller, '_max_speed', 0.5):
            result = self.controller.set_throttle(0.8)
            self.assertTrue(result)  # Should be limited to 0.5
```

### Integration Tests
```python
# test/test_integration.py
import unittest
import time
from app.src.main import InstrumentClusterMain

class TestSystemIntegration(unittest.TestCase):
    
    def setUp(self):
        """Set up integration test environment."""
        self.cluster = InstrumentClusterMain()
    
    def test_full_system_startup(self):
        """Test complete system initialization."""
        success = self.cluster.initialize()
        self.assertTrue(success)
        
        # Verify all modules are initialized
        self.assertIsNotNone(self.cluster.vehicle_controller)
        self.assertIsNotNone(self.cluster.can_interface)
        self.assertIsNotNone(self.cluster.display_controller)
    
    def test_gamepad_to_vehicle_control(self):
        """Test end-to-end control flow."""
        self.cluster.initialize()
        
        # Simulate gamepad input
        test_input = {
            'steering': 0.5,
            'throttle': 0.3,
            'buttons': {'gear_up': True}
        }
        
        # Process input and verify response
        self.cluster.process_gamepad_input(test_input)
        
        # Verify gear change
        self.assertEqual(
            self.cluster.vehicle_controller.current_gear, 
            GearState.DRIVE
        )
```

### Hardware-in-the-Loop Testing
```python
# test/test_hardware.py
import unittest
from app.src.can_interface import CANInterface

class TestHardwareIntegration(unittest.TestCase):
    
    @unittest.skipUnless(
        os.path.exists('/dev/input/js0'), 
        "Gamepad not connected"
    )
    def test_real_gamepad(self):
        """Test with actual hardware gamepad."""
        from app.src.gamepads import GamepadManager
        
        gamepad = GamepadManager()
        self.assertTrue(gamepad.initialize())
        
        # Test input reading
        events = gamepad.get_events()
        self.assertIsInstance(events, list)
    
    @unittest.skipUnless(
        os.path.exists('/sys/class/net/can0'), 
        "CAN interface not available"
    )
    def test_real_can_interface(self):
        """Test with actual CAN hardware."""
        can_interface = CANInterface('can0')
        self.assertTrue(can_interface.initialize())
        
        # Test message sending
        result = can_interface.send_test_message()
        self.assertTrue(result)
```

## Debugging and Profiling

### Logging Configuration
```python
# app/src/utils/logging_config.py
import logging
import logging.handlers
from pathlib import Path

def setup_logging(log_level: str = "INFO") -> logging.Logger:
    """Configure application logging."""
    
    # Create logs directory
    log_dir = Path("logs")
    log_dir.mkdir(exist_ok=True)
    
    # Configure logger
    logger = logging.getLogger("piracer_cluster")
    logger.setLevel(getattr(logging, log_level.upper()))
    
    # File handler with rotation
    file_handler = logging.handlers.RotatingFileHandler(
        log_dir / "cluster.log",
        maxBytes=10_000_000,  # 10MB
        backupCount=5
    )
    
    # Console handler
    console_handler = logging.StreamHandler()
    
    # Formatter
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    file_handler.setFormatter(formatter)
    console_handler.setFormatter(formatter)
    
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)
    
    return logger
```

### Performance Monitoring
```python
# app/src/utils/performance.py
import time
import psutil
from contextlib import contextmanager
from typing import Generator

class PerformanceMonitor:
    """Monitor system performance metrics."""
    
    def __init__(self):
        self.metrics = {}
    
    @contextmanager
    def measure_time(self, operation: str) -> Generator[None, None, None]:
        """Measure execution time of an operation."""
        start_time = time.perf_counter()
        try:
            yield
        finally:
            end_time = time.perf_counter()
            duration = end_time - start_time
            self.metrics[operation] = duration
    
    def get_system_metrics(self) -> dict:
        """Get current system resource usage."""
        return {
            'cpu_percent': psutil.cpu_percent(),
            'memory_percent': psutil.virtual_memory().percent,
            'disk_usage': psutil.disk_usage('/').percent,
            'temperature': self._get_cpu_temperature()
        }
    
    def _get_cpu_temperature(self) -> float:
        """Get CPU temperature (Raspberry Pi specific)."""
        try:
            with open('/sys/class/thermal/thermal_zone0/temp', 'r') as f:
                temp = int(f.read().strip()) / 1000.0
            return temp
        except:
            return 0.0

# Usage example
monitor = PerformanceMonitor()

with monitor.measure_time('can_processing'):
    # Process CAN messages
    pass

print(f"CAN processing took: {monitor.metrics['can_processing']:.3f}s")
```

### Memory Profiling
```python
# Development tool for memory analysis
import tracemalloc
from memory_profiler import profile

@profile
def analyze_memory_usage():
    """Profile memory usage of main components."""
    tracemalloc.start()
    
    # Initialize components
    from app.src.main import InstrumentClusterMain
    cluster = InstrumentClusterMain()
    cluster.initialize()
    
    # Take snapshot
    snapshot = tracemalloc.take_snapshot()
    top_stats = snapshot.statistics('lineno')
    
    print("Top 10 memory allocations:")
    for stat in top_stats[:10]:
        print(stat)
```

## Contributing Guidelines

### Development Workflow

1. **Feature Development**
   ```bash
   # Create feature branch
   git checkout -b feature/new-display-mode
   
   # Make changes and commit
   git add .
   git commit -m "Add new display mode for speed visualization"
   
   # Push and create pull request
   git push origin feature/new-display-mode
   ```

2. **Code Review Process**
   - All code must be reviewed by at least one team member
   - Automated tests must pass
   - Code coverage should not decrease
   - Documentation must be updated for API changes

3. **Merge Requirements**
   - Squash commits before merging
   - Use conventional commit messages
   - Update CHANGELOG.md
   - Tag releases with semantic versioning

### Conventional Commits
```
feat: add new gear display animation
fix: resolve CAN timeout handling issue
docs: update hardware setup instructions
test: add unit tests for vehicle controller
refactor: simplify display controller architecture
```

### Release Process

1. **Version Bumping**
   ```bash
   # Update version in setup.py and __init__.py
   # Update CHANGELOG.md
   # Create release commit
   git commit -m "chore: bump version to 1.2.0"
   git tag v1.2.0
   git push origin main --tags
   ```

2. **Release Testing**
   ```bash
   # Run full test suite
   python -m pytest test/ -v --cov=app/src/
   
   # Run integration tests on hardware
   python -m pytest test/test_hardware.py -v
   
   # Performance benchmarks
   python scripts/benchmark.py
   ```

## Advanced Topics

### Custom Extensions

#### Adding New Display Modes
```python
# app/src/display/modes/custom_mode.py
from app.src.display_controller import DisplayMode
from PIL import Image, ImageDraw, ImageFont

class RacingMode(DisplayMode):
    """High-performance racing display mode."""
    
    def __init__(self):
        super().__init__()
        self.font_large = ImageFont.truetype("Arial.ttf", 20)
        self.font_small = ImageFont.truetype("Arial.ttf", 12)
    
    def render(self, data: dict) -> Image:
        """Render racing-focused display."""
        image = Image.new('1', (128, 32), 0)
        draw = ImageDraw.Draw(image)
        
        # Large speed display
        speed = data.get('speed', 0)
        draw.text((10, 5), f"{speed:.0f}", font=self.font_large, fill=1)
        draw.text((50, 8), "km/h", font=self.font_small, fill=1)
        
        # Gear indicator
        gear = data.get('gear', 'P')
        draw.text((90, 5), gear, font=self.font_large, fill=1)
        
        # Performance bar
        throttle = data.get('throttle', 0)
        bar_width = int(throttle * 100)
        draw.rectangle([(10, 25), (10 + bar_width, 30)], fill=1)
        
        return image
```

#### Custom Input Handlers
```python
# app/src/input/custom_input.py
from app.src.gamepads import InputHandler

class SteeringWheelHandler(InputHandler):
    """Support for racing wheel controllers."""
    
    def __init__(self, device_path: str):
        super().__init__(device_path)
        self.wheel_range = 900  # degrees
        self.force_feedback = True
    
    def process_input(self, raw_input: dict) -> dict:
        """Process steering wheel input with force feedback."""
        processed = super().process_input(raw_input)
        
        # Add force feedback based on speed
        if self.force_feedback:
            speed = self.get_current_speed()
            force = self.calculate_force_feedback(speed)
            self.apply_force_feedback(force)
        
        return processed
```

### Performance Optimization

#### Real-time Scheduling
```python
# app/src/utils/realtime.py
import os
import threading
from ctypes import cdll, c_int

class RealtimeScheduler:
    """Configure real-time scheduling for critical threads."""
    
    @staticmethod
    def set_realtime_priority(priority: int = 50):
        """Set real-time priority for current thread."""
        try:
            libc = cdll.LoadLibrary("libc.so.6")
            
            # SCHED_FIFO = 1
            sched_param = c_int(priority)
            result = libc.sched_setscheduler(
                0,  # Current process
                1,  # SCHED_FIFO
                sched_param
            )
            
            return result == 0
        except Exception as e:
            print(f"Failed to set real-time priority: {e}")
            return False

# Usage in critical threads
def control_loop():
    """Main control loop with real-time priority."""
    RealtimeScheduler.set_realtime_priority(50)
    
    while running:
        # Critical real-time operations
        process_control_input()
        update_vehicle_output()
        time.sleep(0.01)  # 100Hz
```

This completes the comprehensive development documentation for the PiRacer Instrument Cluster project!
