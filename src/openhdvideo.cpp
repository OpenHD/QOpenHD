#if defined(ENABLE_VIDEO_RENDER)

#include "openhdvideo.h"

#include "constants.h"

#include <QtConcurrent>
#include <QtQuick>
#include <QMutex>
#include <QUdpSocket>

#include "localmessage.h"

#include "openhd.h"



#include "h264_common.h"
#include "sps_parser.h"
#include "pps_parser.h"


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

#include <unistd.h>
#include <fcntl.h>


OpenHDVideoReceiver::OpenHDVideoReceiver(OpenHDVideo *video, enum OpenHDStreamType stream_type): QObject(), m_stream_type(stream_type), m_video(video) {
    qDebug() << "OpenHDVideoReceiver::OpenHDVideoReceiver()";
}


OpenHDVideoReceiver::~OpenHDVideoReceiver() {
    qDebug() << "~OpenHDVideoReceiver()";
}


void OpenHDVideoReceiver::onStarted() {
    qDebug() << "OpenHDVideoReceiver::onStarted()";

    connect(this, &OpenHDVideoReceiver::start, this, &OpenHDVideoReceiver::onStart, Qt::BlockingQueuedConnection);
    connect(this, &OpenHDVideoReceiver::stop, this, &OpenHDVideoReceiver::onStop, Qt::BlockingQueuedConnection);

    QSettings settings;

    if (m_stream_type == OpenHDStreamTypeMain) {
        m_video_port = settings.value("main_video_port", 5600).toInt();
    } else {
        m_video_port = settings.value("pip_video_port", 5601).toInt();
    }

    onStart();
}


void OpenHDVideoReceiver::onStop() {
#if defined(USE_RAW_SOCKET)

#else

#endif
}


void OpenHDVideoReceiver::onStart() {
    QSettings settings;

    if (m_stream_type == OpenHDStreamTypeMain) {
        m_video_port = settings.value("main_video_port", 5600).toInt();
    } else {
        m_video_port = settings.value("pip_video_port", 5601).toInt();
    }


    struct sockaddr_in myaddr;
    int recvlen;
    int fd;
    unsigned char buf[65535];


    if ((fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0) {
        perror("cannot create socket\n");
        return;
    }

    memset((char *)&myaddr, 0, sizeof(myaddr));
    myaddr.sin_family = AF_INET;
    myaddr.sin_addr.s_addr = htonl(INADDR_ANY);
    myaddr.sin_port = htons(m_video_port);

    if (bind(fd, (struct sockaddr *)&myaddr, sizeof(myaddr)) < 0) {
        perror("bind failed");
        return;
    }

    int n = 1024 * 1024;

    if (setsockopt(fd, SOL_SOCKET, SO_RCVBUF, &n, sizeof(n)) == -1) {
        qDebug() << "Failed to set socket SO_RCVBUF";
    }


    //int flags = fcntl(fd, F_GETFL, 0);
    //fcntl(fd, F_SETFL, flags | O_NONBLOCK);

    int d;
    socklen_t len = sizeof(d);

    getsockopt(fd, SOL_SOCKET, SO_RCVBUF, &d, &len);

    qDebug() << "real socket buffer size: " << d;

    emit socketChanged(fd);

    for (;;) {
        recvlen = recvfrom(fd, buf, 65535, 0, NULL, NULL);

        if (recvlen > 0) {
            QByteArray datagram((char*)buf, recvlen);
            QMutexLocker(&m_video->m_mutex);
            m_video->onReceivedData(datagram);
        }
    }
}


OpenHDVideo::OpenHDVideo(enum OpenHDStreamType stream_type): QObject(), m_stream_type(stream_type) {
    qDebug() << "OpenHDVideo::OpenHDVideo()";

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

    QSettings settings;

    if (m_stream_type == OpenHDStreamTypeMain) {
        m_video_port = settings.value("main_video_port", 5600).toInt();
    } else {
        m_video_port = settings.value("pip_video_port", 5601).toInt();
    }

    m_enable_rtp = settings.value("enable_rtp", true).toBool();

    lastDataReceived = QDateTime::currentMSecsSinceEpoch();

    timer = new QTimer(this);
    QObject::connect(timer, &QTimer::timeout, this, &OpenHDVideo::reconfigure);
    timer->start(1000);

    m_receiver = new OpenHDVideoReceiver(this, m_stream_type);

    if (m_stream_type == OpenHDStreamTypeMain) {
        m_receiverThread.setObjectName("mainVideoRecv");
    } else {
        m_receiverThread.setObjectName("pipVideoRecv");
    }

    connect(m_receiver, &OpenHDVideoReceiver::socketChanged, this, &OpenHDVideo::onSocketChanged);

    QObject::connect(&m_receiverThread, &QThread::started, m_receiver, &OpenHDVideoReceiver::onStarted);
    m_receiver->moveToThread(&m_receiverThread);

    m_receiverThread.start();
    m_receiverThread.setPriority(QThread::TimeCriticalPriority);

    emit setup();
}


void OpenHDVideo::onSocketChanged(int fd) {
    m_socket = fd;
}


/*
 * Fired by m_timer.
 *
 * This is primarily a way to check for video stalls so the UI layer can take action
 * if necessary, such as hiding the PiP element when the stream has stopped.
 */
void OpenHDVideo::reconfigure() {
    if (m_background) {
        return;
    }

    QMutexLocker locker(&m_mutex);

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

    int port = 0;

    if (m_stream_type == OpenHDStreamTypeMain) {
        port = settings.value("main_video_port", 5600).toInt();
    } else {
        port = settings.value("pip_video_port", 5601).toInt();
    }

    if (m_video_port != port) {
        m_restart = true;
    }

    auto enable_rtp = settings.value("enable_rtp", true).toBool();
    if (m_enable_rtp != enable_rtp) {
        m_enable_rtp = enable_rtp;
        m_restart = true;
    }

    if (m_restart) {
        m_restart = false;
        //emit m_receiver->stop();
        shutdown(m_socket, SHUT_RD);
        m_receiverThread.quit();
        m_receiverThread.wait();
        stop();
        tempBuffer.clear();
        rtpBuffer.clear();
        sentSPS = false;
        haveSPS = false;
        sentPPS = false;
        havePPS = false;
        sentIDR = false;
        isStart = true;
        isConfigured = false;
        m_receiverThread.start();
        m_receiverThread.setPriority(QThread::TimeCriticalPriority);
    }
}


void OpenHDVideo::startVideo() {
    QMutexLocker locker(&m_mutex);
#if defined(ENABLE_MAIN_VIDEO) || defined(ENABLE_PIP)
    firstRun = false;
    lastDataReceived = QDateTime::currentMSecsSinceEpoch();
    OpenHD::instance()->set_main_video_running(false);
    OpenHD::instance()->set_pip_video_running(false);
    QFuture<void> future = QtConcurrent::run(this, &OpenHDVideo::start);
#endif
}


void OpenHDVideo::stopVideo() {
    QMutexLocker locker(&m_mutex);
#if defined(ENABLE_MAIN_VIDEO) || defined(ENABLE_PIP)
    QFuture<void> future = QtConcurrent::run(this, &OpenHDVideo::stop);
#endif
}



void OpenHDVideo::onReceivedData(QByteArray data) {
    if (m_enable_rtp || m_stream_type == OpenHDStreamTypePiP) {
        parseRTP(data);
    } else {
        tempBuffer.append(data);
        findNAL();
    }
}


/*
 * Simple RTP parse, just enough to get the frame data
 *
 */
void OpenHDVideo::parseRTP(QByteArray &datagram) {
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
                reassembled |= (fu_a.type & 0x1f);
                rtpBuffer.append((char*)&reassembled, 1);
                rtpBuffer.append(payload.data() + 2, payload.size() - 2);
            } else if (fu_a.e == 1) {
                rtpBuffer.append(payload.data() + 2, payload.size() - 2);
                submit = true;
            } else {
                rtpBuffer.append(payload.data() + 2, payload.size() - 2);
            }
            break;
        }
        case type_fu_b: {
            // not supported
            break;
        }
        default: {
            // should be a single NAL
            rtpBuffer.append(payload);
            submit = true;
            break;
        }
    }
    if (submit) {
        QByteArray nalUnit(rtpBuffer);
        rtpBuffer.clear();
        processNAL(nalUnit);
    }
};



void OpenHDVideo::findNAL() {
    size_t sz = tempBuffer.size();

    if (sz == 0) {
        return;
    }

    uint8_t* p = (uint8_t*)tempBuffer.data();

    int final_offset = 0;

    auto indexes = webrtc::H264::FindNaluIndices(p, sz);

    if (indexes.empty()) {
        return;
    }

    for (auto & index : indexes) {
        if (index.payload_size == 0) {
            continue;
        }
        QByteArray nalUnit((const char*)&p[index.payload_start_offset], index.payload_size);
        processNAL(nalUnit);
        final_offset = index.payload_start_offset + index.payload_size;
    }

    if (final_offset != 0) {
        tempBuffer.remove(0, final_offset);
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
void OpenHDVideo::processNAL(QByteArray &nalUnit) {
    webrtc::H264::NaluType nalu_type = webrtc::H264::ParseNaluType(nalUnit.data()[0]);

    switch (nalu_type) {
        case webrtc::H264::NaluType::kSlice: {
            if (isConfigured && sentSPS && sentPPS && sentIDR) {
                QByteArray _n;
                _n.append(NAL_HEADER, 4);
                _n.append(nalUnit);
                processFrame(_n, nalu_type);
                //nalQueue.push_back(_n);
            }
            break;
        }
        case webrtc::H264::NaluType::kIdr: {
            if (isConfigured && sentSPS && sentPPS) {
                QByteArray _n;
                _n.append(NAL_HEADER, 4);
                _n.append(nalUnit);

                processFrame(_n, nalu_type);
                //nalQueue.push_back(_n);

                sentIDR = true;
            }
            break;
        }
        case webrtc::H264::NaluType::kSps: {
            auto new_width = 0;
            auto new_height = 0;
            auto new_fps = 0;

            auto _sps = webrtc::SpsParser::ParseSps((const uint8_t*)nalUnit.data() + webrtc::H264::kNaluTypeSize, nalUnit.size() - webrtc::H264::kNaluTypeSize);

            if (_sps) {
                new_width = _sps->width;
                new_height = _sps->height;
                new_fps = 30;

                // the webrtc h264 parser doesn't support this yet, but we can add it
                /*int vui_present = _sps->vui_params_present;
                if (vui_present) {
                    if (nalu_sps->timing_info_present_flag) {
                        auto num_units_in_tick = nalu_sps->num_units_in_tick;

                        auto time_scale = nalu_sps->time_scale;
                        new_fps = time_scale / num_units_in_tick;
                    } else {
                        new_fps = 30;
                    }
                }*/

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

                    processFrame(_n, nalu_type);
                    //nalQueue.push_back(_n);

                    sentSPS = true;
                }
            }

            break;
        }
        case webrtc::H264::NaluType::kPps: {
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

                processFrame(_n, nalu_type);
                //nalQueue.push_back(_n);

                sentPPS = true;
            }
            break;
        }
        case webrtc::H264::NaluType::kAud: {
            QByteArray _n;
            _n.append(NAL_HEADER, 4);
            _n.append(nalUnit);

            processFrame(_n, nalu_type);
            break;
        }
        default: {
            qDebug() << "unknown frame_type: " << nalu_type;
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
