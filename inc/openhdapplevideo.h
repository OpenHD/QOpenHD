#if defined(ENABLE_VIDEO_RENDER)
#if defined(__apple__)

#ifndef OpenHDAppleVideo_H
#define OpenHDAppleVideo_H

#include <QObject>

#include <QtQml>

#include "openhdvideo.h"
#include "openhdmmalrender.h"

#include <VideoToolbox/VideoToolbox.h>

class OpenHDAppleVideo : public OpenHDVideo
{
    Q_OBJECT
    Q_PROPERTY(OpenHDMMALRender *videoOut READ videoOut WRITE setVideoOut NOTIFY videoOutChanged)

public:
    OpenHDAppleVideo(enum OpenHDStreamType stream_type = OpenHDStreamTypeMain);
    virtual ~OpenHDAppleVideo() override;

    OpenHDMMALRender *videoOut() const;
    Q_INVOKABLE void setVideoOut(OpenHDMMALRender *videoOut);


    void start() override;
    void stop() override;
    void renderLoop() override;
    void inputLoop() override;
    void processFrame(QByteArray &nal) override;
    void processDecodedFrame(CVImageBufferRef imageBuffer);

public slots:
    void vtdecConfigure();

signals:
    void videoOutChanged();

protected:
    QPointer<OpenHDMMALRender> m_videoOut;

private:
    quint64 m_last_time = 0;
    quint64 m_frames = 0;

    CMVideoFormatDescriptionRef m_formatDesc = nullptr;
    VTDecompressionSessionRef m_decompressionSession = nullptr;


};

#endif // OpenHDAppleVideo_H

#endif
#endif
