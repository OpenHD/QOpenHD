#include <QtTest>
#include <QTemporaryDir>
#include <QSettings>
#include <thread>
#include <atomic>
#include "util/audioannouncements.h"
#include "videostreaming/vscommon/qt_audio_player.h"
class NativeAudioTest : public QObject {
    Q_OBJECT
    QTemporaryDir m_settings;
private slots:
    void initTestCase() {
        QCoreApplication::setOrganizationName("OpenHD-native-audio-test");
        QCoreApplication::setApplicationName("native-audio");
        QSettings::setDefaultFormat(QSettings::IniFormat);
        QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, m_settings.path());
        QSettings s; s.setValue("audio_welcome_sound",false); s.setValue("audio_notification_volume",0);
        s.setValue("enable_speech",true); s.setValue("audio_speech_language","en"); s.setValue("speech_rate",2.0);
    }
    void localizedPresets() {
        const QVariantMap rule{{"phrase","Battery at {value} percent"}};
        QCOMPARE(audio_rule_phrase(rule,50,"percent",{},"de"),QString::fromUtf8("Batterie bei 50 Prozent"));
        QCOMPARE(audio_rule_phrase(rule,50,"percent",{},"es"),QString::fromUtf8("Batería al 50 por ciento"));
        QCOMPARE(audio_rule_phrase(rule,50,"percent",{},"en"),QString("Battery at 50 percent"));
    }
    void mixerPullContinuityAndClipping() {
        NativeAudioMixer mixer(4, 48000);
        QByteArray pcm(4000, Qt::Uninitialized);
        for (int i=0;i<pcm.size();i+=2) qToLittleEndian(qint16(20000),reinterpret_cast<uchar*>(pcm.data()+i));
        mixer.addStream(pcm); mixer.setNotification(pcm);
        const auto mixed=mixer.read(4000);
        QCOMPARE(mixed.size(),4000);
        for (int i=0;i<mixed.size();i+=2) QCOMPARE(qFromLittleEndian<qint16>(reinterpret_cast<const uchar*>(mixed.constData()+i)),qint16(32767));
        QCOMPARE(mixer.read(4000),QByteArray(4000,'\0'));
        mixer.setNotification(pcm);
        QCOMPARE(mixer.read(1000)+mixer.read(3000),pcm);
    }
    void mixerReadsWhileUiThreadIsBusy() {
        NativeAudioMixer mixer(4,48000);
        mixer.setNotification(QByteArray(4000,'\1'));
        std::atomic<int> received{0};
        std::thread consumer([&]{ for(int i=0;i<40;++i){ if(mixer.read(100)==QByteArray(100,'\1')) ++received; } });
        QTest::qSleep(100);
        consumer.join();
        QCOMPARE(received.load(),40);
    }
    void synchronizedStartupRespectsWelcomeMute() {
        QSettings().setValue("audio_welcome_sound",false);
        AudioAnnouncements controller;
        controller.start(true);
        controller.playStartupSound();
        controller.playStartupSound();
        QCOMPARE(controller.status(),QString("Ready"));
        controller.shutdown();
    }
    void bundledStartupSound() {
        QFile file(":/audio/startup.pcm");
        QVERIFY(file.open(QIODevice::ReadOnly));
        const auto pcm = file.readAll();
        QCOMPARE(pcm.size(), 1105600);
        QCOMPARE(pcm.size() % 4, 0);
        bool stereo = false;
        for (int i = 0; i + 3 < pcm.size(); i += 4)
            if (pcm.mid(i, 2) != pcm.mid(i + 2, 2)) { stereo = true; break; }
        QVERIFY(stereo);
    }
    void startupWaitsForMovieAndPlaysOnce() {
        QSettings().setValue("audio_welcome_sound",true);
        AudioAnnouncements controller;
        controller.start(true);
        int played = 0;
        connect(&controller,&AudioAnnouncements::statusChanged,this,[&]{
            if(controller.status()=="Playing on the selected audio output") ++played;
        });
        QTest::qWait(1700);
        QCOMPARE(played,0);
        controller.playStartupSound();
        controller.playStartupSound();
        QCOMPARE(played,1);
        QTRY_COMPARE_WITH_TIMEOUT(controller.status(),QString("Ready"),8000);
        QCOMPARE(played,1);
        controller.shutdown();
        QSettings().setValue("audio_welcome_sound",false);
    }
    void soundWithoutGstreamer() {
        AudioAnnouncements controller;
        QVERIFY(controller.supported());
        controller.start();
        controller.testSound();
        QCOMPARE(controller.status(),QString("Playing on the selected audio output"));
        QTRY_COMPARE_WITH_TIMEOUT(controller.status(),QString("Ready"),8000);
        controller.shutdown();
    }
    void voiceWithoutGstreamer() {
        AudioAnnouncements controller;
        QVERIFY(controller.speechAvailable());
        controller.start();
        bool played=false;
        connect(&controller,&AudioAnnouncements::statusChanged,this,[&]{
            if(controller.status()=="Playing on the selected audio output" || controller.status()=="Speaking with the system voice")played=true;
        });
        controller.testVoice();
        QTRY_VERIFY_WITH_TIMEOUT(played,20000);
        QTRY_COMPARE_WITH_TIMEOUT(controller.status(),QString("Ready"),20000);
        controller.shutdown();
    }
    void germanVoiceWithoutGstreamer() {
        if (qEnvironmentVariable("OPENHD_TEST_GERMAN_VOICE") != "1") QSKIP("Enable when a German voice is installed");
        QSettings().setValue("audio_speech_language", "de");
        AudioAnnouncements controller;
        controller.start();
        bool played=false;
        connect(&controller,&AudioAnnouncements::statusChanged,this,[&]{
            if(controller.status()=="Playing on the selected audio output")played=true;
        });
        controller.testVoice();
        QTRY_VERIFY_WITH_TIMEOUT(played,20000);
        QTRY_COMPARE_WITH_TIMEOUT(controller.status(),QString("Ready"),20000);
        controller.shutdown();
    }
    void missingSpanishVoiceIsExplained() {
        if (qEnvironmentVariable("OPENHD_TEST_NO_SPANISH_VOICE") != "1") QSKIP("Enable when no Spanish voice is installed");
        QSettings().setValue("audio_speech_language", "es");
        AudioAnnouncements controller;
        controller.start();
        controller.testVoice();
        QTRY_VERIFY_WITH_TIMEOUT(controller.status().startsWith("No Spanish voice is installed"),20000);
        controller.shutdown();
    }
    void warningsAreOffByDefault() {
        QSettings settings;
        settings.setValue("enable_speech", true);
        settings.setValue("audio_warning_sound", true);
        AudioAnnouncements controller;
        controller.start(true);
        QSignalSpy requested(&controller, &AudioAnnouncements::warningAnnouncementRequested);
        for (const auto& kind : {"temp", "cpu", "undervolt", "radio", "fc"}) {
            settings.remove(QString("audio_warning_tts_%1_enabled").arg(kind));
            controller.updateWarning(QString("default.%1").arg(kind), kind, "Test warning", 2, false);
        }
        settings.remove("audio_warning_tts_message_enabled");
        settings.remove("audio_warning_tts_openhd_message_enabled");
        controller.message(4, "Flight controller warning");
        controller.openhdMessage(4, "OpenHD warning");
        QCOMPARE(requested.count(), 0);
    }
    void configurableWarningsRespectMuteAndCooldown() {
        QSettings settings;
        settings.setValue("enable_speech", true);
        settings.setValue("audio_warning_sound", true);
        settings.setValue("audio_warning_tts_temp_enabled", true);
        settings.setValue("audio_warning_tts_temp_mode", 0);
        settings.setValue("audio_warning_tts_temp_phrase", "Custom: {message}");
        AudioAnnouncements controller;
        controller.start(true); // Keep output gated; this test must not speak.
        QSignalSpy requested(&controller, &AudioAnnouncements::warningAnnouncementRequested);
        controller.updateWarning("ground.temp", "temp", "Ground temperature 80", 2, true);
        QCOMPARE(requested.count(), 0);
        controller.updateWarning("ground.temp", "temp", "Ground temperature 80", 2, false);
        QCOMPARE(requested.count(), 1);
        QCOMPARE(requested.at(0).at(1).toString(), QString("Custom: Ground temperature 80"));
        controller.updateWarning("ground.temp", "temp", "Ground temperature 81", 2, false);
        QCOMPARE(requested.count(), 1);
        controller.updateWarning("ground.temp", "temp", "", 0, false);
        controller.updateWarning("ground.temp", "temp", "Ground temperature 80", 2, false);
        QCOMPARE(requested.count(), 1); // Recovery jitter must not spam speech.
        controller.shutdown();
    }
    void warningToneChoicesWorkWithoutSpeech() {
        QSettings settings;
        settings.setValue("enable_speech", false);
        settings.setValue("audio_warning_sound", true);
        settings.setValue("audio_warning_tts_radio_enabled", true);
        for (int mode = 1; mode <= 3; ++mode) {
            settings.setValue("audio_warning_tts_radio_mode", mode);
            AudioAnnouncements controller;
            controller.start(true);
            QSignalSpy requested(&controller, &AudioAnnouncements::warningAnnouncementRequested);
            controller.updateWarning("air.radio", "radio", "Air radio hot", 2, false);
            QCOMPARE(requested.count(), 1);
            QCOMPARE(requested.at(0).at(1).toString(), QString("tone:%1").arg(mode));
            controller.updateWarning("air.radio", "radio", "Air radio hot", 2, true);
            controller.updateWarning("air.cpu", "cpu", "Air CPU high", 2, true);
            QCOMPARE(requested.count(), 1);
            controller.shutdown();
        }
        settings.setValue("enable_speech", true);
        settings.setValue("audio_warning_tts_radio_mode", 0);
    }
    void warningMessageOriginsStaySeparate() {
        QSettings settings;
        settings.setValue("enable_speech", false);
        settings.setValue("audio_warning_sound", true);
        settings.setValue("audio_warning_tts_openhd_message_enabled", true);
        settings.setValue("audio_warning_tts_message_enabled", true);
        settings.setValue("audio_warning_tts_openhd_message_mode", 2);
        settings.setValue("audio_warning_tts_message_mode", 3);
        AudioAnnouncements controller;
        controller.start(true);
        QSignalSpy requested(&controller, &AudioAnnouncements::warningAnnouncementRequested);
        controller.openhdMessage(4, "Temperature warning");
        controller.message(4, "Temperature warning");
        QCOMPARE(requested.count(), 2);
        QCOMPARE(requested.at(0).at(0).toString(), QString("openhd.message"));
        QCOMPARE(requested.at(0).at(1).toString(), QString("tone:2"));
        QCOMPARE(requested.at(1).at(0).toString(), QString("fc.message"));
        QCOMPARE(requested.at(1).at(1).toString(), QString("tone:3"));
        settings.setValue("fc_status_health_muted", true);
        controller.message(4, "Another flight controller warning");
        QCOMPARE(requested.count(), 2);
        settings.setValue("fc_status_health_muted", false);
        controller.shutdown();
        settings.setValue("enable_speech", true);
    }
    void cleanupTestCase() { QtAudioPlayer::instance().stop_playing(); }
};
QTEST_GUILESS_MAIN(NativeAudioTest)
#include "tst_native_audio.moc"
