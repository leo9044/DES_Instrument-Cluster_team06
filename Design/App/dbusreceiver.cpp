#include "dbusreceiver.h"
#include <QDebug>
#include <QDBusReply>
#include <QDBusVariant>

DBusReceiver::DBusReceiver(QObject *parent) : QObject(parent) {
    // Battery DBus Interface
    batteryIface = new QDBusInterface(
        "com.car.Battery",               // Python battery.py의 서비스 이름
        "/com/car/Battery",              // 오브젝트 경로
        "org.freedesktop.DBus.Properties", // Get 메서드는 Properties 인터페이스에서 제공
        QDBusConnection::systemBus(),    // battery.py는 SystemBus 사용
        this
        );

    // Vehicle Controller DBus Interface
    vehicleIface = new QDBusInterface(
        "org.piracer.VehicleController", // Python controller.py의 서비스 이름
        "/org/piracer/VehicleController",// 오브젝트 경로
        "org.piracer.VehicleInterface",  // 인터페이스 이름
        QDBusConnection::sessionBus(),   // controller.py는 SessionBus 사용
        this
        );
}

QString DBusReceiver::getBatteryStatus() {
    if (!batteryIface->isValid()) {
        qWarning() << "Battery D-Bus interface is invalid";
        return QString();
    }

    // Get("com.car.Battery", "Percentage") 호출
    QDBusReply<QDBusVariant> reply =
        batteryIface->call("Get", "com.car.Battery", "Percentage");

    if (reply.isValid()) {
        // QVariant로 꺼내고 int로 변환
        int percentage = reply.value().variant().toInt();
        return QString::number(percentage);
    } else {
        qWarning() << "Battery Get call failed:" << reply.error().message();
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
