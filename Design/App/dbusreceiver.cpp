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
    // ===== Battery DBus Interface Setup (Hybrid Style) =====
    batteryIface = new QDBusInterface(
        "com.car.Battery", "/com/car/Battery", "com.car.Battery",
        QDBusConnection::sessionBus(), this
        );

    if (!batteryIface->isValid()) {
        qWarning() << "Battery D-Bus interface is invalid:" << batteryIface->lastError().message();
    } else {
        qDebug() << "Battery D--Bus interface is valid.";
        // 신호 연결 성공 여부를 확인하는 코드 추가
        bool chargingConnected = QDBusConnection::sessionBus().connect(
            "com.car.Battery", "/com/car/Battery", "com.car.Battery",
            "chargingStatusChanged", this, SLOT(onChargingStatusChanged(double))
            );
        bool percentageConnected = QDBusConnection::sessionBus().connect(
            "com.car.Battery", "/com/car/Battery", "com.car.Battery",
            "percentageChanged", this, SLOT(onPercentageChanged(int))
            );

        if (chargingConnected && percentageConnected) {
            qDebug() << "Successfully connected to battery signals.";
        } else {
            qWarning() << "Failed to connect to one or more battery signals.";
            qWarning() << "Charging Status Signal Connected:" << chargingConnected;
            qWarning() << "Percentage Signal Connected:" << percentageConnected;
        }
    }

    // ===== Vehicle Controller DBus Interface (Gear related) =====
    vehicleIface = new QDBusInterface(
        "org.piracer.VehicleController", "/org/piracer/VehicleController", "org.piracer.VehicleInterface",
        QDBusConnection::sessionBus(), this
        );
    if (!vehicleIface->isValid()) {
        qWarning() << "Vehicle D-Bus interface is invalid:" << vehicleIface->lastError().message();
    } else {
        qDebug() << "Vehicle iface valid? yes";
    }

    // --- 기어 변경 DBus Signal 연결 ---
    bool gearConnected = QDBusConnection::sessionBus().connect(
        "org.piracer.VehicleController", "/org/piracer/VehicleController", "org.piracer.VehicleInterface",
        "gearChanged", this, SLOT(onGearChanged(QString))
        );

    if (!gearConnected) {
        qWarning() << "Failed to connect to gearChanged signal.";
    } else {
        qDebug() << "Connected to gearChanged signal.";
    }

    // 초기 기어값 요청
    getGear();
}

// 앱 시작 시 초기값을 가져오는 함수
void DBusReceiver::requestInitialStatus() {
    if (!batteryIface->isValid()) {
        qWarning() << "[Initial Request] Cannot request status: Battery D-Bus interface is invalid.";
        return;
    }
    qDebug() << "[Initial Request] Requesting initial battery status from server...";

    // 1. 초기 배터리 잔량 요청 및 처리
    QDBusReply<double> voltageReply = batteryIface->call("GetVoltage");
    if (voltageReply.isValid()) {
        double voltage = voltageReply.value();
        // [추가] 수신된 전압 값을 로그로 출력
        qDebug() << "[Initial Request] Voltage received:" << voltage << "V";

        const double MIN_VOLTAGE = 6.0;
        const double MAX_VOLTAGE = 8.4;
        double percentage = ((voltage - MIN_VOLTAGE) / (MAX_VOLTAGE - MIN_VOLTAGE)) * 100.0;
        int newPercentage = qBound(0, static_cast<int>(percentage), 100);

        if (m_batteryPercentage != newPercentage) {
            m_batteryPercentage = newPercentage;
            emit batteryChanged();
            qDebug() << "[Initial Request] Battery percentage set to:" << newPercentage << "%";
        }
    } else {
        // [수정] 오류 메시지를 더 명확하게 표시
        qWarning() << "[Initial Request] GetVoltage call FAILED:" << voltageReply.error().message();
    }

    // 2. 초기 전류(충전 상태) 요청 및 처리
    QDBusReply<double> currentReply = batteryIface->call("GetCurrent");
    if (currentReply.isValid()) {
        double newCurrent = currentReply.value();
        // [추가] 수신된 전류 값을 로그로 출력
        qDebug() << "[Initial Request] Current received:" << newCurrent << "A";

        if (qAbs(m_current - newCurrent) > 0.001) {
            m_current = newCurrent;
            emit currentChanged();
            qDebug() << "[Initial Request] Current set to:" << newCurrent << "A";
        }
    } else {
        // [수정] 오류 메시지를 더 명확하게 표시
        qWarning() << "[Initial Request] GetCurrent call FAILED:" << currentReply.error().message();
    }
}

// 충전 상태 변경 신호를 처리하는 슬롯
void DBusReceiver::onChargingStatusChanged(double newCurrent)
{
    qDebug() << "Signal received: Charging status changed. Current:" << newCurrent << "A";
    if (qAbs(m_current - newCurrent) > 0.001) {
        m_current = newCurrent;
        emit currentChanged();
    }
}

// 주기적인 배터리 잔량 신호를 처리하는 슬롯
void DBusReceiver::onPercentageChanged(int newPercentage)
{
    qDebug() << "Signal received: Percentage changed. Percentage:" << newPercentage << "%";
    if (m_batteryPercentage != newPercentage) {
        m_batteryPercentage = newPercentage;
        emit batteryChanged();
    }
}

// 현재 기어값을 가져오는 함수
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

// D-Bus 신호를 통해 기어 변경을 처리하는 슬롯
void DBusReceiver::onGearChanged(const QString &newGear) {
    if (m_gear != newGear) {
        m_gear = newGear;
        emit gearChanged();
        qDebug() << "Gear changed signal received:" << newGear;
    }
}
