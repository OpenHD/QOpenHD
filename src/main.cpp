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



#if defined(ENABLE_GSTREAMER)

#include "openhdvideostream.h"

#endif

#if defined(ENABLE_VIDEO_RENDER)
#include "openhdvideo.h"
#if defined(__android__)
#include "openhdandroidvideo.h"
#include "openhdandroidrender.h"
#endif

#endif

#include "util.h"

#if defined(ENABLE_GSTREAMER)
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
    qmlRegisterType<FrSkyTelemetry>("OpenHD", 1, 0, "FrSkyTelemetry");
    qmlRegisterType<MSPTelemetry>("OpenHD", 1, 0, "MSPTelemetry");
    qmlRegisterType<LTMTelemetry>("OpenHD", 1, 0, "LTMTelemetry");
    qmlRegisterType<OpenHDRC>("OpenHD", 1, 0, "OpenHDRC");

    qmlRegisterSingletonType<OpenHDPi>("OpenHD", 1, 0, "OpenHDPi", openHDPiSingletonProvider);
    qmlRegisterSingletonType<LocalMessage>("OpenHD", 1, 0, "LocalMessage", localMessageSingletonProvider);

    qmlRegisterType<OpenHDSettings>("OpenHD", 1,0, "OpenHDSettings");

    qmlRegisterType<QOpenHDLink>("OpenHD", 1,0, "QOpenHDLink");


#if defined(ENABLE_VIDEO_RENDER)
#if defined(__android__)
    qmlRegisterType<OpenHDAndroidVideo>("OpenHD", 1, 0, "OpenHDAndroidVideo");
    qmlRegisterType<OpenHDAndroidRender>("OpenHD", 1, 0, "OpenHDAndroidRender");
#endif
#endif

    QQmlApplicationEngine engine;

#if defined(__android__)
    engine.rootContext()->setContextProperty("IsAndroid", QVariant(true));
#else
    engine.rootContext()->setContextProperty("IsAndroid", QVariant(false));
#endif

#if defined(__ios__)
    engine.rootContext()->setContextProperty("IsiOS", QVariant(true));
#else
    engine.rootContext()->setContextProperty("IsiOS", QVariant(false));
#endif

#if defined(__windows__)
    engine.rootContext()->setContextProperty("IsWindows", QVariant(true));
#else
    engine.rootContext()->setContextProperty("IsWindows", QVariant(false));
#endif

#if defined(__desktoplinux__)
    engine.rootContext()->setContextProperty("IsDesktopLinux", QVariant(true));
#else
    engine.rootContext()->setContextProperty("IsDesktopLinux", QVariant(false));
#endif

#if defined(__macos__)
    engine.rootContext()->setContextProperty("IsMac", QVariant(true));
#else
    engine.rootContext()->setContextProperty("IsMac", QVariant(false));
#endif

#if defined(__rasp_pi__)
    engine.rootContext()->setContextProperty("IsRaspPi", QVariant(true));
#else
    engine.rootContext()->setContextProperty("IsRaspPi", QVariant(false));
#endif

    auto openhd = OpenHD::instance();

    auto openhdpower = OpenHDPower::instance();

#if defined(ENABLE_GSTREAMER)
engine.rootContext()->setContextProperty("EnableGStreamer", QVariant(true));
engine.rootContext()->setContextProperty("EnableVideoRender", QVariant(false));
#if defined(ENABLE_MAIN_VIDEO)
    OpenHDVideoStream* mainVideo = new OpenHDVideoStream(argc, argv);
#endif
#if defined(ENABLE_PIP)
    OpenHDVideoStream* pipVideo = new OpenHDVideoStream(argc, argv);
#endif
#endif

#if defined(ENABLE_VIDEO_RENDER)
engine.rootContext()->setContextProperty("EnableGStreamer", QVariant(false));
engine.rootContext()->setContextProperty("EnableVideoRender", QVariant(true));

#if defined(__android__)
#if defined(ENABLE_MAIN_VIDEO)
OpenHDAndroidVideo *mainVideo = new OpenHDAndroidVideo(OpenHDStreamTypeMain);
#endif
#if defined(ENABLE_PIP)
OpenHDAndroidVideo *pipVideo = new OpenHDAndroidVideo(OpenHDStreamTypePiP);
#endif
#endif
#endif


    auto mavlinkTelemetry = MavlinkTelemetry::instance();
    engine.rootContext()->setContextProperty("MavlinkTelemetry", mavlinkTelemetry);
    QThread *mavlinkThread = new QThread();
    QObject::connect(mavlinkThread, &QThread::started, mavlinkTelemetry, &MavlinkTelemetry::onStarted);
    mavlinkTelemetry->moveToThread(mavlinkThread);
    mavlinkThread->start();


    auto openhdTelemetry = OpenHDTelemetry::instance();
    engine.rootContext()->setContextProperty("OpenHDTelemetry", openhdTelemetry);
    QThread *telemetryThread = new QThread();
    QObject::connect(telemetryThread, &QThread::started, openhdTelemetry, &OpenHDTelemetry::onStarted);
    openhdTelemetry->moveToThread(telemetryThread);
    telemetryThread->start();


    engine.rootContext()->setContextProperty("OpenHD", openhd);

    engine.rootContext()->setContextProperty("OpenHDPower", openhdpower);

#if defined(ENABLE_MAIN_VIDEO)
    engine.rootContext()->setContextProperty("EnableMainVideo", QVariant(true));
    engine.rootContext()->setContextProperty("MainStream", mainVideo);
#else
    engine.rootContext()->setContextProperty("EnableMainVideo", QVariant(false));
#endif

#if defined(ENABLE_PIP)
    engine.rootContext()->setContextProperty("EnablePiP", QVariant(true));
    engine.rootContext()->setContextProperty("PiPStream", pipVideo);
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

#if defined(ENABLE_GSTREAMER)
#if defined(ENABLE_MAIN_VIDEO)
    mainVideo->init(&engine, StreamTypeMain);
    mainVideo->startVideo();
#endif
#if defined(ENABLE_PIP)
    pipVideo->init(&engine, StreamTypePiP);
    pipVideo->startVideo();
#endif
#endif

#if defined(ENABLE_VIDEO_RENDER)
    auto rootObjects = engine.rootObjects();
    QQuickWindow *rootObject = static_cast<QQuickWindow *>(rootObjects.first());
    QThread *mainVideoThread = new QThread();
    QThread *pipVideoThread = new QThread();


#if defined(__android__)
    QQuickItem *mainRenderer = rootObject->findChild<QQuickItem *>("mainAndroidSurface");
    mainVideo->setVideoOut((OpenHDAndroidRender*)mainRenderer);
    QObject::connect(mainVideoThread, &QThread::started, mainVideo, &OpenHDAndroidVideo::onStarted);

    QQuickItem *pipRenderer = rootObject->findChild<QQuickItem *>("pipAndroidSurface");
    pipVideo->setVideoOut((OpenHDAndroidRender*)pipRenderer);
    QObject::connect(pipVideoThread, &QThread::started, pipVideo, &OpenHDAndroidVideo::onStarted);
#endif

    mainVideo->moveToThread(mainVideoThread);
    pipVideo->moveToThread(pipVideoThread);

    mainVideoThread->start();
    pipVideoThread->start();

#endif

    const int retval = app.exec();

#if defined(ENABLE_GSTREAMER)
#if defined(ENABLE_MAIN_VIDEO)
    mainVideo->stopVideo();
#endif
#if defined(ENABLE_PIP)
    pipVideo->stopVideo();
#endif
#endif
    return retval;
}
