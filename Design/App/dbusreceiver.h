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

    QString getBatteryStatus();
    QString getGear();
    QString gear() const { return m_gear; }

signals:
    void gearChanged();

private slots:
    void onGearChanged(const QString &newGear);

private:
    QDBusInterface *batteryIface;
    QDBusInterface *vehicleIface;

    QString m_gear;
};

#endif // DBUSRECEIVER_H
