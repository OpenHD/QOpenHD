#ifndef OpenHDVideoStream_H
#define OpenHDVideoStream_H

#include <QObject>

#if defined(ENABLE_VIDEO)
#include "../src/VideoStreaming/VideoStreaming.h"
#include "../src/VideoStreaming/VideoSurface.h"
#include "../src/VideoStreaming/VideoReceiver.h"
#endif

class OpenHDVideoStream : public QObject
{
    Q_OBJECT

public:
    OpenHDVideoStream(QObject *parent = nullptr);
    virtual ~OpenHDVideoStream();

#if defined(ENABLE_VIDEO)
    Q_PROPERTY(VideoReceiver* videoReceiver READ getVideoReceiver NOTIFY videoReceiverChanged)
    VideoReceiver* getVideoReceiver() { return &m_receiver; }
#endif

signals:
#if defined(ENABLE_VIDEO)
    void videoReceiverChanged(VideoReceiver* videoReceiver);
#endif
public slots:
    void startVideo();

private:
    void init();
    void _start();
    QString uri;

#if defined(ENABLE_VIDEO)
    VideoReceiver m_receiver;
#endif
};

#endif // OpenHDVideoStream_H
