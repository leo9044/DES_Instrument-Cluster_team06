import time
from ina219 import INA219

# =========================
# 배터리 스펙
# =========================
BATTERY_CAPACITY_MAH = 3000.0  # 1셀 기준
NUM_CELLS = 3
MIN_VOLTAGE = 3.0 * NUM_CELLS
MAX_VOLTAGE = 4.2 * NUM_CELLS

# =========================
# INA219 초기화
# =========================
ina = INA219(shunt_ohms=0.1)
ina.configure()

# =========================
# SOC 초기화
# =========================
soc = 100.0
last_time = time.time()
count = 0

# 로우패스 필터 초기값
alpha = 0.1
voltage_smoothed_previous = ina.voltage()  # 초기 전압

print("Battery Monitoring Started")

while True:
    voltage = ina.voltage()      # 배터리 전압 (V)
    current_mA = ina.current()   # 배터리 전류 (mA, 양수=방전)

    # 로우패스 필터로 전압 평활
    voltage_smoothed = alpha * voltage + (1 - alpha) * voltage_smoothed_previous
    voltage_smoothed_previous = voltage_smoothed

    # 초기 SOC 설정 (전압 기반)
    if count == 0:
        soc = (voltage_smoothed - MIN_VOLTAGE) / (MAX_VOLTAGE - MIN_VOLTAGE) * 100.0

    now = time.time()
    dt = (now - last_time) / 3600.0  # 시간 단위: h
    last_time = now

    # 1) Coulomb Counting
    soc -= (current_mA * dt) / BATTERY_CAPACITY_MAH * 100.0

    # 2) 전압 기반 SOC 계산
    voltage_soc = (voltage_smoothed - MIN_VOLTAGE) / (MAX_VOLTAGE - MIN_VOLTAGE) * 100.0

    # 3) 혼합 (0.7 Coulomb + 0.3 Voltage)
    soc = 0.7 * soc + 0.3 * voltage_soc

    # SOC 범위 제한
    soc = max(0.0, min(100.0, soc))

    print(f"Voltage: {voltage_smoothed:.2f}V, Current: {current_mA:.1f}mA, SOC: {soc:.1f}%")

    count += 1
    time.sleep(0.5)
