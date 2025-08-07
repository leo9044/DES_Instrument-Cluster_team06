#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QApplication>
#include <QQmlContext>
#include <QQmlEngine>
#include <QtQml>  // 이게 있어야 qmlRegisterSingletonType 사용 가능

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

    // App.qml 로딩
    const QUrl url(QStringLiteral("qrc:/DesignContent/App.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
