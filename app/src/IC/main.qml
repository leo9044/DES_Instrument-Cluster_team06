import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: window
    visible: true
    width: 800
    height: 480
    title: "CAN 속도계 대시보드"

    property real currentSpeed: 0.0
    property real maxSpeed: 120.0

    // CAN 데이터 수신 시그널 연결
    Component.onCompleted: {
        canInterface.speedDataReceived.connect(onSpeedDataReceived)
        canInterface.canConnected.connect(onCanConnected)
        canInterface.canError.connect(onCanError)
    }

    function onSpeedDataReceived(speedKmh, speedCms) {
        currentSpeed = speedKmh
        speedText.text = speedKmh.toFixed(1)
        console.log("속도 업데이트:", speedKmh, "km/h")
    }

    function onCanConnected() {
        statusText.text = "CAN 연결됨"
        statusText.color = "green"
        console.log("CAN 연결 성공")
    }

    function onCanError(error) {
        statusText.text = "CAN 오류: " + error
        statusText.color = "red"
        console.log("CAN 오류:", error)
    }

    // 배경
    Rectangle {
        anchors.fill: parent
        color: "#1a1a1a"

        // 메인 레이아웃
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            // 상태 표시
            Text {
                id: statusText
                text: "CAN 연결 대기 중..."
                color: "yellow"
                font.pixelSize: 16
                Layout.alignment: Qt.AlignHCenter
            }

            // 속도계 영역
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // 속도계 배경 원
                Rectangle {
                    id: speedometerBg
                    width: Math.min(parent.width, parent.height) * 0.8
                    height: width
                    radius: width / 2
                    anchors.centerIn: parent
                    color: "#2a2a2a"
                    border.color: "#4a4a4a"
                    border.width: 3

                    // 속도 텍스트
                    Column {
                        anchors.centerIn: parent
                        spacing: 10

                        Text {
                            id: speedText
                            text: "0.0"
                            color: "#00ff00"
                            font.pixelSize: 48
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: "km/h"
                            color: "#888888"
                            font.pixelSize: 20
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    // 속도 바 (원형)
                    Canvas {
                        id: speedBar
                        anchors.fill: parent
                        anchors.margins: 10

                        property real speedRatio: currentSpeed / maxSpeed
                        property real startAngle: 225 * Math.PI / 180  // 시작 각도 (225도)
                        property real endAngle: -45 * Math.PI / 180    // 끝 각도 (-45도)
                        property real totalAngle: startAngle - endAngle // 총 270도

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)

                            var centerX = width / 2
                            var centerY = height / 2
                            var radius = Math.min(width, height) / 2 - 10

                            // 배경 호
                            ctx.beginPath()
                            ctx.arc(centerX, centerY, radius, endAngle, startAngle, false)
                            ctx.lineWidth = 8
                            ctx.strokeStyle = "#333333"
                            ctx.stroke()

                            // 속도 호
                            if (speedRatio > 0) {
                                var currentAngle = startAngle - (totalAngle * speedRatio)
                                ctx.beginPath()
                                ctx.arc(centerX, centerY, radius, startAngle, currentAngle, true)
                                ctx.lineWidth = 8
                                ctx.strokeStyle = speedRatio > 0.8 ? "#ff4444" : "#00ff00"
                                ctx.stroke()
                            }
                        }

                        Connections {
                            target: window
                            function onCurrentSpeedChanged() {
                                speedBar.requestPaint()
                            }
                        }
                    }

                    // 속도 눈금
                    Repeater {
                        model: 13 // 0, 10, 20, ... 120

                        Rectangle {
                            property real angle: 225 - (index * 270 / 12)
                            property real radian: angle * Math.PI / 180
                            property real tickRadius: speedometerBg.width / 2 - 25

                            width: 2
                            height: 15
                            color: "#666666"

                            x: speedometerBg.width / 2 + tickRadius * Math.cos(radian) - width / 2
                            y: speedometerBg.height / 2 + tickRadius * Math.sin(radian) - height / 2

                            transform: Rotation {
                                origin.x: 1
                                origin.y: 7.5
                                angle: parent.angle + 90
                            }
                        }
                    }

                    // 속도 숫자
                    Repeater {
                        model: 13

                        Text {
                            property real angle: 225 - (index * 270 / 12)
                            property real radian: angle * Math.PI / 180
                            property real textRadius: speedometerBg.width / 2 - 45

                            text: index * 10
                            color: "#888888"
                            font.pixelSize: 14

                            x: speedometerBg.width / 2 + textRadius * Math.cos(radian) - width / 2
                            y: speedometerBg.height / 2 + textRadius * Math.sin(radian) - height / 2
                        }
                    }
                }
            }

            // 하단 컨트롤
            RowLayout {
                Layout.fillWidth: true

                Button {
                    text: "CAN 연결"
                    onClicked: {
                        if (canInterface.connectToCan("can0")) {
                            canInterface.startReceiving()
                        }
                    }
                }

                Button {
                    text: "CAN 해제"
                    onClicked: canInterface.disconnectFromCan()
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "테스트 데이터"
                    onClicked: {
                        // 테스트용 속도 데이터 전송
                        var testSpeed = Math.random() * 100 * 100 // 0-100 km/h를 cm/s로
                        canInterface.sendTestSpeedData(testSpeed)
                    }
                }
            }
        }
    }
}
