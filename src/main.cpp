#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QAbstractVideoSurface>
#include <QDebug>
#include <QFontDatabase>
#if defined(__android__)
#include <QtAndroidExtras/QtAndroid>
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

#if defined(ENABLE_VIDEO)
#include "VideoStreaming/VideoStreaming.h"
#include "VideoStreaming/VideoSurface.h"
#include "VideoStreaming/VideoReceiver.h"
#endif

// SDL hack
#ifdef Q_OS_WIN
    #ifdef main
        #undef main
    #endif
#endif

int main(int argc, char *argv[]) {
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication app(argc, argv);

    QCoreApplication::setOrganizationName("Open.HD");
    QCoreApplication::setOrganizationDomain("open.hd");
    QCoreApplication::setApplicationName("Open.HD");

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

#if defined(ENABLE_VIDEO)
    qDebug() << "Initializing video";
#if defined(__ios__) || defined(__android__)
    initializeVideoStreaming(argc, argv, nullptr, nullptr);
#else
    // Initialize Video Streaming
    char gstLogLevel[] = "*:0";
    char gstLogPath[] = "/dev/null";
    initializeVideoStreaming(argc, argv, gstLogPath, gstLogLevel);
#endif
#endif

    /*qDebug() << "Checking codecs...";

    GList *l;
    GList *elements = gst_element_factory_list_get_elements(GST_ELEMENT_FACTORY_TYPE_ANY, GST_RANK_NONE);
    for (l = elements; l; l = l->next) {
      auto f = l->data;
      qDebug() << "factory: %s" << GST_OBJECT_NAME(f);
    }
    qDebug() << "... done checking codecs";*/

    QFontDatabase::addApplicationFont(":/Font Awesome 5 Free-Solid-900.otf");
    //QFontDatabase::addApplicationFont(":/Font Awesome 5 Free-Regular-400.otf");
    //QFontDatabase::addApplicationFont(":/Font Awesome 5 Brands-Regular-400.otf");

    QFontDatabase::addApplicationFont(":/materialdesignicons-webfont.ttf");
    qmlRegisterType<OpenHDTelemetry>("OpenHD", 1, 0, "OpenHDTelemetry");
    qmlRegisterType<MavlinkTelemetry>("OpenHD", 1, 0, "MavlinkTelemetry");
    qmlRegisterType<FrSkyTelemetry>("OpenHD", 1, 0, "FrSkyTelemetry");
    qmlRegisterType<MSPTelemetry>("OpenHD", 1, 0, "MSPTelemetry");

    qmlRegisterSingletonType<OpenHDRC>("OpenHD", 1, 0, "OpenHDRC", openHDRCSingletonProvider);
    qmlRegisterSingletonType<OpenHDPi>("OpenHD", 1, 0, "OpenHDPi", openHDPiSingletonProvider);
    qmlRegisterSingletonType<LocalMessage>("OpenHD", 1, 0, "LocalMessage", localMessageSingletonProvider);
    qmlRegisterSingletonType<OpenHD>("OpenHD", 1, 0, "OpenHD", openHDSingletonProvider);

    qmlRegisterType<OpenHDSettings>("OpenHD", 1,0, "OpenHDSettings");
    qmlRegisterType<OpenHDVideoStream>("OpenHD", 1,0, "OpenHDVideoStream");



    QQmlApplicationEngine engine;
#if defined(ENABLE_VIDEO)
    engine.rootContext()->setContextProperty("EnableVideo", QVariant(true));
#else
    engine.rootContext()->setContextProperty("EnableVideo", QVariant(false));
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

    engine.rootContext()->setContextProperty("QOPENHD_VERSION", QVariant(QOPENHD_VERSION));

    engine.load(QUrl(QLatin1String("qrc:/main.qml")));

#if defined(__android__)
    QtAndroid::hideSplashScreen();
#endif

    qDebug() << "Running QML";

    return app.exec();
}
