#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QDebug>
#include <QFontDatabase>
#if defined(__android__)
#include <QtAndroidExtras/QtAndroid>
const QVector<QString> permissions({"android.permission.INTERNET",
                                    "android.permission.WRITE_EXTERNAL_STORAGE",
                                    "android.permission.READ_EXTERNAL_STORAGE",

                                    "android.permission.ACCESS_NETWORK_STATE",
                                    "android.permission.ACCESS_FINE_LOCATION"});
#endif

#include "constants.h"

#include "openhdvideostream.h"
#include "openhdtelemetry.h"
#include "openhdrc.h"
#include "openhdsettings.h"
#include "openhdpi.h"
#include "openhd.h"
#include "mavlinktelemetry.h"
#include "localmessage.h"
#include "frskytelemetry.h"
#include "msptelemetry.h"
#include "ltmtelemetry.h"

#include "qopenhdlink.h"

#include "openhdpower.h"

#include "util.h"

#if defined(ENABLE_MAIN_VIDEO) || defined(ENABLE_PIP)
#include <gst/gst.h>
#endif

// SDL hack
#ifdef Q_OS_WIN
    #ifdef main
        #undef main
    #endif
#endif


int main(int argc, char *argv[]) {
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QApplication app(argc, argv);

    QCoreApplication::setOrganizationName("Open.HD");
    QCoreApplication::setOrganizationDomain("open.hd");
    QCoreApplication::setApplicationName("Open.HD");

#if defined(__android__)
    keep_screen_on(true);

    for(const QString &permission : permissions) {
        auto result = QtAndroid::checkPermission(permission);

        if (result == QtAndroid::PermissionResult::Denied) {
            auto resultHash = QtAndroid::requestPermissionsSync(QStringList({permission}));
            if (resultHash[permission] == QtAndroid::PermissionResult::Denied) {
                return 0;
            }
        }
    }
#endif

#if defined(__rasp_pi__)
    qDebug() << "Initializing Pi";
    OpenHDPi pi;
    if (pi.is_raspberry_pi()) {
        // no way around this for the moment due to the way Settings works, hopefully won't
        // be needed forever though
        pi.set_mount_rw();

        // ensure the local message fifo exists before we continue
        QString program("/usr/bin/mkfifo");
        QStringList arguments;
        arguments << MESSAGE_FIFO;
        QProcess p;
        p.start(program, arguments);
        p.waitForFinished();
    }


    QSettings settings;
    // set persistent brightness level at startup
    if (pi.is_raspberry_pi()) {
        auto brightness = settings.value("brightness", 100).toInt();
        pi.set_brightness(brightness);
    }
    qDebug() << "Finished initializing Pi";
#endif

    QFontDatabase::addApplicationFont(":/Font Awesome 5 Free-Solid-900.otf");
    //QFontDatabase::addApplicationFont(":/Font Awesome 5 Free-Regular-400.otf");
    //QFontDatabase::addApplicationFont(":/Font Awesome 5 Brands-Regular-400.otf");

    QFontDatabase::addApplicationFont(":/osdicons.ttf");

    QFontDatabase::addApplicationFont(":/materialdesignicons-webfont.ttf");
    qmlRegisterType<MavlinkTelemetry>("OpenHD", 1, 0, "MavlinkTelemetry");
    qmlRegisterType<FrSkyTelemetry>("OpenHD", 1, 0, "FrSkyTelemetry");
    qmlRegisterType<MSPTelemetry>("OpenHD", 1, 0, "MSPTelemetry");
    qmlRegisterType<LTMTelemetry>("OpenHD", 1, 0, "LTMTelemetry");
    qmlRegisterType<OpenHDRC>("OpenHD", 1, 0, "OpenHDRC");

    qmlRegisterSingletonType<OpenHDPi>("OpenHD", 1, 0, "OpenHDPi", openHDPiSingletonProvider);
    qmlRegisterSingletonType<LocalMessage>("OpenHD", 1, 0, "LocalMessage", localMessageSingletonProvider);

    qmlRegisterType<OpenHDSettings>("OpenHD", 1,0, "OpenHDSettings");

    qmlRegisterType<QOpenHDLink>("OpenHD", 1,0, "QOpenHDLink");

    auto openhd = OpenHD::instance();

    auto openhdpower = OpenHDPower::instance();

    QTimer timer;
    QObject::connect(&timer, &QTimer::timeout, openhd, &OpenHD::updateFlightTimer);
    timer.start(1000);

#if defined(ENABLE_MAIN_VIDEO)
    OpenHDVideoStream* stream = new OpenHDVideoStream(argc, argv);
#endif
#if defined(ENABLE_PIP)
    OpenHDVideoStream* stream2 = new OpenHDVideoStream(argc, argv);
#endif


    QQmlApplicationEngine engine;

    auto openhdTelemetry = new OpenHDTelemetry;
    engine.rootContext()->setContextProperty("OpenHDTelemetry", openhdTelemetry);
    QThread *telemetryThread = new QThread();
    QObject::connect(telemetryThread, &QThread::started, openhdTelemetry, &OpenHDTelemetry::onStarted);
    openhdTelemetry->moveToThread(telemetryThread);
    telemetryThread->start();


    engine.rootContext()->setContextProperty("OpenHD", openhd);

    engine.rootContext()->setContextProperty("OpenHDPower", openhdpower);

#if defined(ENABLE_MAIN_VIDEO)
    engine.rootContext()->setContextProperty("EnableMainVideo", QVariant(true));
    engine.rootContext()->setContextProperty("MainStream", stream);
#else
    engine.rootContext()->setContextProperty("EnableMainVideo", QVariant(false));
#endif

#if defined(ENABLE_PIP)
    engine.rootContext()->setContextProperty("EnablePiP", QVariant(true));
    engine.rootContext()->setContextProperty("PiPStream", stream2);
#else
    engine.rootContext()->setContextProperty("EnablePiP", QVariant(false));
#endif


#if defined(ENABLE_RC)
    engine.rootContext()->setContextProperty("EnableRC", QVariant(true));
#else
    engine.rootContext()->setContextProperty("EnableRC", QVariant(false));
#endif

#if defined(__ios__) || defined(__android__)
    engine.rootContext()->setContextProperty("UseFullscreen", QVariant(true));
#else
    engine.rootContext()->setContextProperty("UseFullscreen", QVariant(false));
#endif

#if defined(ENABLE_LINK)
    engine.rootContext()->setContextProperty("EnableLink", QVariant(true));
#else
    engine.rootContext()->setContextProperty("EnableLink", QVariant(false));
#endif

    engine.rootContext()->setContextProperty("QOPENHD_VERSION", QVariant(QOPENHD_VERSION));

    engine.rootContext()->setContextProperty("OPENHD_VERSION", QVariant(OPENHD_VERSION));
    engine.rootContext()->setContextProperty("BUILDER_VERSION", QVariant(BUILDER_VERSION));

    engine.load(QUrl(QLatin1String("qrc:/main.qml")));

#if defined(__android__)
    QtAndroid::hideSplashScreen();
#endif

    qDebug() << "Running QML";

#if defined(ENABLE_MAIN_VIDEO)
    stream->init(&engine, StreamTypeMain);
    stream->startVideo();
#endif
#if defined(ENABLE_PIP)
    stream2->init(&engine, StreamTypePiP);
    stream2->startVideo();
#endif

    const int retval = app.exec();
#if defined(ENABLE_MAIN_VIDEO)
    stream->stopVideo();
#endif

#if defined(ENABLE_PIP)
    stream2->stopVideo();
#endif
    return retval;
}
