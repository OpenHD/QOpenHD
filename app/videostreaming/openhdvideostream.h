#if defined(ENABLE_GSTREAMER)

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
    typedef enum VideoCodec {
      VideoCodecH264,
      VideoCodecH265,
      VideoCodecMJPEG
    } VideoCodec;
    static VideoCodec intToVideoCodec(int videoCodec){
        if(videoCodec==1)return VideoCodecH265;
        if(videoCodec==2)return VideoCodecMJPEG;
        return VideoCodecH265;
    }
    OpenHDVideoStream(QObject *parent = nullptr);
    virtual ~OpenHDVideoStream();
    void init(QQmlApplicationEngine * engine, enum StreamType stream_type);

    qint64 lastDataTimeout = 0;

signals:
    void videoRunning(bool running);

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
    int m_video_port = 0;
    VideoCodec m_video_codec=VideoCodecH264;
    enum StreamType m_stream_type;

    const int main_default_port = 5600;
    const int pip_default_port = 5601;
    const int lte_default_port = 8000;

    QTimer* timer = nullptr;

    GMainLoop *mainLoop = nullptr;
};

#endif // OpenHDVideoStream_H

#endif
