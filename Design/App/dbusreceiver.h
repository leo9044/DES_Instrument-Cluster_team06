#ifndef DBUSRECEIVER_H
#define DBUSRECEIVER_H

#include <QObject>
#include <QDBusInterface>

class DBusReceiver : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString gear READ gear NOTIFY gearChanged)
    Q_PROPERTY(int batteryPercentage READ batteryPercentage NOTIFY batteryChanged)
    Q_PROPERTY(double current READ current NOTIFY currentChanged)

public:
    explicit DBusReceiver(QObject *parent = nullptr);

    // QML 로딩 후 초기값을 요청하기 위한 함수
    Q_INVOKABLE void requestInitialStatus();

    // Getter methods for properties
    QString getGear();
    QString gear() const { return m_gear; }
    int batteryPercentage() const { return m_batteryPercentage; }
    double current() const { return m_current; }

signals:
    void gearChanged();
    void batteryChanged();
    void currentChanged();

private slots:
    // 기어 변경 D-Bus 신호를 처리하는 슬롯
    void onGearChanged(const QString &newGear);
    // 배터리 상태 변경 D-Bus 신호를 처리하는 새로운 슬롯
    void onBatteryStatusChanged(int percentage, double current);

private:
    // D-Bus Interfaces
    QDBusInterface *vehicleIface;
    QDBusInterface *batteryIface;

    // Member variables to store data
    QString m_gear;
    int m_batteryPercentage;
    double m_current;
};

#endif // DBUSRECEIVER_H
