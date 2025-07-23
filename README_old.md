# DES_Instrument-Cluster
SEA:ME project01 - PiRacer 계기판 프로젝트

## 🚗 프로젝트 개요
PiRacer를 위한 실시간 계기판 시스템으로, CAN 통신을 통해 속도 센서 데이터를 받아와 
배터리 상태, 기어 정보와 함께 표시하는 임베디드 시스템입니다.

## 📁 프로젝트 구조
```
DES_Instrument-Cluster/
├── src/                          # 소스 코드
│   ├── main.py                   # 메인 실행 파일
│   ├── vehicle_controller.py     # 차량 제어 모듈
│   ├── can_interface.py          # CAN 통신 모듈
│   └── display_controller.py     # 디스플레이 제어 모듈
├── tests/                        # 테스트 파일들
│   └── test_can.py              # CAN 통신 테스트
├── gamepads.py                   # 게임패드 라이브러리
├── controller.py                 # 기존 컨트롤러 (레거시)
├── run_instrument_cluster.sh     # 실행 스크립트
└── README.md
```

## ✨ 주요 기능
- 🎮 게임패드를 통한 PiRacer 제어
- 📊 OLED 디스플레이에 실시간 계기판 표시
- 🔋 배터리 잔량 모니터링
- ⚙️ 기어 상태 관리 (D/R/N/P)
- 📡 CAN 통신을 통한 속도 센서 데이터 수신
- 🧩 모듈화된 구조로 유지보수성 향상

## 🚀 실행 방법

### 1. 간단 실행 (권장)
```bash
./run_instrument_cluster.sh
```

### 2. 수동 실행
```bash
# 가상환경 활성화
source /home/team06/IC/venv/bin/activate

# CAN 인터페이스 설정 (가상 CAN)
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0

# 프로그램 실행
cd src
python main.py
```

### 3. 실제 CAN 하드웨어 사용시
```bash
# can0 인터페이스로 실행
python src/main.py can0
```

## 🧪 테스트 방법
```bash
# CAN 통신 테스트
/home/team06/IC/venv/bin/python tests/test_can.py

# 개별 모듈 테스트
/home/team06/IC/venv/bin/python src/vehicle_controller.py
/home/team06/IC/venv/bin/python src/can_interface.py
```

## 📋 요구사항
- Python 3.11+
- piracer-py 라이브러리
- python-can 패키지
- PIL (Pillow)
- Linux CAN 지원 (can-utils)

## 🔧 설정
- CAN 메시지 ID: `can_interface.py`에서 `SPEED_SENSOR_ID` 수정
- 배터리 업데이트 주기: `vehicle_controller.py`에서 조정 가능
- 디스플레이 업데이트 주기: `display_controller.py`에서 조정 가능

## 📝 개발 로그
- v1.0: 기본 OLED 계기판 및 CAN 통신 구현
- v2.0: 모듈화 구조 개선, 코드 분리 및 유지보수성 향상

## 🤝 기여자
- Team06 - SEA:ME DES 과정
