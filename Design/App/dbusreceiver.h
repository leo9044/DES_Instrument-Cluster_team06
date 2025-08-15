#ifndef DBUSRECEIVER_H
#define DBUSRECEIVER_H

#include <QObject>
#include <QDBusInterface>

class DBusReceiver : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString gear READ gear NOTIFY gearChanged)
    Q_PROPERTY(int batteryPercentage READ batteryPercentage NOTIFY batteryChanged)
    Q_PROPERTY(double current READ current NOTIFY currentChanged)

public:
    explicit DBusReceiver(QObject *parent = nullptr);

    // QML/main.cpp에서 초기 상태를 요청하는 함수
    Q_INVOKABLE void requestInitialStatus();

    // 초기 기어값을 요청하는 함수
    QString getGear();

    // QML 프로퍼티를 위한 Getter 함수들
    QString gear() const { return m_gear; }
    int batteryPercentage() const { return m_batteryPercentage; }
    double current() const { return m_current; }

signals:
    void gearChanged();
    void batteryChanged();
    void currentChanged();

private slots:
    // 기어 변경 신호를 처리하는 슬롯
    void onGearChanged(const QString &newGear);
    // [수정] 충전 상태 변경 신호를 처리하는 슬롯
    void onChargingStatusChanged(double newCurrent);
    // [추가] 주기적인 배터리 잔량 신호를 처리하는 슬롯
    void onPercentageChanged(int newPercentage);

private:
    // D-Bus 인터페이스
    QDBusInterface *vehicleIface;
    QDBusInterface *batteryIface;

    // 멤버 변수
    QString m_gear;
    int m_batteryPercentage;
    double m_current;
};

#endif // DBUSRECEIVER_H
