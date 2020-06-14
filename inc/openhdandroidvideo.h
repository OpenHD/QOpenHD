#if defined(ENABLE_VIDEO_RENDER)
#if defined(__android__)

#ifndef OpenHDAndroidVideo_H
#define OpenHDAndroidVideo_H

#include <QObject>

#include <QtQml>

#include "openhdvideo.h"
#include "openhdandroidrender.h"

#include <media/NdkMediaCodec.h>


class OpenHDAndroidVideo : public OpenHDVideo
{
    Q_OBJECT
    Q_PROPERTY(OpenHDAndroidRender *videoOut READ videoOut WRITE setVideoOut NOTIFY videoOutChanged)

public:
    OpenHDAndroidVideo(enum OpenHDStreamType stream_type = OpenHDStreamTypeMain);
    virtual ~OpenHDAndroidVideo() override;

    OpenHDAndroidRender *videoOut() const;
    Q_INVOKABLE void setVideoOut(OpenHDAndroidRender *videoOut);


    void start() override;
    void stop() override;
    void renderLoop() override;
    void inputLoop() override;
    void processFrame(QByteArray &nal, FrameType frameType) override;

public slots:
    void androidConfigure();

signals:
    void videoOutChanged();

private:

    QPointer<OpenHDAndroidRender> m_videoOut;

    AMediaCodec* codec;
    AMediaFormat *format;
    ANativeWindow * window;
};

#endif // OpenHDAndroidVideo_H

#endif
#endif
