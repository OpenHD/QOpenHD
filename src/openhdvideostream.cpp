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
    qDebug() << "OpenHDVideoStream::_start()";
    if (!m_receiver.running()) {
        m_receiver.start();
    }
}

void OpenHDVideoStream::startVideo() {
    QFuture<void> future = QtConcurrent::run(this, &OpenHDVideoStream::_start);
}

void OpenHDVideoStream::_stop() {
    qDebug() << "OpenHDVideoStream::_stop()";
    if (m_receiver.running()) {
        m_receiver.stop();
    }
}

void OpenHDVideoStream::stopVideo() {
    QFuture<void> future = QtConcurrent::run(this, &OpenHDVideoStream::_stop);
}

void OpenHDVideoStream::setUri(QString uri) {
    m_uri = uri;
    emit uriChanged(m_uri);
    m_receiver.setUri(m_uri);
}
