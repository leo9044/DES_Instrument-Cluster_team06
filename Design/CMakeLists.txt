cmake_minimum_required(VERSION 3.16)
project(DesignApp VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt5 REQUIRED COMPONENTS
    Core Gui Widgets Qml Quick QuickControls2
    SerialPort Network QmlModels DBus
)

# 자동 moc/rcc 활성화 (CMake가 알아서 처리)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(SOURCES
    App/main.cpp
    App/caninterface.cpp
    App/dbusreceiver.cpp
    App.qrc
)

add_executable(${PROJECT_NAME} ${SOURCES})

target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt5::Core Qt5::Gui Qt5::Widgets Qt5::Quick Qt5::Qml
    Qt5::QuickControls2 Qt5::SerialPort Qt5::Network
    Qt5::QmlModels Qt5::DBus
)
