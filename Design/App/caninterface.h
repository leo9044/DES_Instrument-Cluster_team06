#ifndef CANINTERFACE_H
#define CANINTERFACE_H

#include <QObject>
#include <QTimer>
#include <QThread>
#include <QMutex>
#include <QDebug>
#include <QProcess>
#include <linux/can.h>
#include <linux/can/raw.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <unistd.h>
#include <cstring>

/**
 * @brief Arduino CAN 통신을 위한 Qt 클래스
 *
 * Arduino MCP2515에서 보내는 속도 데이터를 수신하고 Qt 시그널로 전달
 */
class CanInterface : public QObject
{
    Q_OBJECT

public:
    explicit CanInterface(QObject *parent = nullptr);
    ~CanInterface();

    // CAN 연결 관리
    bool connectToCan(const QString &interface = "can0");
    void disconnectFromCan();
    bool isConnected() const;

    // 현재 속도 데이터 가져오기
    float getCurrentSpeedKmh() const;
    float getCurrentSpeedCms() const;
    float getCurrentRpm() const;

    // 테스트용 데이터 전송
    void sendTestSpeedData(float speedCms);

public slots:
    void startReceiving();
    void stopReceiving();

signals:
    // 새로운 속도 데이터 수신 시 발생
    void speedDataReceived(float speedKmh, float speedCms);
    void rpmDataReceived(float rpm);

    // 연결 상태 변경 시 발생
    void canConnected();
    void canDisconnected();
    void canError(const QString &error);

private slots:
    void receiveCanMessages();

private:
    // CAN 인터페이스 설정
    bool setupCanInterface(const QString &interface);

    // 메시지 처리
    void processCanMessage(const struct can_frame &frame);
    float parseArduinoSpeedData(const uint8_t *data);

    // 멤버 변수
    QString m_interfaceName;
    int m_canSocket;
    bool m_isConnected;
    bool m_isReceiving;

    QTimer *m_receiveTimer;
    mutable QMutex m_dataMutex;  // mutable 추가: const 함수 내에서도 락 가능

    // 속도 데이터 저장
    struct SpeedData {
        float speedCms;    // Arduino에서 전송하는 cm/s
        float speedKmh;    // km/h로 변환된 값
        float rpm;
        qint64 timestamp;
    } m_speedData;

    // Arduino CAN ID (Arduino 코드와 동일)
    static constexpr uint32_t ARDUINO_SPEED_ID = 0x0F6;
    static constexpr uint32_t ARDUINO_RPM_ID = 0x124;  // 추후 RPM 데이터용
};

#endif // CANINTERFACE_H
