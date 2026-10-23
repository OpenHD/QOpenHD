#include <QApplication>
#include <QEventLoop>
#include <QJsonDocument>
#include <QJsonObject>
#include <iostream>
#include <stdexcept>
#include <cstring>
#include <QSettings>
#include <QTcpServer>
#include <QTcpSocket>
#include <QElapsedTimer>
#include "telemetry/MavlinkTelemetry.h"
#include "telemetry/action/fcaction.h"
#include "telemetry/action/impl/xparam.h"
#include "telemetry/models/fcmavlinksystem.h"
#include "telemetry/tutil/telemetryutil.hpp"
static QStringList captured_messages;
static void capture_message(QtMsgType, const QMessageLogContext&, const QString& text) { captured_messages.append(text); }
#define CHECK(v) do { if (!(v)) throw std::runtime_error(#v); } while(0)
static mavlink_message_t identity(int type, int generation=0, int version=0) {
    const auto json=QJsonDocument(QJsonObject{{"sys",1},{"comp",1},{"type",type},{"gen",generation},{"ver",version}}).toJson(QJsonDocument::Compact);
    char id[16]="FC_FW_INFO", value[128]{};
    std::memcpy(value,json.constData(),size_t(json.size()));
    mavlink_message_t msg{};
    mavlink_msg_param_ext_value_pack(101,191,&msg,id,value,MAV_PARAM_EXT_TYPE_CUSTOM,94,92);
    return msg;
}
int main(int argc,char** argv) {
    QApplication app(argc,argv);
    app.setOrganizationName("OpenHDModelRegression");app.setApplicationName("FCObservationsTest");
    const auto publish_diagnostics=[] { QEventLoop loop;QTimer::singleShot(300,&loop,&QEventLoop::quit);loop.exec(); };
    try {
        FCMavlinkSystem fc;
        fc.set_system_id(1,1);
        fc.process_firmware_status(identity(3));
        mavlink_message_t msg{};mavlink_scaled_pressure_t p{};p.temperature=2500;
        mavlink_msg_scaled_pressure_encode(1,1,&msg,&p);fc.process_message(msg);
        CHECK(!fc.craft_diagnostics().contains("messages"));
        CHECK(!fc.craft_diagnostics().contains("observed"));
        CHECK(fc.craft_diagnostics().value("total").toInt()==1);
        fc.acquire_diagnostics();
        CHECK(fc.craft_diagnostics().value("observed").toMap().value("sensorTemperature").toMap().value("value").toDouble()==25);
        p.temperature=2600;mavlink_msg_scaled_pressure_encode(1,1,&msg,&p);fc.process_message(msg);
        publish_diagnostics();
        CHECK(fc.craft_diagnostics().value("observed").toMap().value("sensorTemperature").toMap().value("value").toDouble()==26);
        // PX4 sends valid messages with no dashboard-specific handler. Keep
        // every packet available in the inspector without per-packet log spam.
        const auto previous_handler = qInstallMessageHandler(capture_message);
        mavlink_highres_imu_t imu{};imu.xacc=1.25f;
        for (int i=0;i<100;++i) {
            mavlink_msg_highres_imu_encode(1,1,&msg,&imu);
            CHECK(fc.process_message(msg));
        }
        qInstallMessageHandler(previous_handler);
        publish_diagnostics();
        CHECK(captured_messages.isEmpty());
        bool found_imu=false;
        for (const auto& entry : fc.craft_diagnostics().value("messages").toList()) {
            const auto item=entry.toMap();
            if(item.value("id").toInt()==MAVLINK_MSG_ID_HIGHRES_IMU) {
                found_imu=true;CHECK(item.value("count").toInt()==100);
                CHECK(item.value("name").toString()=="HIGHRES_IMU");
                CHECK(!item.value("fields").toList().isEmpty());
            }
        }
        CHECK(found_imu);
        // A burst must retain every observation without rebuilding all fields
        // or notifying the menu once per telemetry packet.
        int snapshots=0;
        const auto snapshot_connection=QObject::connect(&fc,&FCMavlinkSystem::craft_diagnosticsChanged,
            [&] { ++snapshots; });
        QElapsedTimer burst;burst.start();
        for (int i=0;i<10000;++i) {
            imu.xacc=float(i);
            mavlink_msg_highres_imu_encode(1,1,&msg,&imu);
            CHECK(fc.process_message(msg));
        }
        const auto burst_ms=burst.elapsed();
        CHECK(snapshots==0);
        publish_diagnostics();
        CHECK(snapshots>0 && snapshots<=3);
        bool retained_burst=false;
        for (const auto& entry:fc.craft_diagnostics().value("messages").toList()) {
            const auto item=entry.toMap();
            if(item.value("id").toInt()==MAVLINK_MSG_ID_HIGHRES_IMU) {
                CHECK(item.value("count").toInt()==10100);
                retained_burst=true;
            }
        }
        CHECK(retained_burst);
        // Only the last viewer closing removes formatted fields. Packets
        // received while closed must still be present on reopening.
        fc.acquire_diagnostics();
        fc.release_diagnostics();
        CHECK(!fc.craft_diagnostics().value("messages").toList().isEmpty());
        fc.release_diagnostics();
        CHECK(!fc.craft_diagnostics().contains("messages"));
        CHECK(fc.craft_diagnostics().contains("heartbeatAge"));
        const auto before_closed=fc.craft_diagnostics().value("total").toULongLong();
        for(int i=0;i<100;++i) {
            imu.xacc=42.0f;
            mavlink_msg_highres_imu_encode(1,1,&msg,&imu);
            fc.process_message(msg);
        }
        publish_diagnostics();
        CHECK(!fc.craft_diagnostics().contains("messages"));
        CHECK(fc.craft_diagnostics().value("total").toULongLong()==before_closed+100);
        fc.acquire_diagnostics();
        bool resumed=false;
        for(const auto& entry:fc.craft_diagnostics().value("messages").toList()) {
            const auto item=entry.toMap();
            if(item.value("id").toInt()!=MAVLINK_MSG_ID_HIGHRES_IMU) continue;
            CHECK(item.value("count").toInt()==10200);
            CHECK(!item.value("payload").toString().isEmpty());
            for(const auto& field:item.value("fields").toList())
                if(field.toMap().value("name")=="xacc") {
                    CHECK(field.toMap().value("value").toString()=="42"); resumed=true;
                }
        }
        CHECK(resumed);
        QObject::disconnect(snapshot_connection);
        std::cout<<"10,000 FC packets: "<<burst_ms<<" ms; bounded diagnostics publication passed\n";
        // Timers must age readings, never clear identity or observed fields.
        QEventLoop loop;QTimer::singleShot(11000,&loop,&QEventLoop::quit);loop.exec();
        CHECK(fc.firmware_identity().value("name")=="INAV");
        CHECK(fc.craft_diagnostics().value("observed").toMap().contains("sensorTemperature"));
        CHECK(!fc.telemetry_active());
        // Reflashing to another firmware family also invalidates old fields,
        // even if Air restarted and its generation counter began at zero.
        fc.process_firmware_status(identity(4,0,0x1a060200));
        CHECK(fc.craft_diagnostics().isEmpty());
        // Live Betaflight Acro heartbeat: QUADROTOR, generic autopilot,
        // MANUAL_INPUT_ENABLED with no CUSTOM_MODE_ENABLED flag.
        mavlink_msg_heartbeat_pack(1,1,&msg,MAV_TYPE_QUADROTOR,MAV_AUTOPILOT_GENERIC,
            MAV_MODE_FLAG_MANUAL_INPUT_ENABLED,0,MAV_STATE_STANDBY);
        fc.process_message(msg);
        CHECK(fc.mav_type_str()=="QUADROTOR");
        CHECK(fc.property("flight_mode").toString()=="Acro");
        mavlink_msg_heartbeat_pack(1,1,&msg,MAV_TYPE_QUADROTOR,MAV_AUTOPILOT_GENERIC,
            MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,2,MAV_STATE_STANDBY);
        fc.process_message(msg);
        CHECK(fc.property("flight_mode").toString()=="Horizon");
        // The same custom_mode=2 means Altitude Hold in the existing
        // INAV/ArduPilot parser. A generic heartbeat alone is not Betaflight.
        mavlink_heartbeat_t hb{};
        hb.type=MAV_TYPE_QUADROTOR;hb.autopilot=MAV_AUTOPILOT_GENERIC;
        hb.base_mode=MAV_MODE_FLAG_CUSTOM_MODE_ENABLED;hb.custom_mode=2;
        CHECK(Telemetryutil::parse_heartbeat(hb,3,0x1a060200)->flight_mode=="Altitude Hold");
        CHECK(Telemetryutil::parse_heartbeat(hb,0,0)->flight_mode=="Altitude Hold");
        CHECK(Telemetryutil::parse_heartbeat(hb,4,0x040501ff)->flight_mode=="Altitude Hold");
        hb.autopilot=MAV_AUTOPILOT_ARDUPILOTMEGA;
        CHECK(Telemetryutil::parse_heartbeat(hb,1,0)->flight_mode=="Altitude Hold");
        hb.autopilot=MAV_AUTOPILOT_PX4;hb.type=MAV_TYPE_FIXED_WING;hb.custom_mode=1u<<16;
        const auto px4=Telemetryutil::parse_heartbeat(hb,2,0);
        CHECK(px4->flight_mode=="Manual" && px4->mav_type=="FIXED WING");
        mavlink_msg_scaled_pressure_encode(1,1,&msg,&p);fc.process_message(msg);
        // A real session change clears observations; silence above did not.
        fc.process_firmware_status(identity(1,1));
        CHECK(fc.craft_diagnostics().isEmpty());
        mavlink_param_value_t param{};std::memcpy(param.param_id,"BATT_CAPACITY",13);
        param.param_type=MAV_PARAM_TYPE_INT32;param.param_value=2500;
        mavlink_msg_param_value_encode(2,1,&msg,&param);fc.observe_battery_capacity(msg);
        CHECK(fc.battery_capacity_parameter().isEmpty());
        mavlink_msg_param_value_encode(1,1,&msg,&param);fc.observe_battery_capacity(msg);
        CHECK(fc.battery_capacity_parameter().value("value").toInt()==2500);
        CHECK(fc.battery_capacity_parameter().value("type").toInt()==MAV_PARAM_TYPE_INT32);
        // Remote ID uses exact system/component identity and ignores messages
        // describing a nearby aircraft, even when relayed by our receiver.
        mavlink_open_drone_id_location_t location{};
        mavlink_msg_open_drone_id_location_encode(1,1,&msg,&location);
        CHECK(fc.observe_remote_id(msg));
        CHECK(!fc.remote_id_status().contains("armStatus"));
        CHECK(!fc.remote_id_status().contains("aircraftParameter"));
        mavlink_open_drone_id_basic_id_t basic{};basic.id_type=MAV_ODID_ID_TYPE_SERIAL_NUMBER;
        std::memcpy(basic.uas_id,"12345678901234567890",20);
        mavlink_msg_open_drone_id_basic_id_encode(2,1,&msg,&basic);
        CHECK(!fc.observe_remote_id(msg));
        basic.id_or_mac[0]=1;mavlink_msg_open_drone_id_basic_id_encode(1,236,&msg,&basic);
        CHECK(!fc.observe_remote_id(msg));
        basic.id_or_mac[0]=0;mavlink_msg_open_drone_id_basic_id_encode(1,236,&msg,&basic);
        CHECK(fc.observe_remote_id(msg));
        CHECK(fc.remote_id_status().value("aircraftId").toString()=="12345678901234567890");
        CHECK(!fc.remote_id_status().contains("armStatus"));
        mavlink_param_ext_value_t rid_param{};
        std::memcpy(rid_param.param_id,"UAS_ID",6);std::memcpy(rid_param.param_value,"TEST-ID",7);
        rid_param.param_type=MAV_PARAM_EXT_TYPE_REAL32;
        mavlink_msg_param_ext_value_encode(1,236,&msg,&rid_param);CHECK(!fc.observe_remote_id(msg));
        rid_param.param_type=MAV_PARAM_EXT_TYPE_CUSTOM;
        mavlink_msg_param_ext_value_encode(1,236,&msg,&rid_param);CHECK(fc.observe_remote_id(msg));
        CHECK(fc.remote_id_status().value("aircraftParameter").toMap().value("comp").toInt()==236);
        mavlink_open_drone_id_arm_status_t arm_status{};arm_status.status=1;
        std::memcpy(arm_status.error,"No GPS",6);
        mavlink_msg_open_drone_id_arm_status_encode(1,236,&msg,&arm_status);CHECK(fc.observe_remote_id(msg));
        CHECK(fc.remote_id_status().value("error").toString()=="No GPS");
        fc.set_system_id(2,1);CHECK(fc.battery_capacity_parameter().isEmpty());
        CHECK(fc.remote_id_status().isEmpty());
        // Exercise the actual async setter against a loopback-only transport.
        // A wrong component's ACK must never confirm another device's ID.
        QSettings settings;settings.setValue("qopenhd_mavlink_connection_mode",2);
        settings.setValue("qopenhd_mavlink_connection_manual_tcp_ip","127.0.0.1");
        QTcpServer server;CHECK(server.listen(QHostAddress::LocalHost,5760));
        auto& global_fc=FCMavlinkSystem::instance();global_fc.set_system_id(1,1);
        global_fc.process_firmware_status(identity(2));
        mavlink_msg_heartbeat_pack(1,1,&msg,MAV_TYPE_QUADROTOR,MAV_AUTOPILOT_PX4,0,0,MAV_STATE_STANDBY);
        global_fc.process_message(msg);
        mavlink_msg_open_drone_id_basic_id_encode(1,236,&msg,&basic);global_fc.observe_remote_id(msg);
        mavlink_msg_param_ext_value_encode(1,236,&msg,&rid_param);global_fc.observe_remote_id(msg);
        auto& action=FCAction::instance();
        action.set_remote_id_async(false,QString(21,'A'));CHECK(!action.remote_id_busy());
        auto& transport=MavlinkTelemetry::instance();transport.start();
        const auto spin=[](int ms) {QEventLoop loop;QTimer::singleShot(ms,&loop,&QEventLoop::quit);loop.exec();};
        QElapsedTimer deadline;deadline.start();
        while(!server.hasPendingConnections() && deadline.elapsed()<5000) spin(20);
        CHECK(server.hasPendingConnections());
        auto socket=server.nextPendingConnection();
        action.set_remote_id_async(false,"NEW-TEST-ID");CHECK(action.remote_id_busy());
        mavlink_message_t received{};mavlink_status_t parse_status{};bool got_set=false;
        deadline.restart();
        while(!got_set && deadline.elapsed()<2000) {
            spin(20);
            for(const auto byte:socket->readAll()) {
                if(mavlink_parse_char(MAVLINK_COMM_2,uint8_t(byte),&received,&parse_status) &&
                   received.msgid==MAVLINK_MSG_ID_PARAM_EXT_SET) {
                    mavlink_param_ext_set_t set{};mavlink_msg_param_ext_set_decode(&received,&set);
                    CHECK(set.target_system==1 && set.target_component==236);
                    CHECK(QByteArray(set.param_value,11)=="NEW-TEST-ID");got_set=true;
                }
            }
        }
        CHECK(got_set);
        mavlink_param_ext_ack_t ack{};ack.param_type=MAV_PARAM_EXT_TYPE_CUSTOM;ack.param_result=PARAM_ACK_ACCEPTED;
        std::memcpy(ack.param_id,"UAS_ID",6);std::memcpy(ack.param_value,"NEW-TEST-ID",11);
        mavlink_msg_param_ext_ack_encode(1,237,&msg,&ack);XParam::instance().process_message(msg);
        spin(20);CHECK(action.remote_id_busy());
        mavlink_msg_param_ext_ack_encode(1,236,&msg,&ack);XParam::instance().process_message(msg);
        spin(20);CHECK(!action.remote_id_busy());
        CHECK(global_fc.remote_id_status().value("aircraftParameter").toMap().value("value")=="NEW-TEST-ID");
        action.set_remote_id_async(false,"DENIED-ID");CHECK(action.remote_id_busy());
        ack.param_result=PARAM_ACK_VALUE_UNSUPPORTED;
        mavlink_msg_param_ext_ack_encode(1,236,&msg,&ack);XParam::instance().process_message(msg);
        spin(20);CHECK(!action.remote_id_busy());
        CHECK(global_fc.remote_id_status().value("aircraftParameter").toMap().value("value")=="NEW-TEST-ID");
        transport.terminate();
        std::cout<<"FC observations: bounded snapshots, silence retention, session reset and capacity matching passed\n";
    } catch(const std::exception& e) { std::cerr<<e.what()<<'\n';return 1; }
}
