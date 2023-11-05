#include "qqmlcontext.h"
#include "qscreen.h"
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QDebug>
#include <QFontDatabase>
#if defined(__android__)
#include <QtAndroid>
const QVector<QString> permissions({"android.permission.INTERNET",
                                    "android.permission.WRITE_EXTERNAL_STORAGE",
                                    "android.permission.READ_EXTERNAL_STORAGE",
                                    "android.permission.ACCESS_NETWORK_STATE",
                                    "android.permission.ACCESS_FINE_LOCATION"});
#endif

#include "telemetry/models/fcmavlinksystem.h"
#include "telemetry/action/fcaction.h"
#include "telemetry/action/ohdaction.h"
#include "telemetry/models/fcmavlinkmissionitemsmodel.h"
#include "telemetry/action/fcmissionhandler.h"
#include "telemetry/models/camerastreammodel.h"
#include "telemetry/models/aohdsystem.h"
#include "telemetry/models/wificard.h"
#include "telemetry/MavlinkTelemetry.h"
#include "telemetry/models/rcchannelsmodel.h"
#include "telemetry/settings/mavlinksettingsmodel.h"
#include "telemetry/settings/wblinksettingshelper.h"
#include "osd/speedladder.h"
#include "osd/altitudeladder.h"
#include "osd/headingladder.h"
#include "osd/horizonladder.h"
#include "osd/flightpathvector.h"
#include "osd/aoagauge.h"

// Video - annyoing ifdef crap is needed for all the different platforms / configurations
#include "decodingstatistcs.h"
#ifdef QOPENHD_ENABLE_VIDEO_VIA_AVCODEC
#include "QSGVideoTextureItem.h"
#endif
#ifdef QOPENHD_ENABLE_GSTREAMER_QMLGLSINK
#include "videostreaming/gstreamer/gst_helper.hpp"
#include "videostreaming/gstreamer/gstqmlglsinkstream.h"
#include "videostreaming/gstreamer/gstrtpaudioplayer.h"
#endif //QOPENHD_ENABLE_GSTREAMER_QMLGLSINK
#ifdef QOPENHD_ENABLE_VIDEO_VIA_ANDROID
#include <videostreaming/android/qandroidmediaplayer.h>
#include <videostreaming/android/qsurfacetexture.h>
#endif
#include "videostreaming/vscommon/QOpenHDVideoHelper.hpp"
// Video end

#include "util/qrenderstats.h"

#if defined(__ios__)
#include "platform/appleplatform.h"
#endif

#include "logging/logmessagesmodel.h"
#include "logging/hudlogmessagesmodel.h"
#include "util/qopenhd.h"
#include "util/WorkaroundMessageBox.h"
#include "util/restartqopenhdmessagebox.h"


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

// Write context properties for all platforms, e.g. such that we have boolean variable(s) accessible from .qml
static void write_platform_context_properties(QQmlApplicationEngine& engine){
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

#if defined(__ios__) || defined(__android__)
    engine.rootContext()->setContextProperty("QOPENHD_IS_MOBILE", QVariant(true));
#else
    engine.rootContext()->setContextProperty("QOPENHD_IS_MOBILE", QVariant(false));
#endif
}


int main(int argc, char *argv[]) {

    QCoreApplication::setOrganizationName("OpenHD");
    QCoreApplication::setOrganizationDomain("openhd");
    QCoreApplication::setApplicationName("QOpenHD");
    
    QSettings settings;

    const int screen_custom_font_dpi = settings.value("screen_custom_font_dpi").toInt();
    if (screen_custom_font_dpi) {
        QCoreApplication::setAttribute(Qt::AA_DisableHighDpiScaling);
        const std::string font_dpi_s = std::to_string(screen_custom_font_dpi);
        qputenv("QT_FONT_DPI", QByteArray(font_dpi_s.c_str(), font_dpi_s.length()));
    } else {
        QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    }
    //QCoreApplication::setAttribute(Qt::AA_UseOpenGLES);

    // From https://stackoverflow.com/questions/63473541/how-to-dynamically-toggle-vsync-in-a-qt-application-at-runtime
    // Get rid of VSYNC if possible. Might / might not work. On my ubuntu nvidia & intel laptop, this at least seems to
    // result in tripple buffering with unlimited fps, a bit "better" regarding latency than default.
    if(settings.value("dev_set_swap_interval_zero",false).toBool()){
        qDebug()<<"Request swap interval of 0";
        QSurfaceFormat format=QSurfaceFormat::defaultFormat();
        format.setSwapInterval(0);
        QSurfaceFormat::setDefaultFormat(format);
    }

    const double global_scale = settings.value("global_scale", 1.0).toDouble();
    const std::string global_scale_s = std::to_string(global_scale);
    QByteArray scaleAsQByteArray(global_scale_s.c_str(), global_scale_s.length());
    qputenv("QT_SCALE_FACTOR", scaleAsQByteArray);
    qDebug()<<"Storing settings at ["<<settings.fileName()<<"]";

    // https://doc.qt.io/qt-6/qtquick-visualcanvas-scenegraph-renderer.html
    //qputenv("QSG_VISUALIZE", "overdraw");
    //qputenv("QSG_VISUALIZE", "batches");
    //qputenv("QSG_VISUALIZE", "changes");
    //QCoreApplication::setAttribute(Qt::AA_UseOpenGLES);
    //QLoggingCategory::setFilterRules("qt.scenegraph.*=true");
    //QLoggingCategory::setFilterRules("qt.scenegraph.time.*=true");
    //QLoggingCategory::setFilterRules("qt.scenegraph.general=true");
    //QLoggingCategory::setFilterRules("qt.scenegraph.time.texture=true");
    //QLoggingCategory::setFilterRules("qt.scenegraph.time.renderloop=true");
    //QLoggingCategory::setFilterRules("qt.qpa.eglfs.*=true");
    //QLoggingCategory::setFilterRules("qt.qpa.egl*=true");

    QApplication app(argc, argv);
    // Customize cursor if needed
    QOpenHD::instance().customize_cursor_from_settings();
    {
        QScreen* screen=app.primaryScreen();
        if(screen){
            QRenderStats::instance().set_display_width_height(screen->size().width(),screen->size().height());
        }
    }
    QOpenHDVideoHelper::reset_qopenhd_switch_primary_secondary();

#if defined(__ios__)
    auto applePlatform = ApplePlatform::instance();
    applePlatform->disableScreenLock();
    applePlatform->registerNotifications();
#endif

  QOpenHD::instance().keep_screen_on(true);
#if defined(__android__)
    qDebug()<<"Android request permissions";
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

    load_fonts();

    qmlRegisterType<SpeedLadder>("OpenHD", 1, 0, "SpeedLadder");
    qmlRegisterType<AltitudeLadder>("OpenHD", 1, 0, "AltitudeLadder");
    qmlRegisterType<HeadingLadder>("OpenHD", 1, 0, "HeadingLadder");
    qmlRegisterType<HorizonLadder>("OpenHD", 1, 0, "HorizonLadder");
    qmlRegisterType<FlightPathVector>("OpenHD", 1, 0, "FlightPathVector");
    qmlRegisterType<AoaGauge>("OpenHD", 1, 0, "AoaGauge");

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("_qopenhd", &QOpenHD::instance());
    QOpenHD::instance().setEngine(&engine);
    write_platform_context_properties(engine);

    // Regster all the QT Mavlink system model(s)
    // it is a common practice for QT to prefix models from c++ with an underscore
    // Needs to be registered first, otherwise we can have threading issue(s)
    engine.rootContext()->setContextProperty("_messageBoxInstance", &WorkaroundMessageBox::instance());
    engine.rootContext()->setContextProperty("_restartqopenhdmessagebox", &RestartQOpenHDMessageBox::instance());

    engine.rootContext()->setContextProperty("_qrenderstats", &QRenderStats::instance());

    //engine.rootContext()->setContextProperty("_ohdlogMessagesModel", &LogMessagesModel::instanceOHD());
    //engine.rootContext()->setContextProperty("_fclogMessagesModel", &LogMessagesModel::instanceFC());
    engine.rootContext()->setContextProperty("_logGround", &LogMessagesModel::instanceGround());
    engine.rootContext()->setContextProperty("_logOpenhdAir", &LogMessagesModel::instanceOHDAir());
    engine.rootContext()->setContextProperty("_logFC", &LogMessagesModel::instanceFC());
    engine.rootContext()->setContextProperty("_hudLogMessagesModel", &HUDLogMessagesModel::instance());

    // Telemetry - first all the models
    engine.rootContext()->setContextProperty("_airCameraSettingsModel", &MavlinkSettingsModel::instanceAirCamera());
    engine.rootContext()->setContextProperty("_airCameraSettingsModel2", &MavlinkSettingsModel::instanceAirCamera2());
    engine.rootContext()->setContextProperty("_ohdSystemAirSettingsModel", &MavlinkSettingsModel::instanceAir());
    engine.rootContext()->setContextProperty("_ohdSystemGroundSettings", &MavlinkSettingsModel::instanceGround());
    engine.rootContext()->setContextProperty("_wbLinkSettingsHelper", &WBLinkSettingsHelper::instance());
    engine.rootContext()->setContextProperty("_fcMavlinkSystem", &FCMavlinkSystem::instance());
    engine.rootContext()->setContextProperty("_fcMavlinkAction", &FCAction::instance());
    engine.rootContext()->setContextProperty("_fcMavlinkMissionItemsModel", &FCMavlinkMissionItemsModel::instance());
    engine.rootContext()->setContextProperty("_fcMavlinkMissionHandler", &FCMissionHandler::instance());
    engine.rootContext()->setContextProperty("_rcchannelsmodelground", &RCChannelsModel::instanceGround());
    engine.rootContext()->setContextProperty("_rcchannelsmodelfc", &RCChannelsModel::instanceFC());
    engine.rootContext()->setContextProperty("_ohdSystemAir", &AOHDSystem::instanceAir());
    engine.rootContext()->setContextProperty("_ohdSystemGround", &AOHDSystem::instanceGround());
    engine.rootContext()->setContextProperty("_cameraStreamModelPrimary", &CameraStreamModel::instance(0));
    engine.rootContext()->setContextProperty("_cameraStreamModelSecondary", &CameraStreamModel::instance(1));
    engine.rootContext()->setContextProperty("_ohdAction", &OHDAction::instance());
    engine.rootContext()->setContextProperty("_wifi_card_gnd0", &WiFiCard::instance_gnd(0));
    engine.rootContext()->setContextProperty("_wifi_card_gnd1", &WiFiCard::instance_gnd(1));
    engine.rootContext()->setContextProperty("_wifi_card_gnd2", &WiFiCard::instance_gnd(2));
    engine.rootContext()->setContextProperty("_wifi_card_gnd3", &WiFiCard::instance_gnd(3));
    engine.rootContext()->setContextProperty("_wifi_card_air", &WiFiCard::instance_air());
    // And then the main part
    engine.rootContext()->setContextProperty("_mavlinkTelemetry", &MavlinkTelemetry::instance());

// Platform - dependend video begin -----------------------------------------------------------------
#ifdef QOPENHD_ENABLE_GSTREAMER_QMLGLSINK
    init_gstreamer(argc,argv);
    // NEEDED !! For QMLqlsink to work !!
    init_qmlglsink_and_log();
#endif //QOPENHD_ENABLE_GSTREAMER_QMLGLSINK

#ifdef QOPENHD_ENABLE_GSTREAMER_QMLGLSINK
    engine.rootContext()->setContextProperty("QOPENHD_ENABLE_GSTREAMER_QMLGLSINK", QVariant(true));
#ifdef QOPENHD_GSTREAMER_PRIMARY_VIDEO
    engine.rootContext()->setContextProperty("_primary_video_gstreamer_qml", &GstQmlGlSinkStream::instancePrimary());
#endif
#ifdef QOPENHD_GSTREAMER_SECONDARY_VIDEO
    engine.rootContext()->setContextProperty("_secondary_video_gstreamer_qml", &GstQmlGlSinkStream::instanceSecondary());
#endif
#else
    engine.rootContext()->setContextProperty("QOPENHD_ENABLE_GSTREAMER_QMLGLSINK", QVariant(false));
#endif
#ifdef QOPENHD_ENABLE_VIDEO_VIA_AVCODEC
    // QT doesn't have the define(s) from c++
    engine.rootContext()->setContextProperty("QOPENHD_ENABLE_VIDEO_VIA_AVCODEC", QVariant(true));
    qmlRegisterType<QSGVideoTextureItem>("OpenHD", 1, 0, "QSGVideoTextureItem");
#else
    engine.rootContext()->setContextProperty("QOPENHD_ENABLE_VIDEO_VIA_AVCODEC", QVariant(false));
#endif
#ifdef HAVE_MMAL
    engine.rootContext()->setContextProperty("QOPENHD_HAVE_MMAL", QVariant(true));
#else
    engine.rootContext()->setContextProperty("QOPENHD_HAVE_MMAL", QVariant(false));
#endif
#ifdef QOPENHD_ENABLE_VIDEO_VIA_ANDROID
    engine.rootContext()->setContextProperty("QOPENHD_ENABLE_VIDEO_VIA_ANDROID", QVariant(true));
    qmlRegisterType<QSurfaceTexture>("OpenHD", 1, 0, "SurfaceTexture");
    // Create a player
    QAndroidMediaPlayer player;
    engine.rootContext()->setContextProperty("_mediaPlayer", &player);
#else
     engine.rootContext()->setContextProperty("QOPENHD_ENABLE_VIDEO_VIA_ANDROID", QVariant(false));
#endif
    //GstRtpAudioPlayer::instance().start_playing();
// Platform - dependend video end  -----------------------------------------------------------------

    engine.rootContext()->setContextProperty("_decodingStatistics",&DecodingStatistcs::instance());

    // This allows to use the defines as strings in qml
    engine.rootContext()->setContextProperty("QOPENHD_GIT_VERSION",
#ifdef QOPENHD_GIT_VERSION
        QVariant(QOPENHD_GIT_VERSION)
#else
        QVariant("unknown")
#endif
    );
    engine.rootContext()->setContextProperty("QOPENHD_GIT_COMMIT_HASH",
#ifdef QOPENHD_GIT_COMMIT_HASH
        QVariant(QOPENHD_GIT_COMMIT_HASH)
#else
        QVariant("unknown")
#endif
     );

    engine.load(QUrl(QLatin1String("qrc:/main.qml")));

#if defined(__android__)
    QtAndroid::hideSplashScreen();
#endif

    qDebug() << "Running QML";
    // Now we start mavlink for the first time
    MavlinkTelemetry::instance().start();

    QRenderStats::instance().register_to_root_window(engine);

    LogMessagesModel::instanceGround().addLogMessage("QOpenHD","running");
    const int retval = app.exec();

    return retval;


}
