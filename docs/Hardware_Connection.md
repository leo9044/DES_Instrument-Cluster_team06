# Hardware Connection Guide

This document describes how to assemble and connect the hardware components for the **PiRacer Instrument Cluster** project.

---

## 1. Required Components
- **Vehicle Body**: PiRacer Standard Kit  
- **Main Controller**: Raspberry Pi 4  
- **Sensor Controller**: Arduino Uno  
- **CAN Interface**:  
  - Raspberry Pi: Waveshare 2-Channel CAN FD HAT  
  - Arduino: Seeed Studio CAN-BUS Shield V2.0  
- **Sensor**: Optical Speed Sensor (LM393)  
- **Display**: 5-inch HDMI Touchscreen (or similar)  
- **Cables**: Jumper wires, USB cable, etc.  

---

## 2. Assembly and Wiring

### Step 1: Assemble the PiRacer Vehicle
- Assemble the PiRacer vehicle according to the official manual.  
- Mount the Raspberry Pi on the vehicle chassis.  

### Step 2: Connect the CAN HAT to Raspberry Pi
- Mount the **Waveshare 2-Channel CAN FD HAT** directly onto the Raspberry Pi's 40-pin GPIO header.  

### Step 3: Connect the CAN Shield to Arduino
- Mount the **Seeed Studio CAN-BUS Shield V2.0** onto the Arduino Uno.  

### Step 4: Wire the Speed Sensor to Arduino
Connect the **LM393 optical speed sensor** to the Arduino's CAN Shield:

| LM393 Pin | Arduino Shield Connection |
|-----------|----------------------------|
| VCC       | 5V                        |
| GND       | GND                       |
| DO        | D3 (Interrupt Pin)        |

### Step 5: Connect the CAN Bus
Connect the CAN_H and CAN_L pins between the Raspberry Pi's CAN HAT and the Arduino's CAN Shield:

| Raspberry Pi (CAN HAT) | Arduino (CAN Shield) |
|-------------------------|-----------------------|
| CAN0_H                 | CAN_H                |
| CAN0_L                 | CAN_L                |
| GND                    | GND (shared ground)  |

> ⚡ **Note:** Always connect a common ground between Raspberry Pi and Arduino for reliable communication.

### Step 6: Connect the Display
- Connect the display to the Raspberry Pi's HDMI port.  
- Power the display via USB.  

---

## 3. Final Assembled View
Below is an image of the fully assembled and wired hardware (to be added):

