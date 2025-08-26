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

<p align="center">
  <img src="https://github.com/user-attachments/assets/f65c0956-43da-4222-8f06-5e1f7495d429" width="300">
</p>



### Step 3: Connect the CAN Shield to Arduino
- Mount the **Seeed Studio CAN-BUS Shield V2.0** onto the Arduino Uno.

<p align="center">
  <img src="https://github.com/user-attachments/assets/bf77148f-ef15-4638-b68d-d108ab3a87ff" width="300">
</p>



### Step 4: Wire the Speed Sensor to Arduino
Connect the **LM393 optical speed sensor** to the Arduino's CAN Shield:

                | LM393 Pin | Arduino Shield Connection |
                |-----------|----------------------------|
                | VCC       | 5V                        |
                | GND       | GND                       |
                | DO        | D3 (Interrupt Pin)        |

<p align="center">
  <img src="https://github.com/user-attachments/assets/5c97722f-3573-4e05-875d-fe1345cee716" width="300">
</p>



### Step 5: Connect the CAN Bus
Connect the CAN_H and CAN_L pins between the Raspberry Pi's CAN HAT and the Arduino's CAN Shield:

                | Raspberry Pi (CAN HAT) | Arduino (CAN Shield) |
                |-------------------------|-----------------------|
                | CAN0_H                 | CAN_H                |
                | CAN0_L                 | CAN_L                |
                | GND                    | GND (shared ground)  |

<p align="center">
  <img src="https://github.com/user-attachments/assets/e3686275-35cf-4f0c-b414-8311b3be21e7" width="300">
</p>

> ⚡ **Note:** Always connect a common ground between Raspberry Pi and Arduino for reliable communication.



### Step 6: Connect the Display
- Connect the display to the Raspberry Pi's HDMI port.  
- Power the display via USB.  

<p align="center">
  <img src="https://github.com/user-attachments/assets/0a7cf2aa-c5f7-4995-9f75-c7d59125212f" width="250">
  <img src="https://github.com/user-attachments/assets/ae89c9ab-0b86-4918-b488-a19e837c8ee1" width="250">
</p>



---



## 3. Final Assembled View
Below is an image of the fully assembled and wired hardware :

<p align="center">
  <img src="https://github.com/user-attachments/assets/2d3c4c7f-d18e-4d74-815e-3e2ad6ea9cf4" width="250">
  <img src="https://github.com/user-attachments/assets/5d69a548-6a82-40ba-b416-bdb396c0ef58" width="250">
</p>


