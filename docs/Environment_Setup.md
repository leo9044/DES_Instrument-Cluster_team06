# Environment Setup Guide

This guide covers the setup process for both the Raspberry Pi (Target) and the Host PC (Development) to run the project.

## 1. Raspberry Pi (Target PC) Setup

### Step 1: Install Raspberry Pi OS and Enable SSH
Install the latest version of **Raspberry Pi OS (64-bit)** on an SD card. During the imaging process, it is convenient to **enable SSH** and pre-configure a user account in the settings (cog icon). After booting, you can remotely connect to the Raspberry Pi via SSH from a PC on the same network.

### Step 2: Enable Interfaces
After connecting via SSH, open the configuration tool in the terminal:
```bash
sudo raspi-config
```
Navigate to `3 Interface Options` and **Enable** the following interfaces:
* `I2C`
* `SPI`

### Step 3: Configure Hardware Overlays (`config.txt`)
You need to modify the system config file to enable the CAN HAT and the DSI display.
```bash
sudo nano /boot/config.txt
```
Add the following lines to the end of the file:
```
# Enable SPI and CAN Bus Interface (for Waveshare 2-CH CAN FD HAT)
dtparam=spi=on
dtoverlay=mcp251xfd,spi0-0,interrupt=25

# Enable Waveshare 7.9inch DSI Display
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch
```
Save the file (`Ctrl+O` -> `Enter` -> `Ctrl+X`) and reboot the Raspberry Pi.
```bash
sudo reboot
```

### Step 4: Install Dependencies
Update your system and install the necessary system libraries for D-Bus and CAN communication.
```bash
sudo apt update && sudo apt upgrade
sudo apt install python3-venv git can-utils python3-dbus python3-gi
```

### Step 5: Setup Project and Python Virtual Environment
Clone the project repository from GitHub and set up a Python virtual environment that can access system-level libraries.
```bash
git clone [https://github.com/leo944/DES_Instrument-Cluster_team06.git](https://github.com/leo944/DES_Instrument-Cluster_team06.git)
cd DES_Instrument-Cluster_team06/

# The --system-site-packages flag is crucial for accessing the system's D-Bus library.
python3 -m venv venv --system-site-packages
source venv/bin/activate

# Install Python packages that are only needed within the virtual environment.
pip install piracer gamepads
```

## 2. Host PC (Development) Setup

### Step 1: Install Qt and Qt Creator
Download and install the open-source version of **Qt** and **Qt Creator** (e.g., 6.8.3) from the official Qt website.

### Step 2: Set Up Cross-Compilation Toolchain
To compile code for the Raspberry Pi (ARM architecture) on your PC (x86 architecture), you need a cross-compilation toolchain.

**For a detailed guide, see [Cross-Compilation Setup Guide](./Cross_Compilation_Guide.md).**

## 3. Arduino Setup

### Step 1: Install Arduino IDE
Download and install the **Arduino IDE** on your Host PC.

### Step 2: Install MCP2515 Library
In the Arduino IDE, go to `Sketch > Include Library > Manage Libraries...` and search for and install a library for the MCP2515 CAN controller (e.g., "MCP2515 by autowp").

### Step 3: Upload the Sketch
Connect the Arduino to your PC via USB, select the correct board (`Arduino Uno`) and port in the IDE, and upload the sketch located in the `arduino_speed_sensor/` directory of this project.
