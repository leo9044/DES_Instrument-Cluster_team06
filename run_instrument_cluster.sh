#!/bin/bash
# PiRacer Instrument Cluster 실행 스크립트 v2.0
# 개선된 모듈화 구조로 프로그램을 실행합니다

echo "🚗 PiRacer Instrument Cluster v2.0 시작"
echo "가상환경 활성화 중..."

# 가상환경 경로
VENV_PATH="/home/team06/IC/venv"
PROJECT_PATH="/home/team06/DES_Instrument-Cluster"

# 가상환경 활성화 및 프로그램 실행
cd "$PROJECT_PATH"

echo "모듈화된 계기판 실행..."
echo "종료하려면 Ctrl+C를 누르세요."
echo ""

# 가상 CAN 인터페이스 설정
echo "가상 CAN 인터페이스 설정 중..."
sudo modprobe vcan 2>/dev/null || echo "vcan 모듈 로드 실패 (이미 로드되었을 수 있음)"
sudo ip link add dev vcan0 type vcan 2>/dev/null || echo "vcan0 인터페이스 생성 실패 (이미 존재할 수 있음)"
sudo ip link set up vcan0 2>/dev/null || echo "vcan0 인터페이스 활성화 실패"

echo "✅ CAN 인터페이스 준비 완료"
echo ""

# 모듈화된 메인 프로그램 실행
echo "🚀 메인 프로그램 시작..."
# 새로운 모듈화된 메인 컨트롤러 실행
"$VENV_PATH/bin/python" src/main.py
