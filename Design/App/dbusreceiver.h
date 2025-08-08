#pragma once

#include <QObject>
#include <QDBusInterface>
#include <QDBusReply>

class DBusReceiver : public QObject {
    Q_OBJECT
public:
    explicit DBusReceiver(QObject *parent = nullptr);

    QString getBatteryStatus();
    QString getGear();

private:
    QDBusInterface *batteryIface;
    QDBusInterface *vehicleIface;
};
