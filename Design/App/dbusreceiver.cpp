#include "dbusreceiver.h"
#include <QDebug>

DBusReceiver::DBusReceiver(QObject *parent) : QObject(parent) {
    // 각 D-Bus 서비스에 대한 인터페이스 생성
    batteryIface = new QDBusInterface(
        "org.example.BatteryService",   // 서비스 이름 (버튼.py가 제공하는 서비스명)
        "/Battery",                     // 오브젝트 경로
        "org.example.Battery",          // 인터페이스 이름
        QDBusConnection::sessionBus(), // 버스 종류
        this
        );

    vehicleIface = new QDBusInterface(
        "org.example.VehicleService",   // 서비스 이름 (controller.py가 제공하는 서비스명)
        "/Vehicle",                     // 오브젝트 경로
        "org.example.Vehicle",          // 인터페이스 이름
        QDBusConnection::sessionBus(),
        this
        );
}

QString DBusReceiver::getBatteryStatus() {
    if (!batteryIface->isValid()) {
        qWarning() << "Battery D-Bus interface is invalid";
        return QString();
    }

    QDBusReply<QString> reply = batteryIface->call("GetStatus");
    if (reply.isValid()) {
        return reply.value();
    } else {
        qWarning() << "Battery GetStatus call failed:" << reply.error().message();
        return QString();
    }
}

QString DBusReceiver::getGear() {
    if (!vehicleIface->isValid()) {
        qWarning() << "Vehicle D-Bus interface is invalid";
        return QString();
    }

    QDBusReply<QString> reply = vehicleIface->call("GetGear");
    if (reply.isValid()) {
        return reply.value();
    } else {
        qWarning() << "Vehicle GetGear call failed:" << reply.error().message();
        return QString();
    }
}
