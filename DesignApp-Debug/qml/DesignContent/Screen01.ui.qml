import QtQuick
import QtQuick.Controls
import Design
import QtQuick.Studio.Components 1.0

Item {
    id: root
    width: Constants.width
    height: Constants.height
    property real speed: 0

    Rectangle {
        id: rectangle
        anchors.fill: parent
        color: "#000000"

        Image {
            id: gauge_Speed
            x: 453
            y: 0
            width: 373
            height: 400
            anchors.verticalCenter: parent.verticalCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            source: "images/Gauge_Speed.png"
            fillMode: Image.PreserveAspectFit
        }

        Image {
            id: gaugeSpeedometer_Ticks2
            x: 511
            y: 61
            width: 259
            height: 278
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            source: "images/GaugeSpeedometer_Ticks2.png"
            fillMode: Image.PreserveAspectFit
        }

        Item {
            id: needleContainer
            width: 160
            height: 66
            x: 580
            y: 88
            anchors.horizontalCenter: gauge_Speed.horizontalCenter

            transform: Rotation {
                origin.x: 2
                origin.y: height / 2
                angle: 45 + root.speed * 1.35
            }

            Image {
                id: gaugeNeedleBig
                anchors.fill: parent
                source: "images/gaugeNeedleBig.png"
                fillMode: Image.PreserveAspectFit
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
                anchors.verticalCenter: textInput2.verticalCenter
                anchors.top: textInput2.top
                anchors.bottom: textInput2.bottom
                font.pixelSize: 20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.bold: false
                anchors.horizontalCenterOffset: 1
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

        Text {
            id: speedText
            x: 0
            y: 349
            width: 141
            height: 43
            visible: true
            color: "#a50000"
            anchors.bottom: gaugeNeedleBig.bottom
            anchors.bottomMargin: -150
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pointSize: 30
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.speed.toFixed(0)
        }
    }
}
