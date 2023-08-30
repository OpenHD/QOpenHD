#ifndef OHDACTION_H
#define OHDACTION_H

#include <QObject>

/**
 * @brief This is the only class (other than param /settings) where one can talk to the OpenHD air / ground unit.
 * THE REST IS BROADCAST !
 */
class OHDAction : public QObject
{
    Q_OBJECT
public:
    explicit OHDAction(QObject *parent = nullptr);

    static OHDAction& instance();
public:
    // request the OpenHD version, both OpenHD air and ground unit will respond to that message.
    Q_INVOKABLE void request_openhd_version_async();
    // send the reboot / shutdown command to openhd air or ground unit
    // @param system_id: 0 for ground, 1 for air, 2 for FC
    Q_INVOKABLE bool send_command_reboot_air(bool reboot);
    Q_INVOKABLE bool send_command_reboot_gnd(bool reboot);


    bool send_command_analyze_channels_blocking();
    bool send_command_start_scan_channels_blocking(int freq_bands,int channel_widths);
private:
};

#endif // OHDACTION_H
