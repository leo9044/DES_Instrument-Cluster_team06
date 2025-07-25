# PiRacer System Overview

<img width="613" height="182" alt="System Diagram" src="https://github.com/user-attachments/assets/d84489bc-c1b9-4f77-83f1-ee8b45e3fd52" />

---

## 1. Controller

When the user moves the joystick, the analog sensor inside the controller detects the movement and sends the data to the Raspberry Pi via Bluetooth or USB.

Libraries commonly used for this:
- `inputs`
- `evdev`
- `pygame`

In the `piracer_py` repository, the file `gamepads.py` handles and processes these inputs.

---

## 2. Raspberry Pi

Once the Raspberry Pi receives input from the controller, it determines how much throttle and steering to apply (values between `-1.0` and `1.0`).

Since the Raspberry Pi does not support true analog output, it simulates analog signals using **PWM (Pulse Width Modulation)**.

Libraries involved:
- `adafruit_pca9685`
- `Adafruit-Blinka`
- `RPi.GPIO`
- `busio`, `board`

Main logic is implemented in `vehicles.py`, where the class `PiRacerStandard` uses:
- `MotorController`
- `SteeringController`

When you call methods like `set_throttle()` or `set_steering()`:
- The `piracer` library uses `Adafruit_PCA9685` to send I2C commands.
- These commands are sent to the PCA9685 chip on the vehicle board.

### → How it works internally

- Python libraries internally use C-based libraries like `smbus`.
- These call low-level Linux system calls (`open()`, `ioctl()`, `write()`) to interact with `/dev/i2c-1`, which is the Raspberry Pi’s I2C device.
- The Linux kernel then sends the signal over I2C to the PCA9685.
- PCA9685 generates a PWM signal.

---

## 3. Signal Flow

- If the PWM is for throttle → it is sent to the **ESC (Electronic Speed Controller)**.
- If it's for steering → it is sent directly to the **servo motor**.

The **PCA9685** and **ESC** are both located on the vehicle’s mainboard.

- PCA9685 generates the precise PWM signals.
- ESC interprets the PWM and controls voltage/current for the DC motor.

Connections:
- DC motor is connected through the ESC.
- Servo motor is connected directly to PCA9685.

---

## 4. I2C Communication (Raspberry Pi ↔ PWM Driver)

Raspberry Pi doesn’t send PWM directly. Instead, it uses **I2C** to send control signals to the PCA9685 (PWM driver chip).

- I2C protocol uses two lines: `SDA` and `SCL`.
- The Pi acts as the **master**, and PCA9685 as the **slave**.
- Libraries like `adafruit_pca9685` manage this communication.

---

## 5. ESC (Electronic Speed Controller)

- The ESC receives PWM signals and determines how much voltage to apply and in which direction.
- Though the PWM value comes from the Raspberry Pi, the **ESC is what controls motor power**.

---

## 6. DC Motor & Servo Motor

- The **DC motor** drives the car forward/backward.
- The **servo motor** controls steering (left/right wheel angle).

Both motors respond to the PWM signals:
- DC motor gets PWM via the **ESC**
- Servo motor gets PWM **directly from PCA9685**
