# CAN Communication Implementation Guide - Team06

## 📋 목차
1. [하드웨어 구성 비교](#하드웨어-구성-비교)
2. [소프트웨어 설정](#소프트웨어-설정)
3. [구현 차이점](#구현-차이점)
4. [실행 방법](#실행-방법)
5. [문제 해결](#문제-해결)

---

## 🔌 하드웨어 구성 비교

### 선배 팀 (Team4) 구성
- **라즈베리파이 CAN HAT**: 2-Channel CAN BUS FD Shield
- **Arduino CAN Shield**: MCP2515 기반 CAN-BUS Shield
- **연결**: 직접 CAN High/Low 라인 연결

### 우리 팀 (Team06) 구성  
- **Arduino Uno R3**: 실제 차량 CAN 버스 인터페이스
- **MCP2515 CAN Shield**: Arduino용 CAN 컨트롤러
- *### 🎯 우리 팀의 혁신점
1. **실용적 접근**: 실제 차량 OBD-II 포트와 연결하여 진짜 속도 데이터 수집
2. **하이브리드 아키텍처**: 하드웨어 안정성 + 소프트웨어 유연성 동시 확보
3. **원클릭 시스템**: 복잡한 CAN 설정을 자동화하여 사용자 편의성 극대화
4. **실시간 브리지**: 실제 차량 데이터를 가상 CAN으로 실시간 전송하는 혁신적 구조
5. **비용 효율**: 추가 하드웨어(CAN HAT) 없이 기본 Arduino로 구현
6. **통합 UI**: CAN 데이터, 게임패드, 디스플레이를 하나의 시스템으로 통합

### 📈 기술적 성과

#### 실제 차량 연동
```python
# 실제 OBD-II 프로토콜 구현
PID_VEHICLE_SPEED = 0x0D  # 차량 속도
PID_ENGINE_RPM = 0x0C     # 엔진 RPM  
PID_ENGINE_LOAD = 0x04    # 엔진 부하

# 실시간 데이터 수집 및 파싱
def parse_obd_response(data):
    if data[2] == PID_VEHICLE_SPEED:
        return data[3]  # km/h
    elif data[2] == PID_ENGINE_RPM:
        return ((data[3] * 256) + data[4]) / 4
```

#### 안정성 보장
```python
# 이중화 시스템: 실제 + 가상 CAN
def ensure_data_continuity():
    if arduino_connected:
        use_real_vehicle_data()
    else:
        use_virtual_can_simulation()
```

### 권장 사항
- **교육/학습**: 우리 팀 방식 - 실제 환경에서의 경험과 소프트웨어 아키텍처 학습
- **프로토타입**: 우리 팀 방식 - 빠른 개발과 실제 데이터 검증
- **상용 제품**: 선배 팀 방식 - 하드웨어 기반의 안정성과 성능I 포트**: 실제 차량 속도/RPM 데이터 수집
- **라즈베리파이 4**: 통합 제어 및 UI 시스템
- **하이브리드 통신**: USB 시리얼 + 가상 CAN 네트워크

#### 🔌 물리적 연결
```
실제 차량 (OBD-II) 
    ↓ (CAN High/Low)
MCP2515 CAN Shield
    ↓ (SPI)
Arduino Uno R3
    ↓ (USB Serial: /dev/ttyACM0)
라즈베리파이 4
    ↓ (소켓CAN: vcan0)
Python 애플리케이션
```

#### 📊 데이터 흐름
```
[차량] → [MCP2515] → [Arduino] → [시리얼] → [Python] → [가상CAN] → [UI]
  실제속도    CAN수신    파싱     USB전송    브리지    소켓CAN   화면표시
```

---

## ⚙️ 소프트웨어 설정

### 1. 선배 팀 방식 (라즈베리파이 HAT)

```bash
# /boot/config.txt 수정
sudo nano /boot/config.txt
# 추가: dtoverlay=seeed-can-fd-hat-v2

# 재부팅 후 CAN 인터페이스 설정
sudo ip link set can0 up type can bitrate 1000000 dbitrate 8000000 restart-ms 1000 berr-reporting on fd on
sudo ifconfig can0 txqueuelen 65536

# can-utils로 테스트
cangen can0 -mv
candump can0
```

### 2. 우리 팀 방식 (Arduino + Python 통합 시스템)

#### 🔧 하드웨어 연결
```
Arduino Uno + MCP2515 CAN Shield
         ↓ (USB Serial)
   라즈베리파이 4
         ↓ (Python CAN Interface)
    가상 CAN 네트워크
         ↓
  실제 차량 OBD-II 포트
```

#### 📱 Arduino 코드 (실제 차량 속도 수집)
```cpp
#include <SPI.h>
#include <mcp2515.h>

// MCP2515 CAN 컨트롤러 (CS 핀 10번)
MCP2515 mcp2515(10);

void setup() {
  Serial.begin(9600);
  
  // MCP2515 초기화
  mcp2515.reset();
  mcp2515.setBitrate(CAN_500KBPS, MCP_8MHZ);
  mcp2515.setNormalMode();
  
  Serial.println("CAN Shield 초기화 완료");
}

void loop() {
  can_frame canMsg;
  
  // 차량 CAN 버스에서 메시지 수신
  if (mcp2515.readMessage(&canMsg) == MCP2515::ERROR_OK) {
    
    // 차량 속도 데이터 처리 (표준 OBD-II PID)
    if (canMsg.can_id == 0x7E8 || canMsg.can_id == 0x7E0) {
      // PID 0x0D: Vehicle Speed
      if (canMsg.data[2] == 0x0D) {
        float speed = canMsg.data[3]; // km/h
        
        // 라즈베리파이로 속도 데이터 전송
        Serial.print("Speed: ");
        Serial.print(speed, 1);
        Serial.println(" km/h");
      }
    }
    
    // 엔진 RPM 데이터 처리 (PID 0x0C)
    if (canMsg.data[2] == 0x0C) {
      int rpm = ((canMsg.data[3] * 256) + canMsg.data[4]) / 4;
      Serial.print("RPM: ");
      Serial.println(rpm);
    }
  }
  
  delay(100);
}
```

#### 🐍 Python CAN 인터페이스 (핵심 구현)
```python
# can_interface.py - 우리 팀의 핵심 구현

import can
import serial
import threading
import subprocess
import struct

class CANInterface:
    def __init__(self, interface='vcan0', bitrate=500000):
        self.interface = interface
        self.bitrate = bitrate
        self.bus = None
        self.arduino_serial = None
        
        # 이중 통신 시스템
        self.virtual_can_active = False
        self.arduino_active = False
        
    def setup_hybrid_can_system(self):
        """우리 팀만의 하이브리드 CAN 시스템 구축"""
        
        # 1. 가상 CAN 인터페이스 생성 (테스트용)
        try:
            subprocess.run(['sudo', 'modprobe', 'can', 'can_raw', 'vcan'], check=True)
            subprocess.run(['sudo', 'ip', 'link', 'add', 'dev', 'vcan0', 'type', 'vcan'], check=False)
            subprocess.run(['sudo', 'ip', 'link', 'set', 'up', 'vcan0'], check=True)
            self.virtual_can_active = True
            print("✓ 가상 CAN 인터페이스 활성화")
        except:
            print("✗ 가상 CAN 설정 실패")
            
        # 2. Arduino 시리얼 연결 (실제 데이터)
        try:
            self.arduino_serial = serial.Serial('/dev/ttyACM0', 9600, timeout=1)
            self.arduino_active = True
            print("✓ Arduino CAN Shield 연결됨")
        except:
            print("✗ Arduino 연결 실패")
            
        return self.virtual_can_active or self.arduino_active
    
    def connect(self):
        """통합 CAN 연결"""
        if not self.setup_hybrid_can_system():
            return False
            
        # 가상 CAN 버스 연결
        if self.virtual_can_active:
            self.bus = can.Bus(interface='socketcan', channel='vcan0')
            
        return True
    
    def start_real_time_monitoring(self):
        """실시간 차량 데이터 모니터링 (우리 팀의 핵심 기능)"""
        
        def arduino_data_thread():
            """Arduino에서 실제 차량 데이터 수신"""
            while self.arduino_active:
                try:
                    if self.arduino_serial.in_waiting > 0:
                        line = self.arduino_serial.readline().decode('utf-8').strip()
                        
                        # 속도 데이터 파싱
                        if line.startswith("Speed:"):
                            speed_str = line.split(":")[1].strip().split()[0]
                            speed = float(speed_str)
                            
                            # 가상 CAN으로 브리지
                            self.bridge_to_virtual_can(0x123, speed)
                            
                        # RPM 데이터 파싱  
                        elif line.startswith("RPM:"):
                            rpm_str = line.split(":")[1].strip()
                            rpm = int(rpm_str)
                            
                            # 가상 CAN으로 브리지
                            self.bridge_to_virtual_can(0x124, rpm)
                            
                except Exception as e:
                    print(f"Arduino 데이터 수신 오류: {e}")
                    
        # 백그라운드에서 실행
        arduino_thread = threading.Thread(target=arduino_data_thread)
        arduino_thread.daemon = True
        arduino_thread.start()
        
    def bridge_to_virtual_can(self, can_id, value):
        """실제 데이터를 가상 CAN으로 브리지 (우리 팀만의 혁신)"""
        if self.bus and self.virtual_can_active:
            # 데이터를 CAN 메시지로 변환
            if can_id == 0x123:  # 속도
                data = struct.pack('<f', value) + b'\x00' * 4
            elif can_id == 0x124:  # RPM
                data = struct.pack('<H', value) + b'\x00' * 6
            else:
                data = b'\x00' * 8
                
            message = can.Message(arbitration_id=can_id, data=data)
            self.bus.send(message)
```

#### 🚀 통합 실행 시스템
```bash
#!/bin/bash
# quick_start.sh - 우리 팀의 원클릭 실행 시스템

echo "🚗 Team06 CAN 시스템 시작"

# 1. 가상환경 자동 활성화
source venv/bin/activate

# 2. CAN 모듈 자동 로드
sudo modprobe can can_raw vcan
sudo ip link add dev vcan0 type vcan 2>/dev/null || true
sudo ip link set up vcan0

# 3. Arduino 자동 감지
if [ -e "/dev/ttyACM0" ]; then
    echo "✓ Arduino 감지됨"
else
    echo "⚠️ Arduino 연결을 확인하세요"
fi

# 4. 통합 메뉴 시스템
echo "실행할 기능을 선택하세요:"
echo "1) 전체 시스템 (실제 차량 + 가상 CAN)"
echo "2) CAN 통신 테스트 (가상 + 실제)"  
echo "3) 실시간 속도 모니터링 (Arduino 직접)"

read -p "선택: " choice
case $choice in
    1) cd app/src && python main.py ;;
    2) cd test && python test_can.py ;;
    3) python -c "
import serial
import time

try:
    ser = serial.Serial('/dev/ttyACM0', 9600)
    print('🚗 실시간 차량 속도 모니터링')
    print('차량을 움직여보세요...')
    
    while True:
        line = ser.readline().decode('utf-8').strip()
        if line.startswith('Speed:'):
            print(f'📊 {line}')
except KeyboardInterrupt:
    print('\n모니터링 종료')
" ;;
esac
```

---

## 🔄 구현 차이점

### 선배 팀 (Hardware-based)
| 구분 | 내용 | 장점 | 단점 |
|------|------|------|------|
| **CAN 인터페이스** | 2-Channel CAN HAT | 하드웨어 안정성 | 추가 비용 (HAT) |
| **통신 방식** | 직접 CAN 버스 (can0/can1) | 저지연, 고성능 | 하드웨어 의존적 |
| **설정 방법** | Device Tree Overlay | 표준 리눅스 방식 | 복잡한 설정 |
| **테스트 도구** | can-utils (cangen, candump) | 검증된 도구 | 명령줄 기반 |
| **데이터 소스** | 시뮬레이션/테스트 | 안정적 테스트 | 실제 환경과 차이 |

### 우리 팀 (Hybrid Software-Hardware)
| 구분 | 내용 | 장점 | 단점 |
|------|------|------|------|
| **CAN 인터페이스** | Arduino + MCP2515 + vCAN | 실제 차량 연결 | 복잡한 아키텍처 |
| **통신 방식** | 하이브리드 (시리얼+가상CAN) | 유연성, 확장성 | 다중 프로토콜 |
| **설정 방법** | 원클릭 스크립트 | 사용 편의성 | 커스텀 솔루션 |
| **테스트 도구** | 통합 Python 스크립트 | GUI 기반 | 개발 시간 필요 |
| **데이터 소스** | 실제 차량 OBD-II | 실용성, 현실성 | 차량 의존적 |

### 🎯 우리 팀만의 혁신 포인트

#### 1. **실제 차량 데이터 수집**
```python
# 실제 OBD-II PID를 통한 차량 데이터 파싱
def parse_vehicle_data(can_frame):
    if can_frame.data[2] == 0x0D:  # Vehicle Speed PID
        speed = can_frame.data[3]   # km/h
    elif can_frame.data[2] == 0x0C:  # Engine RPM PID  
        rpm = ((can_frame.data[3] * 256) + can_frame.data[4]) / 4
```

#### 2. **하이브리드 통신 아키텍처**
```
Arduino (실제 CAN) ←→ 시리얼 ←→ Python ←→ 가상 CAN ←→ 애플리케이션
    하드웨어 신뢰성        소프트웨어 유연성        UI 통합
```

#### 3. **원클릭 실행 시스템**
```bash
./quick_start.sh  # 모든 설정 자동화
├── 가상환경 활성화
├── CAN 모듈 로드  
├── Arduino 자동 감지
├── 통합 메뉴 제공
└── 실시간 모니터링
```

#### 4. **실시간 브리지 시스템**
```python
def bridge_real_to_virtual_can(self):
    """실제 차량 데이터를 가상 CAN으로 실시간 전송"""
    while True:
        # Arduino에서 실제 데이터 수신
        real_data = self.arduino_serial.readline()
        
        # 가상 CAN으로 브리지
        virtual_message = can.Message(id=0x123, data=parsed_data)
        self.virtual_can_bus.send(virtual_message)
```

---

## 🚀 실행 방법

### 📦 초기 설정 (한 번만)
```bash
# 1. 프로젝트 클론
git clone https://github.com/leo9044/DES_Instrument-Cluster.git
cd DES_Instrument-Cluster

# 2. Arduino 라이브러리 설치
# Arduino IDE에서 MCP2515 라이브러리 설치:
# 도구 → 라이브러리 관리자 → "mcp2515" 검색 → autowp/mcp2515 설치

# 3. Arduino 코드 업로드
# Arduino IDE에서 vehicle_can_reader.ino 열어서 업로드
```

### ⚡ 빠른 시작
```bash
# 단 한 줄로 모든 기능 실행!
./quick_start.sh
```

### 🎮 메뉴 기반 실행
```
🚗 Team06 CAN 시스템 시작
✓ 가상환경 활성화됨
✓ CAN 모듈 로드됨  
✓ Arduino 감지됨 (/dev/ttyACM0)

실행할 기능을 선택하세요:
1) 전체 인스트루먼트 클러스터    # 실제 차량 + UI + 게임패드
2) CAN 통신 테스트              # 가상 CAN + Arduino 테스트
3) 실시간 속도 모니터링          # Arduino 직접 모니터링
선택 (1-3): 
```

### 🔧 개별 컴포넌트 실행

#### Arduino 단독 테스트
```bash
# 시리얼 모니터로 직접 확인
python -c "
import serial
ser = serial.Serial('/dev/ttyACM0', 9600)
while True:
    print(ser.readline().decode().strip())
"
```

#### 가상 CAN 테스트
```bash
# 가상 CAN 생성 및 테스트
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0

# 메시지 송수신 테스트
cd test && python test_can.py
```

#### 통합 시스템 실행
```bash
# 메인 애플리케이션 (전체 시스템)
source venv/bin/activate
cd app/src && python main.py
```

---

## 🔧 문제 해결

### 자주 발생하는 문제들

#### 1. Arduino 연결 오류
```bash
# 문제: [Errno 5] Input/output error
# 해결: USB 재연결 후 포트 확인
lsusb | grep Arduino
ls -la /dev/ttyACM*
```

#### 2. CAN 모듈 로드 실패
```bash
# 해결: 수동으로 모듈 로드
sudo modprobe can can_raw vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0
```

#### 3. 권한 문제
```bash
# 해결: 사용자를 dialout 그룹에 추가
sudo usermod -a -G dialout $USER
# 재로그인 필요
```

---

## 📊 성능 비교

### 선배 팀 방식
- ✅ **안정성**: 하드웨어 기반으로 안정적
- ✅ **속도**: 직접 CAN 통신으로 빠름
- ❌ **비용**: CAN HAT 추가 구매 필요
- ❌ **유연성**: 하드웨어 의존적

### 우리 팀 방식  
- ✅ **비용 효율**: Arduino + Shield만 사용
- ✅ **실제 활용**: 차량 OBD 포트 직접 연결
- ✅ **유연성**: 소프트웨어로 기능 확장 가능
- ❌ **복잡성**: 시리얼 + CAN 이중 통신

---

## 🎯 결론

### 우리 팀의 혁신점
1. **실용적 접근**: 실제 차량과 연결하여 속도 데이터 수집
2. **통합 시스템**: 하나의 스크립트로 모든 기능 실행
3. **비용 효율**: 추가 하드웨어 없이 기본 구성으로 구현
4. **사용자 친화적**: 복잡한 설정 없이 바로 실행 가능

### 권장 사항
- **학습 목적**: 우리 팀 방식 (소프트웨어 기반)
- **상용 제품**: 선배 팀 방식 (하드웨어 기반)

---

## 📚 참고 자료

- [Team4 CAN Communication Guide](https://github.com/SEA-ME-Team4/DES_Instrument-Cluster/blob/main/Documents/CANCommunicationwithCAN-HAT.md)
- [MCP2515 CAN Controller](https://ww1.microchip.com/downloads/en/DeviceDoc/MCP2515-Stand-Alone-CAN-Controller-with-SPI-20001801J.pdf)
- [Python-CAN Documentation](https://python-can.readthedocs.io/)
- [Arduino CAN Library](https://github.com/autowp/arduino-mcp2515)

---
*작성자: Team06 | 날짜: 2025-01-23*
