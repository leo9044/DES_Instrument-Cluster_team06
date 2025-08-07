pragma Singleton
import QtQuick 2.15

QtObject {
    readonly property int width: 1280
    readonly property int height: 400

    property string relativeFontDirectory: "fonts"

    readonly property font font: Qt.font({
        family: "Arial", // Qt.application.font.family 은 Qt 5에서 지원 안 함
        pixelSize: 20
    })

    readonly property font largeFont: Qt.font({
        family: "Arial",
        pixelSize: 32
    })

    readonly property color backgroundColor: "#EAEAEA"

    // ❌ StudioApplication 제거
    // property StudioApplication application: ...
}
