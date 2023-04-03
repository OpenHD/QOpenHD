#include "camerastreammodel.h"
#include "qdebug.h"
#include "telemetryutil.hpp"
#include "util/WorkaroundMessageBox.h"

#include <qsettings.h>

#include <logging/hudlogmessagesmodel.h>
#include <logging/logmessagesmodel.h>

static std::string video_codec_to_string(int value){
    if(value==0)return "h264";
    if(value==1)return "h265";
    if(value==2)return "mjpeg";
    return "Unknown";
}

CameraStreamModel::CameraStreamModel(int m_camera_index,QObject *parent)
    : QObject{parent},
      m_camera_index(m_camera_index)
{

}

CameraStreamModel &CameraStreamModel::instance(int cam_index)
{
    if(cam_index==0){
        static CameraStreamModel instancePrimary{0};
        return instancePrimary;
    }else if(cam_index==1){
        static CameraStreamModel instanceSecondary{1};
        return instanceSecondary;
    }
    assert(false);
}

void CameraStreamModel::dirty_set_curr_set_video_codec_int(int value)
{
    auto tmp=video_codec_to_string(value);
    set_curr_set_video_codec(tmp.c_str());
}

void CameraStreamModel::dirty_set_curr_set_video_codec_for_cam(int cam_index, int video_codec_in_openhd)
{
    if(cam_index==0){
        CameraStreamModel::instance(0).dirty_set_curr_set_video_codec_int(video_codec_in_openhd);
        if(video_codec_in_openhd==0 || video_codec_in_openhd==1 || video_codec_in_openhd==2){
            QSettings settings;
            const int tmp_video_codec = settings.value("selectedVideoCodecPrimary", 0).toInt();
            if(tmp_video_codec!=video_codec_in_openhd){
                // video codec mismatch, update the QOpenHD settings
                settings.setValue("selectedVideoCodecPrimary",video_codec_in_openhd);
                qDebug()<<"Changed electedVideoCodecPrimary in QOpenHD to "<<video_codec_in_openhd;
                workaround::makePopupMessage("Changed VideoCodec Primary in QOpenHD");
            }
        }
    }else if(cam_index==1){
        CameraStreamModel::instance(1).dirty_set_curr_set_video_codec_int(video_codec_in_openhd);
       if(video_codec_in_openhd==0 || video_codec_in_openhd==1 || video_codec_in_openhd==2){
           QSettings settings;
           const int tmp_video_codec = settings.value("selectedVideoCodecSecondary", 0).toInt();
           if(tmp_video_codec!=video_codec_in_openhd){
               // video codec mismatch, update the QOpenHD settings
               settings.setValue("selectedVideoCodecSecondary",video_codec_in_openhd);
               qDebug()<<"Changed selectedVideoCodecSecondary in QOpenHD to "<<video_codec_in_openhd;
               workaround::makePopupMessage("Changed VideoCodec Secondary in QOpenHD");
           }
       }
    }else{
        qWarning("Invalid cam index");
    }
}

void CameraStreamModel::update_mavlink_openhd_stats_wb_video_air(const mavlink_openhd_stats_wb_video_air_t &msg)
{
    const auto curr_recommended_bitrate_kbits=msg.curr_recommended_bitrate;
    set_curr_recommended_bitrate_from_message(curr_recommended_bitrate_kbits);
    set_curr_video_measured_encoder_bitrate(Telemetryutil::bitrate_bps_to_qstring(msg.curr_measured_encoder_bitrate));
    set_curr_video_injected_bitrate(Telemetryutil::bitrate_bps_to_qstring(msg.curr_injected_bitrate));
    set_curr_video0_injected_pps(Telemetryutil::pps_to_string(msg.curr_injected_pps));
    set_curr_video0_dropped_packets(msg.curr_dropped_packets);
    set_curr_video0_fec_encode_time_avg_min_max(
                Telemetryutil::us_min_max_avg_to_string(msg.curr_fec_encode_time_min_us,msg.curr_fec_encode_time_max_us,msg.curr_fec_encode_time_avg_us));
    set_curr_video0_fec_block_length_min_max_avg(
                Telemetryutil::min_max_avg_to_string(msg.curr_fec_block_size_min,msg.curr_fec_block_size_max,msg.curr_fec_block_size_avg));
    const auto delta_kbits=std::abs(msg.curr_recommended_bitrate-(msg.curr_measured_encoder_bitrate/1000));
    if(delta_kbits>1*1000){
        //qDebug()<<"Diff:"<<delta_kbits;
        // Set and measured bitrate are more than 1MBit/s apart
        set_curr_set_and_measured_bitrate_mismatch(true);
        if(m_n_mismatch_has_been_logged<10){
            LogMessagesModel::instanceOHD().add_message_warn("CAM","Set/ Measured encoder bitrate mismatch");
            m_n_mismatch_has_been_logged++;
        }
    }else{
        set_curr_set_and_measured_bitrate_mismatch(false);
    }
}

void CameraStreamModel::update_mavlink_openhd_stats_wb_video_ground(const mavlink_openhd_stats_wb_video_ground_t &msg)
{
    set_curr_video0_received_bitrate_with_fec(Telemetryutil::bitrate_bps_to_qstring(msg.curr_incoming_bitrate));
    set_video0_count_blocks_lost(msg.count_blocks_lost);
    set_video0_count_blocks_recovered(msg.count_blocks_recovered);
    set_video0_count_fragments_recovered(msg.count_fragments_recovered);
    set_video0_count_blocks_total(msg.count_blocks_total);
    set_curr_video0_fec_decode_time_avg_min_max(
                Telemetryutil::us_min_max_avg_to_string(msg.curr_fec_decode_time_min_us,msg.curr_fec_decode_time_max_us,msg.curr_fec_decode_time_avg_us));
}

void CameraStreamModel::set_curr_recommended_bitrate_from_message(const int64_t curr_recommended_bitrate_kbits)
{
    // We use the fact that the current recommended bitrate is updated regularily to notify the user of
    // changing rate(s) during flight
    if(m_curr_recomended_video_bitrate_kbits!= 0 && curr_recommended_bitrate_kbits!=0 && m_curr_recomended_video_bitrate_kbits != curr_recommended_bitrate_kbits){
        QString message=m_camera_index==0 ? "Cam1 encoder:" : "Cam2 encoder:";
        message+=Telemetryutil::bitrate_kbits_to_qstring(curr_recommended_bitrate_kbits);
        HUDLogMessagesModel::instance().add_message_info(message);
    }
    set_curr_recomended_video_bitrate_kbits(curr_recommended_bitrate_kbits);
    if(curr_recommended_bitrate_kbits>0){
        set_curr_recomended_video_bitrate_string(Telemetryutil::bitrate_kbits_to_qstring(curr_recommended_bitrate_kbits));
    }else{
        set_curr_recomended_video_bitrate_string("N/A");
    }
}
