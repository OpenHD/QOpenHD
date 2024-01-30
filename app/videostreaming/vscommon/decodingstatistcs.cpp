#include "decodingstatistcs.h"
#include <sstream>

DecodingStatistcs::DecodingStatistcs(QObject *parent)
    : QObject{parent}
{

}

DecodingStatistcs& DecodingStatistcs::instance()
{
    static DecodingStatistcs stats{};
    return stats;
}

void DecodingStatistcs::reset_all_to_default()
{
    set_parse_and_enqueue_time("?");
    set_decode_and_render_time("?");
    set_n_renderer_dropped_frames(-1);
    set_udp_rx_bitrate(-1);
    set_doing_wait_for_frame_decode("?");
    set_primary_stream_frame_format("?");
    set_decoding_type("?");
    set_n_missing_rtp_video_packets(-1);
    set_rtp_measured_bitrate("-1");
    set_estimate_rtp_fps("-1");
    set_estimate_keyframe_interval("N/A");
    set_n_decoder_dropped_frames(-1);
}

void DecodingStatistcs::util_set_primary_stream_frame_format(std::string format, int width_px, int height_px)
{
    std::stringstream ss;
    ss<<format<<" "<<width_px<<"x"<<height_px;
    set_primary_stream_frame_format(ss.str().c_str());
}

void DecodingStatistcs::util_set_estimate_keyframe_interval_int(int value)
{
    std::stringstream ss;
    ss<<value;
    set_estimate_keyframe_interval(ss.str().c_str());
}

