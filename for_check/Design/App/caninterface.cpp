#include "caninterface.h"
#include <QDateTime>

CanInterface::CanInterface(QObject *parent)
    : QObject(parent)
    , m_canSocket(-1)
    , m_isConnected(false)
    , m_isReceiving(false)
    , m_receiveTimer(new QTimer(this))
{
    // 속도 데이터 초기화
    m_speedData.speedCms = 0.0f;
    m_speedData.speedKmh = 0.0f;
    m_speedData.rpm = 0.0f;
    m_speedData.timestamp = QDateTime::currentMSecsSinceEpoch();

    // 타이머 설정 (10ms마다 CAN 메시지 체크)
    m_receiveTimer->setSingleShot(false);
    m_receiveTimer->setInterval(10);
    connect(m_receiveTimer, &QTimer::timeout, this, &CanInterface::receiveCanMessages);

    qDebug() << "CanInterface 초기화 완료";
}

CanInterface::~CanInterface()
{
    disconnectFromCan();
}

bool CanInterface::setupCanInterface(const QString &interface)
{
    QProcess process;

    if (interface.startsWith("vcan")) {
        process.start("ip", QStringList() << "link" << "show" << interface);
        process.waitForFinished();

        if (process.exitCode() == 0) {
            qDebug() << "가상 CAN 인터페이스" << interface << "사용 가능";
            return true;
        } else {
            qDebug() << "가상 CAN 인터페이스" << interface << "를 찾을 수 없음";
            return false;
        }
    } else {
        process.start("sudo", QStringList() << "ip" << "link" << "set" << interface << "down");
        process.waitForFinished();

        process.start("sudo", QStringList() << "ip" << "link" << "set" << interface
                                            << "type" << "can" << "bitrate" << "1000000");
        process.waitForFinished();

        if (process.exitCode() != 0) {
            QString error = QString("CAN bitrate 설정 실패: %1").arg(QString(process.readAllStandardError()));
            emit canError(error);
            return false;
        }

        process.start("sudo", QStringList() << "ip" << "link" << "set" << interface << "up");
        process.waitForFinished();

        if (process.exitCode() != 0) {
            QString error = QString("CAN 인터페이스 활성화 실패: %1").arg(QString(process.readAllStandardError()));
            emit canError(error);
            return false;
        }
    }

    qDebug() << "CAN 인터페이스" << interface << "설정 완료";
    return true;
}

bool CanInterface::connectToCan(const QString &interface)
{
    if (m_isConnected) {
        qDebug() << "이미 CAN에 연결되어 있음";
        return true;
    }

    m_interfaceName = interface;

    if (!setupCanInterface(interface)) {
        return false;
    }

    m_canSocket = socket(PF_CAN, SOCK_RAW, CAN_RAW);
    if (m_canSocket < 0) {
        QString error = "CAN 소켓 생성 실패";
        qDebug() << error;
        emit canError(error);
        return false;
    }

    struct ifreq ifr;
    strcpy(ifr.ifr_name, interface.toLocal8Bit().data());

    if (ioctl(m_canSocket, SIOCGIFINDEX, &ifr) < 0) {
        QString error = "인터페이스 인덱스 가져오기 실패";
        qDebug() << error;
        emit canError(error);
        close(m_canSocket);
        m_canSocket = -1;
        return false;
    }

    struct sockaddr_can addr;
    addr.can_family = AF_CAN;
    addr.can_ifindex = ifr.ifr_ifindex;

    if (bind(m_canSocket, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        QString error = "CAN 소켓 바인딩 실패";
        qDebug() << error;
        emit canError(error);
        close(m_canSocket);
        m_canSocket = -1;
        return false;
    }

    m_isConnected = true;
    qDebug() << "CAN 버스" << interface << "에 연결 완료";
    emit canConnected();

    return true;
}

void CanInterface::disconnectFromCan()
{
    stopReceiving();

    if (m_canSocket >= 0) {
        close(m_canSocket);
        m_canSocket = -1;
    }

    if (m_isConnected) {
        m_isConnected = false;
        qDebug() << "CAN 버스 연결 해제";
        emit canDisconnected();
    }
}

bool CanInterface::isConnected() const
{
    return m_isConnected;
}

void CanInterface::startReceiving()
{
    if (!m_isConnected) {
        qDebug() << "CAN에 연결되지 않음";
        return;
    }

    if (m_isReceiving) {
        return;
    }

    m_isReceiving = true;
    m_receiveTimer->start();
    qDebug() << "CAN 메시지 수신 시작";
}

void CanInterface::stopReceiving()
{
    if (m_isReceiving) {
        m_isReceiving = false;
        m_receiveTimer->stop();
        qDebug() << "CAN 메시지 수신 중지";
    }
}

void CanInterface::receiveCanMessages()
{
    if (m_canSocket < 0 || !m_isReceiving) {
        return;
    }

    struct can_frame frame;

    fd_set readfds;
    struct timeval timeout;

    FD_ZERO(&readfds);
    FD_SET(m_canSocket, &readfds);
    timeout.tv_sec = 0;
    timeout.tv_usec = 1000;

    int result = select(m_canSocket + 1, &readfds, nullptr, nullptr, &timeout);

    if (result > 0 && FD_ISSET(m_canSocket, &readfds)) {
        ssize_t bytesRead = read(m_canSocket, &frame, sizeof(frame));

        if (bytesRead == sizeof(frame)) {
            processCanMessage(frame);
        }
    }
}

void CanInterface::processCanMessage(const struct can_frame &frame)
{
    if (frame.can_id == ARDUINO_SPEED_ID) {
        float speedCms = parseArduinoSpeedData(frame.data);
        float speedKmh = speedCms * 0.036f;

        QMutexLocker locker(&m_dataMutex);
        m_speedData.speedCms = speedCms;
        m_speedData.speedKmh = speedKmh;
        m_speedData.timestamp = QDateTime::currentMSecsSinceEpoch();
        locker.unlock();

        emit speedDataReceived(speedKmh, speedCms);



        // 디버깅용 원시 데이터 출력
        QString canData = "CAN 데이터: ";
        for (int i = 0; i < frame.can_dlc; i++) {
            canData += QString("0x%1 ").arg(frame.data[i], 2, 16, QChar('0')).toUpper();
        }
        qDebug() << canData;
    }
    // 추후 RPM 데이터 수신 처리 등도 추가 가능
}

float CanInterface::parseArduinoSpeedData(const uint8_t *data)
{
    try {
        // Arduino 형식에 따라 파싱:
        // data[0] = int1_spd / 256 (정수 부분의 상위 바이트)
        // data[1] = int1_spd % 256 (정수 부분의 하위 바이트)
        // data[2] = int2_spd (소수 부분 * 100)

        int int1_spd = (data[0] << 8) | data[1];  // 정수 부분 재구성
        int int2_spd = data[2];                   // 소수 부분

        float speedCms = int1_spd + (int2_spd / 100.0f);
        return qMax(0.0f, speedCms);  // 음수 방지

    } catch (...) {
        qDebug() << "Arduino 속도 데이터 파싱 오류";
        return 0.0f;
    }
}

float CanInterface::getCurrentSpeedKmh() const
{
    QMutexLocker locker(&m_dataMutex);
    return m_speedData.speedKmh;
}

float CanInterface::getCurrentSpeedCms() const
{
    QMutexLocker locker(&m_dataMutex);
    return m_speedData.speedCms;
}

float CanInterface::getCurrentRpm() const
{
    QMutexLocker locker(&m_dataMutex);
    return m_speedData.rpm;
}

void CanInterface::sendTestSpeedData(float speedCms)
{
    if (m_canSocket < 0) {
        qDebug() << "CAN 소켓이 연결되지 않음";
        return;
    }

    // Arduino와 동일한 형식으로 데이터 포맷
    int int1_spd = static_cast<int>(speedCms);
    int int2_spd = static_cast<int>((speedCms - int1_spd) * 100);

    struct can_frame frame;
    frame.can_id = ARDUINO_SPEED_ID;
    frame.can_dlc = 8;
    memset(frame.data, 0, 8);

    frame.data[0] = int1_spd / 256;      // 상위 바이트
    frame.data[1] = int1_spd % 256;      // 하위 바이트
    frame.data[2] = int2_spd;            // 소수 부분

    ssize_t bytesWritten = write(m_canSocket, &frame, sizeof(frame));
    if (bytesWritten != sizeof(frame)) {
        qDebug() << "CAN 메시지 전송 실패";
    } else {
        qDebug() << QString("테스트 속도 데이터 전송: %1 cm/s").arg(speedCms);
    }
}
