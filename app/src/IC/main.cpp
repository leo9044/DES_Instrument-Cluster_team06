#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "caninterface.h"    // ← 추가

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // CanInterface 객체 생성
    CanInterface canInterface;

    QQmlApplicationEngine engine;

    // QML에 C++ 객체 노출
    engine.rootContext()->setContextProperty("canInterface", &canInterface);

    // QML 로드 (qrc 리소스에서)
    engine.load(QUrl("qrc:/main.qml"));

    return app.exec();
}
