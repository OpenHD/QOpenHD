#pragma once

#include <QObject>
#include <QStringList>
#include <QUdpSocket>
#include <QAudioFormat>
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
#include <QAudioSink>
#else
#include <QAudioOutput>
#endif

class QtAudioPlayer : public QObject {
    Q_OBJECT
    Q_PROPERTY(QStringList outputDeviceNames READ outputDeviceNames NOTIFY outputDevicesChanged)
    Q_PROPERTY(QStringList outputDeviceIds READ outputDeviceIds NOTIFY outputDevicesChanged)
    Q_PROPERTY(QString selectedOutputDevice READ selectedOutputDevice WRITE setSelectedOutputDevice NOTIFY selectedOutputDeviceChanged)
    Q_PROPERTY(int playbackVolume READ playbackVolume WRITE setPlaybackVolume NOTIFY playbackVolumeChanged)
    Q_PROPERTY(int audioLevel READ outputLevel NOTIFY outputLevelChanged)
    Q_PROPERTY(int inputLevel READ inputLevel NOTIFY inputLevelChanged)
    Q_PROPERTY(int outputLevel READ outputLevel NOTIFY outputLevelChanged)
    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
public:
    explicit QtAudioPlayer(QObject *parent = nullptr);
    ~QtAudioPlayer() override;
    static QtAudioPlayer& instance();
    QStringList outputDeviceNames() const { return m_deviceNames; }
    QStringList outputDeviceIds() const { return m_deviceIds; }
    QString selectedOutputDevice() const { return m_selectedDevice; }
    int playbackVolume() const { return m_volume; }
    int inputLevel() const { return m_inputLevel; }
    int outputLevel() const { return m_outputLevel; }
    bool playing() const { return m_audioOutput != nullptr; }
    Q_INVOKABLE void refreshDevices();
    Q_INVOKABLE void setPlaybackEnabled(bool enabled);
    Q_INVOKABLE void start_playing();
    Q_INVOKABLE void stop_playing();
    void setSelectedOutputDevice(const QString &id);
    void setPlaybackVolume(int volume);
signals:
    void outputDevicesChanged();
    void selectedOutputDeviceChanged();
    void playbackVolumeChanged();
    void inputLevelChanged();
    void outputLevelChanged();
    void playingChanged();
private slots:
    void readPendingDatagrams();
private:
    static qint16 decodeAlaw(quint8 value);
    void updateLevel(int input, int output);
    QStringList m_deviceNames, m_deviceIds;
    QString m_selectedDevice;
    int m_volume = 100, m_inputLevel = 0, m_outputLevel = 0;
    QUdpSocket m_socket;
    QIODevice *m_audioDevice = nullptr;
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
    QAudioSink *m_audioOutput = nullptr;
#else
    QAudioOutput *m_audioOutput = nullptr;
#endif
};
