// CanInterface.cpp
#include "caninterface.h"
#include <QDebug>
#include <QStandardPaths>
#include<QtEndian>

CanInterface::CanInterface(QObject *parent)
    : QObject(parent)
    , m_serialPort(new QSerialPort(this))
    , m_receiveTimer(new QTimer(this))
    , m_settings(nullptr)
    , m_isConnected(false)
    , m_isReceiving(false)
    , m_speed(0)
    , m_rpm(0)
    , m_speedSensorId(0x123)
    , m_rpmSensorId(0x124)
    , m_diagnosticId(0x7DF)
{
    // 설정 파일 로드
    loadConfiguration();

    // 시리얼 포트 신호 연결
    connect(m_serialPort, &QSerialPort::readyRead,
            this, &CanInterface::readSerialData);
    connect(m_serialPort, QOverload<QSerialPort::SerialPortError>::of(&QSerialPort::errorOccurred),
            this, &CanInterface::handleSerialError);

    // 타이머 설정 (20ms 간격으로 데이터 처리)
    m_receiveTimer->setInterval(20);
    connect(m_receiveTimer, &QTimer::timeout,
            this, &CanInterface::processCanMessage);

    qDebug() << "CanInterface initialized";
}

CanInterface::~CanInterface()
{
    stopReceiving();
    if (m_serialPort->isOpen()) {
        m_serialPort->close();
    }
}

bool CanInterface::initialize(const QString &portName)
{
    if (m_serialPort->isOpen()) {
        m_serialPort->close();
    }

    // 시리얼 포트 설정
    m_serialPort->setPortName(portName);
    m_serialPort->setBaudRate(QSerialPort::Baud9600);
    m_serialPort->setDataBits(QSerialPort::Data8);
    m_serialPort->setParity(QSerialPort::NoParity);
    m_serialPort->setStopBits(QSerialPort::OneStop);
    m_serialPort->setFlowControl(QSerialPort::NoFlowControl);

    if (m_serialPort->open(QIODevice::ReadWrite)) {
        m_isConnected = true;
        emit connectionChanged();
        qDebug() << "Serial port opened:" << portName;
        return true;
    } else {
        QString error = QString("Failed to open serial port: %1, Error: %2")
        .arg(portName)
            .arg(m_serialPort->errorString());
        emit errorOccurred(error);
        qDebug() << error;
        return false;
    }
}

void CanInterface::startReceiving()
{
    if (!m_isConnected) {
        emit errorOccurred("Cannot start receiving: not connected");
        return;
    }

    m_isReceiving = true;
    m_receiveTimer->start();
    qDebug() << "Started receiving CAN data";
}

void CanInterface::stopReceiving()
{
    m_isReceiving = false;
    m_receiveTimer->stop();
    qDebug() << "Stopped receiving CAN data";
}

void CanInterface::sendCanMessage(quint32 id, const QByteArray &data)
{
    if (!m_isConnected) {
        emit errorOccurred("Cannot send message: not connected");
        return;
    }

    // Arduino로 CAN 메시지 전송 (간단한 프로토콜)
    QByteArray message;
    message.append("CAN:");
    message.append(QString::number(id, 16).toUpper().rightJustified(8, '0'));
    message.append(":");
    message.append(data.toHex().toUpper());
    message.append("\n");

    m_serialPort->write(message);
    qDebug() << "Sent CAN message:" << message;
}

void CanInterface::readSerialData()
{
    QByteArray data = m_serialPort->readAll();
    m_receiveBuffer.append(data);
}

void CanInterface::handleSerialError(QSerialPort::SerialPortError error)
{
    if (error == QSerialPort::ResourceError) {
        m_isConnected = false;
        emit connectionChanged();
        emit errorOccurred("Serial port disconnected");
    }
}

void CanInterface::processCanMessage()
{
    if (m_receiveBuffer.isEmpty()) {
        return;
    }

    // 줄바꿈으로 메시지 분리
    while (m_receiveBuffer.contains('\n')) {
        int index = m_receiveBuffer.indexOf('\n');
        QByteArray line = m_receiveBuffer.left(index);
        m_receiveBuffer.remove(0, index + 1);

        if (!line.isEmpty()) {
            parseCanData(line);
        }
    }
}

void CanInterface::parseCanData(const QByteArray &data)
{
    // Arduino에서 오는 데이터 파싱
    // 예상 형식: "CAN:00000123:1234567890ABCDEF"
    QString dataStr = QString::fromUtf8(data).trimmed();

    if (!dataStr.startsWith("CAN:")) {
        return;
    }

    QStringList parts = dataStr.split(':');
    if (parts.size() != 3) {
        return;
    }

    bool ok;
    quint32 canId = parts[1].toUInt(&ok, 16);
    if (!ok) {
        return;
    }

    QByteArray canData = QByteArray::fromHex(parts[2].toUtf8());

    // CAN ID에 따른 데이터 처리
    if (canId == m_speedSensorId && canData.size() >= 4) {
        // 속도 데이터 처리 (4바이트 정수)
        quint32 speedRaw = qFromBigEndian<quint32>(canData.constData());
        int newSpeed = static_cast<int>(speedRaw);

        if (newSpeed != m_speed) {
            m_speed = newSpeed;
            emit speedChanged();
        }
    } else if (canId == m_rpmSensorId && canData.size() >= 4) {
        // RPM 데이터 처리 (4바이트 정수)
        quint32 rpmRaw = qFromBigEndian<quint32>(canData.constData());
        int newRpm = static_cast<int>(rpmRaw);

        if (newRpm != m_rpm) {
            m_rpm = newRpm;
            emit rpmChanged();
        }
    }

    // 일반적인 CAN 메시지 신호 발생
    emit canMessageReceived(canId, canData);

    qDebug() << "Received CAN message - ID:" << Qt::hex << canId
             << "Data:" << canData.toHex();
}

void CanInterface::loadConfiguration()
{
    // 설정 파일 경로 설정 (프로젝트 루트의 config 디렉토리)
    m_configFile = "config/can_config.ini";
    m_settings = new QSettings(m_configFile, QSettings::IniFormat, this);

    // CAN 메시지 ID 로드
    m_speedSensorId = m_settings->value("CAN_MESSAGES/speed_sensor_id", "0x123").toString().toUInt(nullptr, 16);
    m_rpmSensorId = m_settings->value("CAN_MESSAGES/rpm_sensor_id", "0x124").toString().toUInt(nullptr, 16);
    m_diagnosticId = m_settings->value("CAN_MESSAGES/diagnostic_id", "0x7DF").toString().toUInt(nullptr, 16);

    qDebug() << "Configuration loaded:"
             << "Speed ID:" << Qt::hex << m_speedSensorId
             << "RPM ID:" << Qt::hex << m_rpmSensorId;
}
