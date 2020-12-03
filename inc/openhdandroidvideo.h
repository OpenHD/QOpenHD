#if defined(ENABLE_VIDEO_RENDER)
#if defined(__android__)

#ifndef OpenHDAndroidVideo_H
#define OpenHDAndroidVideo_H

#include <QObject>

#include <QtQml>

#include "openhdvideo.h"
#include "openhdrender.h"

#include <media/NdkMediaCodec.h>


class OpenHDAndroidVideo : public OpenHDVideo
{
    Q_OBJECT
    Q_PROPERTY(OpenHDRender *videoOut READ videoOut WRITE setVideoOut NOTIFY videoOutChanged)

public:
    OpenHDAndroidVideo(enum OpenHDStreamType stream_type = OpenHDStreamTypeMain);
    virtual ~OpenHDAndroidVideo() override;

    OpenHDRender *videoOut() const;
    Q_INVOKABLE void setVideoOut(OpenHDRender *videoOut);


    void start() override;
    void stop() override;
    void renderLoop() override;
    void inputLoop() override;
    void processFrame(QByteArray &nal, webrtc::H264::NaluType frameType) override;

public slots:
    void androidConfigure();

signals:
    void videoOutChanged();

private:

    QPointer<OpenHDRender> m_videoOut;

    AMediaCodec* codec = nullptr;
    AMediaFormat *format = nullptr;
    ANativeWindow * window = nullptr;
};

#endif // OpenHDAndroidVideo_H

#endif
#endif
