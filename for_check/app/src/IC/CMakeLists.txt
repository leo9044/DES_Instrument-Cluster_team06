cmake_minimum_required(VERSION 3.16)

project(IC VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Qt5 패키지 찾기
find_package(Qt5 REQUIRED COMPONENTS
    Core
    Quick
    SerialPort
    Network
    Gui
    Qml
    QmlModels
)

# AUTO 도구들 완전히 비활성화
set(CMAKE_AUTOMOC OFF)
set(CMAKE_AUTORCC OFF)
set(CMAKE_AUTOUIC OFF)

# Qt5 include 디렉토리들 수집
get_target_property(QT5_CORE_INCLUDE_DIRS Qt5::Core INTERFACE_INCLUDE_DIRECTORIES)

# 호스트 시스템의 moc을 직접 실행 (include 경로 수정)
add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/moc_caninterface.cpp
    COMMAND /usr/bin/moc
        -DQT_CORE_LIB
        -DQT_GUI_LIB
        -DQT_NETWORK_LIB
        -DQT_QMLMODELS_LIB
        -DQT_QML_LIB
        -DQT_QUICK_LIB
        -DQT_SERIALPORT_LIB
        -I/home/leo/raspi-sysroot/usr/include/aarch64-linux-gnu/qt5
        -I/home/leo/raspi-sysroot/usr/include/aarch64-linux-gnu/qt5/QtCore
        -I/home/leo/raspi-sysroot/usr/include/aarch64-linux-gnu/qt5/QtQuick
        -I/home/leo/raspi-sysroot/usr/include/aarch64-linux-gnu/qt5/QtQmlModels
        -I/home/leo/raspi-sysroot/usr/include/aarch64-linux-gnu/qt5/QtQml
        -I/home/leo/raspi-sysroot/usr/include/aarch64-linux-gnu/qt5/QtNetwork
        -I/home/leo/raspi-sysroot/usr/include/aarch64-linux-gnu/qt5/QtGui
        -I/home/leo/raspi-sysroot/usr/include/aarch64-linux-gnu/qt5/QtSerialPort
        -I${CMAKE_CURRENT_SOURCE_DIR}
        -o ${CMAKE_CURRENT_BINARY_DIR}/moc_caninterface.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/caninterface.h
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/caninterface.h
    COMMENT "Generating moc_caninterface.cpp"
)

# QML 리소스 수동 처리 (qml.qrc가 있는 경우) - 호스트 RCC 사용
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/qml.qrc)
    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/qrc_qml.cpp
        COMMAND /usr/bin/rcc
            -name qml
            -o ${CMAKE_CURRENT_BINARY_DIR}/qrc_qml.cpp
            ${CMAKE_CURRENT_SOURCE_DIR}/qml.qrc
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/qml.qrc
        COMMENT "Generating qrc_qml.cpp with host RCC"
    )
    set(QML_RESOURCES ${CMAKE_CURRENT_BINARY_DIR}/qrc_qml.cpp)
else()
    set(QML_RESOURCES "")
    message(STATUS "qml.qrc not found, skipping resources")
endif()

# 실행 파일 생성
add_executable(IC
    main.cpp
    caninterface.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/moc_caninterface.cpp
    ${QML_RESOURCES}
)

# include 디렉토리 추가
target_include_directories(IC PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
)

# Qt5 라이브러리 링크
target_link_libraries(IC
    Qt5::Core
    Qt5::Quick
    Qt5::SerialPort
    Qt5::Network
    Qt5::Gui
    Qt5::Qml
    Qt5::QmlModels
)

# 컴파일러별 설정
if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    target_compile_options(IC PRIVATE -Wall -Wextra -Wpedantic)
endif()

# 인스톨 설정
install(TARGETS IC
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
