import QtQuick 2.0

Item {
    width: 200
    height: 200
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.topMargin: 100
    visible: settings.show_dev_stats_overlay && !sidebar.m_extra_is_visible && settings.show_widgets

    Column{
        width: parent.width
        anchors.left: parent.left
        anchors.top: parent.top
        DevStreamingInfoText{
            m_left_text: qsTr("Drop TX:")
            m_right_text: _cameraStreamModelPrimary.total_n_tx_dropped_frames
        }
        DevStreamingInfoText{
            m_left_text: qsTr("Drop RX:")
            m_right_text: _cameraStreamModelPrimary.count_blocks_lost
        }
        DevStreamingInfoText{
            m_left_text: qsTr("BLKS L/R:")
            m_right_text: _cameraStreamModelPrimary.count_blocks_lost+" "+_cameraStreamModelPrimary.count_blocks_recovered
        }
        DevStreamingInfoText{
            m_left_text: qsTr("TX Delay:")
            m_right_text: _cameraStreamModelPrimary.curr_time_until_tx_min_max_avg
        }
        DevStreamingInfoText{
            m_left_text: qsTr("FEC Enc:")
             m_right_text: _cameraStreamModelPrimary.curr_fec_encode_time_avg_min_max
        }
        DevStreamingInfoText{
            m_left_text: qsTr("FEC BL:");
            m_right_text: _cameraStreamModelPrimary.curr_fec_block_length_min_max_avg
        }
        DevStreamingInfoText{
            m_left_text: qsTr("B SET:")
            m_right_text: _cameraStreamModelPrimary.curr_recomended_video_bitrate_string
        }
        DevStreamingInfoText{
            m_left_text: qsTr("B MES:")
            m_right_text: _cameraStreamModelPrimary.curr_video_measured_encoder_bitrate
        }
        DevStreamingInfoText{
            m_left_text: qsTr("B+FEC:")
            m_right_text: _cameraStreamModelPrimary.curr_video_injected_bitrate
        }
        DevStreamingInfoText{
            m_left_text: qsTr("FEC D:")
            m_right_text: _cameraStreamModelPrimary.curr_fec_decode_time_avg_min_max
        }
    }

}
