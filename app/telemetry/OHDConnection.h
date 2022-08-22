#ifndef OHDMAVLINKCONNECTION_H
#define OHDMAVLINKCONNECTION_H

#include <QObject>
#include <QtQuick>
//#include <QTimer>
#include <chrono>
#include <mutex>
#include <optional>

#include "mavlink_include.h"

#include <mavsdk/mavsdk.h>
#include <mavsdk/plugins/telemetry/telemetry.h>
#include <mavsdk/plugins/mavlink_passthrough/mavlink_passthrough.h>
#include <mavsdk/plugins/param/param.h>
#include <mavsdk/plugins/action/action.h>
#include <mavsdk/log_callback.h>


/**
 * Changed: Used to have custom UDP and TCP stuff, but now just uses MAVSDK - MAVSDK already has both TCP and UDP support.
 *
 * @brief This is the one and only (mavlink telemetry) connection of QOpenHD to OpenHD
 * (More specific, the OpenHD Ground Station - but since the Ground station forwards messages to the air pi,
 * one can indirectly also reach the air pi via the ground pi, as well as the mavlink FC connected to the air pi).
 * Its functionalities are simple:
 * 1) sending mavlink messages to OpenHD
 * 2) receiving mavlink messages from OpenHD
 *
 * The received mavlink messages can come from OpenHD itself (Air or ground) or can be telemetry data from the Drone Flight Controller
 * connected to the OpenHD air unit.
 *
 * If we go for a single TCP or 2 udp connections (1 for send, one for receive) is not clear yet.
 *
 * The pulic methods of this class won't change regardeless.
 *
 * If the connection to OpenHD is lost, this class should try and reconnect in intervalls until the connection has been re-established.
 *
 * NOTE: Since QGroundControll does the same, this one sends out mavlink heartbeat messages in reqular intervalls.
 */

class OHDConnection : public QObject
{
public:
    OHDConnection(QObject *parent = nullptr,bool useTcp=true);
    static OHDConnection& instance();
    /**
     * @brief MAV_MSG_CALLBACK Callback that can be registered and is called every time a new incoming mavlink message has been parsed.
     */
    typedef std::function<void(mavlink_message_t msg)> MAV_MSG_CALLBACK;
    void registerNewMessageCalback(MAV_MSG_CALLBACK cb);
    /**
     * @brief sendMessage send a message to the OHD Ground station. If no connection has been established (yet), this should return immediately.
     * @param msg the message to send to the OHD Ground Station
     */
    void sendMessage(mavlink_message_t msg);
private:
    // I am still not sure if we shall use TCP or UDP for the connection between QOpenHD
    // and OpenHD.
    const bool USE_TCP;
    static constexpr auto QOPENHD_GROUND_CLIENT_TCP_ADDRESS="127.0.0.1";
    static constexpr auto QOPENHD_GROUND_CLIENT_TCP_PORT=1234;
    static constexpr auto QOPENHD_GROUND_CLIENT_UDP_ADDRESS="127.0.0.1";
    static constexpr auto QOPENHD_GROUND_CLIENT_UDP_PORT_IN=14550;
    static constexpr auto QOPENHD_GROUND_CLIENT_UDP_PORT_OUT=14551;
    MAV_MSG_CALLBACK callback=nullptr;
private:
    static constexpr auto HARTBEAT_INTERVALL_SECONDS=1;
    QTimer* heartbeatTimer=nullptr;
    std::chrono::steady_clock::time_point lastMavlinkMessage;
private:
    std::mutex systems_mutex;
    int mavsdk_already_known_systems=0;
    std::shared_ptr<mavsdk::Mavsdk> mavsdk=nullptr;
    std::shared_ptr<mavsdk::System> systemOhdGround=nullptr;
    std::shared_ptr<mavsdk::System> systemOhdAir=nullptr;
    std::shared_ptr<mavsdk::MavlinkPassthrough> passtroughOhdGround=nullptr;
private:
    // obsolete
    void sendMessageHeartbeat();
    // called by mavsdk whenever a new system is detected
    void onNewSystem(std::shared_ptr<mavsdk::System> system);
public:
    // request the OpenHD version, both OpenHD air and ground unit will respond to that message.
    void request_openhd_version();
    // send a command, to all connected systems
    // doesn't reatransmitt
    void send_command_long_oneshot(const mavlink_command_long_t& command);
};

#endif // OHDMAVLINKCONNECTION_H
