#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtQml>
// #include <QTimer> // 폴링 방식의 QTimer는 더 이상 필요 없으므로 주석 처리 또는 제거
#include "caninterface.h"
#include "dbusreceiver.h"
#include <QDebug>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    // QML import path 추가
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

    // 폴링 방식의 QTimer 관련 코드는 모두 제거되었습니다.

    // App.qml 로딩 경로
    const QUrl url(QStringLiteral("qrc:/DesignContent/App.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     // 람다 함수에서 dbusReceiver를 참조할 수 있도록 캡처 목록에 추가
                     &app, [&dbusReceiver, url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1);

                         // QML 객체가 성공적으로 생성된 후, 서버에 초기 데이터 요청
                         if (obj && url == objUrl) {
                             qDebug() << "QML object created, requesting initial status.";
                             dbusReceiver.requestInitialStatus();
                         }
                     }, Qt::QueuedConnection);

    engine.load(url);

    // CAN 연결 시도
    if (canInterface.connectToCan("can0")) {
        canInterface.startReceiving();
    } else {
        qWarning() << "Failed to connect to CAN interface";
    }

    return app.exec();
}
