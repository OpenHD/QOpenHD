#ifndef AUDIOANNOUNCEMENTS_H
#define AUDIOANNOUNCEMENTS_H

#include <QObject>
#include <QElapsedTimer>
#include <QHash>
#include <QProcess>
#include <QQueue>
#include <QTemporaryDir>
#include <QTimer>
#include <QVariantList>
#include "audiorules.h"
#ifdef ENABLE_SPEECH
#include <QTextToSpeech>
#endif

class AudioAnnouncements : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList rules READ rules NOTIFY rulesChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(bool supported READ supported CONSTANT)
    Q_PROPERTY(bool speechAvailable READ speechAvailable NOTIFY availabilityChanged)
public:
    explicit AudioAnnouncements(QObject* parent = nullptr);
    static AudioAnnouncements& instance();
    void start(bool synchronizeStartup = false);
    void shutdown();
    bool supported() const;
    bool speechAvailable() const;
    QString status() const { return m_status; }
    QVariantList rules() const { return m_rules; }
    void telemetry(int source, double value);
    void message(int severity, QString text);
    void openhdMessage(int severity, QString text);
    void sayLegacy(const QString& text);
    Q_INVOKABLE void updateWarning(QString key, QString kind, QString message, int severity, bool muted);
    Q_INVOKABLE void addRule(int source);
    Q_INVOKABLE void saveRule(int index, QVariantMap rule);
    Q_INVOKABLE void removeRule(int index);
    Q_INVOKABLE void testSound();
    Q_INVOKABLE void testVoice();
    Q_INVOKABLE void playStartupSound();
signals:
    void warningAnnouncementRequested(QString key, QString phrase);
    void rulesChanged();
    void statusChanged();
    void availabilityChanged();
private:
    struct Sample { double value; qint64 updated; };
    struct Job { QString phrase; QByteArray pcm; qint64 queued; int source = -1; int ruleIndex = -1; int sampleRate = 22050; int channels = 1; QString warningKey = {}; int warningMode = 0; };
    struct Warning { QString kind, message; int severity = 0, lastMode = -1; bool muted = false; qint64 updated = 0, lastSpoken = -1000000000; };
    QHash<QString, Warning> m_warnings;
    void queueWarnings();
    void cancelWarningPlayback();
    void handleMessage(int severity, QString text, bool openhd);
    bool currentTelemetryValid(bool updatePhrase);
    void enqueue(Job job, bool priority = false);
    void playNext();
    void playPcm(QByteArray pcm, int sampleRate = 22050, int channels = 1);
    void queueStartupSound();
    void tick();
    void persist();
    void setStatus(const QString& text);
    void synthesisFinished(int code, QProcess::ExitStatus status);
    QVariantList m_rules;
    QVector<AudioRuleState> m_states;
    QHash<int, Sample> m_samples;
    QHash<QString, qint64> m_messages;
    QElapsedTimer m_clock;
    QTimer m_tick;
    QTimer m_playback;
    QTimer m_synthesisTimeout;
    QProcess m_synth;
    QTemporaryDir m_temp;
    QQueue<Job> m_queue;
    Job m_current;
    QString m_engine;
    QString m_status;
    QHash<QString, qint64> m_lastMessageAlert;
    bool m_started = false;
    bool m_busy = false;
    bool m_waitingForStartup = false;
    bool m_startupSoundHandled = false;
    bool useGstreamer() const;
    QString speechLanguage() const;
    void finishNativeSpeech();
    bool m_nativeSpeaking = false;
    bool m_windowsSpeech = false;
#ifdef ENABLE_SPEECH
    QTextToSpeech* m_nativeSpeech = nullptr;
#endif
};

#endif
