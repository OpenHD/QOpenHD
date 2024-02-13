#ifndef AIRCAMERAMODEL_H
#define AIRCAMERAMODEL_H

#include <QObject>

#include "../util/mavlink_include.h"

#include "../../../lib/lqtutils_master/lqtutils_prop.h"

// NOTE1: This class exists to avoid duplicated code for primary and secondary camera(stream)-stats displayed in the HUD
// NOTE2: Here we have only stats for one camera / camera stream that are transmitted via lossy
// telemetry messages, aka in regular intervalls.
// NOTE3: Camera settings or similar you won't find here, and it is also discouraged to use the data here
// for anything else than display-only HUD elements. See MavlinkSettingsModel and instanceAirCamera();
// This model can be viewed as an "extension" of AOHDSystem, it is also updated from there
class CameraStreamModel : public QObject
{
    Q_OBJECT
public:
    explicit CameraStreamModel(int m_camera_index,QObject *parent = nullptr);
    const int m_camera_index;
    static CameraStreamModel& instance(int cam_index);
public:
    L_RO_PROP(QString,xx_cam_type,set_xx_cam_type,"ARDUCAM SKYMASTER HDR")
    L_RO_PROP(QString,xx_cam_status,set_xx_cam_status,"OK")

    // Width x height @ fps for a camera
    L_RO_PROP(QString,curr_set_video_format,set_curr_set_video_format,"")
    // Width x height @ fps and codec for camera
    L_RO_PROP(QString,curr_set_video_format_and_codec,set_curr_set_video_format_and_codec,"N/A")
    //
    // The following stats are kinda camera related, kinda wb link related
    // They area also only generated by OpenHD air unit.
    // Regarding encoder recommended video bitrate: This value is broadcasted in regular intervals by the openhd air unit,
    // If variable bitrate is disabled, it is the value set by the mavlink parameter (duplicate) but if variable bitrate is enabled,
    // it is the value the openhd air unit currently recommends to the encoder
    L_RO_PROP(QString,curr_recomended_video_bitrate_string,set_curr_recomended_video_bitrate_string,"N/A")
    L_RO_PROP(int,curr_recomended_video_bitrate_kbits,set_curr_recomended_video_bitrate_kbits,0)
    L_RO_PROP(QString,curr_video_measured_encoder_bitrate,set_curr_video_measured_encoder_bitrate,"N/A")
    L_RO_PROP(QString,curr_video_injected_bitrate,set_curr_video_injected_bitrate,"N/A") //includes FEC overhead
    L_RO_PROP(QString,curr_video_injected_pps,set_curr_video_injected_pps,"-1pps") //includes FEC overhead
    // total n of frames that were dropped on the tx (hints at too high bitrate)
    L_RO_PROP(int,total_n_tx_dropped_frames,set_total_n_tx_dropped_frames,0)
    // calculated in fixed X second interval(s) - n of tx frames dropped during this interval
    L_RO_PROP(int,curr_delta_tx_dropped_frames,set_curr_delta_tx_dropped_frames,0)
    // DEV stats
    L_RO_PROP(QString,curr_fec_encode_time_avg_min_max,set_curr_fec_encode_time_avg_min_max,"avg na, min na, max na")
    L_RO_PROP(QString,curr_fec_block_length_min_max_avg,set_curr_fec_block_length_min_max_avg,"avg na, min na, max na")
    L_RO_PROP(QString,curr_time_until_tx_min_max_avg,set_curr_time_until_tx_min_max_avg,"avg na, min na, max na")
    // Used to show the user a visual indication that the set and measured encoder bitrate are far apart
    // 0 - all okay, 1= bitrate is too low (yellow), 2= bitrate is too high (red)
    L_RO_PROP(int,curr_set_and_measured_bitrate_mismatch,set_curr_set_and_measured_bitrate_mismatch,0)
    //
    L_RO_PROP(int,curr_fec_percentage,set_curr_curr_fec_percentage,-1)
    L_RO_PROP(int,curr_keyframe_interval,set_curr_curr_keyframe_interval,-1)
    L_RO_PROP(bool,air_recording_active,set_air_recording_active,false)
    L_RO_PROP(QString,air_tx_packets_per_second_and_bits_per_second,set_air_tx_packets_per_second_and_bits_per_second,"N/A")
    // UI might change slightly depending on the camera type
    L_RO_PROP(int,camera_type,set_camera_type,-1)
    L_RO_PROP(int,camera_status,set_camera_status,-1)
    L_RO_PROP(int,encoding_codec,set_encoding_codec,-1)
    //
    // These are generated by the OpenHD ground unit
    //
    L_RO_PROP(QString,curr_received_bitrate_with_fec,set_curr_received_bitrate_with_fec,"N/A")
    L_RO_PROP(qint64,count_blocks_total,set_count_blocks_total,-1)
    L_RO_PROP(qint64,count_blocks_lost,set_count_blocks_lost,-1)
    L_RO_PROP(qint64,count_blocks_recovered,set_count_blocks_recovered,-1)
    L_RO_PROP(qint64,count_fragments_recovered,set_count_fragments_recovered,-1)
    L_RO_PROP(QString,curr_fec_decode_time_avg_min_max,set_curr_fec_decode_time_avg_min_max,"avg na, min na, max na")
public:
    Q_INVOKABLE QString camera_type_to_string(int camera_type);
    Q_INVOKABLE QString camera_status_to_string(int camera_status);
    Q_INVOKABLE QString camera_codec_to_string(int camera_codec);
    Q_INVOKABLE QString camera_recording_mode_to_string(int recording_mode);
    Q_INVOKABLE bool is_valid_resolution_fps_string(QString input);
    Q_INVOKABLE QString get_default_resolution();
    Q_INVOKABLE QStringList get_supported_resolutions();
    //
public:
    // generated by wb / link
    void update_mavlink_openhd_stats_wb_video_air(const mavlink_openhd_stats_wb_video_air_t &msg);
    void update_mavlink_openhd_stats_wb_video_air_fec_performance(const mavlink_openhd_stats_wb_video_air_fec_performance_t &msg);
    void update_mavlink_openhd_stats_wb_video_ground(const mavlink_openhd_stats_wb_video_ground_t &msg);
    void update_mavlink_openhd_stats_wb_video_ground_fec_performance(const mavlink_openhd_stats_wb_video_ground_fec_performance_t &msg);
    // generated by the camera
    void update_mavlink_openhd_camera_status_air(const mavlink_openhd_camera_status_air_t & msg);
private:
    // We use the fact that the current recommended bitrate is updated regularily to notify the user of
    // changing rate(s) during flight
    void set_curr_recommended_bitrate_from_message(int64_t curr_recommended_bitrate_kbits);
    // Do not completely pollute the Log messages model
    int m_n_mismatch_has_been_logged=0;
    // FEAUTURE - Re-start decoding if resolution / framerate of a camera has changed
    struct ResolutionFramerate{
        int width=-1;
        int height=-1;
        int framerate=-1;
        bool operator==(const ResolutionFramerate &o) const {
            return this->framerate==o.framerate && this->width==o.width && this->height==o.height;
        }
        bool operator !=(const ResolutionFramerate &o) const {
            return !(*this==o);
        }
        bool is_any_invalid()const{
            return (width==-1 || width==0 ||
                   height==-1 || height==0 ||
                    framerate==-1 || framerate==0);
        }
    };
    static std::string resolution_framerate_to_string(const ResolutionFramerate& data);
    ResolutionFramerate m_curr_res_framerate{};
    std::chrono::steady_clock::time_point m_last_hud_message_camera_status=std::chrono::steady_clock::now();
private:
    std::chrono::steady_clock::time_point m_last_tx_frame_drop_calculation=std::chrono::steady_clock::now();
    int m_last_tx_frame_drop_calculation_count=-1;
};

#endif // AIRCAMERAMODEL_H
