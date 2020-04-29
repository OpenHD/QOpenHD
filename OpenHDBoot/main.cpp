#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QFontDatabase>


#include "statusmicroservice.h"
#include "smartsync.h"


int main(int argc, char *argv[]) {
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QGuiApplication app(argc, argv);

    QFontDatabase::addApplicationFont(":/Font Awesome 5 Free-Solid-900.otf");

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);



    auto groundStatusMicroservice = new StatusMicroservice(nullptr, MicroserviceTargetGround, MavlinkTypeTCP);
    engine.rootContext()->setContextProperty("GroundStatusMicroservice", groundStatusMicroservice);
    groundStatusMicroservice->onStarted();

    auto airStatusMicroservice = new StatusMicroservice(nullptr, MicroserviceTargetAir, MavlinkTypeTCP);
    engine.rootContext()->setContextProperty("AirStatusMicroservice", airStatusMicroservice);
    airStatusMicroservice->onStarted();

    auto smartSync = new SmartSync(nullptr);
    engine.rootContext()->setContextProperty("SmartSync", smartSync);
    smartSync->onStarted();


    engine.load(url);

    return app.exec();
}
