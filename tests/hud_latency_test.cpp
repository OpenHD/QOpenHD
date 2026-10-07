// Windows runtime regression harness linked against the current QOpenHD build.
// Run with run_hud_latency_test.py; settings and telemetry use an isolated test scope.

#include "telemetry/MavlinkTelemetry.h"
#include "telemetry/models/fcmavlinksystem.h"
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQuickWindow>
#include "util/qopenhd.h"
#include "telemetry/models/aohdsystem.h"
#include "telemetry/models/wificard.h"
#include "telemetry/models/camerastreammodel.h"
#include "telemetry/action/fcaction.h"
#include "telemetry/settings/wblinksettingshelper.h"

#include <QTemporaryDir>
#include <QDir>
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
    ctx->setContextProperty("_qopenhd",&QOpenHD::instance());
    ctx->setContextProperty("_fcMavlinkSystem",&fc);
    ctx->setContextProperty("_ohdSystemAir",&AOHDSystem::instanceAir());
    ctx->setContextProperty("_ohdSystemGround",&AOHDSystem::instanceGround());
    ctx->setContextProperty("_fcMavlinkAction",&FCAction::instance());
    ctx->setContextProperty("_cameraStreamModelPrimary",&CameraStreamModel::instance(0));
    ctx->setContextProperty("_wbLinkSettingsHelper",&WBLinkSettingsHelper::instance());
    ctx->setContextProperty("_wifi_card_air",&WiFiCard::instance_air());
    for(int i=0;i<4;++i)ctx->setContextProperty(QString("_wifi_card_gnd%1").arg(i),&WiFiCard::instance_gnd(i));
    QString qmlDir=QDir::current().absoluteFilePath("../qml");
    QString scene=QString(R"QML(
import QtQuick 2.15
import QtQuick.Controls 2.15
import "%1/ui/widgets" as W
import "%1/ui/elements" as E
ApplicationWindow {
 id: applicationWindow; width: 1280; height: 720; visible: true
 property bool globalDragLock: false
 property bool m_show_vertical_center_indicator: false
 property bool m_show_horizontal_center_indicator: false
 property var hudOverlayGrid: applicationWindow
 E.AppSettings { id: settings; objectName: "testSettings" }
 W.LinkOverviewWidget { objectName: "top" }
 W.LinkOverviewWidgetBottom { objectName: "bottom" }
}
)QML").arg(QUrl::fromLocalFile(qmlDir).toString());
    QQmlComponent sceneComponent(&engine);
    sceneComponent.setData(scene.toUtf8(),QUrl::fromLocalFile(qmlDir+"/probe.qml"));
    QObject* sceneRoot=sceneComponent.create();
    if(!sceneRoot){qWarning()<<sceneComponent.errors();return 3;}
    auto top=sceneRoot->findChild<QObject*>("top");
    auto bottom=sceneRoot->findChild<QObject*>("bottom");
    sceneRoot->findChild<QObject*>("testSettings")->setProperty("downlink_calc_quality_enabled",true);
    top->setProperty("m_quality_raw",100.0);
    top->setProperty("m_quality_raw",0.0);
    if(top->property("m_quality_smoothed").toDouble()!=0){return 4;}
    for(auto widget:{top,bottom})for(auto name:{"widgetAction","widgetDetail"}){
        auto popup=widget->property(name).value<QObject*>();
        QString componentName=QString(name)+"Component";
        auto loader=widget->property(componentName.toUtf8()).value<QObject*>();
        if(!loader||loader->property("item").value<QObject*>()){return 5;}
        QMetaObject::invokeMethod(popup,"open");
        QElapsedTimer loaded;loaded.start();
        while(!loader->property("item").value<QObject*>()&&loaded.elapsed()<2000)QCoreApplication::processEvents();
        if(!loader->property("item").value<QObject*>()){return 6;}
        QMetaObject::invokeMethod(popup,"close");
        QElapsedTimer closed;closed.start();
        while(loader->property("item").value<QObject*>()&&closed.elapsed()<2000)QCoreApplication::processEvents();
        if(loader->property("item").value<QObject*>()){return 7;}
    }
    std::fprintf(stderr,"MENU LOAD/UNLOAD AND IMMEDIATE QUALITY: PASS\n");
    delete sceneRoot;

    QUdpSocket sender;
    int received=0, sent=0;
    bool wrongThread=false;
    QElapsedTimer time;
    time.start();
    qint64 lastSent=0,maxDelay=0;
    QObject::connect(&fc,&FCMavlinkSystem::rollChanged,&app,[&] {
        wrongThread |= QThread::currentThread()!=app.thread();
        ++received;
        maxDelay=qMax(maxDelay,time.elapsed()-lastSent);
    },Qt::DirectConnection);
    auto send=[&](int sequence) {
        mavlink_message_t msg{};
        mavlink_attitude_t attitude{};
        attitude.time_boot_ms=sequence;
        attitude.roll=sequence*0.10f;
        mavlink_msg_attitude_encode(9,MAV_COMP_ID_AUTOPILOT1,&msg,&attitude);
        uint8_t buffer[MAVLINK_MAX_PACKET_LEN];
        auto length=mavlink_msg_to_send_buffer(buffer,&msg);
        lastSent=time.elapsed();
        sender.writeDatagram(reinterpret_cast<char*>(buffer),length,QHostAddress::LocalHost,14550);
    };
    telemetry.start();
    QTimer feed;
    feed.setInterval(10);
    QObject::connect(&feed,&QTimer::timeout,&app,[&] {
        send(++sent);
        if(sent==40) {
            feed.stop();
            QTimer::singleShot(100,&app,[&] {
                int before=received;
                for(int i=41;i<=60;++i) send(i);
                // Let the receive thread queue samples without servicing the GUI.
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
                telemetry.terminate();
                QCoreApplication::processEvents();
                bool stale=received!=before;
                std::fprintf(stderr,"sent=%d received=%d owner_thread=%s max_delivery_ms=%lld stale_after_stop=%s\n",
                    sent,before,wrongThread?"FAIL":"PASS",static_cast<long long>(maxDelay),stale?"FAIL":"PASS");
                app.exit(before==40&&!wrongThread&&!stale&&maxDelay<100 ? 0:1);
            });
        }
    });
    QTimer::singleShot(100,&feed,[&] {feed.start();});
    QTimer::singleShot(5000,&app,[&] {telemetry.terminate();app.exit(2);});
    return app.exec();
}
