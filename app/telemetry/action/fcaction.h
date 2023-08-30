#ifndef FCACTION_H
#define FCACTION_H

#include <QObject>
#include <mutex>

#include "../util/mavlink_include.h"

/**
 * This is the one and only class from which messages / actions can be sent to the FC.
 * THE REST IS BROADCAST !
 */
class FCAction : public QObject
{
    Q_OBJECT
public:
    explicit FCAction(QObject *parent = nullptr);
    static FCAction& instance();

    // Set the mavlink system sys/comp id, once discovered.
    void set_fc_sys_id(int fc_sys_id,int fc_comp_id);
public:
    // WARNING: Do not call any non-async send command methods from the same thread that is parsing the mavlink messages !
    //
    // Try to change the arming state.
    // The result (success/failure) is logged in the HUD once completed
    Q_INVOKABLE void arm_fc_async(bool arm=false);

    // Sends a command to change the flight mode. Note that this is more complicated than it sounds at first,
    // since copter and plane for example do have different flight mode enums.
    // This function is async to not block the calling UI - the result is logged to the HUDLogMessageModel
    // also, this method only allows one flight mode change queued up at a time
    Q_INVOKABLE void flight_mode_cmd_async(long cmd_msg);

    // Some FC stop sending home position when armed, re-request the home position
    Q_INVOKABLE void request_home_position_from_fc();

    Q_INVOKABLE bool send_command_reboot(bool reboot);
private:
    int m_fc_sys_id=1;
    int m_fc_comp_id=MAV_COMP_ID_AUTOPILOT1;
    std::atomic<bool> m_has_currently_runnning_flight_mode_change=false;
};

#endif // FCACTION_H
