# Hardware Connection Guide

This document describes how to assemble and connect the hardware components for the **PiRacer Instrument Cluster** project.

---

## 1. Required Components
- **Vehicle Body**: PiRacer Standard Kit
  
- **Main Controller**: Raspberry Pi 4

<p align="center">
  <img src="https://github.com/user-attachments/assets/36207a70-9fda-41d7-b023-aa7a00e325bb" width="300">
</p>
    
- **Sensor Controller**: Arduino Uno

<p align="center">
  <img src="https://github.com/user-attachments/assets/2f14ed6e-b506-4800-9e43-972326081ff2" width="300">
</p>

    
- **CAN Interface**:  
  - Raspberry Pi: Waveshare 2-Channel CAN FD HAT
  
<p align="center">
  <img src="https://github.com/user-attachments/assets/74b19580-0f2a-4954-b00a-b9d390de5996" width="300">
</p>

    
  - Arduino: Seeed Studio CAN-BUS Shield V2.0

<p align="center">
  <img src="https://github.com/user-attachments/assets/193ea418-48c4-4b80-9046-8398a165c51b" width="300">
</p>

   
- **Sensor**: Optical Speed Sensor (LM393)

<p align="center">
  <img src="https://github.com/user-attachments/assets/66e8fc87-850e-4011-b0b9-73c73e595d43" width="250">
  <img src="https://github.com/user-attachments/assets/6d50698e-1ed3-419c-a93d-77677b933da2" width="120">
</p>

  
- **Display**: 7.9-inch HDMI Touchscreen

<p align="center">
  <img src="https://github.com/user-attachments/assets/ea60256e-6bf8-4788-b318-3a157b835703" width="300">
</p>

  
- **Cables**: Jumper wires, USB cable, etc.  

---

## 2. Assembly and Wiring

### Step 1: Assemble the PiRacer Vehicle
- Assemble the PiRacer vehicle according to the official manual.  
- Mount the Raspberry Pi on the vehicle chassis.

<p align="center">
  <img src="https://github.com/user-attachments/assets/08fda6d6-4656-48bc-b1d3-4d135bc5ff80" width="300">
</p>


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

