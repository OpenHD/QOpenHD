#include "fcaction.h"
#include "qdebug.h"

#include "../../logging/hudlogmessagesmodel.h"
#include "../MavlinkTelemetry.h"
#include "impl/cmdsender.h"
#include "impl/xparam.h"

#include "create_cmd_helper.hpp"
#include "../models/fcmavlinksystem.h"
#include "tutil/mavlink_enum_to_string.h"
#include "tutil/qopenhdmavlinkhelper.hpp"

#include <cstring>

FCAction::FCAction(QObject *parent)
    : QObject{parent}
{
    m_battery_capacity_timer.setSingleShot(true);
    QObject::connect(&m_battery_capacity_timer, &QTimer::timeout,
                     this, &FCAction::battery_capacity_timeout);
}

FCAction &FCAction::instance()
{
    static FCAction instance;
    return instance;
}

void FCAction::arm_fc_async(bool arm)
{
    if(!FCMavlinkSystem::instance().is_alive()){
        HUDLogMessagesModel::instance().add_message_info("FC not alive");
        return;
    }
    const auto fc_id=MavlinkTelemetry::instance().get_fc_mav_id();
    const auto command=cmd::helper::create_cmd_arm(fc_id.sys_id,fc_id.comp_id,arm);
    auto cb=[this,arm](CmdSender::RunCommandResult result){
        if(!result.opt_ack.has_value()){
            HUDLogMessagesModel::instance().add_message_info(arm ? "ARM - FC not reachable" : "DISARM - FC not reachable");
        }else if(result.is_accepted()){
            HUDLogMessagesModel::instance().add_message_info(arm ? "ARMED FC":"DISARMED FC");
        }else{
            HUDLogMessagesModel::instance().add_message_info(arm ? "ARM not possible":"DISARM not possible");
        }
    };
    CmdSender::instance().send_command_long_async(command,cb);
}

void FCAction::flight_mode_cmd_async(long cmd_msg) {
    if(cmd_msg<0){
        // We get the flight mode command from qml, something is wrong with it
        std::stringstream ss;
        ss<<"Invalid FM "<<cmd_msg;
        HUDLogMessagesModel::instance().add_message_info(ss.str().c_str());
        return;
    }
    if(!FCMavlinkSystem::instance().is_alive()){
        HUDLogMessagesModel::instance().add_message_info("FC not alive");
        return;
    }
    if(m_has_currently_runnning_flight_mode_change){
        HUDLogMessagesModel::instance().add_message_info("Busy, please try again later");
        return;
    }
    const auto fc_id=MavlinkTelemetry::instance().get_fc_mav_id();
    auto command=cmd::helper::create_cmd_do_set_flight_mode(fc_id.sys_id,fc_id.comp_id,cmd_msg);
    auto cb=[this](CmdSender::RunCommandResult result){
        if(!result.opt_ack.has_value()){
            HUDLogMessagesModel::instance().add_message_info("FC not reachable");
        }else if(result.is_accepted()){
            HUDLogMessagesModel::instance().add_message_info("Flight mode success");
        }else{
            HUDLogMessagesModel::instance().add_message_info("Flight mode unsupported");
        }
        m_has_currently_runnning_flight_mode_change=false;
    };
    m_has_currently_runnning_flight_mode_change=true;
    const auto result=CmdSender::instance().send_command_long_async(command,cb,std::chrono::milliseconds(250),6);
    if(!result){
        HUDLogMessagesModel::instance().add_message_info("Failed, please try again later");
    }
}


struct XFlightMode{
    int id_copter=-1;
    int id_plane=-1;
};
static std::map<std::string,XFlightMode> create_fm_mapping(){
    std::map<std::string,XFlightMode> ret;
    ret["RTL"]=XFlightMode{COPTER_MODE_RTL,PLANE_MODE_RTL};
    ret["STABILIZE"]=XFlightMode{COPTER_MODE_STABILIZE,PLANE_MODE_STABILIZE};
    ret["LOITER"]=XFlightMode{COPTER_MODE_LOITER,PLANE_MODE_LOITER};
    ret["CIRCLE"]=XFlightMode{COPTER_MODE_CIRCLE,PLANE_MODE_CIRCLE};
    ret["AUTO"]=XFlightMode{COPTER_MODE_AUTO,PLANE_MODE_AUTO};
    ret["AUTOTUNE"]=XFlightMode{COPTER_MODE_AUTOTUNE,PLANE_MODE_AUTOTUNE};
    ret["MANUAL"]=XFlightMode{-1,PLANE_MODE_MANUAL};
    ret["FBWA"]=XFlightMode{-1,PLANE_MODE_FLY_BY_WIRE_A};
    ret["FBWB"]=XFlightMode{-1,PLANE_MODE_FLY_BY_WIRE_B};
    ret["QSTABILIZE"]=XFlightMode{-1,PLANE_MODE_QSTABILIZE};
    ret["QHOVER"]=XFlightMode{-1,PLANE_MODE_QHOVER};
    ret["QLOITER"]=XFlightMode{-1,PLANE_MODE_QLOITER};
    ret["QLAND"]=XFlightMode{-1,PLANE_MODE_QLAND};
    ret["QRTL"]=XFlightMode{-1,PLANE_MODE_QRTL};
    ret["ALT_HOLD"]=XFlightMode{COPTER_MODE_ALT_HOLD,-1};
    ret["POS_HOLD"]=XFlightMode{COPTER_MODE_POSHOLD,-1};
    ret["ACRO"]=XFlightMode{COPTER_MODE_ACRO,PLANE_MODE_ACRO};

    ret["GUIDED"]=XFlightMode{COPTER_MODE_GUIDED,PLANE_MODE_GUIDED};
    // (weird) copter only mode(s)
    ret["LAND"]=XFlightMode{COPTER_MODE_LAND,-1};
    ret["SMART_RTL"]=XFlightMode{COPTER_MODE_SMART_RTL,-1};
    ret["ZIGZAG"]=XFlightMode{COPTER_MODE_ZIGZAG,-1};
    ret["AUTO_RTL"]=XFlightMode{COPTER_MODE_AUTO_RTL,-1};
    // (weird) plane only mode(s)
    ret["CRUISE"]=XFlightMode{-1,PLANE_MODE_CRUISE};
    ret["TAKEOFF"]=XFlightMode{-1,PLANE_MODE_TAKEOFF};
    //ret[""]=XFlightMode{COPTER_MODE_,PLANE_MODE_};

    return ret;
}

static int flight_mode_string_to_int(const std::string& flight_mode,const int mav_type){
    if(mav_type<0){
        // mav type not yet known
        return -1;
    }
    const auto fm_map=create_fm_mapping();
    if(fm_map.find(flight_mode)!=fm_map.end()){
        // mapped
        const XFlightMode& x_fm=fm_map.at(flight_mode);
        if(qopenhd::flight_mode_is_copter((MAV_TYPE)mav_type)){
            return x_fm.id_copter;
        }else if(qopenhd::flight_mode_is_plane((MAV_TYPE)mav_type)){
            return x_fm.id_plane;
        }else{
            qDebug()<<"FM mapped not to this mav type:"<<(int)mav_type;
        }
    }else{
        qDebug()<<"FM unmapped:"<<flight_mode.c_str();
    }
    return -1;
}

void FCAction::flight_mode_cmd_async_string(QString flight_mode)
{
    auto& fcMavlinkSystem=FCMavlinkSystem::instance();
    if(!fcMavlinkSystem.is_alive()){
        HUDLogMessagesModel::instance().add_message_warning("Flight mode error - no FC");
        return;
    }
    if(m_ardupilot_mav_type<0){
        return;
    }
    const int flight_mode_type=flight_mode_string_to_int(flight_mode.toStdString(),m_ardupilot_mav_type);
    if(flight_mode_type>=0){
        flight_mode_cmd_async(flight_mode_type);
    }else{
        HUDLogMessagesModel::instance().add_message_warning("Invalid flight mode");
    }
}

bool FCAction::has_mapping(QString flight_mode)
{
    int mapping=flight_mode_string_to_int(flight_mode.toStdString(),m_ardupilot_mav_type);
    if(mapping>=0)return true;
    return false;
}

void FCAction::request_home_position_from_fc()
{
    const auto fc_id=MavlinkTelemetry::instance().get_fc_mav_id();
    const auto command=cmd::helper::create_cmd_request_message(fc_id.sys_id,fc_id.comp_id,MAVLINK_MSG_ID_HOME_POSITION);
    const auto result=CmdSender::instance().send_command_long_blocking(command);
    if(result==CmdSender::CMD_SUCCESS){
        HUDLogMessagesModel::instance().add_message_info("Request home success");
    }else{
        HUDLogMessagesModel::instance().add_message_info("Request home failure");
    }
}

bool FCAction::send_command_reboot(bool reboot)
{
    const auto fc_id=MavlinkTelemetry::instance().get_fc_mav_id();
    auto command=cmd::helper::create_cmd_reboot(fc_id.sys_id,fc_id.comp_id,reboot,false);
    const auto res=CmdSender::instance().send_command_long_blocking(command);
    return res==CmdSender::Result::CMD_SUCCESS;
}

bool FCAction::send_command_compass_calibration()
{
    const auto fc_id=MavlinkTelemetry::instance().get_fc_mav_id();
    auto command=cmd::helper::create_cmd_compass_calibration(fc_id.sys_id,fc_id.comp_id);
    const auto res=CmdSender::instance().send_command_long_blocking(command);
    return res==CmdSender::Result::CMD_SUCCESS;
}

void FCAction::request_battery_capacity_if_needed()
{
    const auto identity = FCMavlinkSystem::instance().firmware_identity();
    const int type = identity.value("type").toInt();
    if (type != 1 && type != 2) return;
    const auto session = QString("%1/%2/%3/%4").arg(identity.value("sys").toInt())
        .arg(identity.value("comp").toInt()).arg(identity.value("gen").toULongLong()).arg(type);
    if (session == m_battery_capacity_probe_session) return;
    m_battery_capacity_probe_session = session;
    char id[16]{};
    const QByteArray name = type == 1 ? QByteArray("BATT_CAPACITY") : QByteArray("BAT1_CAPACITY");
    std::memcpy(id, name.constData(), size_t(name.size()));
    mavlink_message_t request{};
    mavlink_msg_param_request_read_pack(QOpenHDMavlinkHelper::get_own_sys_id(),
        QOpenHDMavlinkHelper::get_own_comp_id(), &request, identity.value("sys").toInt(),
        identity.value("comp").toInt(), id, -1);
    MavlinkTelemetry::instance().sendMessage(request);
}

void FCAction::set_battery_capacity_async(int capacity_mah)
{
    if (!FCMavlinkSystem::instance().telemetry_active() || FCMavlinkSystem::instance().armed()) {
        HUDLogMessagesModel::instance().add_message_warning("Battery capacity: no FC connected");
        return;
    }
    if (capacity_mah < 100 || capacity_mah > 100000) {
        HUDLogMessagesModel::instance().add_message_warning("Battery capacity: invalid value");
        return;
    }

    if (m_battery_capacity_timer.isActive()) return;
    const auto parameter = FCMavlinkSystem::instance().battery_capacity_parameter();
    if (parameter.isEmpty()) {
        HUDLogMessagesModel::instance().add_message_warning(
            "Battery capacity: FC does not expose a supported MAVLink parameter");
        return;
    }
    m_pending_battery_capacity_param = parameter.value("id").toString();

    const auto fc_id = MavlinkTelemetry::instance().get_fc_mav_id();
    char param_id[16]{};
    const QByteArray param_bytes = m_pending_battery_capacity_param.toLatin1();
    std::memcpy(param_id, param_bytes.constData(),
                static_cast<size_t>(qMin(param_bytes.size(), 16)));
    mavlink_msg_param_set_pack(QOpenHDMavlinkHelper::get_own_sys_id(),
                               QOpenHDMavlinkHelper::get_own_comp_id(),
                               &m_pending_battery_capacity_message,
                               fc_id.sys_id, fc_id.comp_id, param_id,
                               static_cast<float>(capacity_mah), parameter.value("type").toInt());
    m_pending_battery_capacity_mah = capacity_mah;
    m_battery_capacity_attempts = 0;
    send_pending_battery_capacity();
}

void FCAction::send_pending_battery_capacity()
{
    mavlink_param_set_t pending{};
    mavlink_msg_param_set_decode(&m_pending_battery_capacity_message, &pending);
    const auto fc = MavlinkTelemetry::instance().get_fc_mav_id();
    if (pending.target_system != fc.sys_id || pending.target_component != fc.comp_id ||
        !FCMavlinkSystem::instance().telemetry_active() || FCMavlinkSystem::instance().armed()) {
        m_battery_capacity_timer.stop();
        m_pending_battery_capacity_param.clear();
        HUDLogMessagesModel::instance().add_message_warning("Battery capacity: FC state changed; update stopped");
        return;
    }
    ++m_battery_capacity_attempts;
    if (!MavlinkTelemetry::instance().sendMessage(m_pending_battery_capacity_message)) {
        m_battery_capacity_timer.stop();
        HUDLogMessagesModel::instance().add_message_warning("Battery capacity: MAVLink send failed");
        return;
    }
    m_battery_capacity_timer.start(1200);
}

void FCAction::battery_capacity_timeout()
{
    if (m_battery_capacity_attempts < 3) {
        send_pending_battery_capacity();
        return;
    }
    m_pending_battery_capacity_param.clear();
    HUDLogMessagesModel::instance().add_message_warning(
        "Battery capacity: FC did not acknowledge the parameter");
}

bool FCAction::process_message(const mavlink_message_t &msg)
{
    FCMavlinkSystem::instance().observe_battery_capacity(msg);
    if (msg.msgid != MAVLINK_MSG_ID_PARAM_VALUE || m_pending_battery_capacity_param.isEmpty()) {
        return false;
    }
    const auto fc_id = MavlinkTelemetry::instance().get_fc_mav_id();
    if (msg.sysid != fc_id.sys_id || msg.compid != fc_id.comp_id) return false;
    mavlink_param_value_t value{};
    mavlink_msg_param_value_decode(&msg, &value);
    QByteArray raw_id(value.param_id, 16);
    const int terminator = raw_id.indexOf('\0');
    if (terminator >= 0) raw_id.truncate(terminator);
    if (QString::fromLatin1(raw_id) != m_pending_battery_capacity_param) {
        return false;
    }

    m_battery_capacity_timer.stop();
    const bool accepted = qAbs(value.param_value - static_cast<float>(m_pending_battery_capacity_mah)) < 0.5f;
    m_pending_battery_capacity_param.clear();
    if (accepted) {
        HUDLogMessagesModel::instance().add_message_info("Battery capacity updated on FC");
    } else {
        HUDLogMessagesModel::instance().add_message_warning("Battery capacity: FC rejected the value");
    }
    return true;
}

void FCAction::request_remote_id_parameters_if_needed(int sys, int comp)
{
    const auto identity=FCMavlinkSystem::instance().firmware_identity();
    const auto session=QString("%1/%2/%3/%4").arg(sys).arg(comp)
        .arg(identity.value("gen").toULongLong()).arg(identity.value("type").toInt());
    if(m_remote_id_probes.contains(session)) return;
    if(m_remote_id_probes.size()>32) m_remote_id_probes.clear();
    m_remote_id_probes.insert(session);
    for(const auto* name : {"UAS_ID", "OPERATOR_ID"}) {
        mavlink_param_ext_request_read_t v{};v.target_system=sys;v.target_component=comp;v.param_index=-1;
        std::memcpy(v.param_id,name,std::strlen(name));
        mavlink_message_t request{};
        mavlink_msg_param_ext_request_read_encode(QOpenHDMavlinkHelper::get_own_sys_id(),
            QOpenHDMavlinkHelper::get_own_comp_id(),&request,&v);
        MavlinkTelemetry::instance().sendMessage(request);
    }
}

void FCAction::set_remote_id_async(bool operator_id, QString value)
{
    auto& fc=FCMavlinkSystem::instance();
    const auto field=operator_id?"operatorParameter":"aircraftParameter";
    const auto parameter=fc.remote_id_status().value(field).toMap();
    const auto bytes=value.toLatin1();
    if(remote_id_busy() || !fc.telemetry_active() || fc.armed() || parameter.isEmpty()) return;
    if(value.isEmpty() || value.size()>20 || QString::fromLatin1(bytes)!=value) {
        HUDLogMessagesModel::instance().add_message_warning("Remote ID: enter 1 to 20 ASCII characters");return;
    }
    for(const auto c:bytes) if(c<32 || c>126) {
        HUDLogMessagesModel::instance().add_message_warning("Remote ID: use printable ASCII characters");return;
    }
    const auto identity=fc.firmware_identity();
    const auto cmd=XParam::create_cmd_set_string(parameter.value("sys").toInt(),parameter.value("comp").toInt(),
        parameter.value("id").toString().toStdString(),value.toStdString());
    set_remote_id_busy(true);
    const bool queued=XParam::instance().try_set_param_async(cmd,[this,identity,parameter,value,field](XParam::SetParamResult result) mutable {
        QMetaObject::invokeMethod(this,[this,identity,parameter,value,field,result]() mutable {
            set_remote_id_busy(false);
            auto& fc=FCMavlinkSystem::instance();
            if(fc.firmware_identity()!=identity) return;
            bool matched=false;
            if(result.is_accepted()) {
                QByteArray echoed(result.response->param_value,128);
                const int end=echoed.indexOf('\0');if(end>=0)echoed.truncate(end);
                matched=QString::fromLatin1(echoed)==value;
            }
            if(matched) {
                auto state=fc.remote_id_status();auto updated=parameter;updated["value"]=value;state[field]=updated;
                fc.set_remote_id_status(state);
                HUDLogMessagesModel::instance().add_message_info("Remote ID parameter confirmed by device");
                request_remote_id_parameters_if_needed(parameter.value("sys").toInt(),parameter.value("comp").toInt());
            } else HUDLogMessagesModel::instance().add_message_warning("Remote ID: update was not confirmed by device");
        },Qt::QueuedConnection);
    });
    if(!queued) {set_remote_id_busy(false);HUDLogMessagesModel::instance().add_message_warning("Remote ID: parameter interface busy");}
}
