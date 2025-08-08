#!/usr/bin/env python3
import time
#Dbus
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib


import board
from adafruit_ina219 import INA219


# === 전압 → 퍼센트 계산 ===
def voltage_to_percentage(voltage):
    MAX_VOLTAGE = 12.6
    MIN_VOLTAGE = 11.8
    percent = (voltage - MIN_VOLTAGE) / (MAX_VOLTAGE - MIN_VOLTAGE) * 100
    return max(0, min(100, round(percent)))

# === D-Bus 객체 선언 ===
class BatteryService(dbus.service.Object):
    def __init__(self, bus, object_path='/com/car/Battery'):
        super().__init__(bus, object_path)
        self._percentage = 0

    @dbus.service.method("org.freedesktop.DBus.Properties",
                         in_signature='ss', out_signature='v')
    def Get(self, interface, prop):
        if interface == "com.car.Battery" and prop == "Percentage":
            return dbus.Int32(self._percentage)
        raise dbus.exceptions.DBusException("org.freedesktop.DBus.Error.InvalidArgs",
                                            "No such property")

    @dbus.service.method("org.freedesktop.DBus.Properties",
                         in_signature='s', out_signature='a{sv}')
    def GetAll(self, interface):
        if interface == "com.car.Battery":
            return {"Percentage": dbus.Int32(self._percentage)}
        return {}

    @dbus.service.signal("com.car.Battery", signature='i')
    def PercentageChanged(self, value):
        pass  # Optional: signal if UI listens

    def update(self, voltage):
        self._percentage = voltage_to_percentage(voltage)
        self.PercentageChanged(self._percentage)  # emit signal
        print(f"{self._percentage}")

# === 센서 초기화 ===
i2c_bus = board.I2C()
ina = INA219(i2c_bus)

# === 메인 실행 ===
def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()

    name = dbus.service.BusName("com.car.Battery", bus)
    battery = BatteryService(bus)

    def update_loop():
        try:
            voltage = ina.bus_voltage
            battery.update(voltage)
        except Exception as e:
            print(f"[Error] {e}")
        return True

    GLib.timeout_add_seconds(1, update_loop)
    loop = GLib.MainLoop()
    loop.run()

if __name__ == "__main__":
    main()
