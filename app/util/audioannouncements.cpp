#include "audioannouncements.h"
#include "qopenhd.h"
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QSettings>
#include <QStandardPaths>
#include <QtEndian>
#include <cmath>
#include <limits>
#include <QProcessEnvironment>
#include <QLocale>
#ifdef QOPENHD_ENABLE_QT_AUDIO
#include "videostreaming/vscommon/qt_audio_player.h"
#endif

#ifdef QOPENHD_ENABLE_GSTREAMER_QMLGLSINK
#include "videostreaming/gstreamer/gstrtpaudioplayer.h"
#endif

namespace {
QVariantMap defaultRule(int source)
{
    static const char* phrases[] = {"{message}", "{message}", "{message}",
        "Battery at {value} percent", "Wind speed {value} knots",
        "Altitude {value} meters", "Ground speed {value} kilometers per hour"};
    source = qBound(0, source, 6);
    return {{"source", source}, {"enabled", false}, {"condition", source == 4 ? 1 : 0},
            {"threshold", 50}, {"cooldown", 30}, {"filter", ""},
            {"phrase", QString::fromLatin1(phrases[source])}};
}

QByteArray warningChime(bool error = false)
{
    QByteArray pcm;
    const int count = 2;
    for (int note = 0; note < count; ++note) {
        const double hz = error ? 440.0 : 660.0;
        const int samples = 2205;
        for (int i = 0; i < samples; ++i) {
            const double envelope = qMin(1.0, qMin(i / 220.0, (samples - i) / 440.0));
            const qint16 sample = static_cast<qint16>(9000 * envelope * std::sin(6.28318530718 * hz * i / 22050));
            char bytes[2];
            qToLittleEndian(sample, reinterpret_cast<uchar*>(bytes));
            pcm.append(bytes, 2);
        }
        pcm.append(2204, '\0');
    }
    return pcm;
}

// eSpeak writes PCM WAV. Walk chunks rather than assuming a 44-byte header.
QByteArray speechPcm(const QByteArray& wave)
{
    if (wave.size() < 12 || wave.left(4) != "RIFF" || wave.mid(8, 4) != "WAVE") return {};
    bool formatOk = false;
    for (qint64 offset = 12; offset + 8 <= wave.size();) {
        const auto size = qFromLittleEndian<quint32>(reinterpret_cast<const uchar*>(wave.constData() + offset + 4));
        if (size > static_cast<quint64>(wave.size() - offset - 8)) return {};
        const auto* data = reinterpret_cast<const uchar*>(wave.constData() + offset + 8);
        if (wave.mid(offset, 4) == "fmt " && size >= 16)
            formatOk = qFromLittleEndian<quint16>(data) == 1 &&
                qFromLittleEndian<quint16>(data + 2) == 1 &&
                qFromLittleEndian<quint32>(data + 4) == 22050 &&
                qFromLittleEndian<quint16>(data + 14) == 16;
        if (wave.mid(offset, 4) == "data")
            return formatOk && size <= 2097152 && size % 2 == 0 ? wave.mid(offset + 8, size) : QByteArray{};
        offset += 8 + size + (size & 1);
    }
    return {};
}
}

AudioAnnouncements& AudioAnnouncements::instance()
{
    static AudioAnnouncements instance;
    return instance;
}

AudioAnnouncements::AudioAnnouncements(QObject* parent) : QObject(parent)
{
    m_clock.start();
    m_engine = QStandardPaths::findExecutable("espeak-ng");
    if (m_engine.isEmpty()) m_engine = QStandardPaths::findExecutable("espeak");
#ifdef Q_OS_WIN
    // Windows' built-in speech synthesizer can render WAV without eSpeak.
    if (m_engine.isEmpty()) {
        m_engine = QStandardPaths::findExecutable("powershell.exe");
        m_windowsSpeech = !m_engine.isEmpty();
    }
#endif
#ifdef ENABLE_SPEECH
    m_nativeSpeech = new QTextToSpeech(this);
    connect(m_nativeSpeech, &QTextToSpeech::stateChanged, this, [this](QTextToSpeech::State state) {
        emit availabilityChanged();
        if (!m_nativeSpeaking) return;
        if (state == QTextToSpeech::Ready) finishNativeSpeech();
        else if (static_cast<int>(state) == 3) {
            setStatus(tr("The system speech engine could not speak this announcement"));
            finishNativeSpeech();
        }
    });
#endif
    const auto saved = QSettings().value("audio_voice_rules").toByteArray();
    if (saved.isEmpty()) {
        m_rules = {defaultRule(3), defaultRule(4), defaultRule(0)};
    } else {
        const auto document = QJsonDocument::fromJson(saved);
        if (document.isArray()) m_rules = document.array().toVariantList().mid(0, 16);
    }
    m_states.resize(m_rules.size());
    m_tick.setInterval(250);
    connect(&m_tick, &QTimer::timeout, this, &AudioAnnouncements::tick);
    m_playback.setSingleShot(true);
    connect(&m_playback, &QTimer::timeout, this, [this] {
        m_busy = false;
        if (m_status == tr("Playing on the selected audio output")) setStatus(tr("Ready"));
        playNext();
    });
    m_synthesisTimeout.setSingleShot(true);
    connect(&m_synthesisTimeout, &QTimer::timeout, this, [this] {
        setStatus(tr("Speech synthesis timed out"));
        m_synth.kill();
#ifdef ENABLE_SPEECH
        if (m_nativeSpeaking) { m_nativeSpeech->stop(); finishNativeSpeech(); }
#endif
    });
    connect(&m_synth, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &AudioAnnouncements::synthesisFinished);
    connect(&m_synth, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (error != QProcess::FailedToStart) return;
        m_synthesisTimeout.stop();
        setStatus(tr("Could not start the speech engine"));
        m_busy = false;
        QTimer::singleShot(0, this, &AudioAnnouncements::playNext);
    });
}

bool AudioAnnouncements::supported() const
{
#if defined(QOPENHD_ENABLE_QT_AUDIO) || defined(QOPENHD_ENABLE_GSTREAMER_QMLGLSINK)
    return true;
#else
    return false;
#endif
}

bool AudioAnnouncements::useGstreamer() const
{
#ifdef QOPENHD_ENABLE_GSTREAMER_QMLGLSINK
#ifdef QOPENHD_ENABLE_QT_AUDIO
    return !QOpenHD::instance().is_android();
#else
    return true;
#endif
#else
    return false;
#endif
}

bool AudioAnnouncements::speechAvailable() const
{
    if (!m_engine.isEmpty()) return true;
#ifdef ENABLE_SPEECH
    return m_nativeSpeech && !m_nativeSpeech->availableLocales().isEmpty();
#else
    return false;
#endif
}

QString AudioAnnouncements::speechLanguage() const
{
    const auto language = QSettings().value("audio_speech_language", "en").toString();
    return language == "de" || language == "es" ? language : "en";
}

void AudioAnnouncements::finishNativeSpeech()
{
    m_nativeSpeaking = false;
    m_synthesisTimeout.stop();
    m_busy = false;
    if (m_status == tr("Speaking with the system voice")) setStatus(tr("Ready"));
    QTimer::singleShot(0, this, &AudioAnnouncements::playNext);
}

void AudioAnnouncements::setStatus(const QString& text)
{
    if (m_status == text) return;
    m_status = text;
    emit statusChanged();
}

void AudioAnnouncements::start(bool synchronizeStartup)
{
    if (m_started) return;
    m_started = true;
    m_waitingForStartup = synchronizeStartup;
    setStatus(!supported() ? tr("This build has no audio output backend") :
              speechAvailable() ? tr("Ready") : tr("Chimes ready. Install a system speech voice or espeak-ng for TTS."));
    if (!supported()) return;
    m_tick.start();
    // Windows/Android trigger this from the movie's PlayingState. The timeout
    // also releases queued alerts if the startup UI fails to initialize.
    QTimer::singleShot(synchronizeStartup ? 10000 : 1500, this, &AudioAnnouncements::playStartupSound);
}

void AudioAnnouncements::playStartupSound()
{
    if (!m_started || m_startupSoundHandled) return;
    m_startupSoundHandled = true;
    m_waitingForStartup = false;
    if (QSettings().value("audio_welcome_sound", true).toBool()) queueStartupSound();
    else playNext();
}

void AudioAnnouncements::persist()
{
    QSettings().setValue("audio_voice_rules", QJsonDocument(QJsonArray::fromVariantList(m_rules)).toJson(QJsonDocument::Compact));
    emit rulesChanged();
}

void AudioAnnouncements::shutdown()
{
    m_started = false;
    m_tick.stop();
    m_playback.stop();
    m_synthesisTimeout.stop();
    m_queue.clear();
#ifdef ENABLE_SPEECH
    if (m_nativeSpeech) { m_nativeSpeaking = false; m_nativeSpeech->stop(); }
#endif
    if (m_synth.state() != QProcess::NotRunning) {
        m_synth.kill();
        m_synth.waitForFinished(500);
    }
}

void AudioAnnouncements::addRule(int source)
{
    if (m_rules.size() >= 16) return;
    m_rules.append(defaultRule(source));
    m_states.append(AudioRuleState{});
    persist();
}

void AudioAnnouncements::saveRule(int index, QVariantMap rule)
{
    if (index < 0 || index >= m_rules.size()) return;
    const int source = qBound(0, rule.value("source").toInt(), 6);
    auto clean = defaultRule(source);
    clean["enabled"] = rule.value("enabled").toBool();
    clean["condition"] = qBound(0, rule.value("condition").toInt(), 2);
    const double threshold = rule.value("threshold", 50).toDouble();
    clean["threshold"] = std::isfinite(threshold) ? qBound(-10000.0, threshold, 10000.0) : 50;
    clean["cooldown"] = qBound(5, rule.value("cooldown", 30).toInt(), 3600);
    clean["filter"] = rule.value("filter").toString().left(100);
    clean["phrase"] = rule.value("phrase").toString().trimmed().left(256);
    if (clean.value("phrase").toString().isEmpty()) clean["phrase"] = defaultRule(source).value("phrase");
    m_rules[index] = clean;
    m_states[index] = {};
    // Discard pending jobs that may have been disabled or edited.
    m_queue.clear();
    persist();
}

void AudioAnnouncements::removeRule(int index)
{
    if (index < 0 || index >= m_rules.size()) return;
    m_rules.removeAt(index);
    m_states.removeAt(index);
    m_queue.clear();
    persist();
}

void AudioAnnouncements::telemetry(int source, double value)
{
    // Called on the telemetry thread; all rule and playback state lives here.
    QMetaObject::invokeMethod(this, [this, source, value] {
        if (!std::isfinite(value) || (source == 3 && (value < 0 || value > 100)) ||
            ((source == 4 || source == 6) && value < 0)) {
            m_samples.remove(source);
            return;
        }
        m_samples[source] = {value, m_clock.elapsed()};
    }, Qt::QueuedConnection);
}

void AudioAnnouncements::message(int severity, QString text)
{
    if (!m_started || !supported() || severity < 0 || severity > 6) return;
    text = text.trimmed();
    if (text.startsWith('[') && text.endsWith(']')) text = text.mid(1, text.size() - 2);
    if (text.isEmpty()) return;
    const auto now = m_clock.elapsed();
    const QString key = QString::number(severity) + ":" + text;
    if (m_messages.contains(key) && now - m_messages.value(key) < 10000) return;
    if (m_messages.size() >= 128) m_messages.clear();
    m_messages[key] = now;
    QSettings settings;
    if (severity <= 4 && settings.value("audio_warning_sound", true).toBool() && now - m_lastChime >= 5000) {
        m_lastChime = now;
        enqueue({{}, warningChime(severity <= 3), now}, true);
    }
    if (!settings.value("enable_speech", true).toBool()) return;
    for (int i = 0; i < m_rules.size(); ++i) {
        const auto rule = m_rules[i].toMap();
        auto& state = m_states[i];
        if (!audio_message_rule_due(rule, state, severity, text, now)) continue;
        enqueue({audio_rule_phrase(rule, 0, {}, text, speechLanguage()), {}, now}, severity <= 3);
    }
}

void AudioAnnouncements::tick()
{
#ifdef QOPENHD_ENABLE_GSTREAMER_QMLGLSINK
    const auto error = useGstreamer() ? GstRtpAudioPlayer::instance().poll_error() : QString();
    if (!error.isEmpty()) { setStatus(error); m_queue.clear(); }
#endif
    const auto now = m_clock.elapsed();
    const bool speech = QSettings().value("enable_speech", true).toBool();
    for (int i = 0; i < m_rules.size(); ++i) {
        const auto rule = m_rules[i].toMap();
        const int source = rule.value("source").toInt();
        if (source < 3) continue;
        const auto sample = m_samples.constFind(source);
        if (!speech || sample == m_samples.constEnd() || now - sample->updated > 5000) {
            m_states[i].latched = false;
            continue;
        }
        if (audio_rule_due(rule, m_states[i], sample->value, now)) {
            const QString unit = source == 3 ? "percent" : source == 4 ? "knots" : source == 5 ? "meters" : "kilometers per hour";
            enqueue({audio_rule_phrase(rule, sample->value, unit, {}, speechLanguage()), {}, now, source, i});
        }
    }
}

void AudioAnnouncements::enqueue(Job job, bool priority)
{
    if (!m_started || !supported()) return;
    if (!job.phrase.isEmpty() && !speechAvailable()) {
        setStatus(tr("No speech engine is available. Install a system voice or espeak-ng."));
        return;
    }
    if (m_queue.size() >= 8) {
        if (!priority) return;
        m_queue.removeLast();
    }
    if (priority) m_queue.prepend(job); else m_queue.enqueue(job);
    playNext();
}

void AudioAnnouncements::playNext()
{
    if (m_busy || !m_started || m_waitingForStartup) return;
    while (!m_queue.isEmpty()) {
        m_current = m_queue.dequeue();
        const auto now = m_clock.elapsed();
        if (now - m_current.queued > 10000) continue;
        if (!m_current.phrase.isEmpty() && !QSettings().value("enable_speech", true).toBool()) continue;
        if (!currentTelemetryValid(true)) continue;
        m_busy = true;
        if (!m_current.pcm.isEmpty()) { playPcm(m_current.pcm, m_current.sampleRate, m_current.channels); return; }
#ifdef ENABLE_SPEECH
        if (m_engine.isEmpty()) {
            const auto language = QLocale(speechLanguage()).language();
            bool found = false;
            for (const auto& locale : m_nativeSpeech->availableLocales()) {
                if (locale.language() == language) { m_nativeSpeech->setLocale(locale); found = true; break; }
            }
            if (!found) {
                setStatus(tr("No installed system voice for the selected language"));
                m_busy = false;
                continue;
            }
            const auto voices = m_nativeSpeech->availableVoices();
            const auto preferred = QSettings().value("speech_voice").toString();
            for (const auto& voice : voices) if (voice.name() == preferred) { m_nativeSpeech->setVoice(voice); break; }
            m_nativeSpeech->setVolume(qBound(0, QSettings().value("audio_notification_volume", 70).toInt(), 100) / 100.0);
            m_nativeSpeech->setRate(qBound(0.5, QSettings().value("speech_rate", 1.0).toDouble(), 2.0) - 1.0);
            m_nativeSpeaking = true;
            setStatus(tr("Speaking with the system voice"));
            m_synthesisTimeout.start(45000);
            m_nativeSpeech->say(m_current.phrase);
            return;
        }
#endif
        if (!m_temp.isValid()) { setStatus(tr("Cannot create speech audio file")); m_busy = false; continue; }
        m_synth.setProgram(m_engine);
        if (m_windowsSpeech) {
            // Phrase text travels on stdin; it is never interpolated into shell code.
            QString path = m_temp.filePath("speech.wav"); path.replace("'", "''");
            const QString script = QStringLiteral(
                "$ErrorActionPreference='Stop'; Add-Type -AssemblyName System.Speech; "
                "[Console]::InputEncoding=[Text.Encoding]::UTF8; "
                "$s=New-Object System.Speech.Synthesis.SpeechSynthesizer; $s.Rate=[int]$env:OPENHD_TTS_RATE; "
                "$v=$s.GetInstalledVoices() | Where-Object {$_.Enabled -and $_.VoiceInfo.Culture.TwoLetterISOLanguageName -eq $env:OPENHD_TTS_LANG} | Select-Object -First 1; "
                "if(!$v){throw 'No installed voice for the selected language'}; $s.SelectVoice($v.VoiceInfo.Name); "
                "$f=New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(22050,[System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen,[System.Speech.AudioFormat.AudioChannel]::Mono); "
                "$s.SetOutputToWaveFile('%1',$f); $s.Speak([Console]::In.ReadToEnd()); $s.Dispose();").arg(path);
            auto environment = QProcessEnvironment::systemEnvironment();
            environment.insert("OPENHD_TTS_LANG", speechLanguage());
            environment.insert("OPENHD_TTS_RATE", QString::number(qBound(-10, qRound((QSettings().value("speech_rate", 1.0).toDouble() - 1.0) * 5), 10)));
            m_synth.setProcessEnvironment(environment);
            m_synth.setArguments({"-NoProfile", "-NonInteractive", "-Command", script});
        } else {
            const auto rate = qRound(165 * qBound(0.5, QSettings().value("speech_rate", 1.0).toDouble(), 2.0));
            m_synth.setArguments({"--stdin", "-w", m_temp.filePath("speech.wav"), "-v", speechLanguage(), "-s", QString::number(rate)});
        }
        m_synth.start();
        m_synth.write(m_current.phrase.left(512).toUtf8());
        m_synth.closeWriteChannel();
        m_synthesisTimeout.start(10000);
        return;
    }
}

bool AudioAnnouncements::currentTelemetryValid(bool updatePhrase)
{
    if (m_current.source < 3) return true;
    const auto sample = m_samples.constFind(m_current.source);
    if (sample == m_samples.constEnd() || m_clock.elapsed() - sample->updated > 5000 ||
        m_current.ruleIndex < 0 || m_current.ruleIndex >= m_rules.size()) return false;
    const auto rule = m_rules[m_current.ruleIndex].toMap();
    if (!rule.value("enabled").toBool() || rule.value("source").toInt() != m_current.source) return false;
    const auto condition = rule.value("condition").toInt();
    const auto threshold = rule.value("threshold").toDouble();
    if ((condition == 0 && sample->value > threshold) || (condition == 1 && sample->value < threshold)) return false;
    if (updatePhrase) {
        const int source = m_current.source;
        m_current.phrase = audio_rule_phrase(rule, sample->value,
            source == 3 ? "percent" : source == 4 ? "knots" : source == 5 ? "meters" : "kilometers per hour", {}, speechLanguage());
    }
    return true;
}

void AudioAnnouncements::synthesisFinished(int code, QProcess::ExitStatus exitStatus)
{
    m_synthesisTimeout.stop();
    if (!m_started || !currentTelemetryValid(false)) {
        m_busy = false;
        playNext();
        return;
    }
    QFile wave(m_temp.filePath("speech.wav"));
    if (code == 0 && exitStatus == QProcess::NormalExit && wave.open(QIODevice::ReadOnly)) {
        const auto pcm = speechPcm(wave.read(2097216));
        if (!pcm.isEmpty() && QSettings().value("enable_speech", true).toBool()) { playPcm(pcm); return; }
    }
    const auto detail = QString::fromLocal8Bit(m_synth.readAllStandardError()).trimmed().left(300);
    if (detail.contains("No installed voice")) {
        const auto language = speechLanguage();
        setStatus(tr("No %1 voice is installed. Add it in your system speech settings.")
                  .arg(language == "de" ? tr("German") : language == "es" ? tr("Spanish") : tr("English")));
    } else setStatus(tr("Could not synthesize the voice announcement. Check your system speech engine."));
    m_busy = false;
    playNext();
}

void AudioAnnouncements::playPcm(QByteArray pcm, int sampleRate, int channels)
{
    const double volume = qBound(0, QSettings().value("audio_notification_volume", 70).toInt(), 100) / 100.0;
    for (int i = 0; i + 1 < pcm.size(); i += 2) {
        auto* data = reinterpret_cast<uchar*>(pcm.data() + i);
        qToLittleEndian(static_cast<qint16>(qFromLittleEndian<qint16>(data) * volume), data);
    }
    int duration = 0;
#ifdef QOPENHD_ENABLE_GSTREAMER_QMLGLSINK
    if (useGstreamer()) duration = GstRtpAudioPlayer::instance().play_pcm(pcm, sampleRate, channels);
#endif
#ifdef QOPENHD_ENABLE_QT_AUDIO
    if (!useGstreamer()) duration = QtAudioPlayer::instance().playPcm(pcm, sampleRate, channels);
#endif
    if (duration > 0) {
        setStatus(tr("Playing on the selected audio output"));
        m_playback.start(duration);
    } else {
        setStatus(tr("Selected audio output is unavailable"));
        m_busy = false;
        m_queue.clear();
    }
}

void AudioAnnouncements::sayLegacy(const QString& text)
{
    QMetaObject::invokeMethod(this, [this, text] {
        if (QSettings().value("enable_speech", true).toBool())
            enqueue({text.left(256), {}, m_clock.elapsed()});
    }, Qt::QueuedConnection);
}

void AudioAnnouncements::queueStartupSound()
{
    QFile sound(QStringLiteral(":/audio/startup.pcm"));
    if (!sound.open(QIODevice::ReadOnly) || sound.size() == 0 || sound.size() > 2097152 || sound.size() % 4) {
        setStatus(tr("The bundled startup sound could not be loaded"));
        return;
    }
    enqueue({{}, sound.readAll(), m_clock.elapsed(), -1, -1, 48000, 2}, true);
}

void AudioAnnouncements::testSound() { queueStartupSound(); }
void AudioAnnouncements::testVoice() {
    const auto language = speechLanguage();
    sayLegacy(language == "de" ? QString::fromUtf8("Willkommen bei Open H D. Batterie bei 50 Prozent. Windgeschwindigkeit 50 Knoten.") :
              language == "es" ? QString::fromUtf8("Bienvenido a Open H D. Batería al 50 por ciento. Velocidad del viento 50 nudos.") :
              QStringLiteral("Welcome to Open H D. Battery at 50 percent. Wind speed 50 knots."));
}
