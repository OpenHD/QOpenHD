#ifndef SynchronizedSettings_H
#define SynchronizedSettings_H

#include <QObject>
#include <qsettings.h>
#include "../../../lib/lqtutils_master/lqtutils_prop.h"
#include "param_names.h"
#include "../requestmessagehelper.h"

// Helper for settings that MUST STAY IN SYNC on the ground and air pi, since otherwise the wifibroadcast link is lost
// and the user needs to manually recover the link
// It does not fix the 2 general's problem (this is a unfixable problem) but it makes it really unlikely to happen.
// TODO: I think for these 3 (only) parameters that need to be kept in sync in evo, we should find a better way
// (e.g. exposing the param only on the ground, and having a more advanced wifibroadcast imlementation that establishes a connection/
// handles frequency changes itself)
class SynchronizedSettings : public QObject
{
    Q_OBJECT
public:
    explicit SynchronizedSettings(QObject *parent = nullptr);

    static SynchronizedSettings& instance();

    // These are also in aohdsystem, their usage (and correct setting of them) is required here, too
    L_RO_PROP(int,curr_channel_mhz,set_curr_channel_mhz,-1)
    L_RO_PROP(int,curr_channel_width_mhz,set_curr_channel_width_mhz,-1);

    // Set to true once the channels from the ground have been succesfully fetched
    L_RO_PROP(bool,has_fetched_channels,set_has_fetched_channels,false);
public:
    Q_INVOKABLE void fetch_channels_if_needed();

    Q_INVOKABLE void xx_tmp();
public:
    void validate_and_set_channel_mhz(int channel);
    void validate_and_set_channel_width_mhz(int channel_width_mhz);

    static constexpr auto PARAM_ID_WB_FREQ=openhd::WB_FREQUENCY;
    static constexpr auto PARAM_ID_WB_CHANNEL_WIDTH=openhd::WB_CHANNEL_WIDTH;
    static constexpr auto PARAM_ID_WB_MCS_INDEX=openhd::WB_MCS_INDEX;

    // Air and ground should always match, otherwise something weird has happenened.
    // Note that this would be "really" weird, since on not matching params there should be no connectivitiy.
    Q_INVOKABLE int get_param_int_air_and_ground_value(QString param_id);
    Q_INVOKABLE int get_param_int_air_and_ground_value_freq(){
        return get_param_int_air_and_ground_value(PARAM_ID_WB_FREQ);
    }
    Q_INVOKABLE int get_param_int_air_and_ground_value_channel_width(){
        return get_param_int_air_and_ground_value(PARAM_ID_WB_CHANNEL_WIDTH);
    }

    void change_param_air_and_ground(QString param_id,int value,bool allow_changing_without_connected_air_unit,bool log_to_hud=false);

    Q_INVOKABLE void change_param_air_and_ground_frequency(int value){
        QSettings settings;
        const bool qopenhd_allow_changing_ground_unit_frequency_no_sync = settings.value("qopenhd_allow_changing_ground_unit_frequency_no_sync",false).toBool();
        change_param_air_and_ground(PARAM_ID_WB_FREQ,value,qopenhd_allow_changing_ground_unit_frequency_no_sync);
    }

    Q_INVOKABLE void change_param_air_and_ground_channel_width(int value,bool log_to_hud=false){
        QSettings settings;
        const bool qopenhd_allow_changing_ground_unit_channel_width_no_sync = settings.value("qopenhd_allow_changing_ground_unit_channel_width_no_sync",false).toBool();
        change_param_air_and_ground(PARAM_ID_WB_CHANNEL_WIDTH,value,qopenhd_allow_changing_ground_unit_channel_width_no_sync,log_to_hud);
    }

    //
    Q_INVOKABLE int get_next_frequency_item(int index);
    Q_INVOKABLE QString get_next_frequency_item_description();
private:
    void log_result_message(const std::string& result_message,bool use_hud);
private:
    std::unique_ptr<RequestMessageHelper> m_request_message_helper;
    std::vector<uint16_t> m_supported_channels;
    void update_channels_on_success();
};

#endif // SynchronizedSettings_H
