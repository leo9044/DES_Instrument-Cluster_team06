"""
Main Controller for PiRacer Instrument Cluster
Integrates all modules: Vehicle Control, CAN Interface, and Display
"""

import sys
import time
import os
from typing import Optional

# 현재 디렉토리를 Python 경로에 추가 (모듈 import용)
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

try:
    from vehicle_controller import VehicleController
    from can_interface import CANInterface
    from display_controller import InstrumentClusterDisplay
except ImportError as e:
    print(f"Import error: {e}")
    print("Make sure you're running from the correct directory")
    sys.exit(1)


class InstrumentClusterMain:
    """메인 계기판 컨트롤러 클래스"""
    
    def __init__(self, can_interface: str = 'vcan0'):
        """
        Initialize main controller
        
        Args:
            can_interface: CAN 인터페이스 이름 (기본: vcan0)
        """
        print("🚗 PiRacer Instrument Cluster 초기화 중...")
        
        # 모듈 초기화
        self.vehicle_controller: Optional[VehicleController] = None
        self.can_interface: Optional[CANInterface] = None  
        self.display: Optional[InstrumentClusterDisplay] = None
        
        # 설정
        self.can_interface_name = can_interface
        self.running = False
        
        # 초기화 수행
        self._initialize_modules()
    
    def _initialize_modules(self):
        """모든 모듈 초기화"""
        try:
            # 1. 차량 컨트롤러 초기화
            print("  📱 차량 컨트롤러 초기화...")
            self.vehicle_controller = VehicleController()
            
            # 2. 디스플레이 초기화 (임시 비활성화)
            print("  🖥️ 디스플레이 초기화 건너뛰기...")
            # piracer_display = self.vehicle_controller.piracer.get_display()
            # self.display = InstrumentClusterDisplay(piracer_display)
            # self.display.show_startup()
            self.display = None
            
            # 3. CAN 인터페이스 초기화
            print("  📡 CAN 인터페이스 초기화...")
            self.can_interface = CANInterface(interface=self.can_interface_name)
            
            # CAN 연결 시도
            can_connected = False
            try:
                if self.can_interface.connect():
                    self.can_interface.start_receiving()
                    can_connected = True
                    print("  ✅ CAN 인터페이스 연결 성공")
                else:
                    print("  ⚠️ CAN 인터페이스 연결 실패 - CAN 없이 계속 진행")
            except Exception as e:
                print(f"  ⚠️ CAN 연결 오류: {e} - CAN 없이 계속 진행")
            
            print("✅ 모든 모듈 초기화 완료!")
            
        except Exception as e:
            print(f"❌ 초기화 실패: {e}")
            raise
    
    def run(self):
        """메인 실행 루프"""
        print("🚀 계기판 시작!")
        print("종료하려면 Ctrl+C를 누르세요.\n")
        
        self.running = True
        
        # 메인 루프 카운터
        loop_count = 0
        status_print_interval = 500  # 10초마다 상태 출력 (500 * 0.01s)
        
        try:
            while self.running:
                # 1. 차량 제어 업데이트 (가장 중요 - 최우선 처리)
                control_state = self.vehicle_controller.update_controls()
                
                # 2. CAN 속도 데이터 가져오기 (주기를 늘려서 부하 감소)
                current_speed = 0.0
                can_connected = False
                
                if self.can_interface and self.can_interface.is_connected() and loop_count % 5 == 0:  # 5번에 한번만
                    try:
                        current_speed = self.can_interface.get_current_speed()
                        can_connected = True
                        
                        # 테스트용: 가상 속도 데이터 전송 (실제 센서 없을 때)
                        if loop_count % 100 == 0:  # 1초마다 (주기 늘림)
                            test_speed = abs(control_state['throttle']) * 100  # 스로틀 기반 테스트 속도
                            self.can_interface.send_test_speed_data(test_speed)
                            
                    except Exception as e:
                        print(f"CAN 데이터 읽기 오류: {e}")
                
                # 3. 디스플레이 업데이트 (비활성화됨)
                # if self.display:
                #     self.display.update(
                #         speed=current_speed,
                #         gear=control_state['gear'],
                #         can_connected=can_connected
                #     )
                
                # 4. 상태 출력 (주기 늘림)
                loop_count += 1
                if loop_count % status_print_interval == 0:
                    print(f"📊 상태: 속도={current_speed:.1f}km/h, "
                          f"기어={control_state['gear']}, "
                          f"스로틀={control_state['throttle']:.2f}, "
                          f"조향={control_state['steering']:.2f}, "
                          f"CAN={'연결' if can_connected else '연결안됨'}")
                
                # 5. 짧은 지연 (더 빠른 주기로 변경)
                time.sleep(0.01)  # 10ms로 단축
                
        except KeyboardInterrupt:
            print("\n⏹️ 사용자가 중단했습니다.")
        except Exception as e:
            print(f"❌ 실행 중 오류: {e}")
            if self.display:
                self.display.show_error(str(e)[:20])
        finally:
            self.cleanup()
    
    def cleanup(self):
        """리소스 정리"""
        print("🧹 리소스 정리 중...")
        self.running = False
        
        try:
            if self.can_interface:
                self.can_interface.disconnect()
            
            if self.vehicle_controller:
                self.vehicle_controller.cleanup()
                
            print("✅ 정리 완료")
        except Exception as e:
            print(f"⚠️ 정리 중 오류: {e}")


def main():
    """메인 함수"""
    print("=" * 50)
    print("🚗 PiRacer Instrument Cluster v2.0")
    print("=" * 50)
    
    # CAN 인터페이스 선택
    can_interface = 'vcan0'  # 기본값: 가상 CAN
    
    # 명령행 인자로 실제 CAN 인터페이스 지정 가능
    if len(sys.argv) > 1:
        can_interface = sys.argv[1]
        print(f"사용할 CAN 인터페이스: {can_interface}")
    
    # 메인 컨트롤러 생성 및 실행
    try:
        cluster = InstrumentClusterMain(can_interface=can_interface)
        cluster.run()
    except Exception as e:
        print(f"💥 치명적 오류: {e}")
        return 1
    
    return 0


if __name__ == '__main__':
    sys.exit(main())
