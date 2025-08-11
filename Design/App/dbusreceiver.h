#ifndef DBUSRECEIVER_H
#define DBUSRECEIVER_H

#include <QObject>
#include <QDBusInterface>

class DBusReceiver : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString gear READ gear NOTIFY gearChanged)

public:
    explicit DBusReceiver(QObject *parent = nullptr);

    // 배터리 관련 함수는 일단 주석 처리 (나중에 다시 활성화 가능)
    // QString getBatteryStatus();

    QString getGear();
    QString gear() const { return m_gear; }

signals:
    void gearChanged();

private slots:
    void onGearChanged(const QString &newGear);

private:
    // 배터리 관련 인터페이스는 현재 사용 안 하므로 주석 처리
    // QDBusInterface *batteryIface;

    QDBusInterface *vehicleIface;

    QString m_gear;
};

#endif // DBUSRECEIVER_H
