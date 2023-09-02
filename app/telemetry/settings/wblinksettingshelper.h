#ifndef SynchronizedSettings_H
#define SynchronizedSettings_H

#include <QObject>
#include <qsettings.h>
#include "../../../lib/lqtutils_master/lqtutils_prop.h"
#include "param_names.h"

#include <optional>

#include "../util/mavlink_include.h"


// DON'T ASK, THIS CLASS IS HUGE AND REALLY HARD TO DESCRIBE
// Helper for settings that MUST STAY IN SYNC on the ground and air pi, since otherwise the wifibroadcast link is lost
// and the user needs to manually recover the link
// It does not fix the 2 general's problem (this is a unfixable problem) but it makes it really unlikely to happen.
// TODO: I think for these 3 (only) parameters that need to be kept in sync in evo, we should find a better way
// (e.g. exposing the param only on the ground, and having a more advanced wifibroadcast imlementation that establishes a connection/
// handles frequency changes itself)
class WBLinkSettingsHelper : public QObject
{
    Q_OBJECT
public:
    explicit WBLinkSettingsHelper(QObject *parent = nullptr);

    static WBLinkSettingsHelper& instance();

    // FLOW: Invalid until first message announcing channel frequency and width is received from the ground
    // When we receive this type of message from the ground, we start requesting the supported frequencies from the ground unit
    // (until successfully requested)
    // Then we know the current frequency, channel width and which channels the ground is capable of -
    // and are ready to populate the choices for the user.
    // Whenever we want to change one of those params, we first try changing it on the air unit
    // (Air unit will reject if it is not capable of the given frequency)
    // and on success, we change the ground unit frequency. Since one can only select frequencies the ground unit supports,
    // this should nevver fail.


    // These are also in aohdsystem, their usage (and correct setting of them) is required here, too
    L_RO_PROP(int,curr_channel_mhz,set_curr_channel_mhz,-1)
    L_RO_PROP(int,curr_channel_width_mhz,set_curr_channel_width_mhz,-1);

    // Set to true once the channels from the ground have been succesfully fetched
    //L_RO_PROP(bool,has_fetched_channels,set_has_fetched_channels,false);
    // Dirty
    L_RO_PROP(int,progress_scan_channels_perc,set_progress_scan_channels_perc,-1);
    L_RO_PROP(int,progress_analyze_channels_perc,set_progress_analyze_channels_perc,-1);
    L_RO_PROP(QString,text_for_qml,set_text_for_qml,"NONE");
    // Dirty, incremented to signal to the UI that it should rebuild the model(s)
    L_RO_PROP(int,ui_rebuild_models,set_ui_rebuild_models,0)
public:
    void process_message_openhd_wifibroadcast_supported_channels(const mavlink_openhd_wifbroadcast_supported_channels_t& msg);
    void process_message_openhd_wifibroadcast_analyze_channels_progress(const mavlink_openhd_wifbroadcast_analyze_channels_progress_t& msg);
    void process_message_openhd_wifibroadcast_scan_channels_progress(const mavlink_openhd_wifbroadcast_scan_channels_progress_t& msg);
    void validate_and_set_channel_mhz(int channel);
    void validate_and_set_channel_width_mhz(int channel_width_mhz);
public:
    //Q_INVOKABLE void fetch_channels_if_needed();
    Q_INVOKABLE bool start_analyze_channels();
    // freq_bands:
    // 0: 2.4G and 5.8G
    // 1: 2.4G only
    // 2: 5.8G only
    // similar for channel widths
    Q_INVOKABLE bool start_scan_channels(int freq_bands,int channel_widths);
private:
    static constexpr auto PARAM_ID_WB_FREQ=openhd::WB_FREQUENCY;
    static constexpr auto PARAM_ID_WB_CHANNEL_WIDTH=openhd::WB_CHANNEL_WIDTH;
    // Air and ground should always match, otherwise something weird has happenened.
    // Note that this would be "really" weird, since on not matching params there should be no connectivitiy.
    int get_param_int_air_and_ground_value(QString param_id);
    // Returns 0 on success, error code otherwise.
    // Viable error code(s):
    // -1 : gnd unit not alive
    // -2 : gnd unit alive, but air unit not alive
    // -3 : cannot set value on air - not reachable
    // -4 : cannot set value on air - reached, but param was rejected
    // -5 : succesfully set value on air, but ground doesn't support - really bad
    int change_param_air_and_ground(QString param_id,int value);
    bool change_param_ground_only(QString param_id,int value);
public:

    Q_INVOKABLE int change_param_air_and_ground_frequency(int value){
        return change_param_air_and_ground(PARAM_ID_WB_FREQ,value);
    }

    Q_INVOKABLE int change_param_air_and_ground_channel_width(int value){
        return change_param_air_and_ground(PARAM_ID_WB_CHANNEL_WIDTH,value);
    }

    Q_INVOKABLE bool change_param_ground_only_frequency(int value){
        return change_param_ground_only(PARAM_ID_WB_FREQ,value);
    }
    Q_INVOKABLE bool change_param_ground_only_channel_width(int value){
        return change_param_ground_only(PARAM_ID_WB_CHANNEL_WIDTH,value);
    }
    Q_INVOKABLE int get_next_supported_frequency(int index);
    Q_INVOKABLE QString get_frequency_description(int frequency_mhz);
    Q_INVOKABLE int get_frequency_pollution(int frequency_mhz);
    // These params can be changed "on the fly" and are additionally their value(s) are broadcasted

private:
    void log_result_message(const std::string& result_message,bool use_hud);
private:
    std::vector<uint16_t> m_supported_channels;
    void update_channels_on_success();
    bool m_valid_channel_channel_width_once=false;
private:
    struct PollutionElement{
        int frequency_mhz;
        int width_mhz;
        int n_foreign_packets;
    };
    std::vector<PollutionElement> m_pollution_elements;
    void update_pollution(int frequency,int n_foreign_packets);
    std::optional<PollutionElement> get_pollution_for_frequency_channel_width(int frequency,int width);
private:
    std::atomic<bool> m_has_valid_ground_channel_data=false;
    void signal_ui_rebuild_model_when_possible();
};

#endif // SynchronizedSettings_H
