import QtQuick 2.15
import QtQuick.Controls 2.15
import Design 1.0

Rectangle {
    id: rectangle
    width: Constants.width
    height: Constants.height
    color: "#000000"

    property int speed: 0
    property string gear: "P"

    // ✅ 속도값 증가용 타이머 (자동 증가 테스트용)
    Timer {
        id: speedTimer
        interval: 50
        running: true
        repeat: true
        onTriggered: {
            speed = (speed < 240) ? speed + 1 : 0
        }
    }

    // ✅ 배터리 게이지

    Image {
        id: battery_white
        x: 1005
        y: 125
        width: 150
        height: 150
        opacity: 1
        source: "images/Battery_white.png"
        scale: 1
        rotation: -90
        fillMode: Image.PreserveAspectFit
    }

    Image {
        id: gauge_Speed
        x: 453
        y: 0
        width: 400
        height: 400
        anchors.verticalCenter: parent.verticalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 0
        anchors.bottomMargin: 0
        source: "images/Gauge_Speed.png"
        anchors.horizontalCenterOffset: 0
        rotation: 45
        anchors.horizontalCenter: parent.horizontalCenter
        fillMode: Image.PreserveAspectFit
    }

    Image {
        id: gaugeSpeedometer_Ticks2
        x: 511
        y: 61
        width: 259
        height: 278
        anchors.verticalCenter: parent.verticalCenter
        source: "images/GaugeSpeedometer_Ticks2.png"
        anchors.verticalCenterOffset: 0
        anchors.horizontalCenterOffset: -1
        anchors.horizontalCenter: parent.horizontalCenter
        fillMode: Image.PreserveAspectFit
    }

    Image {
        id: gaugeNeedleBig
        x: 560
        y: 168
        width: 160
        height: 66
        source: "images/gaugeNeedleBig.png"
        anchors.horizontalCenterOffset: -49
        anchors.horizontalCenter: gauge_Speed.horizontalCenter
        fillMode: Image.PreserveAspectFit

        transform: Rotation {
            origin.x: 130
            origin.y: 33
            angle: -45 + (speed * 1.125)
        }
    }

    Image {
        id: bottomPanel
        x: 291
        y: 209
        width: 697
        height: 298
        anchors.right: parent.right
        anchors.rightMargin: 292
        anchors.topMargin: 125
        source: "images/BottomPanel.png"
        fillMode: Image.PreserveAspectFit
    }

    Image {
        id: gaugeSpeedometer_Ticks3
        x: 60
        y: 50
        width: 280
        height: 280
        anchors.verticalCenter: parent.verticalCenter
        source: "images/GaugeSpeedometer_Ticks2.png"
        fillMode: Image.PreserveAspectFit
    }

    Image {
        id: gaugeSpeedometer_Ticks4
        x: 940
        y: 60
        height: 280
        anchors.verticalCenter: parent.verticalCenter
        anchors.top: gaugeSpeedometer_Ticks3.top
        anchors.bottom: gaugeSpeedometer_Ticks3.bottom
        source: "images/GaugeSpeedometer_Ticks2.png"
        fillMode: Image.PreserveAspectFit
    }

    Image {
        id: gaugeSpeedometer_Ticks1
        x: 27
        y: 24
        anchors.verticalCenter: parent.verticalCenter
        source: "images/GaugeSpeedometer_Ticks1.png"
        anchors.horizontalCenter: gaugeSpeedometer_Ticks3.horizontalCenter
        fillMode: Image.PreserveAspectFit

        TextInput {
            id: textInput
            x: 134
            y: 265
            width: 195
            height: 49
            color: "#730000"
            text: qsTr("Gear")
            font.pixelSize: 20
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }

        TextInput {
            id: textInput2
            x: 134
            y: 265
            width: 195
            height: 49
            color: "#730000"
            text: qsTr("Battery")
            font.pixelSize: 20
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.horizontalCenterOffset: 881
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    Image {
        id: gaugeSpeedometer_Ticks5
        x: 907
        y: 24
        anchors.verticalCenter: parent.verticalCenter
        anchors.top: gaugeSpeedometer_Ticks1.top
        anchors.bottom: gaugeSpeedometer_Ticks1.bottom
        source: "images/GaugeSpeedometer_Ticks1.png"
        anchors.horizontalCenter: gaugeSpeedometer_Ticks4.horizontalCenter
        fillMode: Image.PreserveAspectFit
    }

    TextInput {
        id: textInput3
        x: 546
        y: 332
        width: 188
        height: 81
        color: "#730000"
        font.pixelSize: 30
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.bold: true
        readOnly: true

        // ✨ text 속성 바인딩을 명시적으로 설정
        Binding {
            target: textInput3
            property: "text"
            value: speed.toString()
        }
    }

    TextInput {
        id: textInput4
        x: 125
        y: 125
        width: 150
        height: 150
        color: "#ffffff"
        font.pixelSize: 100
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.bold: true
        readOnly: true

        // 기어 표시: 속도에 따라 변경되도록 계산
        text: {
            if (speed <= 60)
                return "P"
            else if (speed <= 120)
                return "R"
            else if (speed <= 180)
                return "N"
            else
                return "D"
        }
    }
    Rectangle {
        id: batteryFill
        x: 1045
        y: 521
        width: 70

        // 🟩🟧🟥 속도에 따라 배터리 색상 설정
        // 0 ~ 80   → 빨강
        // 81 ~ 160 → 주황
        // 161~240  → 초록
        color: {
            if (speed <= 80)
                return "#ff4444"
            else if (speed <= 160)
                return "#ffaa33"
            else
                return "#57e389"
        }

        // 🪫 배터리 게이지의 높이를 속도에 맞게 비례 조절
        // 최대 높이: 150, 최대 속도: 240
        height: 150 * speed / 240

        // 🧲 배터리 외곽 이미지 하단에 고정
        anchors.bottom: battery_white.bottom
        anchors.bottomMargin: -246
        anchors.horizontalCenterOffset: 124
        anchors.horizontalCenter: battery_white.horizontalCenter

        radius: 4
        z: battery_white.z - 1
    }
}
