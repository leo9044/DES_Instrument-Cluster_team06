#include "dbusreceiver.h"
#include <QDebug>
#include <QDBusReply>
#include <QtMath>

DBusReceiver::DBusReceiver(QObject *parent)
    : QObject(parent),
    m_gear("P"),
    m_batteryPercentage(0),
    m_current(0.0)
{
    // ===== Battery DBus Interface Setup =====
    batteryIface = new QDBusInterface(
        "com.car.Battery",
        "/com/car/Battery",
        "com.car.Battery",
        QDBusConnection::sessionBus(),
        this
        );

    if (!batteryIface->isValid()) {
        qWarning() << "Battery D-Bus interface is invalid:" << batteryIface->lastError().message();
    } else {
        qDebug() << "Battery D-Bus interface is valid.";
        // [추가] 배터리 상태 변경 신호(Signal)에 연결
        QDBusConnection::sessionBus().connect(
            "com.car.Battery", "/com/car/Battery", "com.car.Battery",
            "batteryStatusChanged", // 서버에서 보낼 신호 이름
            this, SLOT(onBatteryStatusChanged(int, double))
            );
    }

    // ===== Vehicle Controller DBus Interface (Gear related) =====
    vehicleIface = new QDBusInterface(
        "org.piracer.VehicleController",
        "/org.piracer.VehicleController",
        "org.piracer.VehicleInterface",
        QDBusConnection::sessionBus(),
        this
        );
    // ... (기존 기어 관련 코드는 동일)
}

// [수정] D-Bus 서버에서 보내주는 신호를 받아 처리하는 슬롯
void DBusReceiver::onBatteryStatusChanged(int percentage, double current)
{
    qDebug() << "Received batteryStatusChanged signal:" << percentage << "%," << current << "A";

    if (m_batteryPercentage != percentage) {
        m_batteryPercentage = percentage;
        emit batteryChanged();
    }

    // Use a small tolerance for double comparison
    if (qAbs(m_current - current) > 0.001) {
        m_current = current;
        emit currentChanged();
    }
}

// [수정] 함수 이름을 requestInitialStatus로 변경
void DBusReceiver::requestInitialStatus() {
    if (!batteryIface->isValid()) {
        qWarning() << "Battery D-Bus interface is invalid. Cannot request initial status.";
        return;
    }

    // --- 1. Get Voltage and Calculate Percentage ---
    QDBusReply<double> voltageReply = batteryIface->call("GetVoltage");
    if (voltageReply.isValid()) {
        // ... (전압/전류 계산 로직은 기존과 동일)
    }

    // --- 2. Get Current ---
    QDBusReply<double> currentReply = batteryIface->call("GetCurrent");
    if (currentReply.isValid()) {
        // ... (전압/전류 계산 로직은 기존과 동일)
    }
}

// ... (getGear, onGearChanged 등 나머지 코드는 기존과 동일)
