// CanInterface.h
#ifndef CANINTERFACE_H
#define CANINTERFACE_H

#include <QObject>
#include <QSerialPort>
#include <QTimer>
#include <QSettings>
#include <QByteArray>

class CanInterface : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionChanged)
    Q_PROPERTY(int speed READ speed NOTIFY speedChanged)
    Q_PROPERTY(int rpm READ rpm NOTIFY rpmChanged)

public:
    explicit CanInterface(QObject *parent = nullptr);
    ~CanInterface();

    // Properties
    bool isConnected() const { return m_isConnected; }
    int speed() const { return m_speed; }
    int rpm() const { return m_rpm; }

    // Public methods
    Q_INVOKABLE bool initialize(const QString &portName = "/dev/ttyUSB0");
    Q_INVOKABLE void startReceiving();
    Q_INVOKABLE void stopReceiving();
    Q_INVOKABLE void sendCanMessage(quint32 id, const QByteArray &data);

signals:
    void connectionChanged();
    void speedChanged();
    void rpmChanged();
    void canMessageReceived(quint32 id, const QByteArray &data);
    void errorOccurred(const QString &error);

private slots:
    void readSerialData();
    void handleSerialError(QSerialPort::SerialPortError error);
    void processCanMessage();

private:
    // Arduino 시리얼 통신
    QSerialPort *m_serialPort;
    QTimer *m_receiveTimer;

    // 설정
    QSettings *m_settings;
    QString m_configFile;

    // 상태
    bool m_isConnected;
    bool m_isReceiving;

    // 데이터
    int m_speed;
    int m_rpm;
    QByteArray m_receiveBuffer;

    // CAN 메시지 ID (config에서 로드)
    quint32 m_speedSensorId;
    quint32 m_rpmSensorId;
    quint32 m_diagnosticId;

    // Private methods
    void loadConfiguration();
    void parseCanData(const QByteArray &data);
    quint32 extractCanId(const QByteArray &data);
    QByteArray extractCanData(const QByteArray &data);
};

#endif // CANINTERFACE_H
