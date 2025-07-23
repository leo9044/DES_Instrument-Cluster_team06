"""
Vehicle Controller Module for PiRacer Instrument Cluster
Handles PiRacer hardware control and gamepad input
"""

import time
from piracer.vehicles import PiRacerStandard
from gamepads import ShanWanGamepad
from typing import Dict, Any


class VehicleController:
    """PiRacer 차량 제어 클래스"""
    
    def __init__(self):
        """Initialize vehicle controller"""
        self.piracer = PiRacerStandard()
        self.gamepad = ShanWanGamepad()
        self.gear = "N"  # 초기 기어 상태: Neutral
        
    def update_controls(self) -> Dict[str, Any]:
        """
        게임패드 입력을 읽고 차량을 제어
        
        Returns:
            dict: 제어 상태 정보
        """
        # 게임패드 입력 읽기
        gamepad_input = self.gamepad.read_data()
        
        # 버튼 상태 확인
        a = gamepad_input.button_a  # A 버튼 (Drive)
        b = gamepad_input.button_b  # B 버튼 (Park)
        x = gamepad_input.button_x  # X 버튼 (Neutral)
        y = gamepad_input.button_y  # Y 버튼 (Reverse)
        
        # 조이스틱 입력값
        throttle_input = gamepad_input.analog_stick_right.y  # 우측 스틱 Y축: 스로틀
        steering_input = -gamepad_input.analog_stick_left.x  # 좌측 스틱 X축: 스티어링 (반전)
        
        # 기어별 스로틀 제한
        if self.gear == "D":
            throttle = max(0.0, throttle_input) * 0.5  # 전진만, 50% 파워 제한
        elif self.gear == "R":
            throttle = min(0.0, throttle_input) * 0.5  # 후진만, 50% 파워 제한
        else:
            throttle = 0.0  # 중립/주차: 움직임 차단
        
        steering = steering_input  # 스티어링은 기어와 관계없이 항상 활성
        
        # PiRacer 제어 명령 전송
        self.piracer.set_throttle_percent(throttle)
        self.piracer.set_steering_percent(steering)
        
        # 기어 변경 처리
        if a:
            self.gear = "D"  # Drive
        elif b:
            self.gear = "P"  # Park
        elif x:
            self.gear = "N"  # Neutral
        elif y:
            self.gear = "R"  # Reverse
        
        # 제어 상태 반환
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
            # 차량 정지
            self.piracer.set_throttle_percent(0.0)
            self.piracer.set_steering_percent(0.0)
            print("✅ Vehicle controller cleaned up")
        except Exception as e:
            print(f"❌ Error during vehicle controller cleanup: {e}")


if __name__ == '__main__':
    """테스트용 메인 함수"""
    print("🚗 Vehicle Controller Test")
    
    controller = VehicleController()
    
    try:
        while True:
            # 제어 업데이트
            control_state = controller.update_controls()
            
            # 상태 출력 (5초마다)
            if hasattr(controller, 'loop_counter'):
                controller.loop_counter += 1
            else:
                controller.loop_counter = 0
                
            if controller.loop_counter % 250 == 0:  # 250 * 0.02s = 5초
                print(f"Gear: {control_state['gear']}, "
                      f"Throttle: {control_state['throttle']:.2f}, "
                      f"Steering: {control_state['steering']:.2f}")
            
            time.sleep(0.02)  # 20ms 지연
            
    except KeyboardInterrupt:
        print("\nTest interrupted")
    finally:
        controller.cleanup()
