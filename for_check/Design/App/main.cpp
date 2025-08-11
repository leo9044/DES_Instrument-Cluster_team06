#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtQml>  // qmlRegisterSingletonType 위해 필요
#include "caninterface.h"
#include "dbusreceiver.h"  // 추가: D-Bus 리시버 헤더
#include <QDebug>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    // QML import path 추가 (필요한 경우)
    engine.addImportPath("qrc:/");
    qDebug() << "Import path added: qrc:/";

    // Constants.qml 등록
    qmlRegisterSingletonType(QUrl(QStringLiteral("qrc:/Design/Constants.qml")),
                             "Design", 1, 0, "Constants");

    // CAN 인터페이스 생성 및 QML에 등록
    CanInterface canInterface;
    engine.rootContext()->setContextProperty("canInterface", &canInterface);

    // D-Bus 리시버 생성 및 QML에 등록
    DBusReceiver dbusReceiver;
    engine.rootContext()->setContextProperty("dbusReceiver", &dbusReceiver);
    // -> QML에서 dbusReceiver.getBatteryStatus(), dbusReceiver.getGear() 호출 가능

    // App.qml 로딩 경로
    const QUrl url(QStringLiteral("qrc:/DesignContent/App.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);

    engine.load(url);

    // CAN 연결 시도 (라즈베리파이: can0, 개발시: vcan0)
    if (canInterface.connectToCan("can0")) {
        canInterface.startReceiving();
    } else {
        qWarning() << "Failed to connect to CAN interface";
    }

    return app.exec();
}
