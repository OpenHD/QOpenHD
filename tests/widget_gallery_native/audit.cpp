#define main original_qopenhd_main
#include "../../app/main.cpp"
#undef main
#include <QQuickItem>
#include "telemetry/action/impl/cmdsender.h"
#include <QImage>
#include <QStandardPaths>
int main(int argc,char** argv) {
 QApplication app(argc,argv);
 QFile diagnostics("gallery-audit-report.txt");diagnostics.open(QIODevice::WriteOnly);QTextStream report(&diagnostics);
 QCoreApplication::setOrganizationName("OpenHDTests");QCoreApplication::setApplicationName("WidgetGalleryAudit");QStandardPaths::setTestModeEnabled(true);
 load_fonts();setup_font_substitutions();
 qmlRegisterType<SpeedLadder>("OpenHD",1,0,"SpeedLadder");qmlRegisterType<AltitudeLadder>("OpenHD",1,0,"AltitudeLadder");qmlRegisterType<HeadingLadder>("OpenHD",1,0,"HeadingLadder");qmlRegisterType<HorizonLadder>("OpenHD",1,0,"HorizonLadder");qmlRegisterType<FlightPathVector>("OpenHD",1,0,"FlightPathVector");qmlRegisterType<AoaGauge>("OpenHD",1,0,"AoaGauge");
 qmlRegisterUncreatableType<QmlObjectListModel>("OpenHD",1,0,"QmlObjectListModel","Reference only");
 QQmlEngine engine;
 auto adsbVehicleManager=ADSBVehicleManager::instance();
    engine.rootContext()->setContextProperty("_qopenhd", &QOpenHD::instance());
    engine.rootContext()->setContextProperty("_messageBoxInstance", &WorkaroundMessageBox::instance());
    engine.rootContext()->setContextProperty("_restartqopenhdmessagebox", &RestartQOpenHDMessageBox::instance());
    engine.rootContext()->setContextProperty("_mouseHelper", &MouseHelper::instance());
    engine.rootContext()->setContextProperty("_qrenderstats", &QRenderStats::instance());
    engine.rootContext()->setContextProperty("_logGround", &LogMessagesModel::instanceGround());
    engine.rootContext()->setContextProperty("_logOpenhdAir", &LogMessagesModel::instanceOHDAir());
    engine.rootContext()->setContextProperty("_logFC", &LogMessagesModel::instanceFC());
    engine.rootContext()->setContextProperty("_hudLogMessagesModel", &HUDLogMessagesModel::instance());
    engine.rootContext()->setContextProperty("_airCameraSettingsModel", &MavlinkSettingsModel::instanceAirCamera());
    engine.rootContext()->setContextProperty("_airCameraSettingsModel2", &MavlinkSettingsModel::instanceAirCamera2());
    engine.rootContext()->setContextProperty("_ohdSystemAirSettingsModel", &MavlinkSettingsModel::instanceAir());
    engine.rootContext()->setContextProperty("_ohdSystemGroundSettings", &MavlinkSettingsModel::instanceGround());
    engine.rootContext()->setContextProperty("_wbLinkSettingsHelper", &WBLinkSettingsHelper::instance());
    engine.rootContext()->setContextProperty("_frequencyHelper", &FrequencyHelper::instance());
    engine.rootContext()->setContextProperty("_pollutionHelper", &PollutionHelper::instance());
    engine.rootContext()->setContextProperty("_mlrsController", &MLRSController::instance());
    engine.rootContext()->setContextProperty("_fcMavlinkSystem", &FCMavlinkSystem::instance());
    engine.rootContext()->setContextProperty("_fcMavlinkAction", &FCAction::instance());
    engine.rootContext()->setContextProperty("_fcMavlinkMissionItemsModel", &FCMavlinkMissionItemsModel::instance());
    engine.rootContext()->setContextProperty("_fcMavlinkMissionHandler", &FCMissionHandler::instance());
    engine.rootContext()->setContextProperty("_rcchannelsmodelground", &RCChannelsModel::instanceGround());
    engine.rootContext()->setContextProperty("_rcchannelsmodelfc", &RCChannelsModel::instanceFC());
    engine.rootContext()->setContextProperty("_joystickInputModel", &RCChannelsModel::instanceJoystick());
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
    engine.rootContext()->setContextProperty("_mavlinkMessageStatsModel", &MavlinkMessageStatsModel::instance());
    engine.rootContext()->setContextProperty("AdsbVehicleManager", adsbVehicleManager);
    engine.rootContext()->setContextProperty("_decodingStatistics",&DecodingStatistcs::instance());
    engine.rootContext()->setContextProperty("_mavlinkTelemetry", &MavlinkTelemetry::instance());
    engine.rootContext()->setContextProperty("_audioControl", &QtAudioPlayer::instance());
 UiSimulator::instance().install(engine.rootContext());UiSimulator::instance().setProperty("developerUnlocked",true);UiSimulator::instance().start({{"accessMode",2},{"state",0}});
 QQmlComponent component(&engine,QUrl::fromLocalFile(QFileInfo(argv[1]).absoluteFilePath()));
 auto* object=component.create();if(!object){report<<component.errorString();return 1;}
 auto* window=qobject_cast<QQuickWindow*>(object);
 QElapsedTimer timer;timer.start();while(timer.elapsed()<2500){app.processEvents();QThread::msleep(10);}
 bool success=true;int checked=0;
 for(int category=0;category<8;category++) {
  QMetaObject::invokeMethod(object,"selectCategory",Q_ARG(QVariant,category));
  timer.restart();while(timer.elapsed()<1800){app.processEvents();QThread::msleep(10);}
  window->grabWindow().save(QString("gallery-audit-%1.png").arg(category));
  QVariant result;QMetaObject::invokeMethod(object,"audit",Q_RETURN_ARG(QVariant,result));
  const auto audit=result.toString();
  checked+=audit.count(":rendered");
  if(audit.contains(":EMPTY") || audit.isEmpty())success=false;
  report<<audit<<"\n";report.flush();
 }
 delete object;UiSimulator::instance().stop();XParam::instance().terminate();CmdSender::instance().terminate();
 report<<"Checked "<<checked<<" previews in eight categories\n";
 return success && checked==57?0:1;
}