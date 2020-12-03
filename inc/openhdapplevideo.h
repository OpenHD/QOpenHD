#if defined(ENABLE_VIDEO_RENDER)
#if defined(__apple__)

#ifndef OpenHDAppleVideo_H
#define OpenHDAppleVideo_H

#include <QObject>

#include <QtQml>

#include "openhdvideo.h"
#include "openhdrender.h"

#include <VideoToolbox/VideoToolbox.h>

class OpenHDAppleVideo : public OpenHDVideo
{
    Q_OBJECT
    Q_PROPERTY(OpenHDRender *videoOut READ videoOut WRITE setVideoOut NOTIFY videoOutChanged)

public:
    OpenHDAppleVideo(enum OpenHDStreamType stream_type = OpenHDStreamTypeMain);
    virtual ~OpenHDAppleVideo() override;

    OpenHDRender *videoOut() const;
    Q_INVOKABLE void setVideoOut(OpenHDRender *videoOut);


    void start() override;
    void stop() override;
    void renderLoop() override;
    void inputLoop() override;
    void processFrame(QByteArray &nal, webrtc::H264::NaluType frameType) override;
    void processDecodedFrame(CVImageBufferRef imageBuffer);

public slots:
    void vtdecConfigure();
    void onSetup();

signals:
    void videoOutChanged();

protected:
    QPointer<OpenHDRender> m_videoOut;

private:
    quint64 m_last_time = 0;
    quint64 m_frames = 0;

    CMVideoFormatDescriptionRef m_formatDesc = nullptr;
    VTDecompressionSessionRef m_decompressionSession = nullptr;


};

#endif // OpenHDAppleVideo_H

#endif
#endif
