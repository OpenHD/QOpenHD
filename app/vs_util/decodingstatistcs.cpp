#include "decodingstatistcs.h"

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
    set_estimate_keyframe_interval(-1);
    set_n_decoder_dropped_frames(-1);
}

