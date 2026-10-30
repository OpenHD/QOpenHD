#include <QApplication>
#include <QQmlEngine>
#include <QQmlContext>
#include <QQmlComponent>
#include <QQuickWindow>
#include <QFile>
#include <QElapsedTimer>
#include <QThread>
#include "telemetry/action/ohdaction.h"
#include "telemetry/settings/wblinksettingshelper.h"
#include <QTextStream>
#include "util/uisimulator.h"
#include "telemetry/models/aohdsystem.h"
#include "telemetry/models/camerastreammodel.h"
#include "telemetry/settings/mavlinksettingsmodel.h"
#include "telemetry/action/impl/xparam.h"
#include "telemetry/action/impl/cmdsender.h"
#include <stdexcept>

static void check(bool ok,const char* message) {if(!ok)throw std::runtime_error(message);}
int main(int argc,char** argv) {
    QApplication app(argc,argv);
    QCoreApplication::setOrganizationName("OpenHDTests");QCoreApplication::setApplicationName("UiSimulator");
    QFile report("simulator-smoke-result.txt");report.open(QIODevice::WriteOnly|QIODevice::Text);QTextStream out(&report);
    try {
        QQmlEngine engine;auto* context=engine.rootContext();
        QObject live;
        for(auto key:{"_ohdSystemAir","_ohdSystemGround","_cameraStreamModelPrimary","_cameraStreamModelSecondary",
             "_ohdSystemAirSettingsModel","_ohdSystemGroundSettings","_airCameraSettingsModel","_airCameraSettingsModel2",
             "_wifi_card_air","_wifi_card_gnd0","_wifi_card_gnd1","_wifi_card_gnd2","_wifi_card_gnd3","_fcMavlinkSystem","_wbLinkSettingsHelper","_pollutionHelper","_ohdAction","_rcchannelsmodelfc","_rcchannelsmodelground"})
            context->setContextProperty(key,&live);
        auto& sim=UiSimulator::instance();sim.install(context);
        check(!sim.start({}),"Simulator must reject activation before developer unlock");
        sim.setProperty("developerUnlocked",true);
        check(!sim.start({{"accessMode",3}}),"Invalid access mode must be rejected");
        check(sim.start({{"accessMode",2}})&&sim.profile()["accessMode"].toInt()==2,"Developer mode must be stored");
        sim.stop();
        check(sim.start({{"accessMode",0}}),"Normal scenario must start");
        check(sim.profile()["accessMode"].toInt()==0,"Normal mode must be stored");
        check(UiSimulator::isActive(),"Outbound transport guard must be active");
        auto* air=qobject_cast<AOHDSystem*>(sim.simulatedObject("_ohdSystemAir"));
        auto* ground=qobject_cast<AOHDSystem*>(sim.simulatedObject("_ohdSystemGround"));
        auto* params=qobject_cast<MavlinkSettingsModel*>(sim.simulatedObject("_ohdSystemAirSettingsModel"));
        auto* primary=qobject_cast<MavlinkSettingsModel*>(sim.simulatedObject("_airCameraSettingsModel"));
        auto* secondary=qobject_cast<MavlinkSettingsModel*>(sim.simulatedObject("_airCameraSettingsModel2"));
        auto* camera2=qobject_cast<CameraStreamModel*>(sim.simulatedObject("_cameraStreamModelSecondary"));
        check(air->is_alive()&&ground->is_alive(),"Both systems must appear online");
        check(ground->ohd_platform_type()==21&&air->ohd_platform_type()==11,"Default ROCK5A/Pi topology");
        check(primary->get_cached_int("CAMERA_TYPE")==32&&secondary->get_cached_int("CAMERA_TYPE")==3,"Default IMX708/IP topology");
        check(params->get_ui_metadata("WB_MCS_INDEX").value("control")=="dropdown","Simulator must install valid isolated metadata");
        check(params->get_ui_metadata("MULTI_LINK_CAP").value("readOnly").toBool(),"Capabilities must remain read only");
        const auto beforeLive=MavlinkSettingsModel::instanceAir().get_cached_int("WB_MCS_INDEX");
        params->try_set_param_int_async("WB_MCS_INDEX",4,false);
        check(params->get_cached_int("WB_MCS_INDEX")==4,"Native parameter editor must update simulation");
        check(MavlinkSettingsModel::instanceAir().get_cached_int("WB_MCS_INDEX")==beforeLive,"Real cache must not change");
        check(!params->setSimulationValue("MULTI_LINK_CAP",0),"Readonly simulated parameter must reject writes");
        check(!params->setSimulationValue("WB_MCS_INDEX",99),"Invalid range must be rejected");
        check(params->try_update_parameter_string("FC_UART_CONN","/dev/ttyS4").isEmpty(),"Serial port edit");
        secondary->try_set_param_int_async("STREAMING_E",0,false);
        check(camera2->camera_status()==0&&air->n_openhd_cameras()==1,"Disable secondary camera without restart");
        secondary->try_set_param_int_async("STREAMING_E",1,false);
        check(camera2->camera_status()==1&&air->n_openhd_cameras()==2,"Reenable secondary camera");
        primary->try_update_parameter_string("RESOLUTION_FPS","1280x720@60");
        check(qobject_cast<CameraStreamModel*>(sim.simulatedObject("_cameraStreamModelPrimary"))->curr_set_video_format()=="1280x720@60","Video format reacts to parameter edits");
        bool acknowledged=false;
        auto cmd=XParam::create_cmd_set_int(101,191,"WB_FREQUENCY",5825);
        XParam::instance().try_set_param_async(cmd,[&](XParam::SetParamResult reply){acknowledged=reply.is_accepted();});
        check(acknowledged&&air->curr_channel_mhz()==5825,"Link helper writes must route locally");
        mavlink_command_long_t command{};command.command=MAV_CMD_PREFLIGHT_REBOOT_SHUTDOWN;
        acknowledged=false;
        CmdSender::instance().send_command_long_async(command,[&](CmdSender::RunCommandResult reply){acknowledged=reply.is_accepted();});
        check(acknowledged,"Power commands acknowledged without transport");
        check(context->contextProperty("_ohdSystemAir").value<QObject*>()==air,"UI context points to simulation");
        sim.stop();check(!UiSimulator::isActive(),"Stop clears outbound guard");
        check(context->contextProperty("_ohdSystemAir").value<QObject*>()==&live,"Stop restores original live bindings");
        check(sim.start({{"camera2",32},{"secondLink",2}}),"Two controllable cameras / multi-link scenario");
        params->try_set_param_int_async("V_PRIMARY_PERC",60,false);
        auto streams=air->link_usage().first().toMap()["allocation"].toMap()["streams"].toList();
        check(streams[0].toMap()["percent"].toInt()==60&&streams[1].toMap()["percent"].toInt()==40,"Complementary camera shares");
        check(air->link_usage().size()==2,"Both links must be displayed");
        check(sim.start({{"state",0}}),"Disconnected scenario starts");check(!air->is_alive(),"Disconnected fixture must appear offline");
        check(sim.start({{"state",2}}),"Restarting scenario starts");check(camera2->camera_status()==2,"Restarting fixture state");
        check(sim.start({{"ground",21},{"air",11},{"camera1",32},{"camera2",3},{"state",1},{"link",1},{"secondLink",2},{"groundRadios",2}}),"Restore example profile");
        auto* action=qobject_cast<OHDAction*>(sim.simulatedObject("_ohdAction"));
        check(action->airStorageDevices().size()==2,"Simulated disk and recording partition");
        check(action->refresh_air_storage()&&action->airStorageDevices().size()==2,"Storage refresh stays local");
        auto* helper=qobject_cast<WBLinkSettingsHelper*>(sim.simulatedObject("_wbLinkSettingsHelper"));
        check(helper->start_scan_channels(0,20),"Offline scan starts");
        QElapsedTimer wait;wait.start();while(wait.elapsed()<5300){app.processEvents();QThread::msleep(10);}
        check(helper->scan_progress_perc()==100,"Offline scan completes");
        check(helper->start_analyze_channels(0,1),"Offline analysis starts");
        wait.restart();while(wait.elapsed()<5300){app.processEvents();QThread::msleep(10);}
        check(helper->analyze_progress_perc()==100&&helper->analyzed_channel_count()>0,"Offline RF analysis completes");
        // Render the actual popup against the native simulator, not a QML mock.
        QQmlComponent popup(&engine);
        popup.setData(R"QML(import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12
import "qrc:/ui/configpopup/dev"
Window {
 width:760;height:760;visible:true;color:"#091827"
 FontLoader { source:"qrc:/osdfonts/Archivo-Regular.ttf" }
 FontLoader { source:"qrc:/osdfonts/Archivo-Bold.ttf" }
 FontLoader { source:"qrc:/resources/Font Awesome 5 Free-Solid-900.otf" }
 QtObject {id:settings_form;property color panelBackground:"#102235";property color panelBackgroundRaised:"#15283b";property color primaryText:"white";property color secondaryText:"#aebdcb";property color lineColor:"#26394c";property color accentColor:"#278cff"}
 SimulationPopup {id:dialog;objectName:"nativeSimulationPopup"}
 Component.onCompleted:dialog.open()
})QML",QUrl("qrc:/simulator-test.qml"));
        auto* object=popup.create();
        if(!object){out<<popup.errorString();throw std::runtime_error("Native simulator popup creation failed");}
        auto* window=qobject_cast<QQuickWindow*>(object);
        wait.restart();while(wait.elapsed()<500){app.processEvents();QThread::msleep(10);}
        check(window&&!window->grabWindow().isNull(),"Native simulator popup must render");
        window->grabWindow().save("simulator-popup-native.png");
        delete object;
        sim.stop();
        XParam::instance().terminate();CmdSender::instance().terminate();
        out<<"PASS: activation gate, topology, metadata, writable isolated parameters, camera enable/format, local link edits, command guard, shares, multiple links, states and live restoration\n";
        return 0;
    } catch(const std::exception& error) {out<<"FAIL: "<<error.what()<<"\n";return 1;}
}
