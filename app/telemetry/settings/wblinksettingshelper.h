#ifndef SynchronizedSettings_H
#define SynchronizedSettings_H

#include <QObject>
#include <qsettings.h>
#include "../../../lib/lqtutils_master/lqtutils_prop.h"
#include "param_names.h"

#include <mutex>
#include <optional>

#include "../util/mavlink_include.h"
#include "util/openhd_defines.hpp"


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
    L_RO_PROP(int,curr_air_channel_width_mhz,set_curr_air_channel_width_mhz,-1);
    // Dirty, incremented to signal to the UI that it should rebuild the model(s)
    L_RO_PROP(int,ui_rebuild_models,set_ui_rebuild_models,0)
    // Scanning
    L_RO_PROP(QString,scanning_text_for_ui,set_scanning_text_for_ui,"NONE");
    L_RO_PROP(int,scan_progress_perc,set_scan_progress_perc,0)
    // Analyzing
    L_RO_PROP(int,analyze_progress_perc,set_analyze_progress_perc,0)
public:
    void process_message_openhd_wifibroadcast_supported_channels(const mavlink_openhd_wifbroadcast_supported_channels_t& msg);
    void process_message_openhd_wifibroadcast_analyze_channels_progress(const mavlink_openhd_wifbroadcast_analyze_channels_progress_t& msg);
    void process_message_openhd_wifibroadcast_scan_channels_progress(const mavlink_openhd_wifbroadcast_scan_channels_progress_t& msg);
    void validate_and_set_gnd_channel_mhz(int channel);
    void validate_and_set_gnd_channel_width_mhz(int channel_width_mhz);
    void validate_and_set_air_channel_width_mhz(int channel_width_mhz);
public:
    Q_INVOKABLE void set_simplify_channels(bool enable);
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
    // Returns 0 on success, error code otherwise.
    // Viable error code(s):
    // -1 : air unit reached, but rejected the value (value unsupported)
    // -2 : air unit not reached
    // -3 : really bad, we changed the value on air, but ground rejected
    int change_param_air_and_ground_blocking(QString param_id,int value);
    bool change_param_ground_only_blocking(QString param_id,int value);
    void change_param_air_async(const int comp_id,const std::string param_id,std::variant<int32_t,std::string> param_value,const std::string tag);
public:
    Q_INVOKABLE int change_param_air_and_ground_frequency(int value){
        return change_param_air_and_ground_blocking(PARAM_ID_WB_FREQ,value);
    }
    //
    // Changing the channel width (bandwidth) is a bit special - read the documentation in openhd
    // wb_link for more info.
    // This method won't return any success / error message, since we update the UI not depending on the result,
    // but what channel width the ground reports via broadcast
    //
    Q_INVOKABLE void change_param_air_channel_width_async(int value,bool log_result);

    Q_INVOKABLE bool change_param_ground_only_frequency(int value){
        return change_param_ground_only_blocking(PARAM_ID_WB_FREQ,value);
    }
    Q_INVOKABLE QList<int> get_supported_frequencies();
    // To not overload the user, we filter the frequencies a bit
    Q_INVOKABLE QList<int> get_supported_frequencies_filtered(int filter_level);
    Q_INVOKABLE QStringList pollution_frequencies_int_to_qstringlist(QList<int> frequencies);
    Q_INVOKABLE QVariantList pollution_frequencies_int_get_pollution(QList<int> frequencies,bool normalize=false);

    Q_INVOKABLE QString get_frequency_description(int frequency_mhz);
    Q_INVOKABLE bool get_frequency_radar(int frequency_mhz);
    Q_INVOKABLE bool get_frequency_simplify(int frequency_mhz);
    Q_INVOKABLE bool get_frequency_reccommended(int frequency_mhz);
    Q_INVOKABLE int get_frequency_openhd_race_band(int frequency_mhz);
    // These params can be changed "on the fly" and are additionally their value(s) are broadcasted
    // so we can update them completely async, log the result to the user
    // and use the broadcasted value(s) to update the UI
    Q_INVOKABLE void set_param_keyframe_interval_async(int keyframe_interval);
    Q_INVOKABLE void set_param_fec_percentage_async(int percent);
    Q_INVOKABLE void set_param_video_resolution_framerate_async(bool primary,QString res_str);
    Q_INVOKABLE void set_param_air_only_mcs_async(int value);
    // Extra
    Q_INVOKABLE bool set_param_tx_power(bool ground,bool is_tx_power_index,bool is_for_armed_state,int value);
    Q_INVOKABLE bool set_param_stbc_ldpc_enable_air_ground();
private:
    struct SupportedChannel{
        uint16_t frequency;
        int n_foreign_packets;
    };
    // Written by telemetry, read by UI
    std::mutex m_supported_channels_mutex;
    std::vector<uint16_t> m_supported_channels;
    bool update_supported_channels(const std::vector<uint16_t> supported_channels);
    bool has_valid_reported_channel_data();
    std::atomic<bool> m_simplify_channels=false;
private:
    void signal_ui_rebuild_model_when_possible();
};

#endif // SynchronizedSettings_H
