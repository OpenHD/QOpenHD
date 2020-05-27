#if defined(ENABLE_VIDEO_RENDER)

#include "openhdvideo.h"

#include "constants.h"

#include <QtConcurrent>
#include <QtQuick>
#include <QUdpSocket>

#include "localmessage.h"

#include "openhd.h"


#include "h264bitstream/h264_stream.h"



OpenHDVideo::OpenHDVideo(enum OpenHDStreamType stream_type): QObject(), m_stream_type(stream_type) {
    qDebug() << "OpenHDVideo::OpenHDVideo()";

    h264_stream = h264_new();

    sps = (uint8_t*)malloc(sizeof(uint8_t)*1024);
    pps = (uint8_t*)malloc(sizeof(uint8_t)*1024);
}

OpenHDVideo::~OpenHDVideo() {
    qDebug() << "~OpenHDVideo()";
}


/*
 * General initialization.
 *
 * Video decoder setup happens in subclasses.
 *
 */
void OpenHDVideo::onStarted() {
    qDebug() << "OpenHDVideo::onStarted()";

    m_socket = new QUdpSocket();

    QSettings settings;

    if (m_stream_type == OpenHDStreamTypeMain) {
        m_video_port = settings.value("main_video_port", 5600).toInt();
    } else {
        m_video_port = settings.value("pip_video_port", 5601).toInt();
    }
    m_enable_rtp = settings.value("enable_rtp", true).toBool();

    lastDataReceived = QDateTime::currentMSecsSinceEpoch();

    m_socket->bind(QHostAddress::Any, m_video_port);

    timer = new QTimer(this);
    QObject::connect(timer, &QTimer::timeout, this, &OpenHDVideo::reconfigure);
    timer->start(1000);

    connect(m_socket, &QUdpSocket::readyRead, this, &OpenHDVideo::processDatagrams);
}



/*
 * Fired by m_timer.
 *
 * This is primarily a way to check for video stalls so the UI layer can take action
 * if necessary, such as hiding the PiP element when the stream has stopped.
 */
void OpenHDVideo::reconfigure() {
    bool restart = false;

    auto currentTime = QDateTime::currentMSecsSinceEpoch();

    if (currentTime - lastDataReceived < 2500) {
        if (m_stream_type == OpenHDStreamTypeMain) {
            OpenHD::instance()->set_main_video_running(true);
        } else {
            OpenHD::instance()->set_pip_video_running(true);
        }
    } else {
        if (m_stream_type == OpenHDStreamTypeMain) {
            OpenHD::instance()->set_main_video_running(false);
        } else {
            OpenHD::instance()->set_pip_video_running(false);
        }
    }

    QSettings settings;

    if (m_stream_type == OpenHDStreamTypeMain) {
        m_video_port = settings.value("main_video_port", 5600).toInt();
    } else {
        m_video_port = settings.value("pip_video_port", 5601).toInt();
    }
    if (m_video_port != m_socket->localPort()) {
        restart = true;
    }

    auto enable_rtp = settings.value("enable_rtp", true).toBool();
    if (m_enable_rtp != enable_rtp) {
        m_enable_rtp = enable_rtp;
        restart = true;
    }

    if (restart) {
        m_socket->close();
        stop();
        tempBuffer.clear();
        rtpBuffer.clear();
        sentSPS = false;
        haveSPS = false;
        sentPPS = false;
        havePPS = false;
        sentIDR = false;
        isStart = true;
        m_socket->bind(QHostAddress::Any, m_video_port);
    }
}

void OpenHDVideo::startVideo() {
#if defined(ENABLE_MAIN_VIDEO) || defined(ENABLE_PIP)
    firstRun = false;
    lastDataReceived = QDateTime::currentMSecsSinceEpoch();
    OpenHD::instance()->set_main_video_running(false);
    OpenHD::instance()->set_pip_video_running(false);
    QFuture<void> future = QtConcurrent::run(this, &OpenHDVideo::start);
#endif
}


void OpenHDVideo::stopVideo() {
#if defined(ENABLE_MAIN_VIDEO) || defined(ENABLE_PIP)
    QFuture<void> future = QtConcurrent::run(this, &OpenHDVideo::stop);
#endif
}


/*
 * Called by QUdpSocket signal readyRead()
 *
 */
void OpenHDVideo::processDatagrams() {
    QByteArray datagram;

    while (m_socket->hasPendingDatagrams()) {
        datagram.resize(int(m_socket->pendingDatagramSize()));
        m_socket->readDatagram(datagram.data(), datagram.size());

        if (m_enable_rtp || m_stream_type == OpenHDStreamTypePiP) {
            parseRTP(datagram);
        } else {
            tempBuffer.append(datagram.data(), datagram.size());
            findNAL();
        }
    }
}



/*
 * Simple RTP parse, just enough to get the frame data
 *
 */
void OpenHDVideo::parseRTP(QByteArray datagram) {
    const uint8_t MINIMUM_HEADER_LENGTH = 12;

    if (datagram.size() < MINIMUM_HEADER_LENGTH) {
        // too small to be RTP
        return;
    }

    uint8_t first_byte = datagram[0];
    uint8_t second_byte = datagram[1];

    uint8_t version = static_cast<uint8_t>(first_byte >> 6);
    uint8_t padding = static_cast<uint8_t>((first_byte >> 5) & 1);
    uint8_t extension = static_cast<uint8_t>((first_byte >> 4) & 1);
    uint8_t csrcCount = static_cast<uint8_t>(first_byte & 0x0f);
    uint8_t marker = static_cast<uint8_t>(second_byte >> 7);
    uint8_t payload_type = static_cast<uint8_t>(second_byte & 0x7f);
    uint16_t sequence_number = static_cast<uint16_t>((datagram[2] << 8) | datagram[3]);
    uint32_t timestamp = static_cast<uint32_t>((datagram[4] << 24) | (datagram[5] << 16) | (datagram[6] << 8) | datagram[7]);
    uint32_t ssrc = static_cast<uint32_t>((datagram[8] << 24) | (datagram[9] << 16) | (datagram[10] << 8) | (datagram[11]));

    QByteArray csrc;
    for (int i = 0; i < csrcCount; i++) {
        csrc.append(datagram[9 + 4 * i]);
    }

    auto payloadOffset = MINIMUM_HEADER_LENGTH + 4 * csrcCount;

    QByteArray payload(datagram.data() + payloadOffset, datagram.size() - payloadOffset);

    const int type_stap_a = 24;
    const int type_stap_b = 25;

    const int type_fu_a = 28;
    const int type_fu_b = 29;



    auto nalu_f    = static_cast<uint8_t>((payload[0] >> 7) & 0x1);
    auto nalu_nri  = static_cast<uint8_t>((payload[0] >> 5) & 0x3);
    auto nalu_type = static_cast<uint8_t>( payload[0]       & 0x1f);

    bool submit = false;

    switch (nalu_type) {
        case type_stap_a: {
            // not supported
            break;
        }
        case type_stap_b: {
            // not supported
            break;
        }
        case type_fu_a: {
            fu_a_header fu_a;
            fu_a.s    = static_cast<uint8_t>((payload[1] >> 7) & 0x1);
            fu_a.e    = static_cast<uint8_t>((payload[1] >> 6) & 0x1);
            fu_a.r    = static_cast<uint8_t>((payload[1] >> 5) & 0x1);
            fu_a.type = static_cast<uint8_t>((payload[1])      & 0x1f);

            if (fu_a.s == 1) {
                rtpBuffer.clear();
                uint8_t reassembled = 0;
                reassembled |= (nalu_f << 7);
                reassembled |= (nalu_nri << 5);
                reassembled |= (fu_a.type);
                rtpBuffer.append((char*)&reassembled, 1);
            }

            rtpBuffer.append(payload.data() + 2, payload.size() - 2);
            if (fu_a.e == 1) {
                tempBuffer.append(rtpBuffer.data(), rtpBuffer.size());
                rtpBuffer.clear();
                submit = true;
            }
            break;
        }
        case type_fu_b: {
            // not supported
            break;
        }
        default: {
            // should be a single NAL
            tempBuffer.append(payload.data(), payload.size());
            rtpBuffer.clear();
            submit = true;
            break;
        }
    }
    if (submit) {
        QByteArray nalUnit(tempBuffer);
        tempBuffer.clear();
        processNAL(nalUnit);
    }
};



/*
 * Simple NAL search
 *
 */
void OpenHDVideo::findNAL() {
    size_t sz = tempBuffer.size();
    uint8_t* p = (uint8_t*)tempBuffer.data();

    int nal_start, nal_end;

    while (find_nal_unit(p, sz, &nal_start, &nal_end) > 0) {
        QByteArray nalUnit;

        auto nal_size = nal_end - nal_start;
        nalUnit.resize(nal_size);

        memcpy(nalUnit.data(), &p[nal_start], nal_size);

        tempBuffer.remove(0, nal_end);

        // update the temporary pointer with the new start of the buffer
        p = (uint8_t*)tempBuffer.data();
        sz = tempBuffer.size();

        processNAL(nalUnit);
    }
}



/*
 * Parses the NAL header to determine which kind of NAL this is, and then either
 * configure the decoder if needed or send the NAL on to the decoder, taking
 * care to send the PPS and SPS first, then an IDR, then other frame types.
 *
 * Some hardware decoders, particularly on Android, will crash if sent an IDR
 * before the PPS/SPS, or a non-IDR before an IDR.
 *
 */
void OpenHDVideo::processNAL(QByteArray nalUnit) {
    //auto forbidden_zero_bit = (nalUnit[0] >> 7) & 0x1;
    //auto nal_ref_idc = (nalUnit[0] >> 5) & 0x3;
    auto nal_unit_type = nalUnit[0] & 0x1F;

    read_nal_unit(h264_stream, (uint8_t*)nalUnit.data(), nalUnit.length());

    switch (nal_unit_type) {
        case NAL_UNIT_TYPE_UNSPECIFIED: {
            break;
        }
        case NAL_UNIT_TYPE_CODED_SLICE_NON_IDR: {
            if (isConfigured && sentSPS && sentPPS && sentIDR) {
                QByteArray _n;
                _n.append(NAL_HEADER, 4);
                _n.append(nalUnit);
                processFrame(_n, FrameTypeNonIDR);
                //nalQueue.push_back(_n);
            }
            break;
        }
        case NAL_UNIT_TYPE_CODED_SLICE_IDR: {
            if (isConfigured && sentSPS && sentPPS) {
                QByteArray _n;
                _n.append(NAL_HEADER, 4);
                _n.append(nalUnit);

                processFrame(_n, FrameTypeIDR);
                //nalQueue.push_back(_n);

                sentIDR = true;
            }
            break;
        }
        case NAL_UNIT_TYPE_SPS: {
            auto new_width = 0;
            auto new_height = 0;
            auto new_fps = 0;

            if (h264_stream->sps->frame_cropping_flag) {
                new_width = ((h264_stream->sps->pic_width_in_mbs_minus1 + 1) * 16) - h264_stream->sps->frame_crop_left_offset * 2 - h264_stream->sps->frame_crop_right_offset * 2;
                new_height = ((2 - h264_stream->sps->frame_mbs_only_flag)* (h264_stream->sps->pic_height_in_map_units_minus1 + 1) * 16) - (h264_stream->sps->frame_crop_top_offset * 2) - (h264_stream->sps->frame_crop_bottom_offset * 2);
            }
            else {
                new_width = ((h264_stream->sps->pic_width_in_mbs_minus1 + 1) * 16);
                new_height = ((2 - h264_stream->sps->frame_mbs_only_flag) * (h264_stream->sps->pic_height_in_map_units_minus1 + 1) * 16);
            }

            int vui_present = h264_stream->sps->vui_parameters_present_flag;
            if (vui_present) {
                if (h264_stream->sps->vui.timing_info_present_flag) {
                    auto num_units_in_tick = h264_stream->sps->vui.num_units_in_tick;
                    auto time_scale = h264_stream->sps->vui.time_scale;
                    new_fps = time_scale / num_units_in_tick;
                } else {
                    new_fps = 30;
                }
            }

            if (new_height != height || new_width != width || new_fps != fps) {
                height = new_height;
                width = new_width;
                fps = new_fps;
            }

            if (!haveSPS) {
                QByteArray extraData;
                extraData.append(NAL_HEADER, 4);
                extraData.append(nalUnit);

                sps_len = extraData.size();
                memcpy(sps, extraData.data(), extraData.size());
                haveSPS = true;
            }
            if (isConfigured) {
                QByteArray _n;
                _n.append(NAL_HEADER, 4);
                _n.append(nalUnit);

                processFrame(_n, FrameTypeSPS);
                //nalQueue.push_back(_n);

                sentSPS = true;
            }
            break;
        }
        case NAL_UNIT_TYPE_PPS: {
            if (!havePPS) {
                QByteArray extraData;
                extraData.append(NAL_HEADER, 4);
                extraData.append(nalUnit);

                pps_len = extraData.length();
                memcpy(pps, extraData.data(), extraData.size());
                havePPS = true;
            }
            if (isConfigured && sentSPS) {
                QByteArray _n;
                _n.append(NAL_HEADER, 4);
                _n.append(nalUnit);

                processFrame(_n, FrameTypePPS);
                //nalQueue.push_back(_n);

                sentPPS = true;
            }
            break;
        }
        case NAL_UNIT_TYPE_AU: {
            QByteArray _n;
            _n.append(NAL_HEADER, 4);
            _n.append(nalUnit);

            processFrame(_n, FrameTypeAU);
            break;
        }
        default: {
            break;
        }
    }

    if (haveSPS && havePPS && isStart) {
        emit configure();
        isStart = false;
    }
    if (isConfigured) {
        lastDataReceived = QDateTime::currentMSecsSinceEpoch();
    }
}

#endif
