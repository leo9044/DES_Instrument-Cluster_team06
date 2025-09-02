#!/bin/bash

# Qt5 크로스컴파일 설정

# 라즈베리파이 정보
RPI_IP="greywolf1"
RPI_USER="team06"

# 경로 설정
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$HOME/build"
SYSROOT_DIR="$PROJECT_ROOT/sysroot"
TOOLCHAIN_FILE="$PROJECT_ROOT/toolchain-rpi.cmake"

# 크로스 컴파일러
CROSS_GCC="aarch64-linux-gnu-gcc-11"
CROSS_GXX="aarch64-linux-gnu-g++-11"
