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
    void cleanupTestCase() { QtAudioPlayer::instance().stop_playing(); }
};
QTEST_GUILESS_MAIN(NativeAudioTest)
#include "tst_native_audio.moc"
