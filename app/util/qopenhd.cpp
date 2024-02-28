#include "qopenhd.h"
#include "qpixmap.h"
#include <QCoreApplication>
#include <QSettings>
#include <QDebug>
#include <qapplication.h>
#include <QTimer>

#include<iostream>
#include <sys/stat.h>
#include<fstream>
#include<string>

#if defined(__linux__) || defined(__macos__)
#include "common/openhd-util.hpp"
#endif

#if defined(ENABLE_SPEECH)
#include <QHostAddress>
#include <QTextToSpeech>
#include <QVoice>
#include <qsettings.h>
#include <qtimer.h>
#endif

#if defined(__android__)
#include <QAndroidJniEnvironment>
#include <QtAndroid>
#endif

#include "mousehelper.h"

QOpenHD &QOpenHD::instance()
{
    static QOpenHD instance=QOpenHD();
    return instance;
}

QOpenHD::QOpenHD(QObject *parent)
    : QObject{parent}
{
    connect(this, &QOpenHD::signal_toast_add, this, &QOpenHD::do_not_call_toast_add);

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
    QLocale::setDefault(QLocale(language));

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
    }else{
        qDebug()<<"TextToSpeech disabled, msg:"<<message;
    }
#else
    qDebug()<<"TextToSpeech not available, msg:"<<message;
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

bool QOpenHD::backup_settings_locally()
{
#ifdef __linux__
    QSettings settings;
    const std::string src_file_name = settings.fileName().toStdString();
    std::ifstream src(src_file_name, std::ios::binary);
    if(!src){
        qDebug() << "Failed to open source file" << QString::fromStdString(src_file_name);
        return false;
    }
    const std::string dst_file_name = "/boot/openhd/QOpenHD.conf";
    std::ofstream dst(dst_file_name, std::ios::binary);
    if(!dst){
        qDebug() << "Failed to open destination file" << QString::fromStdString(dst_file_name);
        return false;
    }
    dst << src.rdbuf();
    src.close();
    dst.close();
    return true;
#endif
    return false;
}

bool QOpenHD::overwrite_settings_from_backup_file()
{
#ifdef __linux__
    QSettings settings;
    const std::string src_file_name="/boot/openhd/QOpenHD.conf";
    std::ifstream src(src_file_name, std::ios::binary);
    if (!src) {
        qDebug() << "Error: Failed to open source file" << QString::fromStdString(src_file_name);
        return false;
    }
    if(src.peek() == std::ifstream::traits_type::eof()){
        qDebug() << "Error: Source file is empty";
        src.close();
        return false;
    }
    const std::string dst_file_name = settings.fileName().toStdString();
    std::ofstream dst(dst_file_name, std::ios::binary);
    if (!dst) {
        qDebug() << "Error: Failed to open destination file" << QString::fromStdString(dst_file_name);
        src.close();
        return false;
    }
    dst << src.rdbuf();
    src.close();
    dst.close();
    return true;
#endif
    return false;
}

bool QOpenHD::reset_settings()
{
/*#ifdef __linux__
    QSettings settings;
    std::string file_name = settings.fileName().toStdString();
    int result = remove(file_name.c_str());
    if (result == 0) {
        qDebug() << "File" << QString::fromStdString(file_name) << "deleted successfully";
        return true;
    }
    qDebug() << "Error: Failed to delete file" << QString::fromStdString(file_name);
    return false;
#endif
    return false;*/
    QSettings settings;
    settings.clear();
    return true;
}


QString QOpenHD::show_local_ip()
{
#ifdef __linux__
    auto res=OHDUtil::run_command_out("hostname -I");
    return QString(res->c_str());
#elif defined(__macos__)
    auto res=OHDUtil::run_command_out("ifconfig -l | xargs -n1 ipconfig getifaddr");
    return QString(res->c_str());
#else
    return QString("Only works on linux");
#endif

}

bool QOpenHD::is_linux()
{
// weird - linux might be defined on android ?!
#if defined(__android__)
    //qDebug()<<"Is android";
    return false;
#elif defined(__linux__)
    //qDebug()<<"Is linux";
    return true;
#endif
    return false;
}

bool QOpenHD::is_mac()
{
#if defined(__macos__)
    return true;
#else
    return false;
#endif
}

bool QOpenHD::is_android()
{
#if defined(__android__)
    return true;
#else
    return false;
    //return true;
#endif
}

bool QOpenHD::is_windows()
{
#ifdef __windows__
    return true;
#else
    return false;
#endif
}

void QOpenHD::android_open_tethering_settings()
{
#ifdef __android__
    qDebug()<<"android_open_tethering_settings()";
    QAndroidJniObject::callStaticMethod<void>("org/openhd/IsConnected",
                                              "makeAlertDialogOpenTetherSettings2",
                                              "()V");
#endif
}

void QOpenHD::sysctl_openhd(int task)
{
#ifdef __linux__
    if(task==0){
       OHDUtil::run_command("systemctl start openhd",{""},true);
    }else if(task==1){
       OHDUtil::run_command("systemctl stop openhd",{""},true);
    }else if(task==2){
       OHDUtil::run_command("systemctl enable openhd",{""},true);
    }else if(task==3){
       OHDUtil::run_command("systemctl disable openhd",{""},true);
    }else{
       qDebug()<<"Unknown task";
    }
    return;
#endif
    // not supported
}

bool QOpenHD::is_valid_ip(QString ip)
{
    QHostAddress addr;
    bool valid=addr.setAddress(ip);
    return valid;
}

bool QOpenHD::is_platform_rpi()
{
#ifdef IS_PLATFORM_RPI
    return true;
#else
    return false;
#endif
}

bool QOpenHD::is_platform_rock()
{
#ifdef IS_PLATFORM_ROCK
    return true;
#else
    return false;
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

void QOpenHD::show_toast(QString message,bool long_toast)
{
    emit signal_toast_add(message,long_toast);
}

void QOpenHD::set_busy_for_milliseconds(int milliseconds,QString reason)
{
    set_is_busy(true);
    set_busy_reason(reason);
    const int timeout_ms = milliseconds;
    QTimer::singleShot(timeout_ms, this, &QOpenHD::handle_busy_timeout);
}


void QOpenHD::handle_toast_timeout()
{
    if(m_toast_message_queue.empty()){
       set_toast_text("I SHOULD NEVER APPEAR");
       set_toast_visible(false);
    }else{
       auto front=m_toast_message_queue.front();
       m_toast_message_queue.pop_front();
       show_toast_and_add_remove_timer(front.text,front.long_toast);
    }
}

void QOpenHD::handle_busy_timeout()
{
    set_is_busy(false);
    set_busy_reason("");
}

void QOpenHD::do_not_call_toast_add(QString text,bool long_toast)
{
    qDebug()<<"do_not_call_toast_add"<<text;
    if(m_toast_message_queue.empty() && !m_toast_visible){
       show_toast_and_add_remove_timer(text,long_toast);
    }else{
       m_toast_message_queue.push_back(ToastMessage{text,long_toast});
    }
}

void QOpenHD::show_toast_and_add_remove_timer(QString text,bool long_toast)
{
    set_toast_text(text);
    set_toast_visible(true);
    // Android uses:
    // https://stackoverflow.com/questions/7965135/what-is-the-duration-of-a-toast-length-long-and-length-short
    // 2 / 3.5 seconds respective
    //const int timeout_ms = long_toast ? 8*1000 : 3*1000;
    const int timeout_ms = long_toast ? 3500 : 2000;
    QTimer::singleShot(timeout_ms, this, &QOpenHD::handle_toast_timeout);
}
