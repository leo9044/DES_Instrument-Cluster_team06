# Environment Setup Guide

This guide covers the setup process for both the Raspberry Pi (Target) and the Host PC (Development) to run the project.

## 1. Raspberry Pi (Target PC) Setup

### Step 1: Install Raspberry Pi OS
Install the latest version of **Raspberry Pi OS (64-bit)** on an SD card and boot the Raspberry Pi.

### Step 2: Basic Configuration
Connect to the Raspberry Pi via SSH. Open the configuration tool:
```bash
sudo raspi-config
```
Navigate to `3 Interface Options` and enable:
* `I2C`
* `SPI`
* `SSH`

### Step 3: Install Dependencies
Update your system and install the required libraries.
```bash
sudo apt update && sudo apt upgrade
sudo apt install python3-venv git
```

### Step 4: Setup Project and Python Virtual Environment
Clone the project repository from GitHub and set up a Python virtual environment.
```bash
git clone [https://github.com/leo9044/DES_Instrument-Cluster_team06.git](https://github.com/leo9044/DES_Instrument-Cluster_team06.git)
cd DES_Instrument-Cluster_team06/
python3 -m venv venv
source venv/bin/activate

# Install required Python packages
pip install dbus-python piracer gamepads PyGObject
```

## 2. Host PC (Development) Setup

### Step 1: Install Qt and Qt Creator
Download and install the open-source version of **Qt** (e.g., Qt 5.15.2) and **Qt Creator** from the official Qt website.

### Step 2: Set Up Cross-Compilation Toolchain
To compile code for the Raspberry Pi (ARM architecture) on your PC (x86 architecture), you need a cross-compilation toolchain.

*(This is a complex topic. It's highly recommended to create a separate, detailed guide for this and link it here.)*

**For a detailed guide, see [Cross-Compilation Setup Guide](./Cross_Compilation_Guide.md).**

A brief overview of the steps:
1.  Download the ARM toolchain.
2.  Synchronize the Raspberry Pi's `sysroot` to your Host PC.
3.  Configure a new "Kit" in Qt Creator that uses the cross-compiler and the synchronized sysroot.

## 3. Arduino Setup

### Step 1: Install Arduino IDE
Download and install the **Arduino IDE** on your Host PC.

### Step 2: Install MCP2515 Library
In the Arduino IDE, go to `Sketch > Include Library > Manage Libraries...` and install the library for the MCP2515 CAN controller (e.g., "MCP2515 by autowp").

### Step 3: Upload the Sketch
Connect the Arduino to your PC via USB, select the correct board and port in the IDE, and upload the sketch located in the `arduino_speed_sensor/` directory of this project.
