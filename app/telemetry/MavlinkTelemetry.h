#ifndef OHDMAVLINKCONNECTION_H
#define OHDMAVLINKCONNECTION_H

#include <QObject>
#include <QtQuick>
#include <chrono>
#include <mutex>

#include "mavsdk_include.h"

/**
 * Changed: Used to have custom UDP and TCP stuff, but now just uses MAVSDK - MAVSDK already has both TCP and UDP support.
 *
 * @brief This is the one and only (mavlink telemetry) connection of QOpenHD to OpenHD
 * (More specific, the OpenHD Ground Station - but since the Ground station forwards messages to the air pi,
 * one can indirectly also reach the air pi via the ground pi, as well as the mavlink FC connected to the air pi).
 * Its functionalities are simple:
 * 1) sending mavlink messages to OpenHD
 * 2) receiving mavlink messages from OpenHD
 * 3) Handling the mavsdk "system discovery" for our OpenHD mavlink network, which is defined by
 *      a) OHD Air unit (own sys id)
 *      b) OHD Ground unit (own sys id)
 *      c) Optional FC connected to the air unit
 */
class MavlinkTelemetry : public QObject
{
    Q_OBJECT
public:
    MavlinkTelemetry(QObject *parent = nullptr);
    static MavlinkTelemetry& instance();
    // Called in main.cpp such that we can call the couple of Q_INVOCABLE methods
    static void register_for_qml(QQmlContext* qml_context);
    /**
     * Send a message to the OHD ground unit. If no connection has been established (yet), this should return immediately.
     * The message can be aimed at either the OHD ground unit, the OHD air unit (forwarded by OpenHD) or the FC connected to the
     * OHD air unit (forwarded by OpenHD).
     * @param msg the message to send.
     * @return true on success (this does not mean the message was received, but rather the message was sent out via the lossy connection)
     */
    bool sendMessage(mavlink_message_t msg);
private:
    // We follow the same practice as QGrouncontroll: Listen for incoming data on a specific UDP port,
    // -> as soon as we got the first packet, we know the address to send data to for bidirectional communication
    static constexpr auto QOPENHD_GROUND_CLIENT_UDP_PORT_IN=14550;
    // workaround systems discovery is not thread safe
    std::mutex systems_mutex;
    int mavsdk_already_known_systems=0;
    std::shared_ptr<mavsdk::Mavsdk> mavsdk=nullptr;
    std::shared_ptr<mavsdk::System> systemOhdGround=nullptr;
    std::shared_ptr<mavsdk::System> systemOhdAir=nullptr;
    std::shared_ptr<mavsdk::MavlinkPassthrough> passtroughOhdGround=nullptr;
    // urgh, mavsdk is really annoying in this regard. In case of OpenHD, the telemetry from the drone
    // always comes through via the OHD Ground unit, so we have the passtroughOhdGround. However, if there is no
    // OpenHD running (e.g. only the SITL during development) we never get the OHD ground system, and therefore the ground passtrough
    // is never created. hacky workaround that for now
    std::shared_ptr<mavsdk::MavlinkPassthrough> passtroughFromFC=nullptr;
    // called by mavsdk whenever a new system is detected
    void onNewSystem(std::shared_ptr<mavsdk::System> system);
    // Called every time we get a mavlink message (from any system). Intended to be used for message types that don't
    // work with mavsdk / their subscription based pattern.
    void onProcessMavlinkMessage(mavlink_message_t msg);
public:
    // ping all the systems (using timesync, since "ping" is deprecated)
    Q_INVOKABLE void ping_all_systems();
    // request the OpenHD version, both OpenHD air and ground unit will respond to that message.
    Q_INVOKABLE void request_openhd_version();
    // send a command, to all connected systems
    // doesn't reatransmitt
    bool send_command_long_oneshot(const mavlink_command_long_t& command);
private:
    int pingSequenceNumber=0;
    int64_t lastTimeSyncOut=0;
private:
    std::chrono::steady_clock::time_point m_last_time_version_requested=std::chrono::steady_clock::now();
public:
    // freq_bands:
    // 0: 2.4G and 5.8G
    // 1: 2.4G only
    // 2: 5.8G only
    // similar for channel widths
    Q_INVOKABLE bool request_channel_scan(int freq_bands,int channel_widths);
};

#endif // OHDMAVLINKCONNECTION_H
