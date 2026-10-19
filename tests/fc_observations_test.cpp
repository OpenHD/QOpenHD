#include <QApplication>
#include <QEventLoop>
#include <QJsonDocument>
#include <QJsonObject>
#include <iostream>
#include <stdexcept>
#include <cstring>
#include "telemetry/models/fcmavlinksystem.h"
#define CHECK(v) do { if (!(v)) throw std::runtime_error(#v); } while(0)
static mavlink_message_t identity(int type, int generation=0) {
    const auto json=QJsonDocument(QJsonObject{{"sys",1},{"comp",1},{"type",type},{"gen",generation},{"ver",0}}).toJson(QJsonDocument::Compact);
    char id[16]="FC_FW_INFO", value[128]{};
    std::memcpy(value,json.constData(),size_t(json.size()));
    mavlink_message_t msg{};
    mavlink_msg_param_ext_value_pack(101,191,&msg,id,value,MAV_PARAM_EXT_TYPE_CUSTOM,94,92);
    return msg;
}
int main(int argc,char** argv) {
    QApplication app(argc,argv);
    app.setOrganizationName("OpenHDModelRegression");app.setApplicationName("FCObservationsTest");
    try {
        FCMavlinkSystem fc;
        fc.set_system_id(1,1);
        fc.process_firmware_status(identity(3));
        mavlink_message_t msg{};mavlink_scaled_pressure_t p{};p.temperature=2500;
        mavlink_msg_scaled_pressure_encode(1,1,&msg,&p);fc.process_message(msg);
        CHECK(fc.craft_diagnostics().value("observed").toMap().value("sensorTemperature").toMap().value("value").toDouble()==25);
        p.temperature=2600;mavlink_msg_scaled_pressure_encode(1,1,&msg,&p);fc.process_message(msg);
        CHECK(fc.craft_diagnostics().value("observed").toMap().value("sensorTemperature").toMap().value("value").toDouble()==26);
        // Timers must age readings, never clear identity or observed fields.
        QEventLoop loop;QTimer::singleShot(11000,&loop,&QEventLoop::quit);loop.exec();
        CHECK(fc.firmware_identity().value("name")=="INAV");
        CHECK(fc.craft_diagnostics().value("observed").toMap().contains("sensorTemperature"));
        CHECK(!fc.telemetry_active());
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
        fc.set_system_id(2,1);CHECK(fc.battery_capacity_parameter().isEmpty());
        std::cout<<"FC observations: immediate updates, silence retention, session reset and capacity matching passed\n";
    } catch(const std::exception& e) { std::cerr<<e.what()<<'\n';return 1; }
}
