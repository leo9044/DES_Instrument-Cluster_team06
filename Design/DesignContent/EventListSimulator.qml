import QtQuick

QtObject {
    id: simulator
    property bool active: true

    property Timer __timer: Timer {
        id: timer
        interval: 100
        onTriggered: {
            // Studio 전용 기능 제거 → 로그로 대체
            console.log("Simulated event triggered (Qt5 fallback)")
        }
    }

    Component.onCompleted: {
        // EventSystem 제거
        if (simulator.active)
            timer.start()
    }
}
