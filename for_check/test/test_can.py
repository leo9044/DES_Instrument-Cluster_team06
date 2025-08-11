#!/usr/bin/env python3
"""
CAN 통신 테스트 스크립트 - 핵심 기능만 포함
"""

import sys
import time
import serial
import os

# 프로젝트 루트 경로 추가 (더 간단한 방법)
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(__file__)), 'app', 'src'))

from can_interface import CANInterface

def test_virtual_can():
    """가상 CAN 인터페이스 테스트"""
    print("=== 가상 CAN (vcan0) 테스트 ===")
    
    can_interface = CANInterface('vcan0')
    
    if can_interface.connect():
        print("✓ vcan0 연결 성공")
        
        # 테스트 메시지 전송
        test_data = bytearray([0x01, 0x01, 0x2C, 0x00, 0x00, 0x00, 0x00, 0x2D])  # 30 km/h
        
        if can_interface.send_message(0x123, test_data):
            print("✓ 테스트 메시지 전송 성공")
        else:
            print("✗ 메시지 전송 실패")
            
        can_interface.disconnect()
        return True
    else:
        print("✗ vcan0 연결 실패")
        return False

def test_arduino_serial():
    """Arduino 시리얼 통신 테스트"""
    print("\n=== Arduino 시리얼 통신 테스트 ===")
    
    try:
        ser = serial.Serial('/dev/ttyACM0', 9600, timeout=2)
        print("✓ Arduino 연결 성공")
        
        print("차량 속도 데이터 수신 중 (5초)...")
        start_time = time.time()
        messages_received = 0
        
        while time.time() - start_time < 5:
            if ser.in_waiting > 0:
                line = ser.readline().decode('utf-8').strip()
                if line.startswith("Speed:"):
                    messages_received += 1
                    print(f"  {line}")
        
        ser.close()
        
        if messages_received > 0:
            print(f"✓ {messages_received}개 속도 메시지 수신됨")
            return True
        else:
            print("- 속도 메시지 없음 (차량이 정지상태일 수 있음)")
            return False
            
    except Exception as e:
        print(f"✗ Arduino 연결 실패: {e}")
        return False

def test_real_time_monitoring():
    """실시간 속도 모니터링 테스트"""
    print("\n=== 실시간 속도 모니터링 ===")
    
    try:
        ser = serial.Serial('/dev/ttyACM0', 9600, timeout=1)
        print("✓ 실시간 모니터링 시작 (차량을 움직여보세요)")
        print("10초 후 자동 종료...")
        
        last_speed = None
        start_time = time.time()
        message_count = 0
        
        while time.time() - start_time < 10:
            if ser.in_waiting > 0:
                line = ser.readline().decode('utf-8').strip()
                
                if line.startswith("Speed:"):
                    message_count += 1
                    speed_str = line.split(":")[1].strip().split()[0]
                    current_speed = float(speed_str)
                    
                    if last_speed != current_speed:
                        elapsed = time.time() - start_time
                        if current_speed > 0:
                            print(f"🚗 [{elapsed:5.1f}s] 속도: {current_speed:.1f} km/h")
                        else:
                            print(f"🛑 [{elapsed:5.1f}s] 정지")
                        last_speed = current_speed
            
            time.sleep(0.1)
        
        ser.close()
        elapsed = time.time() - start_time
        print(f"\n📊 모니터링 완료: {elapsed:.1f}초, {message_count}개 메시지")
        return True
        
    except Exception as e:
        print(f"✗ 모니터링 실패: {e}")
        return False

if __name__ == "__main__":
    try:
        print("🚗 CAN 통신 테스트")
        print("=" * 30)
        
        # 1. 가상 CAN 테스트
        vcan_success = test_virtual_can()
        
        # 2. Arduino 시리얼 통신 테스트
        arduino_success = test_arduino_serial()
        
        # 3. 실시간 모니터링 테스트 (옵션)
        if arduino_success:
            print("\n실시간 모니터링을 시작하시겠습니까? (y/N): ", end="")
            try:
                import sys
                import select
                # 3초 대기 후 자동으로 넘어감
                if select.select([sys.stdin], [], [], 3)[0]:
                    response = sys.stdin.readline().strip().lower()
                    if response == 'y':
                        monitoring_success = test_real_time_monitoring()
                    else:
                        monitoring_success = True
                else:
                    print("(자동 넘어감)")
                    monitoring_success = True
            except:
                monitoring_success = True
        else:
            monitoring_success = False
        
        # 결과 요약
        print("\n" + "=" * 30)
        print("📊 테스트 결과:")
        print(f"  가상 CAN: {'✓' if vcan_success else '✗'}")
        print(f"  Arduino:  {'✓' if arduino_success else '✗'}")
        
        if arduino_success:
            print("\n🎉 CAN 통신 시스템 정상 작동!")
        else:
            print("\n⚠️  Arduino 연결을 확인하세요")
            
    except KeyboardInterrupt:
        print("\n테스트 중단됨")
    except Exception as e:
        print(f"\n오류 발생: {e}")
