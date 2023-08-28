#ifndef FCACTION_H
#define FCACTION_H

#include <QObject>

#include "../util/mavsdk_include.h"

/**
 * This is the one and only class from which messages / actions can be sent to the FC.
 * In general, sending messages to the FC should avoided - a broacast pattern is usually sueficient and preferred in QOpenHD.
 */
class FCAction : public QObject
{
    Q_OBJECT
public:
    explicit FCAction(QObject *parent = nullptr);
    static FCAction& instance();

    // Set the mavlink system reference, once discovered.
    // NOTE: We only use the system to get broadcast message(s) (pass_through) and a few more things
    void set_system(std::shared_ptr<mavsdk::System> system);
public:
    // WARNING: Do not call any non-async send command methods from the same thread that is parsing the mavlink messages !
    //
    // Try to change the arming state.
    // The result (success/failure) is logged in the HUD once completed
    Q_INVOKABLE void arm_fc_async(bool arm=false);

    // return true on success, false otherwise
    Q_INVOKABLE bool enable_disable_mission_updates(bool enable);

    // Sends a command to change the flight mode. Note that this is more complicated than it sounds at first,
    // since copter and plane for example do have different flight mode enums.
    // For RTL (which is really important) we have a extra impl. just to be sure
    Q_INVOKABLE void flight_mode_cmd(long cmd_msg);
    // Some FC stop sending home position when armed, re-request the home position
    Q_INVOKABLE void request_home_position_from_fc();
private:
    // NOTE: Null until system discovered
    std::shared_ptr<mavsdk::System> m_system=nullptr;
    std::shared_ptr<mavsdk::Action> m_action=nullptr;
    // We got rid of this submodule for a good reason (see above)
    //std::shared_ptr<mavsdk::Telemetry> _mavsdk_telemetry=nullptr;
    std::shared_ptr<mavsdk::MavlinkPassthrough> m_pass_thru=nullptr;
    // TODO: figure out if we shall use mission plugin (compatible with ardupilot) or not
    // R.N: must be manually enabled by the user to save resources
    std::shared_ptr<mavsdk::Mission> m_mission=nullptr;
};

#endif // FCACTION_H
