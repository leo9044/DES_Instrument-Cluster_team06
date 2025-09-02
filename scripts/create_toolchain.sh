#!/bin/bash

# 툴체인 파일 생성 스크립트 (핵심만)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLCHAIN_FILE="$PROJECT_ROOT/toolchain-rpi.cmake"

echo "🔧 툴체인 파일 생성: $TOOLCHAIN_FILE"

cat > "$TOOLCHAIN_FILE" << 'EOF'
# CMake 툴체인 파일 - Raspberry Pi ARM64 크로스 컴파일용

# 타겟 시스템 정보
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# 크로스 컴파일러 설정
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc-11)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++-11)

# Sysroot 경로 설정
set(CMAKE_SYSROOT ${CMAKE_CURRENT_LIST_DIR}/sysroot)

# 라이브러리 및 헤더 검색 경로
set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Qt5 라이브러리 경로 오버라이드
set(Qt5Core_DIR "${CMAKE_SYSROOT}/usr/lib/aarch64-linux-gnu/cmake/Qt5Core")
set(Qt5Gui_DIR "${CMAKE_SYSROOT}/usr/lib/aarch64-linux-gnu/cmake/Qt5Gui")
set(Qt5Widgets_DIR "${CMAKE_SYSROOT}/usr/lib/aarch64-linux-gnu/cmake/Qt5Widgets")
set(Qt5Qml_DIR "${CMAKE_SYSROOT}/usr/lib/aarch64-linux-gnu/cmake/Qt5Qml")
set(Qt5Quick_DIR "${CMAKE_SYSROOT}/usr/lib/aarch64-linux-gnu/cmake/Qt5Quick")
EOF

echo "✅ 완료: $TOOLCHAIN_FILE"
