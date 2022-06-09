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

#include "rc/openhdrc.h"
#include "platform/openhdpi.h"
#include "openhd.h"
#include "../app/telemetry/mavlinktelemetry.h"
#include "util/localmessage.h"

//#if defined(ENABLE_LOG)
#include "util/logger.h"
//#endif

#include "util/statuslogmodel.h"

#if defined(ENABLE_ADSB)
#include "../app/adsb/ADSBVehicleManager.h"
#include "../app/adsb/ADSBVehicle.h"
#endif


#include "util/QmlObjectListModel.h"

#include "osd/speedladder.h"
#include "osd/altitudeladder.h"
#include "osd/headingladder.h"
#include "osd/horizonladder.h"
#include "osd/flightpathvector.h"
#include "osd/drawingcanvas.h"

#include "videostreaming/QOpenHDVideoHelper.hpp"


#if defined(ENABLE_RC)
#include "QJoysticks.h"
#endif

#if defined(__ios__)
#include "platform/appleplatform.h"
#endif

#if defined(ENABLE_GSTREAMER)

#include "videostreaming/gstvideostream.h"

#endif

#if defined(ENABLE_VIDEO_RENDER)
#include "openhdvideo.h"
#if defined(__android__)
#include "openhdandroidvideo.h"
#include "openhdrender.h"
#endif
#if defined(__rasp_pi__)
#include "openhdmmalvideo.h"
#include "openhdrender.h"
#endif
#if defined(__apple__)
#include "openhdapplevideo.h"
#include "openhdrender.h"
#endif
#endif

#include "util/util.h"

#if defined(ENABLE_GSTREAMER)
#include <gst/gst.h>
#endif

// SDL hack
#ifdef Q_OS_WIN
    #ifdef main
        #undef main
    #endif
#endif

// Load all the fonts we use ?!
static void load_fonts(){
    QFontDatabase::addApplicationFont(":/resources/Font Awesome 5 Free-Solid-900.otf");
    QFontDatabase::addApplicationFont(":/resources/osdicons.ttf");
    QFontDatabase::addApplicationFont(":/resources/materialdesignicons-webfont.ttf");
    //
    QFontDatabase::addApplicationFont(":/osdfonts/Acme-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Aldrich-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/AnonymousPro-Bold.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/AnonymousPro-BoldItalic.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Archivo-Bold.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Archivo-Medium.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Archivo-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/ArchivoBlack-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Armata-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Bangers-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/BlackOpsOne-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Bungee-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Carbon-Bold.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Chicle-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Digital7SegmentDisplay.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/DigitalDotDisplay.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/DigitalSubwayTicker.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/ExpletusSans-Bold.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/FjallaOne-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/FredokaOne-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/GeostarFill-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Iceberg-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Iceland-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Jura-Bold.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/KeaniaOne-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Larabie.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/LuckiestGuy-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Merysha-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/NixieOne-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Orbitron-Bold.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Orbitron-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Oxygen-Bold.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Oxygen-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/PassionOne-Bold.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Quantico-Bold.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Quantico-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Quicksand-Bold.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Quicksand-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/RammettoOne-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Rationale-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Righteous-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/RobotoMono-Bold.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/RobotoMono-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/RussoOne-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/ShareTech-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/ShareTechMono-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/SigmarOne-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Slackey-Regular.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/UbuntuMono-Bold.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/UbuntuMono-BoldItalic.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/Visitor.ttf");
    QFontDatabase::addApplicationFont(":/osdfonts/ZolanMonoOblique.ttf");
}


int main(int argc, char *argv[]) {
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QCoreApplication::setOrganizationName("Open.HD");
    QCoreApplication::setOrganizationDomain("open.hd");
    QCoreApplication::setApplicationName("QOpenHD");

    QSettings settings;

    double global_scale = settings.value("global_scale", 1.0).toDouble();

    std::string global_scale_s = std::to_string(global_scale);
    QByteArray scaleAsQByteArray(global_scale_s.c_str(), global_scale_s.length());
    qputenv("QT_SCALE_FACTOR", scaleAsQByteArray);

    QApplication app(argc, argv);

    auto util = new OpenHDUtil;


#if defined(__ios__)
    auto applePlatform = ApplePlatform::instance();
    applePlatform->disableScreenLock();
    applePlatform->registerNotifications();
#endif


#if defined(__android__)
    util->keep_screen_on(true);

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

    // set persistent brightness level at startup
    if (pi.is_raspberry_pi()) {
        auto brightness = settings.value("brightness", 100).toInt();
        pi.set_brightness(brightness);
    }
    qDebug() << "Finished initializing Pi";
#endif

   load_fonts();

    qmlRegisterType<OpenHDRC>("OpenHD", 1, 0, "OpenHDRC");

    qmlRegisterSingletonType<OpenHDPi>("OpenHD", 1, 0, "OpenHDPi", openHDPiSingletonProvider);
    qmlRegisterSingletonType<LocalMessage>("OpenHD", 1, 0, "LocalMessage", localMessageSingletonProvider);

    //#if defined(ENABLE_LOG)
    qmlRegisterSingletonType<Logger>("OpenHD", 1, 0, "Logger", loggerSingletonProvider);
    //#endif

    qmlRegisterUncreatableType<QmlObjectListModel>("OpenHD", 1, 0, "QmlObjectListModel", "Reference only");

    qmlRegisterType<SpeedLadder>("OpenHD", 1, 0, "SpeedLadder");

    qmlRegisterType<AltitudeLadder>("OpenHD", 1, 0, "AltitudeLadder");

    qmlRegisterType<HeadingLadder>("OpenHD", 1, 0, "HeadingLadder");

    qmlRegisterType<HorizonLadder>("OpenHD", 1, 0, "HorizonLadder");

    qmlRegisterType<FlightPathVector>("OpenHD", 1, 0, "FlightPathVector");

    qmlRegisterType<DrawingCanvas>("OpenHD", 1, 0, "DrawingCanvas");

#if defined(ENABLE_VIDEO_RENDER)
#if defined(__android__)
    qmlRegisterType<OpenHDAndroidVideo>("OpenHD", 1, 0, "OpenHDAndroidVideo");
    qmlRegisterType<OpenHDRender>("OpenHD", 1, 0, "OpenHDRender");
#endif
#if defined(__rasp_pi__)
    qmlRegisterType<OpenHDMMALVideo>("OpenHD", 1, 0, "OpenHDMMALVideo");
    qmlRegisterType<OpenHDRender>("OpenHD", 1, 0, "OpenHDRender");
#endif
#if defined(__apple__)
    qmlRegisterType<OpenHDAppleVideo>("OpenHD", 1, 0, "OpenHDAppleVideo");
    qmlRegisterType<OpenHDRender>("OpenHD", 1, 0, "OpenHDRender");
#endif
#endif

    QQmlApplicationEngine engine;
    auto openhd = OpenHD::instance();
    openhd->setEngine(&engine);

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

#if defined(ENABLE_GSTREAMER)
engine.rootContext()->setContextProperty("EnableGStreamer", QVariant(true));
engine.rootContext()->setContextProperty("EnableVideoRender", QVariant(false));
#if defined(ENABLE_MAIN_VIDEO)
    GstVideoStream* mainVideo = new GstVideoStream();
#endif
#if defined(ENABLE_PIP)
    GstVideoStream* pipVideo = new GstVideoStream();
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

#if defined(__rasp_pi__)
#if defined(ENABLE_MAIN_VIDEO)
OpenHDMMALVideo *mainVideo = new OpenHDMMALVideo(OpenHDStreamTypeMain);
#endif
#if defined(ENABLE_PIP)
OpenHDMMALVideo *pipVideo = new OpenHDMMALVideo(OpenHDStreamTypePiP);
#endif
#endif

#if defined(__apple__)
#if defined(ENABLE_MAIN_VIDEO)
OpenHDAppleVideo *mainVideo = new OpenHDAppleVideo(OpenHDStreamTypeMain);
#endif
#if defined(ENABLE_PIP)
OpenHDAppleVideo *pipVideo = new OpenHDAppleVideo(OpenHDStreamTypePiP);
#endif
#endif


#endif


    auto openHDRC = new OpenHDRC();
    //QObject::connect(openHDSettings, &OpenHDSettings::groundStationIPUpdated, openHDRC, &OpenHDRC::setGroundIP, Qt::QueuedConnection);
    engine.rootContext()->setContextProperty("openHDRC", openHDRC);

    auto mavlinkTelemetry = MavlinkTelemetry::instance();
    engine.rootContext()->setContextProperty("MavlinkTelemetry", mavlinkTelemetry);
    mavlinkTelemetry->onSetup();

    auto statusLogModel = StatusLogModel::instance();
    engine.rootContext()->setContextProperty("StatusLogModel", statusLogModel);
    statusLogModel->populateWithExampleMessage();

    #if defined(ENABLE_EXAMPLE_WIDGET)
    engine.rootContext()->setContextProperty("EnableExampleWidget", QVariant(true));
    #else
    engine.rootContext()->setContextProperty("EnableExampleWidget", QVariant(false));
    #endif


    #if defined(ENABLE_LOG)
    engine.rootContext()->setContextProperty("EnableLog", QVariant(true));
    #else
    engine.rootContext()->setContextProperty("EnableLog", QVariant(false));
    #endif


    engine.rootContext()->setContextProperty("OpenHDUtil", util);

    engine.rootContext()->setContextProperty("OpenHD", openhd);


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

#if defined(ENABLE_ADSB)
    engine.rootContext()->setContextProperty("EnableADSB", QVariant(true));
#else
    engine.rootContext()->setContextProperty("EnableADSB", QVariant(false));
#endif

#if defined(ENABLE_CHARTS)
    engine.rootContext()->setContextProperty("EnableCharts", QVariant(true));
#else
    engine.rootContext()->setContextProperty("EnableCharts", QVariant(false));
#endif

#if defined(ENABLE_RC)
    engine.rootContext()->setContextProperty("EnableRC", QVariant(true));
    //QJoysticks* jinstance = QJoysticks::getInstance();
    auto QJoysticks = QJoysticks::getInstance();
    engine.rootContext()->setContextProperty("QJoysticks", QJoysticks);
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

    engine.load(QUrl(QLatin1String("qrc:/main.qml")));

#if defined(__android__)
    QtAndroid::hideSplashScreen();
#endif

    qDebug() << "Running QML";

#if defined(ENABLE_GSTREAMER)
#if defined(ENABLE_MAIN_VIDEO)
    const auto windowPrimary=QOpenHDVideoHelper::find_qt_video_window(engine,true);
    if(windowPrimary==nullptr){
        throw std::runtime_error("Window not found");
    }
    mainVideo->init(windowPrimary,true);
#endif
#if defined(ENABLE_PIP)
    const auto windowSecondary=QOpenHDVideoHelper::find_qt_video_window(engine,false);
    if(windowSecondary==nullptr){
        throw std::runtime_error("Window not found");
    }
    pipVideo->init(windowSecondary,false);
#endif
#endif

#if defined(ENABLE_VIDEO_RENDER)
    auto rootObjects = engine.rootObjects();
    QQuickWindow *rootObject = static_cast<QQuickWindow *>(rootObjects.first());
    QThread *mainVideoThread = new QThread();
    mainVideoThread->setObjectName("mainVideoThread");
    QThread *pipVideoThread = new QThread();
    pipVideoThread->setObjectName("pipVideoThread");


#if defined(__android__)
#if defined(ENABLE_MAIN_VIDEO)
    QQuickItem *mainRenderer = rootObject->findChild<QQuickItem *>("mainSurface");
    mainVideo->setVideoOut((OpenHDRender*)mainRenderer);
    QObject::connect(mainVideoThread, &QThread::started, mainVideo, &OpenHDAndroidVideo::onStarted);
#endif

#if defined(ENABLE_PIP)
    QQuickItem *pipRenderer = rootObject->findChild<QQuickItem *>("pipSurface");
    pipVideo->setVideoOut((OpenHDRender*)pipRenderer);
    QObject::connect(pipVideoThread, &QThread::started, pipVideo, &OpenHDAndroidVideo::onStarted);
#endif
#endif

#if defined(__rasp_pi__)
#if defined(ENABLE_MAIN_VIDEO)
    QQuickItem *mainRenderer = rootObject->findChild<QQuickItem *>("mainSurface");
    mainVideo->setVideoOut((OpenHDRender*)mainRenderer);
    QObject::connect(mainVideoThread, &QThread::started, mainVideo, &OpenHDMMALVideo::onStarted);
#endif

#if defined(ENABLE_PIP)
    QQuickItem *pipRenderer = rootObject->findChild<QQuickItem *>("pipSurface");
    pipVideo->setVideoOut((OpenHDRender*)pipRenderer);
    QObject::connect(pipVideoThread, &QThread::started, pipVideo, &OpenHDMMALVideo::onStarted);
#endif
#endif


#if defined(__apple__)
#if defined(ENABLE_MAIN_VIDEO)
    QQuickItem *mainRenderer = rootObject->findChild<QQuickItem *>("mainSurface");
    mainVideo->setVideoOut((OpenHDRender*)mainRenderer);
    QObject::connect(mainVideoThread, &QThread::started, mainVideo, &OpenHDAppleVideo::onStarted);
#endif

#if defined(ENABLE_PIP)
    QQuickItem *pipRenderer = rootObject->findChild<QQuickItem *>("pipSurface");
    pipVideo->setVideoOut((OpenHDRender*)pipRenderer);
    QObject::connect(pipVideoThread, &QThread::started, pipVideo, &OpenHDAppleVideo::onStarted);
#endif
#endif


#if defined(ENABLE_MAIN_VIDEO)
    mainVideo->moveToThread(mainVideoThread);
    mainVideoThread->start();
#endif

#if defined(ENABLE_PIP)
    pipVideo->moveToThread(pipVideoThread);
    pipVideoThread->start();
#endif

#endif

    const int retval = app.exec();

#if defined(ENABLE_GSTREAMER) || defined(ENABLE_VIDEO_RENDER)
#if defined(ENABLE_MAIN_VIDEO)
    mainVideo->stopVideoSafe();
#endif
#if defined(ENABLE_PIP)
    pipVideo->stopVideoSafe();
#endif
#endif
    return retval;


}
