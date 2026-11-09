#pragma once

#include <QIODevice>
#include <QMutex>
#include <QMutexLocker>
#include <QtEndian>
#include <cstring>
#include <utility>

// Pull PCM on the audio backend's schedule rather than a UI-thread timer.
// Silence is always available, so gaps in RTP never starve local speech.
class NativeAudioMixer : public QIODevice
{
public:
    NativeAudioMixer(int frameBytes, int streamLimit, QObject* parent = nullptr)
        : QIODevice(parent), m_frameBytes(frameBytes), m_streamLimit(streamLimit)
    { open(QIODevice::ReadOnly | QIODevice::Unbuffered); }

    bool isSequential() const override { return true; }
    qint64 bytesAvailable() const override { return 65536 + QIODevice::bytesAvailable(); }
    void addStream(const QByteArray& pcm) {
        QMutexLocker lock(&m_mutex);
        m_stream.append(pcm);
        if (m_stream.size() > m_streamLimit)
            m_stream.remove(0, m_stream.size() - m_streamLimit);
    }
    void setNotification(QByteArray pcm) {
        QMutexLocker lock(&m_mutex);
        m_notification = std::move(pcm);
    }
protected:
    qint64 readData(char* destination, qint64 maximum) override {
        const int bytes = int(qMin<qint64>(maximum, 65536)) / m_frameBytes * m_frameBytes;
        if (!bytes) return 0;
        QMutexLocker lock(&m_mutex);
        std::memset(destination, 0, bytes);
        for (int i = 0; i < bytes; i += 2) {
            int value = i + 1 < m_stream.size() ? qFromLittleEndian<qint16>(reinterpret_cast<const uchar*>(m_stream.constData() + i)) : 0;
            if (i + 1 < m_notification.size()) value += qFromLittleEndian<qint16>(reinterpret_cast<const uchar*>(m_notification.constData() + i));
            qToLittleEndian(qint16(qBound(-32768, value, 32767)), reinterpret_cast<uchar*>(destination + i));
        }
        m_stream.remove(0, qMin(bytes, int(m_stream.size())));
        m_notification.remove(0, qMin(bytes, int(m_notification.size())));
        return bytes;
    }
    qint64 writeData(const char*, qint64) override { return -1; }
private:
    QMutex m_mutex;
    QByteArray m_stream, m_notification;
    int m_frameBytes;
    int m_streamLimit;
};
