// ADS-B QObject lifetime regression, linked against the current Windows build.
// Run run_hud_latency_test.py with --source tests/adsb_interaction_test.cpp.
// Settings are isolated; no network workers or real telemetry are started.

#include "telemetry/MavlinkTelemetry.h"
#include "telemetry/models/fcmavlinksystem.h"
#include "adsb/adsbvehiclemanager.h"
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQuickWindow>
#include <QQuickItem>
#include <QMouseEvent>
#include "util/qopenhd.h"
#include "telemetry/models/aohdsystem.h"
#include "telemetry/models/wificard.h"
#include "telemetry/models/camerastreammodel.h"
#include "telemetry/action/fcaction.h"
#include "telemetry/settings/wblinksettingshelper.h"

#include <QJSValue>
#include <QTemporaryDir>
#include <QDir>
#include <QFileInfo>
#include <QUdpSocket>
#include <QTimer>
#include <QEventLoop>
#include <QProcess>
#include <QProcessEnvironment>
#include <QThread>
#include <QSettings>
#include <QElapsedTimer>
#include <cstdio>
#include <thread>
int main(int argc, char** argv) {
    QApplication app(argc,argv);
    QTemporaryDir settingsDir;
    QCoreApplication::setOrganizationName("QOpenHD-test");
    QCoreApplication::setApplicationName("telemetry-delivery");
    QSettings::setDefaultFormat(QSettings::IniFormat);
    const QString testSettingsDir=qEnvironmentVariable("QOPENHD_MINIMAL_TEST_SETTINGS",settingsDir.path());
    QSettings::setPath(QSettings::IniFormat,QSettings::UserScope,testSettingsDir);
    QSettings settings;
    settings.setValue("qopenhd_mavlink_connection_mode",1);
    settings.setValue("set_mavlink_message_rates",false);
    if(!app.arguments().contains("--check-minimal") && !app.arguments().contains("--check-callout-closed")) {
        settings.setValue("map_widget_align",1);
        settings.setValue("map_widget_x_offset",12);
        settings.setValue("map_widget_y_offset",48);
    }
    settings.sync();
    auto& fc=FCMavlinkSystem::instance();
    auto& telemetry=MavlinkTelemetry::instance();
    
    qmlRegisterModule("OpenHD",1,0);
    QQmlApplicationEngine engine;
    auto ctx=engine.rootContext();
    ADSBVehicleManager manager;
    qmlRegisterUncreatableType<QmlObjectListModel>("OpenHD",1,0,"QmlObjectListModel","Test");
    ctx->setContextProperty("AdsbVehicleManager",&manager);
    ctx->setContextProperty("_qopenhd",&QOpenHD::instance());
    ctx->setContextProperty("_fcMavlinkSystem",&fc);
    ctx->setContextProperty("_ohdSystemAir",&AOHDSystem::instanceAir());
    ctx->setContextProperty("_ohdSystemGround",&AOHDSystem::instanceGround());
    ctx->setContextProperty("_fcMavlinkAction",&FCAction::instance());
    ctx->setContextProperty("_cameraStreamModelPrimary",&CameraStreamModel::instance(0));
    ctx->setContextProperty("_wbLinkSettingsHelper",&WBLinkSettingsHelper::instance());
    ctx->setContextProperty("_wifi_card_air",&WiFiCard::instance_air());
    for(int i=0;i<4;++i)ctx->setContextProperty(QString("_wifi_card_gnd%1").arg(i),&WiFiCard::instance_gnd(i));
    QString qmlDir=QFileInfo(QString::fromUtf8(__FILE__)).absoluteDir().absoluteFilePath("../qml");
    QString scene=QString(R"QML(
import QtQuick 2.15
import QtQuick.Controls 2.15
import "%1/ui/widgets" as W
import "%1/ui/widgets/map" as M
import "%1/ui/elements" as E
ApplicationWindow {
 id: applicationWindow; width: 1280; height: 720; visible: true
 property bool referencePositionValid: true
 property real referenceLatitude: 50
 property real referenceLongitude: 7
 property bool globalDragLock: false
 property bool m_show_vertical_center_indicator: false
 property bool m_show_horizontal_center_indicator: false
 property var hudOverlayGrid: applicationWindow
 E.AppSettings { id: settings; objectName: "testSettings" }
 W.AdsbTrafficWidget { objectName: "adsb" }
 M.MapWidget { objectName: "testMap" }
 W.LinkOverviewWidgetBottom { objectName: "bottomBar" }
 W.AdsbOsdOverlay { objectName: "markers"; anchors.fill: parent }
}
)QML").arg(QUrl::fromLocalFile(qmlDir).toString());
    QQmlComponent sceneComponent(&engine);
    sceneComponent.setData(scene.toUtf8(),QUrl::fromLocalFile(qmlDir+"/probe.qml"));
    QObject* sceneRoot=sceneComponent.create();
    if(!sceneRoot){qWarning()<<sceneComponent.errors();return 3;}

    auto widget=sceneRoot->findChild<QObject*>("adsb");
    sceneRoot->findChild<QObject*>("testSettings")->setProperty("adsb_enable",true);
    auto markers=sceneRoot->findChild<QObject*>("markers");
    sceneRoot->findChild<QObject*>("testSettings")->setProperty("adsb_show_osd_markers",true);
    auto popup=widget->property("widgetAction").value<QObject*>();
    auto trafficWidget=qobject_cast<QQuickItem*>(widget);
    auto waitMs=[](int milliseconds) {
        QEventLoop loop;
        QTimer::singleShot(milliseconds,&loop,&QEventLoop::quit);
        loop.exec();
    };
    auto centrePress=[&](int milliseconds) {
        const QPointF point=trafficWidget->mapToScene(QPointF(trafficWidget->width()/2,trafficWidget->height()/2));
        QMouseEvent press(QEvent::MouseButtonPress,point,Qt::LeftButton,Qt::LeftButton,Qt::NoModifier);
        QCoreApplication::sendEvent(trafficWidget->window(),&press);
        waitMs(milliseconds);
        QMouseEvent release(QEvent::MouseButtonRelease,point,Qt::LeftButton,Qt::NoButton,Qt::NoModifier);
        QCoreApplication::sendEvent(trafficWidget->window(),&release);
        waitMs(250);
    };
    waitMs(300);
    auto mapWidget=sceneRoot->findChild<QQuickItem*>("testMap");
    auto gpsCallout=sceneRoot->findChild<QQuickItem*>("bottomBarGpsPopup");
    if(app.arguments().contains("--check-minimal")) {
        const auto latitude=sceneRoot->findChild<QObject*>("gpsPopupLatitude");
        const auto longitude=sceneRoot->findChild<QObject*>("gpsPopupLongitude");
        if(!latitude || !longitude
            || latitude->property("text").toString()!=QStringLiteral("Last 51.250000\u00b0 N")
            || longitude->property("text").toString()!=QStringLiteral("5.125000\u00b0 E")) return 19;
        if(!widget->property("minimalView").toBool() || !mapWidget->property("mapHalfSize").toBool()
            || !gpsCallout || !gpsCallout->property("expanded").toBool() || !gpsCallout->isVisible()
            || qAbs(trafficWidget->height()-32*widget->property("bw_current_scale").toReal())>1
            || qAbs(mapWidget->width()-mapWidget->property("compactWidth").toReal())>1) {
            qWarning()<<"Restored states:"<<widget->property("minimalView")<<mapWidget->property("mapHalfSize")
                      <<trafficWidget->height()<<mapWidget->width()<<mapWidget->property("compactWidth");
            delete sceneRoot;
            return 13;
        }
        std::fprintf(stderr,"ADS-B/MAP PERSISTENCE: new process restored both minimal views PASS\n");
        delete sceneRoot;
        return 0;
    }
    if(app.arguments().contains("--check-callout-closed")) {
        if(!gpsCallout || gpsCallout->property("expanded").toBool()) return 15;
        delete sceneRoot;
        return 0;
    }
    auto preferences=sceneRoot->findChild<QObject*>("testSettings");
    if(!preferences->property("map_minimal").toBool() || !preferences->property("adsb_widget_minimal").toBool()
        || mapWidget->property("defaultAlignment").toInt()!=2
        || settings.value("map_widget_align").toInt()!=2
        || settings.value("map_widget_x_offset").toInt()!=128
        || settings.value("map_widget_y_offset").toInt()!=128) return 18;
    preferences->setProperty("map_minimal",false);
    preferences->setProperty("adsb_widget_minimal",false);
    waitMs(250);
    const qreal normalWidth=trafficWidget->width(), normalHeight=trafficWidget->height();
    centrePress(1000);
    if(!widget->property("minimalView").toBool() || widget->property("dragging").toBool()
        || popup->property("visible").toBool()
        || qAbs(trafficWidget->width()-normalWidth/2)>1
        || qAbs(trafficWidget->height()-32*widget->property("bw_current_scale").toReal())>1) return 10;
    QMetaObject::invokeMethod(mapWidget,"toggleHalfSizeMap");
    if(!gpsCallout || !QMetaObject::invokeMethod(gpsCallout,"open")) return 16;
    preferences->setProperty("gps_hide_identity_using_offset",true);
    preferences->setProperty("hide_identity_latitude_offset",1.0);
    preferences->setProperty("hide_identity_longitude_offset",-2.0);
    fc.set_lat(50.25);
    fc.set_lon(7.125);
    fc.set_gps_fix_type(3);
    fc.set_is_alive(true);
    waitMs(650);
    QProcess restored;
    auto childEnvironment=QProcessEnvironment::systemEnvironment();
    childEnvironment.insert("QOPENHD_MINIMAL_TEST_SETTINGS",testSettingsDir);
    restored.setProcessEnvironment(childEnvironment);
    restored.start(QCoreApplication::applicationFilePath(),{"--check-minimal"});
    if(!restored.waitForFinished(15000) || restored.exitStatus()!=QProcess::NormalExit || restored.exitCode()!=0) {
        qWarning()<<"Minimal mode restart check failed:"<<restored.readAllStandardError();
        return 14;
    }
    std::fprintf(stderr,"ADS-B/MAP PERSISTENCE: new process restored both minimal views PASS\n");
    QMetaObject::invokeMethod(gpsCallout,"close");
    restored.start(QCoreApplication::applicationFilePath(),{"--check-callout-closed"});
    if(!restored.waitForFinished(15000) || restored.exitStatus()!=QProcess::NormalExit || restored.exitCode()!=0) return 17;
    std::fprintf(stderr,"GPS CALLOUT PERSISTENCE: open and closed states restored in fresh processes PASS\n");
    std::fprintf(stderr,"GPS POSITION PERSISTENCE: last valid fix restored with privacy offset PASS\n");
    QMetaObject::invokeMethod(mapWidget,"toggleHalfSizeMap");
    centrePress(1000);
    if(widget->property("minimalView").toBool() || widget->property("dragging").toBool()
        || qAbs(trafficWidget->width()-normalWidth)>1 || qAbs(trafficWidget->height()-normalHeight)>1) return 11;
    centrePress(10);
    if(!popup->property("visible").toBool()) return 12;
    QMetaObject::invokeMethod(popup,"close");
    waitMs(250);
    std::fprintf(stderr,"ADS-B MINIMAL: centre holds toggle single-row/normal size without dragging; short click opens details PASS\n");
    for(int cycle=0;cycle<150;++cycle){
        for(int i=1;i<=30;++i){
            ADSBVehicle::VehicleInfo_t info{};
            info.icaoAddress=i; info.callsign=QString("TEST%1").arg(i);
            info.lat=50+i*.001;info.lon=7+i*.001;info.distance=i*.2;
            info.altitude=1000; info.heading=90;info.velocity=200;
            info.availableFlags=0xffffffff;
            manager.adsbVehicleUpdate(info);
        }
        QMetaObject::invokeMethod(widget,"refresh");
        QMetaObject::invokeMethod(markers,"refresh");
        QMetaObject::invokeMethod(popup,"open");
        QCoreApplication::processEvents();
        auto list=widget->property("displayedAircraft").value<QJSValue>();
        widget->setProperty("selectedAircraft",QVariant::fromValue(list.property(cycle%30)));
        // Send real pointer events through the popup's list, including a
        // removal between press and release while delegates are incubating.
        QQuickItem* trafficList=nullptr;
        auto content=popup->property("contentItem").value<QObject*>();
        for(auto item:content->findChildren<QQuickItem*>())
            if(QString(item->metaObject()->className()).startsWith("QQuickListView")) {trafficList=item;break;}
        if(!trafficList || !trafficList->window()) return 8;
        const QPointF point=trafficList->mapToScene(QPointF(25,25));
        auto window=trafficList->window();
        QMouseEvent press(QEvent::MouseButtonPress,point,Qt::LeftButton,Qt::LeftButton,Qt::NoModifier);
        QCoreApplication::sendEvent(window,&press);
        if(cycle%2==0){manager.adsbClearModel();QCoreApplication::sendPostedEvents(nullptr,QEvent::DeferredDelete);}
        QMouseEvent release(QEvent::MouseButtonRelease,point,Qt::LeftButton,Qt::NoButton,Qt::NoModifier);
        QCoreApplication::sendEvent(window,&release);
        if(cycle%2 && widget->property("selectedAircraft").value<QJSValue>().property("icaoAddress").toInt()!=1) return 9;
        engine.collectGarbage();
        QCoreApplication::processEvents();
        QMetaObject::invokeMethod(popup,"close");
        QCoreApplication::processEvents();
    }
    delete sceneRoot;
    std::fprintf(stderr,"ADS-B STRESS: 150 popup cycles, 4500 reports, clicks across deletion and garbage collection PASS\n");
    return 0;
}
