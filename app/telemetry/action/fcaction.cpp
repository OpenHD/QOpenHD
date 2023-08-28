#include "fcaction.h"
#include "qdebug.h"

#include "../../logging/hudlogmessagesmodel.h"
#include "util/mavsdk_helper.hpp"


FCAction::FCAction(QObject *parent)
    : QObject{parent}
{

}

FCAction &FCAction::instance()
{
    static FCAction instance;
    return instance;
}

void FCAction::set_system(std::shared_ptr<mavsdk::System> system)
{
    // The system is set once when discovered, then should not change !!
    if(m_system!=nullptr){
        HUDLogMessagesModel::instance().add_message_warning("FC sys id conflict");
        return;
    }
    assert(m_system==nullptr);
    m_system=system;
    if(!m_system->has_autopilot()){
        qDebug()<<"FCMavlinkSystem::set_system WARNING no autopilot";
    }
    const int tmp_sys_id=m_system->get_system_id();
    qDebug()<<"FCMavlinkSystem::set_system: FC SYS ID is:"<<(int)tmp_sys_id;
    m_action=std::make_shared<mavsdk::Action>(system);
    m_pass_thru=std::make_shared<mavsdk::MavlinkPassthrough>(system);
}

void FCAction::arm_fc_async(bool arm)
{
    if(!m_action){
        qDebug()<<"No fc action module";
        HUDLogMessagesModel::instance().add_message_info("No FC");
        return;
    }
    qDebug()<<"FCMavlinkSystem::arm_fc_async "<<(arm ? "arm" : "disarm");
    // We listen for the armed / disarmed changes directly
    auto cb=[this](mavsdk::Action::Result res){
        if(res!=mavsdk::Action::Result::Success){
            std::stringstream ss;
            ss<<"ARM/Disarm failed:"<<res;
            qDebug()<<ss.str().c_str();
            HUDLogMessagesModel::instance().add_message_info(ss.str().c_str());
        }
    };
    if(arm){
        m_action->arm_async(cb);
    }else{
        m_action->disarm_async(cb);
    }
}



void FCAction::flight_mode_cmd(long cmd_msg) {
    if(!m_pass_thru){
        HUDLogMessagesModel::instance().add_message_info("No FC");
        qDebug()<<"No fc pass_thru module";
        return;
    }
    if(cmd_msg<0){
        // We get the flight mode command from qml, something is wrong with it
        std::stringstream ss;
        ss<<"Invalid FM "<<cmd_msg;
        HUDLogMessagesModel::instance().add_message_info(ss.str().c_str());
        return;
    }
    /*
    qDebug() << "flight_mode_cmd CMD:" << cmd_msg;
    qDebug() << "flight_mode_cmd our sysid:" << _pass_thru->get_our_sysid();
    qDebug() << "flight_mode_cmd our comp id:" << _pass_thru->get_our_compid();
    qDebug() << "flight_mode_cmd target id:" << _pass_thru->get_target_sysid();
    qDebug() << "flight_mode_cmd target compid:" << _pass_thru->get_target_compid();*/
    mavsdk::MavlinkPassthrough::CommandLong cmd;

    cmd.command = MAV_CMD_DO_SET_MODE;

    cmd.target_sysid= m_pass_thru->get_target_sysid();
    cmd.target_compid=m_pass_thru->get_target_compid();

    cmd.param1=MAV_MODE_FLAG_CUSTOM_MODE_ENABLED;
    cmd.param2=cmd_msg;
    cmd.param3=0;
    cmd.param4=0;
    cmd.param5=0;
    cmd.param6=0;
    cmd.param7=0;

    const auto res=m_pass_thru->send_command_long(cmd);

    //result is not really used right now as mavsdk will output errors
    //----here for future use----
    if(res==mavsdk::MavlinkPassthrough::Result::Success){
        const auto msg="flight_mode_cmd Success!!";
        qDebug()<<msg;
        HUDLogMessagesModel::instance().add_message_info(msg);
    }
    else {
        const auto msg=mavsdk::helper::to_string2("flight_mode_cmd error:",res);
        qDebug()<<msg.c_str();
        HUDLogMessagesModel::instance().add_message_warning(msg.c_str());
    }
}

void FCAction::request_home_position_from_fc()
{
    if(!m_pass_thru){
        HUDLogMessagesModel::instance().add_message_info("No FC");
        qDebug()<<"No fc pass_thru module";
        return;
    }
    mavsdk::MavlinkPassthrough::CommandLong cmd{};
    cmd.command = MAV_CMD_REQUEST_MESSAGE;
    cmd.target_sysid= m_pass_thru->get_target_sysid();
    cmd.target_compid=m_pass_thru->get_target_compid();
    cmd.param1=MAVLINK_MSG_ID_HOME_POSITION;
    const auto res=m_pass_thru->send_command_long(cmd);
    if(res==mavsdk::MavlinkPassthrough::Result::Success){
        const auto msg="Request home Success!!";
        qDebug()<<msg;
        HUDLogMessagesModel::instance().add_message_info(msg);
    }else {
        const auto msg=mavsdk::helper::to_string2("Request home error:",res);
        qDebug()<<msg.c_str();
        HUDLogMessagesModel::instance().add_message_warning(msg.c_str());
    }
}
