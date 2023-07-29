#ifndef SynchronizedSettings_H
#define SynchronizedSettings_H

#include <QObject>
#include <qsettings.h>
#include "../../../lib/lqtutils_master/lqtutils_prop.h"
#include "param_names.h"

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

    void change_param_air_and_ground(QString param_id,int value,bool allow_changing_without_connected_air_unit);

    Q_INVOKABLE void change_param_air_and_ground_frequency(int value){
        QSettings settings;
        const bool qopenhd_allow_changing_ground_unit_frequency_no_sync = settings.value("qopenhd_allow_changing_ground_unit_frequency_no_sync",false).toBool();
        change_param_air_and_ground(PARAM_ID_WB_FREQ,value,qopenhd_allow_changing_ground_unit_frequency_no_sync);
    }

    Q_INVOKABLE void change_param_air_and_ground_channel_width(int value){
        QSettings settings;
        const bool qopenhd_allow_changing_ground_unit_channel_width_no_sync = settings.value("qopenhd_allow_changing_ground_unit_channel_width_no_sync",false).toBool();
        change_param_air_and_ground(PARAM_ID_WB_CHANNEL_WIDTH,value,qopenhd_allow_changing_ground_unit_channel_width_no_sync);
    }
    // MCS index does not need to match - 2.3.3 and upwards uses the lowest mcs index possible for uplink, and
    // allows changing the MCS index of the downlink (e.g. the mcs index used for injecting packets on the air unit)
    // @param use_hud: when true, errors are logged to the HUD, otherwise, they are logged via a message popup
    Q_INVOKABLE void change_param_air_only_mcs(int value,bool use_hud);
    Q_INVOKABLE int get_param_int_air_only_mcs();
private:
    void log_result_message(const std::string& result_message,bool use_hud);
};

#endif // SynchronizedSettings_H
