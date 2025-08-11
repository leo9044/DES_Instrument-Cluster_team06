#include "dbusreceiver.h"
#include <QDebug>
#include <QDBusReply>
// QDBusVariant는 배터리 Get 구현에서만 사용했으므로 제거(주석 처리)
// #include <QDBusVariant>

DBusReceiver::DBusReceiver(QObject *parent) : QObject(parent), m_gear("P") {
    // ===== 배터리 DBus 인터페이스 생성 (비활성화) =====
    /*
    batteryIface = new QDBusInterface(
        "com.car.Battery",
        "/com/car/Battery",
        "org.freedesktop.DBus.Properties",
        QDBusConnection::systemBus(),
        this
    );
    qDebug() << "Battery iface valid?" << (batteryIface->isValid() ? "yes":"no");
    if (!batteryIface->isValid()) {
        qWarning() << "Battery D-Bus interface is invalid:" << batteryIface->lastError().message();
    }
    */

    // ===== Vehicle Controller DBus Interface (기어 관련) =====
    vehicleIface = new QDBusInterface(
        "org.piracer.VehicleController",
        "/org/piracer/VehicleController",
        "org.piracer.VehicleInterface",
        QDBusConnection::sessionBus(),
        this
        );

    qDebug() << "Vehicle iface valid?" << (vehicleIface->isValid() ? "yes":"no");
    if (!vehicleIface->isValid()) {
        qWarning() << "Vehicle D-Bus interface is invalid:" << vehicleIface->lastError().message();
        // 주의: 서비스가 아직 등록되지 않았을 경우가 있으므로,
        // 필요하면 NameOwnerChanged 방식으로 재시도 로직을 추가할 수 있음.
    }

    // --- 기어 변경 DBus Signal 연결 ---
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
    } else {
        qDebug() << "Connected to gearChanged signal.";
    }

    // 초기 기어값 요청 (옵션)
    getGear();
}

/* 배터리 관련 함수는 주석 처리 (나중에 다시 사용 시 주석 해제)
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
*/

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

// --- 신호 슬롯 구현 ---
void DBusReceiver::onGearChanged(const QString &newGear) {
    if (m_gear != newGear) {
        m_gear = newGear;
        emit gearChanged();  // QML 쪽에 시그널 방출
        qDebug() << "Gear changed signal received:" << newGear;
    }
}
