#include "dbusreceiver.h"
#include <QDebug>
#include <QDBusReply>
#include <QDBusVariant>

DBusReceiver::DBusReceiver(QObject *parent) : QObject(parent), m_gear("P") {
    // Battery DBus Interface (기존)
    batteryIface = new QDBusInterface(
        "com.car.Battery",
        "/com/car/Battery",
        "org.freedesktop.DBus.Properties",
        QDBusConnection::systemBus(),
        this
    );

    // Vehicle Controller DBus Interface (기존)
    vehicleIface = new QDBusInterface(
        "org.piracer.VehicleController",
        "/org/piracer/VehicleController",
        "org.piracer.VehicleInterface",
        QDBusConnection::sessionBus(),
        this
    );

    // --- 수정: 기어 변경 DBus Signal 연결 ---
    bool connected = QDBusConnection::sessionBus().connect(
        "org.piracer.VehicleController",      // 서비스 이름
        "/org/piracer/VehicleController",     // 오브젝트 경로
        "org.piracer.VehicleInterface",       // 인터페이스 이름
        "gearChanged",                        // 신호 이름
        this,
        SLOT(onGearChanged(QString))
    );

    if (!connected) {
        qWarning() << "Failed to connect to gearChanged signal.";
    }

    // 초기 기어값 요청 (옵션)
    getGear();
}

QString DBusReceiver::getBatteryStatus() {
    if (!batteryIface->isValid()) {
        qWarning() << "Battery D-Bus interface is invalid";
        return QString();
    }

    QDBusReply<QDBusVariant> reply =
        batteryIface->call("Get", "com.car.Battery", "Percentage");

    if (reply.isValid()) {
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
        onGearChanged(reply.value());  // 값 받으면 내부 처리 (emit 신호 포함)
        return reply.value();
    } else {
        qWarning() << "Vehicle GetGear call failed:" << reply.error().message();
        return QString();
    }
}

// --- 수정: 신호 슬롯 구현 ---
void DBusReceiver::onGearChanged(const QString &newGear) {
    if (m_gear != newGear) {
        m_gear = newGear;
        emit gearChanged();  // QML 쪽에 시그널 방출
        qDebug() << "Gear changed signal received:" << newGear;
    }
}
