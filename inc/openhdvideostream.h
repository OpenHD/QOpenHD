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

    Q_PROPERTY(QString uri MEMBER m_uri WRITE setUri NOTIFY uriChanged)
    void setUri(QString uri);

signals:
#if defined(ENABLE_VIDEO)
    void videoReceiverChanged(VideoReceiver* videoReceiver);
#endif
    void uriChanged(QString uri);

public slots:
    void startVideo();

private:
    void init();
    void _start();
    QString m_uri;

#if defined(ENABLE_VIDEO)
    VideoReceiver m_receiver;
#endif
};

#endif // OpenHDVideoStream_H
