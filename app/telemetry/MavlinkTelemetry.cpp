#include "MavlinkTelemetry.h"

#include "qopenhdmavlinkhelper.hpp"
#include "telemetry/openhd_defines.hpp"
#include "models/aohdsystem.h"
#include "models/fcmavlinksystem.h"

#include "settings/mavlinksettingsmodel.h"
#include "../logging/logmessagesmodel.h"

MavlinkTelemetry::MavlinkTelemetry(QObject *parent):QObject(parent)
{   
    mavsdk::Mavsdk::Configuration config{QOpenHDMavlinkHelper::get_own_sys_id(),QOpenHDMavlinkHelper::get_own_comp_id(),false};
    mavsdk=std::make_shared<mavsdk::Mavsdk>();
    mavsdk->set_configuration(config);
    mavsdk::log::subscribe([](mavsdk::log::Level level,   // message severity level
                              const std::string& message, // message text
                              const std::string& file,    // source file from which the message was sent
                              int line) {                 // line number in the source file
      // process the log message in a way you like
      qDebug()<<"MAVSDK::"<<message.c_str();
      // Annoying, but no better way - we manually parse the mavlink statustext messages. The problem here is that
      // mavsdk doesn't tell if it is a message from a mavlink system or internal, and also not the system id such that
      // we can create the proper tag for the message
      // Dirty fix,we only want messages from "mavlink" displayed, not internal MAVSDK log messages.
      //if(message.find("MAVLink: warning:")!=std::string::npos){
      //if(level>=mavsdk::log::Level::Warn){
      //    LogMessagesModel::instance().addLogMessage("T",message.c_str(),0);
      //}
      // returning true from the callback disables printing the message to stdout
      //return level < mavsdk::log::Level::Warn;
      return true;
    });
    // NOTE: subscribe before adding any connection(s)
    mavsdk->subscribe_on_new_system([this]() {
        std::lock_guard<std::mutex> lock(systems_mutex);
        // hacky, fucking hell. mavsdk might call this callback with more than 1 system added.
        auto systems=mavsdk->systems();
        for(auto i=mavsdk_already_known_systems;i<systems.size();i++){
            auto new_system=systems.at(i);
            this->onNewSystem(new_system);
        }
        mavsdk_already_known_systems=systems.size();
        //qDebug()<<this->mavsdk->systems().size();
        //auto system = this->mavsdk->systems().back();
        //this->onNewSystem(system);
    });
    QSettings settings;
    dev_use_tcp = settings.value("dev_mavlink_via_tcp",false).toBool();
    if(dev_use_tcp){
        dev_tcp_server_ip=settings.value("dev_mavlink_via_tcp","0.0.0.0").toString().toStdString();
        qDebug()<<"TCP enabled with "<<dev_tcp_server_ip.c_str()<<" as ip";
        // start a timer that tries to connect via tcp until success
        m_tcp_connect_timer = new QTimer(this);
        QObject::connect(m_tcp_connect_timer, &QTimer::timeout, this, &MavlinkTelemetry::tcp_only_connect_if_not_connected);
        m_tcp_connect_timer->start(3000);
        tcp_only_connect_if_not_connected();
    }else{
        // default, udp, passive (like QGC)
        mavsdk::ConnectionResult connection_result = mavsdk->add_udp_connection(QOPENHD_GROUND_CLIENT_UDP_PORT_IN);
        std::stringstream ss;
        ss<<"MAVSDK UDP connection: " << connection_result;
        qDebug()<<ss.str().c_str();
    }
}

MavlinkTelemetry &MavlinkTelemetry::instance()
{
    static MavlinkTelemetry instance{};
    return instance;
}

void MavlinkTelemetry::register_for_qml(QQmlContext *qml_context)
{
    qml_context->setContextProperty("_mavlinkTelemetry", &MavlinkTelemetry::instance());
}

void MavlinkTelemetry::onNewSystem(std::shared_ptr<mavsdk::System> system){
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
            onProcessMavlinkMessage(msg);
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
        MavlinkSettingsModel::instanceAirCamera2().set_param_client(system);
        AOHDSystem::instanceAir().set_system(system);
    }
    // mavsdk doesn't report iNAV as being an "autopilot", so for now we just assume that if we have a mavlink system that has not one of the
    // pre-defined OpenHD sys id's it is the one FC system (connected on the air pi).
    //else if(system->has_autopilot()){
    else {
        qDebug()<<"Found FC";
        // we got the flight controller
        FCMavlinkSystem::instance().set_system(system);
        // hacky, for SITL testing
        if(passtroughOhdGround==nullptr){
            passtroughOhdGround=std::make_shared<mavsdk::MavlinkPassthrough>(system);
            passtroughOhdGround->intercept_incoming_messages_async([this](mavlink_message_t& msg){
                //qDebug()<<"Intercept:Got message"<<msg.msgid;
                onProcessMavlinkMessage(msg);
                return true;
            });
        }
        //MavlinkSettingsModel::instanceFC().set_param_client(system);
    }
}

bool MavlinkTelemetry::sendMessage(mavlink_message_t msg){
    const auto sys_id=QOpenHDMavlinkHelper::get_own_sys_id();
    const auto comp_id=QOpenHDMavlinkHelper::get_own_comp_id();
    if(msg.sysid!=sys_id){
        // probably a programming error, the message was not packed with the right sys id
        qDebug()<<"WARN Sending message with sys id:"<<msg.sysid<<" instead of"<<sys_id;
    }
    if(msg.compid!=comp_id){
        // probably a programming error, the message was not packed with the right comp id
        qDebug()<<"WARN Sending message with comp id:"<<msg.compid<<" instead of"<<comp_id;
    }
    assert(mavsdk!=nullptr);
    std::lock_guard<std::mutex> lock(systems_mutex);
    if(passtroughOhdGround!=nullptr){
        passtroughOhdGround->send_message(msg);
        return true;
    }else{
        // If the passtrough is not created yet, a connection to the OHD ground unit has not yet been established.
        //qDebug()<<"MAVSDK passtroughOhdGround not created";
        // only log it once, then not again to keep logcat clean
        static bool first=true;
        if(first){
            qDebug()<<"No OHD Ground unit connected";
            //first=false;
        }
    }
    return false;
}

void MavlinkTelemetry::onProcessMavlinkMessage(mavlink_message_t msg)
{
    //qDebug()<<"MavlinkTelemetry::onProcessMavlinkMessage"<<msg.msgid;
    //if(pause_telemetry==true){
    //    return;
    //}
    // We use timesync to ping the OpenHD systems and the FC ourselves.
    if(msg.msgid==MAVLINK_MSG_ID_TIMESYNC){
        mavlink_timesync_t timesync;
        mavlink_msg_timesync_decode(&msg,&timesync);
        if(timesync.tc1==0){
            // someone (most likely the FC) wants to timesync with us, but we ignore it to save uplink bandwidth.
            return;
        }
        if(timesync.ts1==lastTimeSyncOut){
            qDebug()<<"Got timesync response with we:"<<lastTimeSyncOut<<" msg tc1:"<<timesync.tc1<<" ts1:"<<timesync.ts1;
            const auto delta=QOpenHDMavlinkHelper::getTimeMicroseconds()-timesync.ts1;
            const auto delta_readable=QOpenHDMavlinkHelper::time_microseconds_readable(delta);
            if(msg.sysid==OHD_SYS_ID_AIR){
                AOHDSystem::instanceAir().set_last_ping_result_openhd(delta_readable.c_str());
            }else if(msg.sysid==OHD_SYS_ID_GROUND){
                AOHDSystem::instanceGround().set_last_ping_result_openhd(delta_readable.c_str());
            }else{
                qDebug()<<"Got ping from fc";
                // almost 100% from flight controller
                //if(msg.compid==MAV_COMP_ID_AUTOPILOT1)
               FCMavlinkSystem::instance().set_last_ping_result_flight_ctrl(delta_readable.c_str());
            }
        }else{
            qDebug()<<"Got timesync but it doesn't match: we:"<<lastTimeSyncOut<<" msg tc1:"<<timesync.tc1<<" ts1:"<<timesync.ts1;
        }
        return;
    }
    // Other than ping, we seperate by sys ID's - there are up to 3 Systems - The OpenHD air unit, the OpenHD ground unit and the FC connected to the OHD air unit.
    // The systems then (optionally) can seperate by components, but r.n this is not needed.
    if(msg.sysid==OHD_SYS_ID_AIR){
        // msg was produced by the OHD air unit
        if(AOHDSystem::instanceAir().process_message(msg)){
            // OHD specific message comsumed
        }else{
            //qDebug()<<"MavlinkTelemetry received unmatched message from OHD Air unit "<<QOpenHDMavlinkHelper::debug_mavlink_message(msg);
        }
        return;
    } else if(msg.sysid==OHD_SYS_ID_GROUND){
        // msg was produced by the OHD ground unit
        if(AOHDSystem::instanceGround().process_message(msg)){
            // OHD specific message consumed
        }else{
            //qDebug()<<"MavlinkTelemetry received unmatched message from OHD Air unit "<<QOpenHDMavlinkHelper::debug_mavlink_message(msg);
        }
        return;
    }else {
        // msg was neither produced by the OHD air nor ground unit, so almost 100% from the FC
        const auto fc_sys_id=FCMavlinkSystem::instance().get_fc_sys_id();
        if(fc_sys_id.has_value()){
            if(msg.sysid==fc_sys_id.value()){
                bool processed=FCMavlinkSystem::instance().process_message(msg);
            }else{
                qDebug()<<"MavlinkTelemetry received unmatched message "<<QOpenHDMavlinkHelper::debug_mavlink_message(msg);

            }
        }else{
             // we don't know the FC sys id yet.
            qDebug()<<"MavlinkTelemetry received unmatched message (FC not yet known) "<<QOpenHDMavlinkHelper::debug_mavlink_message(msg);
        }
    }
    /*const auto elapsed_version_request=std::chrono::steady_clock::now()-m_last_time_version_requested;
    if(elapsed_version_request>std::chrono::seconds(1)){
        m_last_time_version_requested=std::chrono::steady_clock::now();
        if(AOHDSystem::instanceAir().should_request_version()  || AOHDSystem::instanceGround().should_request_version()){
            request_openhd_version();
        }
    }*/
}

void MavlinkTelemetry::tcp_only_connect_if_not_connected()
{
    assert(dev_use_tcp);
    mavsdk::ConnectionResult connection_result = mavsdk->add_tcp_connection(dev_tcp_server_ip,OHD_GROUND_SERVER_TCP_PORT);
    std::stringstream ss;
    ss<<"MAVSDK TCP connection: " << connection_result;
    qDebug()<<ss.str().c_str();
    if(connection_result==mavsdk::ConnectionResult::Success){
        qDebug()<<"Stopping tcp connect timer";
        m_tcp_connect_timer->stop();
    }
}

void MavlinkTelemetry::ping_all_systems()
{
    mavlink_message_t msg;
    mavlink_timesync_t timesync{};
    timesync.tc1=0;
    // NOTE: MAVSDK does time in nanoseconds by default
    lastTimeSyncOut=QOpenHDMavlinkHelper::getTimeMicroseconds();
    timesync.ts1=lastTimeSyncOut;
    mavlink_msg_timesync_encode(QOpenHDMavlinkHelper::get_own_sys_id(),QOpenHDMavlinkHelper::get_own_comp_id(),&msg,&timesync);
    sendMessage(msg);
}

void MavlinkTelemetry::request_openhd_version()
{
    mavlink_command_long_t command{};
    command.command=MAV_CMD_REQUEST_MESSAGE;
    command.param1=static_cast<float>(MAVLINK_MSG_ID_OPENHD_VERSION_MESSAGE);
    send_command_long_oneshot(command);
    /*if(passtroughOhdGround){
        mavsdk::MavlinkPassthrough::CommandLong cmd;
        cmd.command=MAV_CMD_REQUEST_MESSAGE;
        cmd.param1=static_cast<float>(MAVLINK_MSG_ID_OPENHD_VERSION_MESSAGE);
        passtroughOhdGround->send_command_long(cmd);
    }*/
}

bool MavlinkTelemetry::send_command_long_oneshot(const mavlink_command_long_t &command)
{
    mavlink_message_t msg;
    mavlink_msg_command_long_encode(QOpenHDMavlinkHelper::get_own_sys_id(),QOpenHDMavlinkHelper::get_own_comp_id(), &msg,&command);
    return sendMessage(msg);
}

bool MavlinkTelemetry::ohd_gnd_request_channel_scan(int freq_bands,int channel_widths)
{
    qDebug()<<"Channels can: "<<freq_bands<<","<<channel_widths;
    /*mavlink_command_long_t command{};
    // channel scan is always done by teh ground unit
    command.target_system=OHD_SYS_ID_GROUND;
    command.command=OPENHD_CMD_INITIATE_CHANNEL_SEARCH;
    command.param1=static_cast<float>(freq_bands);
    command.param2=static_cast<float>(channel_widths);
    return send_command_long_oneshot(command);*/
    if(passtroughOhdGround){
        mavsdk::MavlinkPassthrough::CommandLong command{};
        command.target_sysid=OHD_SYS_ID_GROUND;
        command.target_compid=OHD_COMP_ID_LINK_PARAM;
        command.command=OPENHD_CMD_INITIATE_CHANNEL_SEARCH;
        command.param1=static_cast<float>(freq_bands);
        command.param2=static_cast<float>(channel_widths);
        auto res=passtroughOhdGround->send_command_long(command);
        return res==mavsdk::MavlinkPassthrough::Result::Success;
    }
    return false;
}
