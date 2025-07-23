#!/usr/bin/env python3
"""
실시간 차량 속도 모니터링 (독립 실행용)
"""

import serial
import time

def monitor_speed():
    """Arduino에서 실시간 속도 모니터링"""
    try:
        ser = serial.Serial('/dev/ttyACM0', 9600, timeout=1)
        print("🚗 실시간 속도 모니터링 시작")
        print("차량을 움직여보세요! (Ctrl+C로 종료)\n")
        
        last_speed = None
        start_time = time.time()
        message_count = 0
        
        while True:
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
            
    except KeyboardInterrupt:
        elapsed = time.time() - start_time
        print(f"\n\n📊 모니터링 완료:")
        print(f"   총 시간: {elapsed:.1f}초")
        print(f"   메시지: {message_count}개")
        print(f"   최종 속도: {last_speed or 0.0:.1f} km/h")
        
    except Exception as e:
        print(f"오류: {e}")
        
    finally:
        if 'ser' in locals():
            ser.close()

if __name__ == "__main__":
    monitor_speed()
