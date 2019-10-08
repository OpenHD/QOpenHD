#include "openhdvideostream.h"


#include <QtConcurrent>


OpenHDVideoStream::OpenHDVideoStream(QObject *parent): QObject(parent) {
    qDebug() << "OpenHDVideoStream::OpenHDVideoStream()";
    uri = QString("udp://0.0.0.0:%1").arg(5600);
    init();
}

OpenHDVideoStream::~OpenHDVideoStream() {
    qDebug() << "~OpenHDVideoStream()";
}

void OpenHDVideoStream::init() {
    qDebug() << "OpenHDVideoStream::init()";
}

void OpenHDVideoStream::_start() {
#if defined(ENABLE_VIDEO)
    qDebug() << "OpenHDVideoStream::_start()";
    m_receiver.setUri(uri);
    m_receiver.start();
#endif
}

void OpenHDVideoStream::startVideo() {
#if defined(ENABLE_VIDEO)
    QFuture<void> future = QtConcurrent::run(this, &OpenHDVideoStream::_start);
#endif
}
