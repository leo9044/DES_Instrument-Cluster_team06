#!/bin/bash
# 빠른 실행 스크립트 - 자주 사용하는 기능들

echo "🚗 PiRacer 빠른 실행 메뉴"
echo "========================"

cd "$(dirname "$0")/.."

echo "1) CAN 테스트"
echo "2) 속도 모니터링"
echo "3) 전체 실행"
echo ""
echo -n "선택하세요 (1-3): "
read -r choice

case $choice in
    1)
        echo "CAN 테스트 실행 중..."
        ./scripts/run_can_test.sh
        ;;
    2)
        echo "속도 모니터링 실행 중..."
        ./scripts/run_speed_monitor.sh
        ;;
    3)
        echo "전체 시스템 실행 중..."
        ./scripts/run_instrument_cluster.sh
        ;;
    *)
        echo "잘못된 선택입니다."
        exit 1
        ;;
esac
