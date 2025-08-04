cmake_minimum_required(VERSION 3.16)
project(IC VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(CMAKE_CROSSCOMPILING)
    set(Qt5_DIR "${CMAKE_SYSROOT}/usr/lib/aarch64-linux-gnu/cmake/Qt5")
    find_package(Qt5 REQUIRED COMPONENTS Core Quick SerialPort)
    set(Qt5Core_RCC_EXECUTABLE /usr/lib/qt5/bin/rcc)
    set(Qt5Core_MOC_EXECUTABLE /usr/lib/qt5/bin/moc)
    set(QT_VERSION_MAJOR 5)
else()
    find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core Quick SerialPort)
    find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Quick SerialPort)
endif()

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

qt5_add_resources(QRC_FILES "IC/Resources/qml.qrc")

set(PROJECT_SOURCES
    main.cpp
    caninterface.cpp
    ${QRC_FILES}
)

if(${QT_VERSION_MAJOR} GREATER_EQUAL 6)
    qt_add_executable(IC MANUAL_FINALIZATION ${PROJECT_SOURCES})
else()
    add_executable(IC ${PROJECT_SOURCES})
endif()

target_link_libraries(IC
    PRIVATE Qt${QT_VERSION_MAJOR}::Core
            Qt${QT_VERSION_MAJOR}::Quick
            Qt${QT_VERSION_MAJOR}::SerialPort
)

if(QT_VERSION_MAJOR EQUAL 6 AND NOT CMAKE_CROSSCOMPILING)
    qt_import_qml_plugins(IC)
    qt_finalize_executable(IC)
endif()

set_target_properties(IC PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)
