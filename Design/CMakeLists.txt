cmake_minimum_required(VERSION 3.10)
project(DesignApp LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

find_package(Qt5 REQUIRED COMPONENTS Core Gui Widgets Qml Quick QuickControls2)

qt5_add_resources(QML_RESOURCES "${CMAKE_CURRENT_SOURCE_DIR}/App.qrc")

add_executable(${PROJECT_NAME}
    App/main.cpp
    ${QML_RESOURCES}
)

target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt5::Core
    Qt5::Gui
    Qt5::Widgets
    Qt5::Quick
    Qt5::Qml
    Qt5::QuickControls2
)
