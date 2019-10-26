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
    m_receiver.start();
#endif
}

void OpenHDVideoStream::startVideo() {
#if defined(ENABLE_VIDEO)
    QFuture<void> future = QtConcurrent::run(this, &OpenHDVideoStream::_start);
#endif
}

void OpenHDVideoStream::setUri(QString uri) {
    m_uri = uri;
    emit uriChanged(m_uri);
    m_receiver.setUri(m_uri);
}
