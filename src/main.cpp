#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QAbstractVideoSurface>
#include <QDebug>
#include <QFontDatabase>

#include "constants.h"

#include "openhdvideostream.h"
#include "openhdtelemetry.h"
#include "openhdrc.h"
#include "openhdsettings.h"
#include "openhdpi.h"
#include "mavlinktelemetry.h"
#include "localmessage.h"

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
#endif

#if defined(ENABLE_VIDEO)
#if defined(__ios__) || defined(__android__)
    initializeVideoStreaming(argc, argv, nullptr, nullptr);
#else
    // Initialize Video Streaming
    char gstLogLevel[] = "*:0";
    char gstLogPath[] = "/dev/null";
    initializeVideoStreaming(argc, argv, gstLogPath, gstLogLevel);
#endif
#endif


    QFontDatabase::addApplicationFont(":/Font Awesome 5 Free-Solid-900.otf");
    //QFontDatabase::addApplicationFont(":/Font Awesome 5 Free-Regular-400.otf");
    //QFontDatabase::addApplicationFont(":/Font Awesome 5 Brands-Regular-400.otf");

    QFontDatabase::addApplicationFont(":/materialdesignicons-webfont.ttf");
    qmlRegisterSingletonType<OpenHDTelemetry>("OpenHD", 1, 0, "OpenHDTelemetry", openHDTelemetrySingletonProvider);
    qmlRegisterSingletonType<MavlinkTelemetry>("OpenHD", 1, 0, "MavlinkTelemetry", mavlinkTelemetrySingletonProvider);
    qmlRegisterSingletonType<OpenHDRC>("OpenHD", 1, 0, "OpenHDRC", openHDRCSingletonProvider);
    qmlRegisterSingletonType<OpenHDPi>("OpenHD", 1, 0, "OpenHDPi", openHDPiSingletonProvider);
    qmlRegisterSingletonType<LocalMessage>("OpenHD", 1, 0, "LocalMessage", localMessageSingletonProvider);

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

    engine.load(QUrl(QLatin1String("qrc:/main.qml")));
    return app.exec();
}
