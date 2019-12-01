#ifndef OpenHDVideoStream_H
#define OpenHDVideoStream_H

#include <QObject>

#include <QtQml>
#include <gst/gst.h>

enum StreamType {
    StreamTypeMain,
    StreamTypePiP
};

class OpenHDVideoStream : public QObject
{
    Q_OBJECT

public:
    OpenHDVideoStream(int &argc, char *argv[], QObject *parent = nullptr);
    virtual ~OpenHDVideoStream();
    void init(QQmlApplicationEngine * engine, enum StreamType stream_type);

public slots:
    void startVideo();
    void stopVideo();

private:
    void _start();
    void _stop();
    QString m_elementName;

    void _timer() ;

    QQmlApplicationEngine *m_engine;
    GstElement * m_pipeline;
    bool firstRun = true;

    bool m_enable_videotest = false;
    bool m_enable_hardware_video_decoder = true;
    bool m_enable_rtp = true;

    bool m_enable_pip_video = false;

    enum StreamType m_stream_type;

    int m_video_port = 0;

    int main_default_port = 5600;
    int pip_default_port = 5601;

    QTimer* timer = nullptr;
};

#endif // OpenHDVideoStream_H
