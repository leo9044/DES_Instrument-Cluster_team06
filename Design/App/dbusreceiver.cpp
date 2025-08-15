#include "dbusreceiver.h"
#include <QDebug>
#include <QDBusReply>
#include <QDBusArgument>
#include <QtMath>

DBusReceiver::DBusReceiver(QObject *parent)
    : QObject(parent),
    m_gear("P"),
    m_batteryPercentage(0),
    m_current(0.0)
{
    // [수정] 서비스, 경로, 인터페이스 이름을 Python 서버와 모두 일치시킴
    const QString service = "org.piracer.Battery";
    const QString path = "/org/piracer/Battery";
    const QString interface = "org.piracer.Battery";

    // ===== Battery DBus Interface Setup =====
    batteryIface = new QDBusInterface(service, path, interface, QDBusConnection::sessionBus(), this);

    if (!batteryIface->isValid()) {
        qWarning() << "Battery D-Bus interface is invalid:" << batteryIface->lastError().message();
    } else {
        qDebug() << "Battery D-Bus interface is valid.";
        bool chargingConnected = QDBusConnection::sessionBus().connect(
            service, path, interface, "chargingStatusChanged", this, SLOT(onChargingStatusChanged(double))
            );
        bool percentageConnected = QDBusConnection::sessionBus().connect(
            service, path, interface, "percentageChanged", this, SLOT(onPercentageChanged(int))
            );

        if (chargingConnected && percentageConnected) {
            qDebug() << "Successfully connected to battery signals.";
        } else {
            qWarning() << "Failed to connect to one or more battery signals.";
        }
    }

    // ===== Vehicle Controller DBus Interface (Gear related) =====
    vehicleIface = new QDBusInterface(
        "org.piracer.VehicleController", "/org/piracer/VehicleController", "org.piracer.VehicleInterface",
        QDBusConnection::sessionBus(), this
        );
    if (!vehicleIface->isValid()) {
        qWarning() << "Vehicle D-Bus interface is invalid:" << vehicleIface->lastError().message();
    }

    bool gearConnected = QDBusConnection::sessionBus().connect(
        "org.piracer.VehicleController", "/org/piracer/VehicleController", "org.piracer.VehicleInterface",
        "gearChanged", this, SLOT(onGearChanged(QString))
        );

    if (gearConnected) {
        qDebug() << "Connected to gearChanged signal.";
    }

    getGear();
}

// [수정] 서버에서 직접 계산된 초기값을 받아오는 함수
void DBusReceiver::requestInitialStatus() {
    if (!batteryIface->isValid()) {
        qWarning() << "[Initial Request] Cannot request status: Battery D-Bus interface is invalid.";
        return;
    }
    qDebug() << "[Initial Request] Requesting initial status from server...";

    // 서버의 GetInitialStatus 메소드를 호출
    QDBusMessage replyMsg = batteryIface->call("GetInitialStatus");
    QDBusReply<QDBusArgument> reply(replyMsg);

    if (reply.isValid()) {
        // [수정] D-Bus 튜플(구조체)을 올바르게 파싱하는 로직
        const QDBusArgument &arg = reply.value();
        arg.beginStructure();
        int percentage;
        double current;
        arg >> percentage >> current; // 구조체에서 값을 순서대로 읽어옴
        arg.endStructure();

        qDebug() << "[Initial Request] Received Percentage:" << percentage << "%, Current:" << current << "A";

        // 받은 값으로 GUI 업데이트
        onPercentageChanged(percentage);
        onChargingStatusChanged(current);

    } else {
        qWarning() << "[Initial Request] GetInitialStatus call FAILED:" << reply.error().message();
    }
}

void DBusReceiver::onChargingStatusChanged(double newCurrent)
{
    qDebug() << "Signal received: Charging status changed. Current:" << newCurrent << "A";
    if (qAbs(m_current - newCurrent) > 0.001) {
        m_current = newCurrent;
        emit currentChanged();
    }
}

void DBusReceiver::onPercentageChanged(int newPercentage)
{
    qDebug() << "Signal received: Percentage changed. Percentage:" << newPercentage << "%";
    if (m_batteryPercentage != newPercentage) {
        m_batteryPercentage = newPercentage;
        emit batteryChanged();
    }
}

QString DBusReceiver::getGear() {
    if (!vehicleIface->isValid()) {
        qWarning() << "Vehicle D-Bus interface is invalid";
        return QString();
    }

    QDBusReply<QString> reply = vehicleIface->call("GetGear");
    if (reply.isValid()) {
        onGearChanged(reply.value());
        return reply.value();
    } else {
        qWarning() << "Vehicle GetGear call failed:" << reply.error().message();
        return QString();
    }
}

void DBusReceiver::onGearChanged(const QString &newGear) {
    if (m_gear != newGear) {
        m_gear = newGear;
        emit gearChanged();
        qDebug() << "Gear changed signal received:" << newGear;
    }
}
