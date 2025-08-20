# PiRacer Digital Instrument Cluster

This is a real-time digital instrument cluster application for the PiRacer vehicle, developed with Qt. It runs on a Raspberry Pi, receiving vehicle speed data via CAN bus and other data like battery and gear status via D-Bus to display on a GUI.


<p align="center">
  <img src="https://github.com/user-attachments/assets/06e859e9-9b4d-4404-b436-e556d9a8056b" width="800">
</p>



## Key Features

* **Real-time Data Visualization**: Displays vehicle speed from the CAN bus on a real-time speedometer.
* **Vehicle Status Display**: Shows battery state of charge (SOC) received through D-Bus.
* **Modular Architecture**: Employs a flexible and scalable structure by decoupling the data processing part (Python) from the GUI (Qt/C++) using D-Bus.
* **Qt/QML-based UI**: Provides a user-friendly graphical interface designed with Qt Design Studio.

## System Architecture & Design Decisions
```mermaid
graph TD
    subgraph "Host PC (Development Environment)"
        A[Qt Creator Project] -- Cross-Compile --> B[Executable File]
        B -- scp --> C[Raspberry Pi]
    end

    subgraph "Raspberry Pi (Runtime Environment)"
        D[Optical Sensor] --> E[Arduino]
        E --> F[CAN Bus]
        F --> G[Qt Application]
        
        H[Python Scripts] --> I[D-Bus]
        I --> G
        
        C -- Executes --> G
        G --> J[GUI Display]
    end

    %% Styling
    style G fill:#baffc9,stroke:#333,stroke-width:2px
    
### Data Flow

This project integrates two independent data streams:

1.  **Real-time Speed Data (Direct CAN Communication)**
    * **Measurement (Arduino)**: An optical speed sensor connected to an Arduino detects wheel rotation and sends speed data over the CAN bus.
    * **Reception & Processing (Qt/C++)**: A C++ CAN interface (`caninterface.cpp`) within the Qt application directly receives and processes the real-time speed data from the CAN bus.

2.  **Vehicle Status Data (D-Bus IPC)**
    * **Publishing (Python on RPi)**: Separate Python scripts (`vehicle_controller.py`, `soc.py`) act as D-Bus 'Senders', broadcasting information like battery and gear status.
    * **Subscribing (Qt/C++)**: The Qt application's D-Bus client (`dbusreceiver.cpp`) acts as a 'Receiver', subscribing to this status data and reflecting it on the GUI.

### Development Decisions

This project intentionally adopted specific development methodologies to deepen technical understanding.

* **Cross-Compilation Environment**: We adopted a professional embedded development workflow by cross-compiling on a powerful development PC and deploying only the executable to the resource-constrained Raspberry Pi. This significantly reduced build times and maximized productivity.
* **IPC using D-Bus**: We deliberately separated the data processing logic (Python) from the GUI (Qt/C++) and connected them via D-Bus. The goal was to experience a modular design where multiple, single-responsibility processes communicate, which greatly enhances the system's flexibility and scalability.

## Tech Stack

* **Hardware**:
    * **Main Controller**: Raspberry Pi 4
    * **Sensor Controller**: Arduino Uno (ATmega328P)
    * **CAN Interface**: Keyestudio CAN-BUS Shield (MCP2515 + MCP2551), Seeed Studio 2-Channel CAN-BUS FD Shield
    * **Sensor**: Optical Speed Sensor
* **Software**:
    * **Languages**: C++, Python, QML
    * **Frameworks / Libraries**: Qt 5, python-can, dbus-python
    * **IPC (Inter-Process Communication)**: D-Bus
    * **Build System**: Qt-based Cross-Compilation (PC → Raspberry Pi)

## Implementation Details

### 1. Speed Measurement & CAN Transmission (Arduino)

* Pulses from the optical speed sensor are counted using an interrupt pin (`3`) on the Arduino.
* Inside the `loop()` function, the accumulated pulse count is used to calculate RPM and distance traveled every 100ms, which is then converted to speed in cm/s.
* The Keyestudio CAN-BUS Shield, which uses **MCP2515** (CAN controller) and **MCP2551** (CAN transceiver) chips, encodes and transmits this speed data as a CAN message.

### 2. CAN Data Reception (Qt/C++)

* The `caninterface.cpp` module in the Qt application is dedicated to receiving CAN data.
* It uses Linux's SocketCAN interface to connect directly to the CAN bus, filtering and reading messages with the specific CAN ID for speed data.
* The received raw data is parsed into an actual speed value and then passed to the QML UI using Qt's Signal/Slot mechanism.

### 3. Status Data Publishing (Python)

* The `vehicle_controller.py` and `soc.py` scripts are responsible for vehicle control status (e.g., gear) and battery status (SOC), respectively.
* Using the `dbus-python` library, these scripts create unique services and object paths on D-Bus, emitting signals periodically or upon a state change.

### 4. D-Bus Data Subscription (Qt/C++)

* The `dbusreceiver.cpp` module uses Qt's `QtDBus` module to subscribe to the D-Bus signals emitted by the Python scripts.
* It connects by targeting specific service names, object paths, and interfaces. When a signal is received, the connected slot function is executed to update the relevant part of the QML UI.

## Setup and Execution

### 1. Hardware Connection

*(Link to detailed instructions to be added)*

### 2. Environment Setup

*(Link to detailed instructions to be added)*

### 3. Build and Run

1.  **Run Data Senders (on RPi)**: Open a terminal on the Raspberry Pi and run the Python scripts to start publishing data.
    ```bash
    cd DES_Instrument-Cluster_team06/
    source vene/bin/activate
    cd app/src/sender
    python soc.py &
    python vehicle_controller.py &
    ```
2. **Run GUI Application**:
    Cross-Compile (on PC): Build the project in Qt Creator on your PC to generate the executable for the Raspberry Pi.

    Transfer File (from PC): Use the scp command to transfer the generated executable to the Raspberry Pi.
    Example:
    ```bash
    scp [built_executable] [pi_username]@[pi_ip_address]:~
    ```

3. **Execute (on RPi)**: SSH into the Raspberry Pi, grant execute permissions to the transferred file, and run it.
   ```bash
    ssh pi@192.168.1.10
   
    chmod +x ~/YourProjectName
    export DISPLAY=:0
    ./YourProjectName
   ```


## Contributors

* **JAEHONG LIM** - ([Your Role, e.g., System Architecture, Qt Development])
* **SIWOO LEE** - ([Their Role])
