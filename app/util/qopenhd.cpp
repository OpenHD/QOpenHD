#include "qopenhd.h"
#include <QCoreApplication>
#include <QSettings>
#include <QDebug>
#include <qapplication.h>

#include<iostream>
#include<fstream>
#include<string>

#ifdef __linux__
#include "common/openhd-util.hpp"
#endif

#if defined(ENABLE_SPEECH)
#include <QTextToSpeech>
#include <QVoice>
#include <qsettings.h>
#endif

#if defined(__android__)
#include <QAndroidJniEnvironment>
#include <QtAndroid>
#endif

QOpenHD &QOpenHD::instance()
{
    static QOpenHD instance=QOpenHD();
    return instance;
}

QOpenHD::QOpenHD(QObject *parent)
    : QObject{parent}
{
#if defined(ENABLE_SPEECH)
    m_speech = new QTextToSpeech(this);
    QStringList engines = QTextToSpeech::availableEngines();
    qDebug() << "Available SPEECH engines:";
    for (auto& engine : engines) {
        qDebug() << "  " << engine;
    }
    // List the available locales.
//    qDebug() << "Available locales:";
    for (auto& locale : m_speech->availableLocales()) {
//        qDebug() << "  " << locale;
    }
    // Set locale.
    m_speech->setLocale(QLocale(QLocale::English, QLocale::LatinScript, QLocale::UnitedStates));
    // List the available voices.
//    qDebug() << "Available voices:";
    for (auto& voice : m_speech->availableVoices()) {
//        qDebug() << "  " << voice.name();
    }
    // Display properties.
    qDebug() << "Locale:" << m_speech->locale();
    qDebug() << "Pitch:" << m_speech->pitch();
    qDebug() << "Rate:" << m_speech->rate();
    qDebug() << "Voice:" << m_speech->voice().name();
    qDebug() << "Volume:" << m_speech->volume();
    qDebug() << "State:" << m_speech->state();
#endif
}


void QOpenHD::setEngine(QQmlApplicationEngine *engine) {
    m_engine = engine;
}

void QOpenHD::switchToLanguage(const QString &language) {
    if(m_engine==nullptr){
        qDebug()<<"Error switch language- engine not set";
        return;
    }
    QLocale::setDefault(language);

    if (!m_translator.isEmpty()) {
        QCoreApplication::removeTranslator(&m_translator);
    }

    bool success = m_translator.load(":/translations/QOpenHD.qm");
    if (!success) {
        qDebug() << "Translation load failed";
        return;
    }
    QCoreApplication::installTranslator(&m_translator);
    m_engine->retranslate();
}

void QOpenHD::setFontFamily(QString fontFamily) {
    m_fontFamily = fontFamily;
    emit fontFamilyChanged(m_fontFamily);
    m_font = QFont(m_fontFamily, 11, QFont::Bold, false);

}

void QOpenHD::textToSpeech_sayMessage(QString message)
{
#if defined(ENABLE_SPEECH)  
    QSettings settings;
    if (settings.value("enable_speech", false).toBool() == true){
        //m_speech->setVolume(m_volume/100.0);
        qDebug() << "QOpenHD::textToSpeech_sayMessage say:" << message;
        m_speech->say(message);
    }
#else
    qDebug()<<"TextToSpeech disabled, msg:"<<message;
#endif
}

void QOpenHD::quit_qopenhd()
{
    qDebug()<<"quit_qopenhd() begin";
    QApplication::quit();
    qDebug()<<"quit_qopenhd() end";
}

void QOpenHD::disable_service_and_quit()
{
#ifdef __linux__
    OHDUtil::run_command("sudo systemctl stop qopenhd",{""},true);
#endif
    quit_qopenhd();
}

void QOpenHD::restart_local_oenhd_service()
{
#ifdef __linux__

    OHDUtil::run_command("sudo systemctl stop openhd",{""},true);
    OHDUtil::run_command("sudo systemctl start openhd",{""},true);
#endif
}

void QOpenHD::run_dhclient_eth0()
{
#ifdef __linux__
    OHDUtil::run_command("sudo dhclient eth0",{""},true);
#endif
}

bool QOpenHD::copy_settings()
{
#ifdef __linux__
    QSettings settings;
    std::string file_name = settings.fileName().toStdString();
    std::ifstream src(file_name, std::ios::binary);
    std::ofstream dst("/boot/openhd/QOpenHD.conf", std::ios::binary);

    dst << src.rdbuf();
    src.close();
    dst.close();

    if (!src) {
        qDebug() << "Error: Failed to open source file" << QString::fromStdString(file_name);
        return false;
        if (!dst) {
            qDebug() << "Error: Failed to open destination file" << QString::fromStdString(file_name);
            return false;
        }
    }
    else{
    return true;
    }
#endif
}

bool QOpenHD::read_settings()
{
#ifdef __linux__
    QSettings settings;
    std::string file_name = settings.fileName().toStdString();
    std::ifstream src("/boot/openhd/QOpenHD.conf", std::ios::binary);

    if (!src) {
        qDebug() << "Error: Failed to open source file" << QString::fromStdString("/boot/openhd/QOpenHD.conf");
        return false;
    }

    if(src.peek() == std::ifstream::traits_type::eof()){
        qDebug() << "Error: Source file is empty" << QString::fromStdString("/boot/openhd/QOpenHD.conf");
        src.close();
        return false;
    }

    std::ofstream dst(file_name, std::ios::binary);
    dst << src.rdbuf();
    src.close();
    dst.close();

    if (!dst) {
        qDebug() << "Error: Failed to open destination file" << QString::fromStdString(file_name);
        return false;
    }
    else{
    return true;
    }
#endif
}

QString QOpenHD::show_local_ip()
{
#ifdef __linux__
    auto res=OHDUtil::run_command_out("hostname -I");
    return QString(res->c_str());
#else
    return QString("Only works on linux");
#endif

}

void QOpenHD::keep_screen_on(bool on)
{
#if defined(__android__)
    QtAndroid::runOnAndroidThread([on] {
        QAndroidJniObject activity = QtAndroid::androidActivity();
        if (activity.isValid()) {
            QAndroidJniObject window = activity.callObjectMethod("getWindow", "()Landroid/view/Window;");

            if (window.isValid()) {
                const int FLAG_KEEP_SCREEN_ON = 128;
                if (on) {
                    window.callMethod<void>("addFlags", "(I)V", FLAG_KEEP_SCREEN_ON);
                } else {
                    window.callMethod<void>("clearFlags", "(I)V", FLAG_KEEP_SCREEN_ON);
                }
            }
        }
        QAndroidJniEnvironment env;
        if (env->ExceptionCheck()) {
            env->ExceptionClear();
        }
    });
  // Not needed on any other platform so far
#endif //defined(__android__)
}
