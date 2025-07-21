from piracer.vehicles import PiRacerStandard  # PiRacer vehicle control class
from piracer.gamepads import ShanWanGamepad     # ShanWan gamepad input class
import time                                     # Time-related functions
from PIL import Image, ImageDraw, ImageFont     # OLED display graphics processing library

def main():
    # Initialize gamepad and PiRacer objects
    shanwan_gamepad = ShanWanGamepad()
    piracer = PiRacerStandard()
    gear = "N"  # Initial gear state: Neutral
    
    # OLED display setup (PiRacer built-in 128x32 pixel display)
    display = piracer.get_display()
    
    # Font setup (for display text output)
    try:
        font = ImageFont.load_default()  # Load default font
    except:
        font = None  # Use None if font loading fails

    # Battery voltage buffer for averaging (stabilization)
    voltage_buffer = []
    buffer_size = 10
    
    # Initial battery information setup
    battery_voltage = 12.0  # Initial value
    battery_current = 0.0   # Initial value
    
    # Battery update interval control (update battery data every 2 minutes)
    battery_counter = 0
    battery_update_interval = 6000  # Update battery data every 6000 loops (every 2 minutes)
    
    # Display update interval control (frequent updates)
    display_counter = 0
    display_update_interval = 25  # Update display every 25 loops (every 0.5 seconds)

    while True:
        # Read gamepad input data
        gamepad_input = shanwan_gamepad.read_data()

        # Check button input states
        a = gamepad_input.button_a  # A button (for Drive gear)
        b = gamepad_input.button_b  # B button (for Park gear)
        x = gamepad_input.button_x  # X button (for Neutral gear)
        y = gamepad_input.button_y  # Y button (for Reverse gear)

        # Read joystick input values
        throttle_input = gamepad_input.analog_stick_right.y  # Right joystick Y-axis: throttle input
        steering_input = -gamepad_input.analog_stick_left.x  # Left joystick X-axis: steering input (inverted)

        # Limit throttle based on gear (car transmission simulation)
        if gear == "D":
            throttle = max(0.0, throttle_input) * 0.5  # Drive: forward only, 50% power limit
        elif gear == "R":
            throttle = min(0.0, throttle_input) * 0.5  # Reverse: backward only, 50% power limit
        else:
            throttle = 0.0  # Neutral/Park: block movement

        steering = steering_input  # Left/right steering value (always active regardless of gear)

        # Send PiRacer motor control commands (immediate execution - no delay)
        piracer.set_throttle_percent(throttle)   # Set throttle
        piracer.set_steering_percent(steering)   # Set steering

        # Change gear with buttons (car transmission lever simulation)
        if a:
            gear = "D"  # A button: Drive (forward)
        elif b:
            gear = "P"  # B button: Park
        elif x:
            gear = "N"  # X button: Neutral
        elif y:
            gear = "R"  # Y button: Reverse (backward)

        # Battery data update (every 2 minutes)
        battery_counter += 1
        if battery_counter >= battery_update_interval:
            # Collect and average battery information (execute only every 2 minutes)
            raw_voltage = piracer.get_battery_voltage()
            
            # Add to battery voltage buffer
            voltage_buffer.append(raw_voltage)
            if len(voltage_buffer) > buffer_size:
                voltage_buffer.pop(0)  # Remove oldest value
            
            # Calculate average voltage (stabilized value)
            battery_voltage = sum(voltage_buffer) / len(voltage_buffer)
            battery_current = piracer.get_battery_current()
            power_consumption = piracer.get_power_consumption()
            
            # Console output (for debugging)
            print(f"Battery Updated: {battery_voltage:.2f}V, {battery_current:.1f}mA, {power_consumption:.1f}W")
            
            battery_counter = 0

        # Display update (frequent updates - every 0.5 seconds)
        display_counter += 1
        if display_counter >= display_update_interval:
            update_display(display, gear, battery_voltage, battery_current, 
                          throttle, steering, font)
            display_counter = 0

        # Minimize delay (improve steering responsiveness)
        time.sleep(0.02)  # 20ms delay (faster response)



def update_display(display, gear, voltage, current, throttle, steering, font):
    """OLED display update function - displays battery bar only"""
    # Create image (128x32 pixels)
    image = Image.new('1', (128, 32))
    draw = ImageDraw.Draw(image)
    
    # Calculate battery level (based on 11V~12.6V)
    battery_level = max(0, min(1, (voltage - 11.0) / 1.6))
    
    # Large battery level bar (big in center of screen)
    bar_x = 10
    bar_y = 8
    bar_width = 108  # Larger width
    bar_height = 16  # Larger height
    
    # Battery outline
    draw.rectangle([bar_x, bar_y, bar_x + bar_width, bar_y + bar_height], outline=1, fill=0)
    
    # Fill battery level
    fill_width = int(bar_width * battery_level)
    if fill_width > 0:
        draw.rectangle([bar_x, bar_y, bar_x + fill_width, bar_y + bar_height], fill=1)
    
    # Display on screen
    display.image(image)
    display.show()


if __name__ == '__main__':
    main()