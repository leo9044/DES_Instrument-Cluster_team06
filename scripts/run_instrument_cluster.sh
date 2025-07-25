#!/bin/bash
# 메인 인스트루먼트 클러스터 실행 스크립트

set -e

echo "🚗 PiRacer 인스트루먼트 클러스터"
echo "==============================="

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_menu() {
    echo -e "${BLUE}[MENU]${NC} $1"
}

# 프로젝트 루트로 이동
cd "$(dirname "$0")/.."

# 하드웨어 연결 확인
check_hardware() {
    print_status "하드웨어 연결 상태 확인 중..."
    
    # Arduino 확인
    if [ -e "/dev/ttyACM0" ]; then
        print_status "✓ Arduino 연결됨"
    else
        print_warning "✗ Arduino 연결되지 않음"
    fi
    
    # I2C 확인 (디스플레이용)
    if command -v i2cdetect &> /dev/null; then
        print_status "✓ I2C 도구 사용 가능"
    else
        print_warning "✗ I2C 도구 없음"
    fi
    
    # CAN 모듈 확인
    if lsmod | grep -q can; then
        print_status "✓ CAN 모듈 로드됨"
    else
        print_warning "✗ CAN 모듈 로드되지 않음"
    fi
    
    echo ""
}

# 실행 옵션 메뉴
show_menu() {
    echo "실행할 모드를 선택하세요:"
    echo ""
    print_menu "1) 전체 인스트루먼트 클러스터 실행"
    print_menu "2) CAN 통신 테스트만 실행"
    print_menu "3) 실시간 속도 모니터링만 실행"
    print_menu "4) 컨트롤 패드 테스트만 실행"
    print_menu "5) 종료"
    echo ""
    echo -n "선택하세요 (1-5): "
}

# 가상환경 활성화
activate_venv() {
    print_status "Python 가상환경 활성화 중..."
    if [ -d "venv" ]; then
        source venv/bin/activate
        print_status "✓ 가상환경 활성화됨: $(which python)"
    else
        print_error "가상환경을 찾을 수 없습니다."
        print_status "가상환경을 생성하시겠습니까? (y/N): "
        read -r create_venv
        if [[ $create_venv =~ ^[Yy]$ ]]; then
            python3 -m venv venv
            source venv/bin/activate
            pip install --upgrade pip
            pip install python-can pyserial pillow piracer-py
            print_status "✓ 가상환경 생성 및 활성화 완료"
        else
            print_error "가상환경이 필요합니다. scripts/setup.sh를 먼저 실행하세요."
            exit 1
        fi
    fi
}

# CAN 환경 설정
setup_can_env() {
    print_status "CAN 환경 설정 중..."
    sudo modprobe can can_raw vcan 2>/dev/null || true
    
    if ! ip link show vcan0 > /dev/null 2>&1; then
        sudo ip link add dev vcan0 type vcan
        sudo ip link set up vcan0
    else
        sudo ip link set up vcan0
    fi
    print_status "CAN 환경 준비됨"
}

# 메인 실행 함수
main() {
    check_hardware
    activate_venv
    
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1)
                print_status "전체 인스트루먼트 클러스터 실행 중..."
                setup_can_env
                cd app/src
                python main.py
                cd ../..
                ;;
            2)
                print_status "CAN 통신 테스트 실행 중..."
                setup_can_env
                cd test
                python test_can.py
                cd ..
                ;;
            3)
                print_status "실시간 속도 모니터링 실행 중..."
                python real_time_speed_monitor.py
                ;;
            4)
                print_status "컨트롤 패드 테스트 실행 중..."
                cd app/src
                python -c "
import gamepads
print('🎮 컨트롤 패드 테스트 시작')
print('컨트롤러 버튼을 눌러보세요 (Ctrl+C로 종료)')
try:
    gamepad = gamepads.GamepadController()
    gamepad.test_controls()
except KeyboardInterrupt:
    print('\n테스트 종료됨')
except Exception as e:
    print(f'오류: {e}')
"
                cd ../..
                ;;
            5)
                print_status "종료합니다."
                break
                ;;
            *)
                print_error "잘못된 선택입니다. 1-5 중에서 선택하세요."
                ;;
        esac
        
        echo ""
        echo "계속하려면 Enter를 누르세요..."
        read -r
        echo ""
    done
}

# 스크립트 실행
main "$@"
