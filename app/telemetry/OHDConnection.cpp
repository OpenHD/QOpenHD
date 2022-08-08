#include "OHDConnection.h"

#include "qopenhdmavlinkhelper.hpp"
#include "telemetry/openhd_defines.hpp"
#include "../openhd_systems/aohdsystem.h"
#include "../fcmavlinksystem.h"

#include "settings/mavlinksettingsmodel.h"

OHDConnection::OHDConnection(QObject *parent,bool useTcp):QObject(parent),USE_TCP(useTcp)
{
    mavsdk=std::make_shared<mavsdk::Mavsdk>();
    mavsdk::log::subscribe([](mavsdk::log::Level level,   // message severity level
                              const std::string& message, // message text
                              const std::string& file,    // source file from which the message was sent
                              int line) {                 // line number in the source file
      // process the log message in a way you like
      qDebug()<<"MAVSDK::"<<message.c_str();
      // returning true from the callback disables printing the message to stdout
      return level < mavsdk::log::Level::Warn;
    });
    // NOTE: subscribe before adding any connection(s)
    mavsdk->subscribe_on_new_system([this]() {
        std::lock_guard<std::mutex> lock(systems_mutex);
        // hacky, fucking hell. mavsdk might call this callback with more than 1 system added.
        auto systems=mavsdk->systems();
        for(int i=mavsdk_already_known_systems;i<systems.size();i++){
            auto new_system=systems.at(i);
            this->onNewSystem(new_system);
        }
        mavsdk_already_known_systems=systems.size();
        //qDebug()<<this->mavsdk->systems().size();
        //auto system = this->mavsdk->systems().back();
        //this->onNewSystem(system);
    });
    mavsdk::ConnectionResult connection_result = mavsdk->add_udp_connection(QOPENHD_GROUND_CLIENT_UDP_PORT_IN);
    std::stringstream ss;
    ss<<"MAVSDK connection: " << connection_result;
    qDebug()<<ss.str().c_str();
}

OHDConnection &OHDConnection::instance()
{
    static OHDConnection instance=new OHDConnection();
    return instance;
}

void OHDConnection::onNewSystem(std::shared_ptr<mavsdk::System> system){
    const auto components=system->component_ids();
    qDebug()<<"System found"<<(int)system->get_system_id()<<" with components:"<<components.size();
    for(const auto& component:components){
        qDebug()<<"Component:"<<(int)component;
    }
    if(system->get_system_id()==OHD_SYS_ID_GROUND){
        qDebug()<<"Found OHD Ground station";
        systemOhdGround=system;
        passtroughOhdGround=std::make_shared<mavsdk::MavlinkPassthrough>(system);
        qDebug()<<"XX:"<<passtroughOhdGround->get_target_sysid();
        passtroughOhdGround->subscribe_message_async(MAVLINK_MSG_ID_ONBOARD_COMPUTER_STATUS,[](const mavlink_message_t& msg){
            //qDebug()<<"Got MAVLINK_MSG_ID_ONBOARD_COMPUTER_STATUS";
        });
        passtroughOhdGround->intercept_incoming_messages_async([this](mavlink_message_t& msg){
            //qDebug()<<"Intercept:Got message"<<msg.msgid;
            if(this->callback!=nullptr){
                 this->callback(msg);
            }
            return true;
        });
        passtroughOhdGround->intercept_outgoing_messages_async([](mavlink_message_t& msg){
            //qDebug()<<"Intercept:send message"<<msg.msgid;
            return true;
        });
        MavlinkSettingsModel::instanceGround().set_param_client(system);
        AOHDSystem::instanceGround().set_system(system);
    }else if(system->get_system_id()==OHD_SYS_ID_AIR){
        qDebug()<<"Found OHD AIR station";
        systemOhdAir=system;
        MavlinkSettingsModel::instanceAir().set_param_client(system);
        MavlinkSettingsModel::instanceAirCamera().set_param_client(system);
        AOHDSystem::instanceAir().set_system(system);
    }else if(system->has_autopilot()){
        qDebug()<<"Found FC";
        // we got the flight controller
        FCMavlinkSystem::instance().set_system(system);
    }
}

void OHDConnection::registerNewMessageCalback(MAV_MSG_CALLBACK cb){
    if(callback!= nullptr){
        // this might be a common programming mistake - you can only register one callback here
         qDebug()<<"OHDConnection::Overwriting already existing callback\n";
    }
    callback=std::move(cb);
}

void OHDConnection::sendMessage(mavlink_message_t msg){
    const auto sys_id=QOpenHDMavlinkHelper::getSysId();
    const auto comp_id=QOpenHDMavlinkHelper::getCompId();
    if(msg.sysid!=sys_id){
        // probably a programming error, the message was not packed with the right sys id
        qDebug()<<"WARN Sending message with sys id:"<<msg.sysid<<" instead of"<<sys_id;
    }
    if(msg.compid!=comp_id){
        // probably a programming error, the message was not packed with the right comp id
        qDebug()<<"WARN Sending message with comp id:"<<msg.compid<<" instead of"<<comp_id;
    }
    if(mavsdk!=nullptr){
        if(passtroughOhdGround!=nullptr){
            passtroughOhdGround->send_message(msg);
        }else{
            // If the passtrough is not created yet, a connection to the OHD ground unit has not yet been established.
            //qDebug()<<"MAVSDK passtroughOhdGround not created";
            // only log it once, then not again to keep logcat clean
            static bool first=true;
            if(first){
                qDebug()<<"No OHD Ground unit connected";
                first=false;
            }
        }
        return;
    }
}


void OHDConnection::request_openhd_version()
{
    mavlink_command_long_t command{};
    command.command=MAV_CMD_REQUEST_MESSAGE;
    command.param1=static_cast<float>(MAVLINK_MSG_ID_OPENHD_VERSION_MESSAGE);
    send_command_long_oneshot(command);
}

void OHDConnection::send_command_long_oneshot(const mavlink_command_long_t &command)
{
    mavlink_message_t msg;
    mavlink_msg_command_long_encode(QOpenHDMavlinkHelper::getSysId(),QOpenHDMavlinkHelper::getCompId(), &msg,&command);
    sendMessage(msg);
}

void OHDConnection::sendMessageHeartbeat(){
    //qDebug() << "OHDConnection::onHeartbeat";
    mavlink_message_t msg;
    // values from QGroundControll
    mavlink_msg_heartbeat_pack(QOpenHDMavlinkHelper::getSysId(),QOpenHDMavlinkHelper::getCompId(), &msg,MAV_TYPE_GCS,            // MAV_TYPE
                               MAV_AUTOPILOT_INVALID,   // MAV_AUTOPILOT
                               MAV_MODE_MANUAL_ARMED,   // MAV_MODE
                               0,                       // custom mode
                               MAV_STATE_ACTIVE);       // MAV_STATE
    sendMessage(msg);
}
