#if defined(ENABLE_VIDEO_RENDER)

#ifndef OpenHDVideo_H
#define OpenHDVideo_H

#include <QObject>
#include <QtMultimedia/QVideoFrame>
#include <QtQml>

#include "sharedqueue.h"


enum OpenHDStreamType {
    OpenHDStreamTypeMain,
    OpenHDStreamTypePiP
};

class QUdpSocket;


#define NAL_UNIT_TYPE_UNSPECIFIED                    0
#define NAL_UNIT_TYPE_CODED_SLICE_NON_IDR            1
#define NAL_UNIT_TYPE_CODED_SLICE_IDR                5
#define NAL_UNIT_TYPE_SPS                            7
#define NAL_UNIT_TYPE_PPS                            8
#define NAL_UNIT_TYPE_AU                             9

constexpr char NAL_HEADER[] = "\x00\x00\x00\x01";

typedef struct {
    uint8_t s : 1;
    uint8_t e : 1;
    uint8_t r : 1;
    uint8_t type : 5;
} fu_a_header;

enum FrameType {
    FrameTypeIDR,
    FrameTypeNonIDR,
    FrameTypeSPS,
    FrameTypePPS,
    FrameTypeAU
};

class OpenHDVideo : public QObject
{
    Q_OBJECT

public:
    OpenHDVideo(enum OpenHDStreamType stream_type = OpenHDStreamTypeMain);
    virtual ~OpenHDVideo();

    qint64 lastDataReceived = 0;

signals:
    void videoRunning(bool running);
    void configure();

public slots:
    void startVideo();
    void stopVideo();
    void onStarted();

protected:
    void processDatagrams();
    void parseRTP(QByteArray datagram);
    void findNAL();
    void processNAL(const uint8_t* data, size_t length);
    void reconfigure();

    virtual void start() = 0;
    virtual void stop() = 0;
    virtual void inputLoop() = 0;
    virtual void renderLoop() = 0;
    virtual void processFrame(QByteArray &nal, FrameType frameType) = 0;

    bool firstRun = true;

    bool m_enable_rtp = true;

    enum OpenHDStreamType m_stream_type;

    int m_video_port = 0;

    int main_default_port = 5600;
    int pip_default_port = 5601;


    QTimer* timer = nullptr;

    QUdpSocket *m_socket;

    QByteArray tempBuffer;
    QByteArray accessUnit;

    QByteArray rtpBuffer;
    size_t rtpData = 0;

    bool haveSPS = false;
    bool havePPS = false;
    bool isStart = true;
    bool isFirstAU = true;
    bool isConfigured = false;
    bool sentIDR = false;
    bool sentSPS = false;
    bool sentPPS = false;

    uint8_t *sps = nullptr;
    uint8_t sps_len = 0;
    uint8_t *pps = nullptr;
    uint8_t pps_len = 0;

    int width;
    int height;
    int fps;

    QVideoFrame::PixelFormat format = QVideoFrame::PixelFormat::Format_YUV420P;

    uint32_t pts = 0;
    bool sawInputEOS = false;
    bool sawOutputEOS = false;

    SharedQueue<QByteArray> nalQueue;
};

#endif // OpenHDVideo_H

#endif
