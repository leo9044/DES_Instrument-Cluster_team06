#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtQml>
#include <QTimer>
#include "caninterface.h"
#include "dbusreceiver.h"
#include <QDebug>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    // --- [추가] QML 엔진의 경고/에러를 직접 확인하기 위한 연결 ---
    // QML 파일에 문법 오류 등이 있을 경우, 이 부분이 자세한 정보를 출력합니다.
    QObject::connect(&engine, &QQmlApplicationEngine::warnings, [](const QList<QQmlError> &warnings) {
        for (const QQmlError &warning : warnings) {
            qWarning() << "QML Warning:" << warning.toString();
        }
    });

    engine.addImportPath("qrc:/");
    qDebug() << "Import path added: qrc:/";

    qmlRegisterSingletonType(QUrl(QStringLiteral("qrc:/Design/Constants.qml")),
                             "Design", 1, 0, "Constants");

    qDebug() << "Registering C++ objects to QML context...";
    CanInterface canInterface;
    engine.rootContext()->setContextProperty("canInterface", &canInterface);

    DBusReceiver dbusReceiver;
    engine.rootContext()->setContextProperty("dbusReceiver", &dbusReceiver);
    qDebug() << "C++ objects registered.";

    const QUrl url(QStringLiteral("qrc:/DesignContent/App.qml"));

    // --- [수정] QML 로딩 실패 시 더 명확한 에러를 확인하는 로직 ---
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [&dbusReceiver, url](QObject *obj, const QUrl &objUrl) {
                         if (url == objUrl) { // URL이 일치하는지 먼저 확인
                             if (!obj) {
                                 // obj가 null이면 로딩에 치명적인 오류가 발생한 것
                                 qCritical() << "FATAL: Failed to create QML object from" << url.toString() << ". Application will exit.";
                                 QCoreApplication::exit(-1);
                             } else {
                                 qDebug() << "QML object created successfully. Requesting initial status in 2 seconds.";
                                 QTimer::singleShot(2000, &dbusReceiver, &DBusReceiver::requestInitialStatus);
                             }
                         }
                     }, Qt::QueuedConnection);

    qDebug() << "Loading QML file:" << url.toString();
    engine.load(url);

    // --- [추가] 로딩 후 루트 객체가 비어있는지 확인 ---
    // 이 부분이 실패하면, qrc 리소스 경로가 잘못되었을 가능성이 높습니다.
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "FATAL: No root objects were created from QML. Check QML file path and content in your .qrc file.";
        return -1;
    }

    qDebug() << "Connecting to CAN interface...";
    if (canInterface.connectToCan("can0")) {
        canInterface.startReceiving();
        qDebug() << "CAN receiving started.";
    } else {
        qWarning() << "Failed to connect to CAN interface";
    }

    return app.exec();
}
