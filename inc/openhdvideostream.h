#ifndef OpenHDVideoStream_H
#define OpenHDVideoStream_H

#include <QObject>

#include "VideoStreaming/VideoStreaming.h"
#include "VideoStreaming/VideoSurface.h"
#include "VideoStreaming/VideoReceiver.h"

class OpenHDVideoStream : public QObject
{
    Q_OBJECT

public:
    OpenHDVideoStream(QObject *parent = nullptr);
    virtual ~OpenHDVideoStream();

    Q_PROPERTY(VideoReceiver* videoReceiver READ getVideoReceiver NOTIFY videoReceiverChanged)
    VideoReceiver* getVideoReceiver() { return &m_receiver; }

    Q_PROPERTY(QString uri MEMBER m_uri WRITE setUri NOTIFY uriChanged)
    void setUri(QString uri);

signals:
    void videoReceiverChanged(VideoReceiver* videoReceiver);
    void uriChanged(QString uri);

public slots:
    void startVideo();
    void stopVideo();

private:
    void init();
    void _start();
    void _stop();
    QString m_uri;

    VideoReceiver m_receiver;
};

#endif // OpenHDVideoStream_H
