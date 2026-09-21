#ifndef GSTRTPAUDIOPLAYER_H
#define GSTRTPAUDIOPLAYER_H

#include <QObject>
#include <QStringList>
#include <QTimer>
#include <gst/gstelement.h>

class GstRtpAudioPlayer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList outputDeviceNames READ outputDeviceNames NOTIFY outputDevicesChanged)
    Q_PROPERTY(QStringList outputDeviceIds READ outputDeviceIds NOTIFY outputDevicesChanged)
    Q_PROPERTY(QString selectedOutputDevice READ selectedOutputDevice WRITE setSelectedOutputDevice NOTIFY selectedOutputDeviceChanged)
    Q_PROPERTY(int playbackVolume READ playbackVolume WRITE setPlaybackVolume NOTIFY playbackVolumeChanged)
    Q_PROPERTY(int audioLevel READ audioLevel NOTIFY audioLevelChanged)
    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
    Q_PROPERTY(bool recording READ recording WRITE setRecording NOTIFY recordingChanged)
    Q_PROPERTY(QString recordingPath READ recordingPath NOTIFY recordingPathChanged)

public:
    explicit GstRtpAudioPlayer(QObject *parent = nullptr);
    ~GstRtpAudioPlayer() override;
    static GstRtpAudioPlayer& instance();
    QStringList outputDeviceNames() const { return m_outputDeviceNames; }
    QStringList outputDeviceIds() const { return m_outputDeviceIds; }
    QString selectedOutputDevice() const { return m_selectedOutputDevice; }
    int playbackVolume() const { return m_playbackVolume; }
    int audioLevel() const { return m_audioLevel; }
    bool playing() const { return m_pipeline != nullptr; }
    bool recording() const { return m_recording; }
    QString recordingPath() const { return m_recordingPath; }

    Q_INVOKABLE void refreshDevices();
    Q_INVOKABLE void setPlaybackEnabled(bool enabled);
    Q_INVOKABLE void start_playing();
    Q_INVOKABLE void stop_playing();
    void setSelectedOutputDevice(const QString& deviceId);
    void setPlaybackVolume(int volume);
    void setRecording(bool recording);

signals:
    void outputDevicesChanged();
    void selectedOutputDeviceChanged();
    void playbackVolumeChanged();
    void audioLevelChanged();
    void playingChanged();
    void recordingChanged();
    void recordingPathChanged();

private slots:
    void pollBus();

private:
    QString constructPipeline();
    QString createRecordingPath() const;
    QString sinkDescription() const;
    void restartIfPlaying();
    void onError(const QString& tag);

    GstElement *m_pipeline = nullptr;
    QTimer m_busTimer;
    QStringList m_outputDeviceNames;
    QStringList m_outputDeviceIds;
    QString m_selectedOutputDevice;
    QString m_recordingPath;
    int m_playbackVolume = 100;
    int m_audioLevel = 0;
    bool m_recording = false;
    bool m_pipelineRecording = false;
};

#endif
