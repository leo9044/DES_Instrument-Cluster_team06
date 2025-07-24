PiRacer System Overview

<img width="613" height="182" alt="Image" src="https://github.com/user-attachments/assets/d84489bc-c1b9-4f77-83f1-ee8b45e3fd52" />

Controller
When the user moves the joystick, the analog sensor inside the controller detects the movement and sends the data to the Raspberry Pi via Bluetooth or USB.
Libraries like inputs, evdev, or pygame are often used to handle this input, and in piracer, the gamepads.py file processes those values.

Raspberry Pi
Once the Raspberry Pi receives input data from the controller, it decides how much throttle and steering to apply (values between -1.0 and 1.0).
Since the Pi doesn’t support true analog output, it uses PWM (Pulse Width Modulation) signals to simulate analog behavior for controlling the motors.

To generate PWM, the Pi uses libraries like adafruit_pca9685, Adafruit-Blinka, RPi.GPIO, busio, and board.
In the piracer_py repository, there’s a file called vehicles.py, which defines a class named PiRacerStandard. This class uses two main components: MotorController and SteeringController, which handle sending motor control signals.

When you call a method like set_throttle() or set_steering() in your code, it uses the piracer library, which internally uses Adafruit’s PCA9685 library.
This library sends a command over the I2C bus to the PCA9685 chip on the vehicle’s board.

Under the hood, the Python library calls low-level C libraries like smbus, which use Linux system calls such as open(), ioctl(), and write() to interact with /dev/i2c-1, which represents the Pi’s I2C hardware.
The Linux kernel then sends this signal through the I2C interface to the PCA9685 chip, which generates a PWM signal.

That PWM signal is sent out through the vehicle’s circuit board.

If it’s for throttle, the signal goes to the ESC (Electronic Speed Controller), which controls the DC motor to move forward or backward.

If it’s for steering, the signal goes directly to the servo motor, which turns the wheels.

The PCA9685 and ESC are both installed on the vehicle’s mainboard.

The PCA9685 creates accurate PWM signals.

The ESC receives those signals and adjusts the power and direction of the DC motor accordingly.

The DC motor and servo motor are both connected to the PCA9685.

The ESC is specifically used for the DC motor.

The servo motor is controlled directly by PWM from the PCA9685.

I2C Communication (Raspberry Pi ↔ PWM Driver Board)
The Raspberry Pi doesn’t send PWM signals directly to the motors.
Instead, it communicates with the PCA9685 (PWM driver board) using I2C, a protocol that works over two lines: SDA and SCL.

The Pi acts as the master, and the PCA9685 as the slave.
Libraries like adafruit_pca9685 handle this I2C communication, sending data to the chip to update PWM values.

ESC (Electronic Speed Controller)
The ESC receives the PWM signal and decides how much voltage and in which direction to send it to the DC motor.
So, even though the Raspberry Pi creates the PWM signal, it’s the ESC that actually controls motor power.

DC Motor & Servo Motor
The DC motor controls the forward and backward movement of the car.

The servo motor controls the steering, turning the wheels left or right.

Both of them respond to the PWM signals received — either directly from the PCA9685, or through the ESC.
