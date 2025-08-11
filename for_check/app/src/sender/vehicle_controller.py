#!/usr/bin/env python3
"""
Vehicle Controller Module for PiRacer Instrument Cluster
Handles PiRacer hardware control and gamepad input
and exposes current gear state via DBus.
"""

import time
from typing import Dict, Any

# PiRacer 관련
from piracer.vehicles import PiRacerStandard
from gamepads import ShanWanGamepad

# DBus 관련
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib


# DBus 설정
BUS_NAME = 'org.piracer.VehicleController'
OBJECT_PATH = '/org/piracer/VehicleController'
INTERFACE = 'org.piracer.VehicleInterface'


class VehicleController:
    """PiRacer 차량 제어 클래스"""

    def __init__(self):
        """Initialize vehicle controller"""
        self.piracer = PiRacerStandard()
        self.gamepad = ShanWanGamepad()
        self.gear = "N"  # 초기 기어 상태: Neutral

    def update_controls(self) -> Dict[str, Any]:
        """게임패드 입력을 읽고 차량을 제어"""
        gamepad_input = self.gamepad.read_data()

        # 버튼 상태 확인
        a = gamepad_input.button_a  # Drive
        b = gamepad_input.button_b  # Park
        x = gamepad_input.button_x  # Neutral
        y = gamepad_input.button_y  # Reverse

        # 조이스틱 입력
        throttle_input = gamepad_input.analog_stick_right.y
        steering_input = -gamepad_input.analog_stick_left.x

        # 기어별 스로틀 제한
        if self.gear == "D":
            throttle = max(0.0, throttle_input) * 0.5
        elif self.gear == "R":
            throttle = min(0.0, throttle_input) * 0.5
        else:
            throttle = 0.0

        steering = steering_input

        # 차량 제어
        self.piracer.set_throttle_percent(throttle)
        self.piracer.set_steering_percent(steering)

        # 기어 변경 처리
        if a:
            self.gear = "D"
        elif b:
            self.gear = "P"
        elif x:
            self.gear = "N"
        elif y:
            self.gear = "R"

        return {
            'throttle': throttle,
            'steering': steering,
            'gear': self.gear,
            'throttle_input': throttle_input,
            'steering_input': steering_input
        }

    def get_gear(self) -> str:
        """현재 기어 상태 반환"""
        return self.gear

    def cleanup(self):
        """리소스 정리"""
        try:
            self.piracer.set_throttle_percent(0.0)
            self.piracer.set_steering_percent(0.0)
            print("✅ Vehicle controller cleaned up")
        except Exception as e:
            print(f"❌ Error during vehicle controller cleanup: {e}")


class VehicleControllerService(dbus.service.Object):
    """DBus 서비스: VehicleController의 기어 상태 제공"""

    # --- 수정: 기어 변경 신호 선언 ---
    gearChanged = dbus.service.signal(dbus_interface=INTERFACE, signature='s')

    def __init__(self, bus, controller: VehicleController):
        super().__init__(bus, OBJECT_PATH)
        self.controller = controller
        self.last_gear = None  # 마지막 기어 상태 저장용

    @dbus.service.method(INTERFACE, in_signature='', out_signature='s')
    def GetGear(self):
        """현재 기어 상태 반환 (DBus 메서드)"""
        return self.controller.get_gear()

    # --- 수정: 기어 상태가 변경되면 신호를 emit하는 메서드 추가 ---
    def emit_gear_changed_if_needed(self):
        current_gear = self.controller.get_gear()
        if current_gear != self.last_gear:
            self.last_gear = current_gear
            # 신호 방출 (기어 변경 알림)
            self.gearChanged(current_gear)


if __name__ == '__main__':
    print("🚗 Vehicle Controller with DBus started")

    # DBus 메인 루프 설정
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    name = dbus.service.BusName(BUS_NAME, bus)

    # Vehicle Controller 초기화
    controller = VehicleController()
    service = VehicleControllerService(bus, controller)

    loop = GLib.MainLoop()

    try:
        while True:
            # 주기적으로 차량 제어 업데이트
            controller.update_controls()

            # --- 수정: 기어 변경 신호 체크 및 emit ---
            service.emit_gear_changed_if_needed()

            # DBus는 GLib 이벤트 루프가 처리
            while loop.get_context().pending():
                loop.get_context().iteration(False)

            time.sleep(0.02)  # 20ms 주기
    except KeyboardInterrupt:
        print("\nStopping Vehicle Controller...")
    finally:
        controller.cleanup()
