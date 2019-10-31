#include "openhdvideostream.h"

#include "constants.h"

#include <QtConcurrent>


OpenHDVideoStream::OpenHDVideoStream(QObject *parent): QObject(parent) {
    qDebug() << "OpenHDVideoStream::OpenHDVideoStream()";
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
    if (!m_receiver.running()) {
        m_receiver.start();
    }
#endif
}

void OpenHDVideoStream::startVideo() {
#if defined(ENABLE_VIDEO)
    QFuture<void> future = QtConcurrent::run(this, &OpenHDVideoStream::_start);
#endif
}

void OpenHDVideoStream::_stop() {
#if defined(ENABLE_VIDEO)
    qDebug() << "OpenHDVideoStream::_stop()";
    if (m_receiver.running()) {
        m_receiver.stop();
    }
#endif
}

void OpenHDVideoStream::stopVideo() {
#if defined(ENABLE_VIDEO)
    QFuture<void> future = QtConcurrent::run(this, &OpenHDVideoStream::_stop);
#endif
}

void OpenHDVideoStream::setUri(QString uri) {
    m_uri = uri;
    emit uriChanged(m_uri);
    #if defined(ENABLE_VIDEO)
    m_receiver.setUri(m_uri);
    #endif
}
