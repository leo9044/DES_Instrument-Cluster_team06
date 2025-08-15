#ifndef CANINTERFACE_H
#define CANINTERFACE_H

#include <QObject>
#include <QMutex>
#include <QTimer>
#include <QProcess>
#include <QDebug>
#include <QDateTime>

// C++ 표준 라이브러리 및 시스템 헤더
#include <cstring>
#include <unistd.h>

// 시스템 관련 헤더 (소켓 프로그래밍)
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <linux/can.h>
#include <linux/can/raw.h>

// CAN ID 정의
#define ARDUINO_SPEED_ID 0x0F6

// 속도 데이터를 담는 구조체 (kmh 제거)
struct SpeedData {
    float speedCms; // cm/s
    float rpm;
    qint64 timestamp;
};

class CanInterface : public QObject
{
    Q_OBJECT

public:
    explicit CanInterface(QObject *parent = nullptr);
    ~CanInterface();

    bool connectToCan(const QString &interface);
    void disconnectFromCan();
    bool isConnected() const;

    void startReceiving();
    void stopReceiving();

    // Getter 함수 (kmh 제거)
    float getCurrentSpeedCms() const;
    float getCurrentRpm() const;

    // 테스트용 함수
    void sendTestSpeedData(float speedCms);

signals:
    void canConnected();
    void canDisconnected();
    void canError(const QString &error);
    // [수정] cm/s 값 하나만 보내는 신호로 최종 수정
    void speedDataReceived(float speedCms);

private slots:
    void receiveCanMessages();

private:
    bool setupCanInterface(const QString &interface);
    void processCanMessage(const struct can_frame &frame);
    float parseArduinoSpeedData(const uint8_t *data);

    int m_canSocket;
    bool m_isConnected;
    bool m_isReceiving;
    QString m_interfaceName;
    QTimer *m_receiveTimer;

    SpeedData m_speedData;
    mutable QMutex m_dataMutex;
};

#endif // CANINTERFACE_H
