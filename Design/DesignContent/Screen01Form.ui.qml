import QtQuick 2.15
import QtQuick.Controls 2.15
import Design 1.0

Rectangle {
    id: rectangle
    width: Constants.width
    height: Constants.height
    color: "#000000"

    // 속도 프로퍼티
    property int speed: 0

    // 기어 상태 프로퍼티 (초기값 'P')
    property string gear: "P"

    // dbusReceiver의 신호를 감지해서 QML 내부 프로퍼티를 업데이트
    Connections {
        target: dbusReceiver

        // 기어 변경 신호 처리
        onGearChanged: {
            gear = dbusReceiver.gear
            console.log("Gear updated from D-Bus:", gear)
        }

        // 배터리 변경 신호 처리 (UI는 아래에서 직접 바인딩되므로 여기서는 로그만 출력)
        onBatteryChanged: {
            console.log("Battery Percentage updated:", dbusReceiver.batteryPercentage)
        }

        // 전류 변경 신호 처리 (UI는 아래에서 직접 바인딩되므로 여기서는 로그만 출력)
        onCurrentChanged: {
            console.log("Current updated:", dbusReceiver.current)
        }
    }

    // QML에서 CanInterface의 speedDataReceived 시그널 연결
    Connections {
        target: canInterface
        onSpeedDataReceived: {
            speed = Math.min(Math.round(speedCms), 240);
            speed *= 27.7778;
        }
    }

    // --- Battery UI ---
    Rectangle {
        id: battery_fill
        width: 70
        // ⬇ 배터리 잔량(%)에 따라 높이를 계산하도록 바인딩
        height: 116 * dbusReceiver.batteryPercentage / 100
        x: 1045
        y: 145
        border.color: "#ffffff"
        z: battery_outline_icon.z

        //anchors.bottom: battery_outline_icon.bottom
        //anchors.horizontalCenter: battery_outline_icon.horizontalCenter
        anchors.bottomMargin: 15

        // ⬇ 배터리 잔량(%)에 따라 색상을 변경하도록 바인딩
        color: dbusReceiver.batteryPercentage <= 20 ? "#ff4444"  // 20% 이하 빨강
             : dbusReceiver.batteryPercentage <= 60 ? "#ffaa33"  // 60% 이하 주황
                                                    : "#57e389"  // 그 외 초록
    }

    Image {
        id: battery_outline_icon
        x: 1024
        y: 80
        width: 120
        source: "images/battery_outline_icon.png"
        fillMode: Image.PreserveAspectFit
    }

    // ⬇ 충전 중 번개 아이콘 표시: 전류(current)가 0.1A 이상일 때 (충전 상태)
    Image {
        id: bolt_icon
        x: 1050
        y: 140
        width: 60
        source: "images/bolt_icon.png"
        fillMode: Image.PreserveAspectFit
        visible: dbusReceiver.current > 0.1
    }

    // ⬇ 배터리 잔량을 텍스트로 표시
    Text {
        id: battery_text
        anchors.centerIn: battery_outline_icon
        font.pixelSize: 25
        font.bold: true
        color: "white"
        // ⬇ 배터리 퍼센티지 값과 '%' 기호를 함께 표시
        text: dbusReceiver.batteryPercentage + "%"
        // ⬇ 번개 아이콘이 보일 때는 텍스트를 숨김
        visible: !bolt_icon.visible
    }


    // --- 이하 기존 UI 코드 (수정 없음) ---

    //Gauge
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

    //Bottom
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

    // 속도 표시 텍스트
    TextInput {
        id: textInput3
        x: 546
        y: 332
        width: 188
        height: 81
        color: "#ffffff"
        font.pixelSize: 30
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.bold: true
        readOnly: true
        text: speed.toString()
    }

    // 기어 상태 표시 텍스트
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
        text: gear
    }
}
