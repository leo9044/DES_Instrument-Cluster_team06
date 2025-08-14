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
        # 초기값을 한 번 읽어와서 설정
        initial_voltage = self.piracer.get_battery_voltage()
        self.voltage_smoothed = initial_voltage

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
        self.last_percentage = -1
        self.last_current = -999.0

    # 데코레이터를 사용하여 DBus 메소드로 등록
    @dbus.service.method(INTERFACE, in_signature='', out_signature='d')
    def GetVoltage(self):
        return self.monitor.get_voltage()

    @dbus.service.method(INTERFACE, in_signature='', out_signature='d')
    def GetCurrent(self):
        return self.monitor.get_current()

    # D-Bus 신호(Signal) 정의
    # 'id'는 int, double 타입의 데이터를 함께 보낸다는 의미
    @dbus.service.signal(INTERFACE, signature='id')
    def batteryStatusChanged(self, percentage, current):
        # 이 함수는 신호를 보내는 역할만 하므로 내부는 비워둡니다.
        pass

    def get_percentage_from_voltage(self, voltage):
        MIN_VOLTAGE = 6.0
        MAX_VOLTAGE = 8.4
        percentage = ((voltage - MIN_VOLTAGE) / (MAX_VOLTAGE - MIN_VOLTAGE)) * 100.0
        # 0~100 사이로 값 제한
        return max(0, min(100, int(percentage)))

    # 상태를 확인하고, 변경되었을 때만 신호를 보내는 함수
    def check_and_emit_status(self):
        voltage = self.monitor.get_voltage()
        current = self.monitor.get_current()
        percentage = self.get_percentage_from_voltage(voltage)

        # 이전 값과 비교하여 변경되었을 때만 신호를 전송
        # 전류는 0.1A 이상 변했을 때만 신호 전송
        if self.last_percentage != percentage or abs(self.last_current - current) > 0.1:
            print(f"Status changed. Emitting signal: {percentage}%, {current:.2f}A")
            self.batteryStatusChanged(percentage, current) # 신호 발생
            self.last_percentage = percentage
            self.last_current = current


if __name__ == '__main__':
    print("🔋 Battery Monitor DBus Service Started (Interrupt Mode)")

    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    name = dbus.service.BusName(BUS_NAME, bus)

    monitor = BatteryMonitor()
    service = BatteryService(bus, monitor)

    loop = GLib.MainLoop()

    try:
        while True:
            # 상태 변경 시 신호를 보내는 함수 호출
            service.check_and_emit_status()
            # GLib의 이벤트 루프 처리
            while loop.get_context().pending():
                loop.get_context().iteration(False)
            # 서버는 1초마다 상태를 체크
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nStopping Battery Monitor...")
