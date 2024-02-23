#include "fcaction.h"
#include "qdebug.h"

#include "../../logging/hudlogmessagesmodel.h"
#include "../MavlinkTelemetry.h"
#include "impl/cmdsender.h"

#include "create_cmd_helper.hpp"
#include "../models/fcmavlinksystem.h"
#include "tutil/mavlink_enum_to_string.h"

FCAction::FCAction(QObject *parent)
    : QObject{parent}
{

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
