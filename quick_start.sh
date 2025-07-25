#!/bin/bash
# 빠른 실행 스크립트 - 복잡한 설정 없이 바로 실행

echo "🚗 빠른 실행"
echo "============"

# 가상환경 활성화
if [ -d "venv" ]; then
    source venv/bin/activate
    echo "✓ 가상환경 활성화됨"
else
    echo "❌ 가상환경이 없습니다. 먼저 생성하세요:"
    echo "   python3 -m venv venv"
    echo "   source venv/bin/activate"
    echo "   pip install python-can pyserial pillow piracer-py"
    exit 1
fi

# CAN 설정
echo "CAN 설정 중..."
sudo modprobe can can_raw vcan 2>/dev/null || true
if ! ip link show vcan0 > /dev/null 2>&1; then
    sudo ip link add dev vcan0 type vcan
fi
sudo ip link set up vcan0
echo "✓ CAN 준비됨"

# 메뉴
echo ""
echo "실행할 항목을 선택하세요:"
echo "1) 메인 애플리케이션 (main.py)"
echo "2) CAN 테스트"
echo "3) 속도 모니터링"
echo -n "선택 (1-3): "
read choice

case $choice in
    1)
        echo "메인 애플리케이션 실행..."
        cd app/src && python main.py
        ;;
    2)
        echo "CAN 테스트 실행..."
        cd test && python test_can.py
        ;;
    3)
        echo "속도 모니터링 실행..."
        cd test && python -c "
import sys
sys.path.append('../app/src')
from test_can import test_real_time_monitoring
test_real_time_monitoring()
"
        ;;
    *)
        echo "메인 애플리케이션 실행..."
        cd app/src && python main.py
        ;;
esac
