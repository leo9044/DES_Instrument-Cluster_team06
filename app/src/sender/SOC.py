import time
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
from piracer.vehicles import PiRacerStandard

BUS_NAME = 'com.car.Battery'
OBJECT_PATH = '/com/car/Battery'
INTERFACE = 'com.car.Battery'

class BatteryMonitor:
    def __init__(self):
        self.piracer = PiRacerStandard()
        self.alpha = 0.1
        self.voltage_smoothed = self.piracer.get_battery_voltage()

    # 로우패스필터로 전압을 부드럽게 처리
    # alpha 값이 작을수록 부드러워짐
    def get_voltage(self) -> float:
        v = self.piracer.get_battery_voltage()
        self.voltage_smoothed = self.alpha * v + (1 - self.alpha) * self.voltage_smoothed
        return self.voltage_smoothed

    def get_current(self) -> float:
        return self.piracer.get_battery_current()


class BatteryService(dbus.service.Object):
    def __init__(self, bus, monitor: BatteryMonitor):
        super().__init__(bus, OBJECT_PATH)
        self.monitor = monitor

    #데코레이터를 사용하여 DBus 메소드로 등록
    @dbus.service.method(INTERFACE, in_signature='', out_signature='d')
    def GetVoltage(self):
        return self.monitor.get_voltage()

    @dbus.service.method(INTERFACE, in_signature='', out_signature='d')
    def GetCurrent(self):
        return self.monitor.get_current()

    #데코레이터를 사용하여 DBus 신호로 등록
    @dbus.service.signal(INTERFACE, signature='d')
    def currentAlert(self, current):
        pass

    def check_current_and_emit(self):
        current = self.monitor.get_current()
        if abs(current) >= 100.0:
            self.currentAlert(current)


if __name__ == '__main__':
    print("🔋 Battery Monitor DBus Service Started")

    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    name = dbus.service.BusName(BUS_NAME, bus)

    monitor = BatteryMonitor()
    service = BatteryService(bus, monitor)

    loop = GLib.MainLoop()

    try:
        while True:
            service.check_current_and_emit()
            while loop.get_context().pending():
                loop.get_context().iteration(False)
            time.sleep(0.5)
    except KeyboardInterrupt:
        print("\nStopping Battery Monitor...")
