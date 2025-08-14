import time
import busio
from board import SCL, SDA
from adafruit_pca9685 import PCA9685
import math

# PWM 관련 설정
PWM_RESOLUTION = 16
PWM_MAX_RAW_VALUE = math.pow(2, PWM_RESOLUTION) - 1
PWM_FREQ_50HZ = 50.0
PWM_WAVELENGTH_50HZ = 1.0 / PWM_FREQ_50HZ

def set_channel_active_time(time_sec, pwm_controller, channel):
    raw_value = int(PWM_MAX_RAW_VALUE * (time_sec / PWM_WAVELENGTH_50HZ))
    pwm_controller.channels[channel].duty_cycle = raw_value

def get_50hz_duty_cycle_from_percent(value):
    """value: -1.0(왼쪽) ~ 0.0(중립) ~ 1.0(오른쪽)"""
    return 0.0015 + (value * 0.0005)

# I2C 초기화
i2c_bus = busio.I2C(SCL, SDA)
pwm_steering = PCA9685(i2c_bus, address=0x40)
pwm_steering.frequency = PWM_FREQ_50HZ

channel = 0  # 스티어링 서보 채널

# 서보 테스트
try:
    while True:
        print("왼쪽")
        set_channel_active_time(get_50hz_duty_cycle_from_percent(-1.0), pwm_steering, channel)
        time.sleep(1)

        print("중립")
        set_channel_active_time(get_50hz_duty_cycle_from_percent(0.0), pwm_steering, channel)
        time.sleep(1)

        print("오른쪽")
        set_channel_active_time(get_50hz_duty_cycle_from_percent(1.0), pwm_steering, channel)
        time.sleep(1)
except KeyboardInterrupt:
    pwm_steering.deinit()
    print("테스트 종료")
