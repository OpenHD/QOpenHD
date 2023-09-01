#include "MavlinkTelemetry.h"

#include "common/openhd-util.hpp"

#include "models/aohdsystem.h"
#include "models/fcmavlinksystem.h"

#include "settings/mavlinksettingsmodel.h"
#include "../logging/logmessagesmodel.h"
#include "util/mavsdk_helper.hpp"
#include "util/qopenhdmavlinkhelper.hpp"
#include "models/fcmavlinkmissionitemsmodel.h"

#include "action/fcmissionhandler.h"
#include "action/fcaction.h"
#include "action/cmdsender.h"
#include "action/fcmsgintervalhandler.h"
#include "settings/xparam.h"

MavlinkTelemetry::MavlinkTelemetry(QObject *parent):QObject(parent)
{
    mavsdk::Mavsdk::Configuration config{QOpenHDMavlinkHelper::get_own_sys_id(),QOpenHDMavlinkHelper::get_own_comp_id(),false};
    m_mavsdk=std::make_shared<mavsdk::Mavsdk>();
    m_mavsdk->set_configuration(config);
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
    m_mavsdk->subscribe_on_new_system([this]() {
        std::lock_guard<std::mutex> lock(systems_mutex);
        // hacky, fucking hell. mavsdk might call this callback with more than 1 system added.
        auto systems=m_mavsdk->systems();
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
        /*dev_tcp_server_ip=settings.value("dev_mavlink_tcp_ip","0.0.0.0").toString().toStdString();
        if(!OHDUtil::is_valid_ip(dev_tcp_server_ip)){
            qWarning("%s not a valid ip, using default",dev_tcp_server_ip.c_str());
            dev_tcp_server_ip = "0.0.0.0";
        }*/
        //dev_tcp_server_ip = "0.0.0.0";
        // We try connecting until success
        m_tcp_connect_thread=std::make_unique<std::thread>(&MavlinkTelemetry::tcp_only_establish_connection,this);
    }else{
        // default, udp, passive (like QGC)
        mavsdk::ConnectionResult connection_result = m_mavsdk->add_udp_connection(QOPENHD_GROUND_CLIENT_UDP_PORT_IN);
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

void MavlinkTelemetry::onNewSystem(std::shared_ptr<mavsdk::System> system){
    const auto components=system->component_ids();
    qDebug()<<"System found"<<(int)system->get_system_id()<<" with components:"<<components.size();
    for(const auto& component:components){
        qDebug()<<"Component:"<<(int)component;
    }
    if(system->get_system_id()==OHD_SYS_ID_GROUND){
        qDebug()<<"Found OHD Ground station";
        m_system_ohd_ground=system;
        m_passtrough=std::make_shared<mavsdk::MavlinkPassthrough>(system);
        qDebug()<<"XX:"<<m_passtrough->get_target_sysid();
        m_passtrough->intercept_incoming_messages_async([this](mavlink_message_t& msg){
            //qDebug()<<"Intercept:Got message"<<msg.msgid;
            process_mavlink_message(msg);
            return true;
        });
        //passtroughOhdGround->intercept_outgoing_messages_async([](mavlink_message_t& msg){
        //    //qDebug()<<"Intercept:send message"<<msg.msgid;
        //    return true;
        //});
        MavlinkSettingsModel::instanceGround().set_param_client(system);
    }else if(system->get_system_id()==OHD_SYS_ID_AIR){
        qDebug()<<"Found OHD AIR station";
        m_system_ohd_air=system;
        MavlinkSettingsModel::instanceAir().set_param_client(system);
        MavlinkSettingsModel::instanceAirCamera().set_param_client(system);
        MavlinkSettingsModel::instanceAirCamera2().set_param_client(system);
        // hacky, for connecting to the air unit directly
        if(m_passtrough==nullptr){
            m_passtrough=std::make_shared<mavsdk::MavlinkPassthrough>(system);
            m_passtrough->intercept_incoming_messages_async([this](mavlink_message_t& msg){
                //qDebug()<<"Intercept:Got message"<<msg.msgid;
                process_mavlink_message(msg);
                return true;
            });
        }
    }
    // mavsdk doesn't report iNAV as being an "autopilot", so for now we just assume that if we have a mavlink system that has not one of the
    // pre-defined OpenHD sys id's it is the one FC system (connected on the air pi).
    //else if(system->has_autopilot()){
    else {
        qDebug()<<"Got system id: "<<(int)system->get_system_id()<<" components:"<<mavsdk::helper::comp_ids_to_string(system->component_ids()).c_str();
        // By default, we assume there is one additional non-openhd system - the FC
        bool is_fc=true;
        QSettings settings;
        const bool dirty_enable_mavlink_fc_sys_id_check=settings.value("dirty_enable_mavlink_fc_sys_id_check",false).toBool();
        if(dirty_enable_mavlink_fc_sys_id_check){
            // filtering, default off
            const auto comp_ids=system->component_ids();
            is_fc=mavsdk::helper::any_comp_id_autopilot(comp_ids);
        }
        if(is_fc){
            qDebug()<<"Found FC";
            m_system_fc=system;
            // we got the flight controller
            FCMavlinkSystem::instance().set_system_id(m_system_fc->get_system_id());
            // hacky, for SITL testing
            if(m_passtrough==nullptr){
                m_passtrough=std::make_shared<mavsdk::MavlinkPassthrough>(system);
                m_passtrough->intercept_incoming_messages_async([this](mavlink_message_t& msg){
                    //qDebug()<<"Intercept:Got message"<<msg.msgid;
                    process_mavlink_message(msg);
                    return true;
                });
            }

        }else{
            qDebug()<<"Got weird system:"<<(int)system->get_system_id();
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
    assert(m_mavsdk!=nullptr);
    std::lock_guard<std::mutex> lock(systems_mutex);
    if(m_passtrough!=nullptr){
        m_passtrough->send_message(msg);
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

static int get_message_size(const mavlink_message_t& msg){
    return sizeof(msg);
}

void MavlinkTelemetry::process_mavlink_message(const mavlink_message_t& msg)
{
    m_tele_received_packets++;
    m_tele_received_bytes+=get_message_size(msg);
    set_telemetry_pps_in(m_tele_pps_in.get_last_or_recalculate(m_tele_received_packets));
    set_telemetry_bps_in(m_tele_bitrate_in.get_last_or_recalculate(m_tele_received_bytes));
    //qDebug()<<"MavlinkTelemetry::onProcessMavlinkMessage"<<msg.msgid;
    //if(pause_telemetry==true){
    //    return;
    //}
    // We use timesync to ping the OpenHD systems and the FC ourselves.
    if(msg.msgid==MAVLINK_MSG_ID_TIMESYNC){
        process_message_timesync(msg);
        return;
    }
    if(CmdSender::instance().process_message(msg)){
        // Consumed, no further processing needed
        return;
    }
    /*if(XParam::instance().process_message(msg)){
        // Consumed, no further processing needed
        return;
    }*/
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
               process_message_fc(msg);
               FCMsgIntervalHandler::instance().opt_send_messages();
               FCMissionHandler::instance().opt_send_messages();
            }else{
                qDebug()<<"MavlinkTelemetry received unmatched message "<<QOpenHDMavlinkHelper::debug_mavlink_message(msg);
            }
        }else{
            // we don't know the FC sys id yet.
            qDebug()<<"MavlinkTelemetry received unmatched message (FC not yet known) "<<QOpenHDMavlinkHelper::debug_mavlink_message(msg);
        }
    }
}

void MavlinkTelemetry::process_message_fc(const mavlink_message_t &msg)
{
    if(FCMissionHandler::instance().process_message(msg)){
        return; // No further processing needed;
    }
    if(FCMavlinkSystem::instance().process_message(msg)){
        return;
    }
    qDebug()<<"MavlinkTelemetry::process_message_fc unmatched message:"<<QOpenHDMavlinkHelper::debug_mavlink_message(msg);
}

void MavlinkTelemetry::process_message_timesync(const mavlink_message_t &msg)
{
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
            FCMavlinkSystem::instance().set_last_ping_result_flight_ctrl(delta_readable.c_str());
        }
    }else{
        qDebug()<<"Got timesync but it doesn't match: we:"<<lastTimeSyncOut<<" msg tc1:"<<timesync.tc1<<" ts1:"<<timesync.ts1;
    }
}

void MavlinkTelemetry::tcp_only_establish_connection()
{
    //assert(dev_use_tcp);
    qDebug()<<"tcp_only_establish_connection";
    while(true){
        QSettings settings;
        auto dev_tcp_server_ip=settings.value("dev_mavlink_tcp_ip","0.0.0.0").toString().toStdString();
        if(!OHDUtil::is_valid_ip(dev_tcp_server_ip)){
            qWarning("%s not a valid ip, using default",dev_tcp_server_ip.c_str());
            dev_tcp_server_ip = "0.0.0.0";
        }
        //dev_tcp_server_ip = "0.0.0.0";
        {
            std::stringstream ss;
            ss<<"TCP try connecting to ["<<dev_tcp_server_ip<<"]:"<<OHD_GROUND_SERVER_TCP_PORT;
            qDebug()<<ss.str().c_str();
        }
        // This might block, but that's not quaranteed (it won't if the host is there, but no server on the tcp port)
        mavsdk::ConnectionResult connection_result = m_mavsdk->add_tcp_connection(dev_tcp_server_ip,OHD_GROUND_SERVER_TCP_PORT);
        std::stringstream ss;
        ss<<"MAVSDK TCP connection result: " << connection_result;
        qDebug()<<ss.str().c_str();
        if(connection_result==mavsdk::ConnectionResult::Success){
            qDebug()<<"TCP connection established";
            return;
        }
        // wait a bit before trying again
        std::this_thread::sleep_for(std::chrono::seconds(3));
    }
}

void MavlinkTelemetry::add_tcp_connection_handler(QString ip)
{
    QSettings settings;
    //settings.setValue("dev_mavlink_via_tcp",true);
    settings.setValue("dev_mavlink_tcp_ip",ip);
    if(m_tcp_connect_thread!=nullptr){
        qDebug()<<"Already enabled";
        return;
    }
    m_tcp_connect_thread=std::make_unique<std::thread>(&MavlinkTelemetry::tcp_only_establish_connection,this);
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

MavlinkTelemetry::FCMavId MavlinkTelemetry::get_fc_mav_id()
{
    std::lock_guard<std::mutex> lock(systems_mutex);
    if(m_system_fc!=nullptr){
        return {m_system_fc->get_system_id(),MAV_COMP_ID_AUTOPILOT1};
    }
    return {1,MAV_COMP_ID_AUTOPILOT1};
}

void MavlinkTelemetry::re_apply_rates()
{
    FCMsgIntervalHandler::instance().restart();
}
