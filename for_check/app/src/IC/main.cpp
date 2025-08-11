#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "caninterface.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // CAN 인터페이스 생성
    CanInterface canInterface;

    QQmlApplicationEngine engine;

    // QML에서 CAN 인터페이스 사용할 수 있도록 등록
    engine.rootContext()->setContextProperty("canInterface", &canInterface);

    // QML 파일 로드
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);

    engine.load(url);

    // CAN 연결 시도 (라즈베리파이에서는 can0, 개발 시에는 vcan0)
    if (canInterface.connectToCan("can0")) {
        canInterface.startReceiving();
    }

    return app.exec();
}
