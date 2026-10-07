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
    QSettings::setPath(QSettings::IniFormat,QSettings::UserScope,settingsDir.path());
    QSettings settings;
    settings.setValue("qopenhd_mavlink_connection_mode",1);
    settings.setValue("set_mavlink_message_rates",false);
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
