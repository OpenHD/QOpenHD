#include "qt_audio_player.h"

#include <QDebug>
#include <QSettings>
#include <QtEndian>
#include <QtMath>
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
#include <QMediaDevices>
#include <QAudioDevice>
#else
#include <QAudioDeviceInfo>
#endif

QtAudioPlayer::QtAudioPlayer(QObject *parent) : QObject(parent) {
    QSettings settings;
    m_selectedDevice = settings.value("audio_output_device").toString();
    m_volume = qBound(0, settings.value("audio_playback_volume", 100).toInt(), 100);
    connect(&m_socket, &QUdpSocket::readyRead, this, &QtAudioPlayer::readPendingDatagrams);
}
QtAudioPlayer::~QtAudioPlayer() { stop_playing(); }
QtAudioPlayer &QtAudioPlayer::instance() { static QtAudioPlayer player; return player; }

void QtAudioPlayer::refreshDevices() {
    m_deviceNames = QStringList() << tr("System default");
    m_deviceIds = QStringList() << QString();
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
    for (const QAudioDevice &device : QMediaDevices::audioOutputs()) {
        m_deviceNames << device.description(); m_deviceIds << QString::fromUtf8(device.id().toBase64());
    }
#else
    for (const QAudioDeviceInfo &device : QAudioDeviceInfo::availableDevices(QAudio::AudioOutput)) {
        m_deviceNames << device.deviceName(); m_deviceIds << device.deviceName();
    }
#endif
    if (!m_selectedDevice.isEmpty() && !m_deviceIds.contains(m_selectedDevice)) m_selectedDevice.clear();
    emit outputDevicesChanged(); emit selectedOutputDeviceChanged();
}

void QtAudioPlayer::setPlaybackEnabled(bool enabled) { QSettings().setValue("dev_enable_live_audio_playback", enabled); enabled ? start_playing() : stop_playing(); }
void QtAudioPlayer::setSelectedOutputDevice(const QString &id) { if (id == m_selectedDevice) return; const bool wasPlaying = playing(); stop_playing(); m_selectedDevice = id; QSettings().setValue("audio_output_device", id); emit selectedOutputDeviceChanged(); if (wasPlaying) start_playing(); }
void QtAudioPlayer::setPlaybackVolume(int volume) { volume = qBound(0, volume, 100); if (volume == m_volume) return; m_volume = volume; QSettings().setValue("audio_playback_volume", volume); emit playbackVolumeChanged(); }

void QtAudioPlayer::start_playing() {
    if (playing()) return;
    if (!m_socket.bind(QHostAddress::AnyIPv4, 5610, QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint)) {
        qWarning() << "Audio: cannot bind UDP port 5610:" << m_socket.errorString();
        return;
    }
    if (!ensureOutput()) m_socket.close();
    emit playingChanged();
}

bool QtAudioPlayer::ensureOutput() {
    if (m_audioOutput && m_audioDevice) return true;
    QAudioFormat format; format.setSampleRate(48000); format.setChannelCount(2);
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
    format.setSampleFormat(QAudioFormat::Int16);
    QAudioDevice device = QMediaDevices::defaultAudioOutput();
    for (const QAudioDevice &candidate : QMediaDevices::audioOutputs()) if (QString::fromUtf8(candidate.id().toBase64()) == m_selectedDevice) device = candidate;
    if (!device.isFormatSupported(format)) {
        format = device.preferredFormat();
        if (format.sampleFormat() != QAudioFormat::Int16) {
            format.setSampleFormat(QAudioFormat::Int16);
        }
    }
    if (!device.isFormatSupported(format)) {
        qWarning() << "Audio: output device has no supported signed 16-bit PCM format" << device.description();
        emit playingChanged();
        return false;
    }
    m_audioOutput = new QAudioSink(device, format, this);
#else
    format.setSampleSize(16); format.setCodec("audio/pcm"); format.setByteOrder(QAudioFormat::LittleEndian); format.setSampleType(QAudioFormat::SignedInt);
    QAudioDeviceInfo device = QAudioDeviceInfo::defaultOutputDevice();
    for (const QAudioDeviceInfo &candidate : QAudioDeviceInfo::availableDevices(QAudio::AudioOutput)) if (candidate.deviceName() == m_selectedDevice) device = candidate;
    if (!device.isFormatSupported(format)) {
        const int sampleRates[] = {48000, 44100, 32000, 16000, 8000};
        const int channelCounts[] = {2, 1};
        bool found = false;
        for (int sampleRate : sampleRates) {
            for (int channelCount : channelCounts) {
                QAudioFormat candidate = format;
                candidate.setSampleRate(sampleRate);
                candidate.setChannelCount(channelCount);
                if (device.isFormatSupported(candidate)) {
                    format = candidate;
                    found = true;
                    break;
                }
            }
            if (found) break;
        }
        if (!found) {
            qWarning() << "Audio: output device has no supported signed 16-bit PCM format" << device.deviceName();
            emit playingChanged();
            return false;
        }
    }
    m_audioOutput = new QAudioOutput(device, format, this);
#endif
    m_outputSampleRate = format.sampleRate();
    m_outputChannelCount = format.channelCount();
    m_mixer = new NativeAudioMixer(m_outputChannelCount * 2, (m_outputSampleRate / 2) * m_outputChannelCount * 2, this);
    m_audioOutput->setBufferSize(m_outputSampleRate * m_outputChannelCount * 2 * 120 / 1000);
    m_audioOutput->start(m_mixer);
    m_audioDevice = m_mixer;
    if (m_audioOutput->error() != QAudio::NoError) {
        qWarning() << "Audio: failed to start output device at" << m_outputSampleRate << "Hz with" << m_outputChannelCount << "channel(s)";
        delete m_audioOutput;
        m_audioOutput = nullptr;
        delete m_mixer; m_mixer = nullptr; m_audioDevice = nullptr;
        emit playingChanged();
        return false;
    }
    qDebug() << "Audio: playing at" << m_outputSampleRate << "Hz with" << m_outputChannelCount << "channel(s)";
    return true;
}
void QtAudioPlayer::stop_playing() {
    m_socket.close(); m_audioDevice = nullptr;
    if (m_audioOutput) { m_audioOutput->stop(); delete m_audioOutput; m_audioOutput = nullptr; }
    delete m_mixer; m_mixer = nullptr;
    updateLevel(0, 0); emit playingChanged();
}

qint16 QtAudioPlayer::decodeAlaw(quint8 value) {
    value ^= 0x55; int sample = (value & 0x0f) << 4; const int segment = (value & 0x70) >> 4;
    sample += segment ? 0x108 : 8; if (segment > 1) sample <<= segment - 1;
    return (value & 0x80) ? sample : -sample;
}
void QtAudioPlayer::updateLevel(int input, int output) { if (input != m_inputLevel) { m_inputLevel = input; emit inputLevelChanged(); } if (output != m_outputLevel) { m_outputLevel = output; emit outputLevelChanged(); } }
void QtAudioPlayer::readPendingDatagrams() {
    while (m_socket.hasPendingDatagrams()) {
        QByteArray packet; packet.resize(int(m_socket.pendingDatagramSize())); m_socket.readDatagram(packet.data(), packet.size());
        if (packet.size() < 12 || (quint8(packet[0]) >> 6) != 2) continue;
        int offset = 12 + (quint8(packet[0]) & 0x0f) * 4;
        if (quint8(packet[0]) & 0x10) { if (packet.size() < offset + 4) continue; offset += 4 + qFromBigEndian<quint16>(reinterpret_cast<const uchar*>(packet.constData() + offset + 2)) * 4; }
        if (offset >= packet.size()) continue;
        const int inputSamples = packet.size() - offset;
        QVector<qint16> decoded(inputSamples);
        int peakIn = 0, peakOut = 0;
        for (int i = 0; i < inputSamples; ++i) {
            const qint16 raw = decodeAlaw(quint8(packet[offset + i]));
            decoded[i] = qint16((qint32(raw) * m_volume) / 100);
            peakIn = qMax(peakIn, qAbs(int(raw)));
            peakOut = qMax(peakOut, qAbs(int(decoded[i])));
        }
        QByteArray mono(inputSamples * 2, Qt::Uninitialized);
        for (int i = 0; i < inputSamples; ++i)
            qToLittleEndian(decoded[i], reinterpret_cast<uchar*>(mono.data() + i * 2));
        const auto pcm = convertPcm(mono, 8000);
        updateLevel(qMin(100, peakIn * 100 / 32767), qMin(100, peakOut * 100 / 32767));
        if (m_mixer) m_mixer->addStream(pcm);
    }
}

QByteArray QtAudioPlayer::convertPcm(const QByteArray& pcm, int sampleRate, int channels) const {
    const int samples = pcm.size() / (2 * channels);
    if (!samples || sampleRate <= 0) return {};
    if (sampleRate == m_outputSampleRate && channels == m_outputChannelCount) return pcm;
    const int frames = int(qint64(samples) * m_outputSampleRate / sampleRate);
    QByteArray result(frames * m_outputChannelCount * 2, Qt::Uninitialized);
    const auto sample = [&](int frame, int channel) {
        const auto read = [&](int c) { return int(qFromLittleEndian<qint16>(reinterpret_cast<const uchar*>(pcm.constData() + (frame * channels + c) * 2))); };
        return channels == 2 && m_outputChannelCount == 1 ? (read(0) + read(1)) / 2 : read(qMin(channel, channels - 1));
    };
    for (int frame = 0; frame < frames; ++frame) {
        const double position = double(frame) * sampleRate / m_outputSampleRate;
        const int first = qMin(samples - 1, int(position));
        const int second = qMin(samples - 1, first + 1);
        for (int channel = 0; channel < m_outputChannelCount; ++channel) {
            const int a = sample(first, channel), b = sample(second, channel);
            const qint16 value = qint16(a + (b - a) * (position - first));
            qToLittleEndian(value, reinterpret_cast<uchar*>(result.data() + (frame * m_outputChannelCount + channel) * 2));
        }
    }
    return result;
}

int QtAudioPlayer::playPcm(const QByteArray& pcm, int sampleRate, int channels) {
    if (sampleRate < 8000 || sampleRate > 192000 || (channels != 1 && channels != 2) ||
        pcm.isEmpty() || pcm.size() % (2 * channels) || pcm.size() > 2097152 || !ensureOutput()) return 0;
    m_mixer->setNotification(convertPcm(pcm, sampleRate, channels));
    return int(qint64(pcm.size() / (2 * channels)) * 1000 / sampleRate) + 300;
}
