#if defined(ENABLE_VIDEO_RENDER)
#if defined(__rasp_pi__)

#ifndef OpenHDMMALVideo_H
#define OpenHDMMALVideo_H

#include <QObject>

#include <QtQml>

#include "openhdvideo.h"
#include "openhdrender.h"

#include "bcm_host.h"
#include "interface/mmal/mmal.h"
#include "interface/mmal/util/mmal_default_components.h"
#include "interface/vcos/vcos.h"

struct CONTEXT_T {
    VCOS_SEMAPHORE_T in_semaphore;
    VCOS_SEMAPHORE_T out_semaphore;
    MMAL_QUEUE_T *queue;
};

class OpenHDMMALVideo : public OpenHDVideo
{
    Q_OBJECT
    Q_PROPERTY(OpenHDRender *videoOut READ videoOut WRITE setVideoOut NOTIFY videoOutChanged)

public:
    OpenHDMMALVideo(enum OpenHDStreamType stream_type = OpenHDStreamTypeMain);
    virtual ~OpenHDMMALVideo() override;

    OpenHDRender *videoOut() const;
    Q_INVOKABLE void setVideoOut(OpenHDRender *videoOut);


    void start() override;
    void stop() override;
    void renderLoop() override;
    void inputLoop() override;
    void processFrame(QByteArray &nal, FrameType frameType) override;

public slots:
    void mmalConfigure();

signals:
    void videoOutChanged();

private:
    struct CONTEXT_T m_context;

    MMAL_STATUS_T m_status = MMAL_EINVAL;
    MMAL_COMPONENT_T *m_decoder = 0;

    MMAL_POOL_T *m_pool_in = 0;
    MMAL_POOL_T *m_pool_out = 0;

    QPointer<OpenHDRender> m_videoOut;

    quint64 m_last_time = 0;
    quint64 m_frames = 0;


};

#endif // OpenHDMMALVideo_H

#endif
#endif
