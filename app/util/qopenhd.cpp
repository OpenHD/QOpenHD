#include "qopenhd.h"
#include "qpixmap.h"
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
#ifdef __linux__
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
    return false;
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

void QOpenHD::customize_cursor(const int cursor_type,const int cursor_scale)
{
    QApplication::restoreOverrideCursor();
    // Default 0 - do not change
    if(cursor_type==0)return;
    qDebug()<<"Custom cursor type:"<<cursor_type<<" scale:"<<cursor_scale;
    // QCursor cursor(Qt::PointingHandCursor);
    // QApplication::setOverrideCursor(cursor);
    // NOTE: the "OS" cursors cannot be scaled easily
    QPixmap pixmap;
    if(cursor_type==1){
        pixmap=QPixmap("://resources/cursors/arrow_512_transparent.png");
    }else if(cursor_type==2){
        pixmap=QPixmap("://resources/cursors/arrow_512_white.png");
    }else if(cursor_type==3){
        pixmap=QPixmap("://resources/cursors/arrow_512_green.png");
    }else{
        pixmap=QPixmap("://resources/cursors/hand_white.png");
    }
    int size_px= 16;
    if(cursor_scale==0){
       size_px =16;
    }else if(cursor_scale==1){
       size_px = 32;
    }else if(cursor_scale==2){
       size_px=64;
    }else if(cursor_scale==3){
       size_px= 128;
    }
    pixmap = pixmap.scaled(size_px,size_px);
    // position is a bit of a mess
    QCursor cursor;
    // arrow - roughly
    if(cursor_type==1 || cursor_type==2 || cursor_type==3){
       cursor=QCursor(pixmap,pixmap.width()/16,pixmap.height()/16);
    }else{
       // The hand is a bit different
       cursor=QCursor(pixmap,pixmap.width()/3,pixmap.height()/4);
    }
    QApplication::setOverrideCursor(cursor);
}

void QOpenHD::customize_cursor_from_settings()
{
    QSettings settings;
    const int custom_cursor_type=settings.value("custom_cursor_type",0).toInt();
    const int custom_cursor_scale=settings.value("custom_cursor_scale",1).toInt();
    customize_cursor(custom_cursor_type,custom_cursor_scale);
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

bool QOpenHD::is_android()
{
#if defined(__android__)
    return true;
#else
    return false;
    //return true;
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
#ifdef __windows__
    //TODO fix windows
    return true;
#else
    return OHDUtil::is_valid_ip(ip.toStdString());
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
