#ifndef OHDMAVLINKCONNECTION_H
#define OHDMAVLINKCONNECTION_H

#include <QObject>
#include <QtQuick>
#include <chrono>
#include <mutex>
#include <thread>

#include "util/mavlink_include.h"
#include "../../lib/lqtutils_master/lqtutils_prop.h"
#include "../common/TimeHelper.hpp"

#include "connection/udp_connection.h"
#include "connection/tcp_connection.h"

/**
 *
 * @brief Main entry / exit point for all mavlink telemetry
 * (More specific, to / from the OpenHD Ground Station - but since the Ground station forwards messages to/from the air pi,
 * one can indirectly also reach the air pi via the ground pi, as well as the mavlink FC connected to the air pi).
 * Its functionalities are simple:
 * 1) "Connecting to the ground unit (either UDP or TCP)"
 * 1) sending mavlink messages to OpenHD
 * 2) receiving mavlink messages from OpenHD
 * 3) Handling the "system discovery" for our OpenHD mavlink network, which is defined by
 *      a) OHD Air unit (own sys id)
 *      b) OHD Ground unit (own sys id)
 *      c) Optional FC connected to the air unit
 */
class MavlinkTelemetry : public QObject
{
    Q_OBJECT
public:
    MavlinkTelemetry(QObject *parent = nullptr);
    ~MavlinkTelemetry();
    static MavlinkTelemetry& instance();
    void start();
    /**
     * Send a message to the OHD ground unit. If no connection has been established (yet), this should return immediately.
     * The message can be aimed at either the OHD ground unit, the OHD air unit (forwarded by OpenHD) or the FC connected to the
     * OHD air unit (forwarded by OpenHD).
     * @param msg the message to send.
     * @return true on success (this does not mean the message was received, but rather the message was sent out via the lossy connection)
     */
    bool sendMessage(mavlink_message_t msg);
    struct FCMavId{
        int comp_id;
        int sys_id;
    };
    // Returns default FC sys / comp id until FC is successfully discovered.
    FCMavId get_fc_mav_id();
public:
    // ping all the systems (using timesync, since "ping" is deprecated)
    Q_INVOKABLE void ping_all_systems();
    // re-apply all FC telemetry rate(s)
    Q_INVOKABLE void re_apply_rates();
    // Change the conenction mode
    Q_INVOKABLE void change_telemetry_connection_mode(int mode);
    Q_INVOKABLE bool change_manual_tcp_ip(QString ip);
public:
    // A couple of stats exposed as QT properties
    L_RO_PROP(int,telemetry_pps_in,set_telemetry_pps_in,-1)
    L_RO_PROP(int,telemetry_bps_in,set_telemetry_bps_in,-1)
    L_RO_PROP(bool,udp_localhost_mode_enabled,set_udp_localhost_mode_enabled,true)
    //
    L_RO_PROP(QString,telemetry_connection_status,set_telemetry_connection_status,"N/A");

private:
    // We follow the same practice as QGrouncontroll: Listen for incoming data on a specific UDP port,
    // -> as soon as we got the first packet, we know the address to send data to for bidirectional communication
    static constexpr auto QOPENHD_GROUND_CLIENT_UDP_PORT_IN=14550;
    static constexpr auto QOPENHD_OPENHD_GROUND_TCP_SERVER_PORT=5760;
    // Called every time we get a mavlink message (from any system).
    void process_mavlink_message(const mavlink_message_t& msg);
    void process_broadcast_message_openhd_air(const mavlink_message_t& msg);
    void process_broadcast_message_openhd_gnd(const mavlink_message_t& msg);
    void process_broadcast_message_fc(const mavlink_message_t& msg);
    // timesync is handled extra independently
    void process_message_timesync(const mavlink_message_t &msg);
private:
    std::unique_ptr<UDPConnection> m_udp_connection=nullptr;
    std::unique_ptr<TCPConnection> m_tcp_connection=nullptr;
    int64_t m_last_timesync_out_us=0;
    bool m_fc_found=false;
    int m_fc_sys_id=-1;
    int m_fc_comp_id=-1;
    // For calculating input pps / bps
    int64_t m_tele_received_bytes=0;
    int64_t m_tele_received_packets=0;
    BitrateCalculator2 m_tele_bitrate_in;
    PacketsPerSecondCalculator m_tele_pps_in;
    std::unique_ptr<std::thread> m_heartbeat_thread;
    std::atomic_bool m_heartbeat_thread_run;
    std::atomic<int> m_connection_mode;
    std::shared_ptr<std::string> m_connction_manual_tcp_ip;
    void send_heartbeat_loop();
    void perform_connection_management();
};

#endif // OHDMAVLINKCONNECTION_H
