/******************************************************************************
 * OpenHD
 *
 * Licensed under the GNU General Public License (GPL) Version 3.
 *
 * This software is provided "as-is," without warranty of any kind, express or
 * implied, including but not limited to the warranties of merchantability,
 * fitness for a particular purpose, and non-infringement. For details, see the
 * full license in the LICENSE file provided with this source code.
 *
 * Non-Military Use Only:
 * This software and its associated components are explicitly intended for
 * civilian and non-military purposes. Use in any military or defense
 * applications is strictly prohibited unless explicitly and individually
 * licensed otherwise by the OpenHD Team.
 *
 * Contributors:
 * A full list of contributors can be found at the OpenHD GitHub repository:
 * https://github.com/OpenHD
 *
 * © OpenHD, All Rights Reserved.
 ******************************************************************************/

#include "uisimulator.h"
#include "settingsbackup.h"
#include "widgetpreviewimage.h"
#include <QQuickItemGrabResult>
#include <QQuickWindow>
#include <QKeyEvent>
#include <QBuffer>
#include "qopenhd.h"
#include "audioannouncements.h"
#include "qtcreatorlaunch.h"
#include "qpixmap.h"
#include <QCoreApplication>
#include <QGuiApplication>
#include <QSettings>
#include <QDebug>
#include <QLocale>
#include <qapplication.h>
#include <QTimer>
#include <QFile>
#include <QHostAddress>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>
#include <QStandardPaths>
#include <QDir>

#include<iostream>
#include <sys/stat.h>
#include<fstream>
#include<string>
#include <QProcess>

#if defined(__linux__) || defined(__macos__)
#include "common/openhd-util.hpp"
#endif

#if defined(ENABLE_SPEECH)
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

void QOpenHD::postRcNavigationKey(int key) const
{
    switch (key) {
    case Qt::Key_Up:
    case Qt::Key_Down:
    case Qt::Key_Left:
    case Qt::Key_Right:
        break;
    default:
        return;
    }

    auto* window = qobject_cast<QQuickWindow*>(QGuiApplication::focusWindow());
    if (!window || !window->isActive()) return;

    QCoreApplication::postEvent(window, new QKeyEvent(QEvent::KeyPress, key, Qt::NoModifier));
    QCoreApplication::postEvent(window, new QKeyEvent(QEvent::KeyRelease, key, Qt::NoModifier));
}

QOpenHD &QOpenHD::instance()
{
    static QOpenHD instance=QOpenHD();
    return instance;
}

QString QOpenHD::credit_archive_text() const
{
    QFile report(QStringLiteral(":/resources/credits/01.dat"));
    if (!report.open(QIODevice::ReadOnly)) {
        return QStringLiteral("ARCHIVE UNAVAILABLE");
    }
    return QString::fromUtf8(qUncompress(report.readAll()));
}

void QOpenHD::setDebugMenuPreview(bool enabled)
{
    setDebugMenuPreviewLevel(enabled ? 1 : 0);
}

void QOpenHD::setDebugMenuPreviewLevel(int level)
{
    if (UiSimulator::isActive()) level=0;
    // The setter is guarded as well as the button; production QML cannot opt in.
    level = m_launchedFromQtCreator ? qBound(0, level, 2) : 0;
    const int previous = m_debugMenuPreviewLevel.exchange(level);
    if (previous == level) return;
    emit debugMenuPreviewLevelChanged();
    if ((previous > 0) != (level > 0)) emit debugMenuPreviewChanged();
}

QOpenHD::QOpenHD(QObject *parent)
    : QObject{parent}, m_launchedFromQtCreator(qopenhd::launchedFromQtCreator())
{
    connect(this, &QOpenHD::signal_toast_add, this, &QOpenHD::do_not_call_toast_add);
    connect(&m_ping, &AsyncPing::finished, this, &QOpenHD::pingFinished);
    connect(&m_commands, &AsyncCommandRunner::finished, this, &QOpenHD::systemActionFinished);
    connect(&m_commands, &AsyncCommandRunner::finished, this, [this](QString id, QString result, bool success) {
        if (!success || id == "service" || id == "dhcp") show_toast(result, !success);
    });

#if defined(ENABLE_SPEECH)
    m_speech = new QTextToSpeech(this);
    qDebug() << "Available SPEECH engines:" << QTextToSpeech::availableEngines();
    // Android initializes TTS asynchronously. In Qt 5.15.2, locale() can
    // dereference a null Java locale before onInit and abort the whole app.
    // Do not query the current locale, or configure voices, during startup.
    const auto initializeSpeech = [this]() {
        if (m_speechInitialized || m_speech->state() != QTextToSpeech::Ready) return;
        m_speechInitialized = true;
        const QLocale english(QLocale::English, QLocale::LatinScript, QLocale::UnitedStates);
        if (m_speech->availableLocales().contains(english)) m_speech->setLocale(english);
        m_defaultSpeechVoice = m_speech->voice();
        QSettings preferences;
        configureSpeech(preferences.value("speech_voice", "").toString(),
                        preferences.value("speech_rate", 1.0).toDouble(),
                        preferences.value("speech_volume", 1.0).toDouble());
    };
    connect(m_speech, &QTextToSpeech::stateChanged, this,
            [this, initializeSpeech](QTextToSpeech::State) {
        initializeSpeech();
        emit speechVoicesChanged();
    });
    initializeSpeech();
#endif
}


void QOpenHD::setEngine(QQmlApplicationEngine *engine) {
    m_engine = engine;
}

bool QOpenHD::loadTranslator(const QString &language, QSettings *settings)
{
    QLocale::setDefault(QLocale(language));

    QString qmFile = QString(":/translations/QOpenHD_%1.qm").arg(language);
    if (!m_translator.load(qmFile)) {
        qDebug() << "Translation load failed for" << language << ", falling back to English";
        QLocale::setDefault(QLocale("en"));
        if (settings != nullptr) {
            settings->setValue("locale", "en");
        }
        return m_translator.load(":/translations/QOpenHD_en.qm");
    }

    if (settings != nullptr) {
        settings->setValue("locale", language);
    }

    return true;
}

bool QOpenHD::installTranslatorForLanguage(const QString &language, QSettings *settings)
{
    QCoreApplication::removeTranslator(&m_translator);

    bool success = loadTranslator(language, settings);
    QCoreApplication::installTranslator(&m_translator);

    return success;
}

void QOpenHD::switchToLanguage(const QString &language) {
    if(m_engine==nullptr){
        qDebug()<<"Error switch language- engine not set";
        return;
    }
    QSettings settings;
    installTranslatorForLanguage(language, &settings);
    // QML should automatically retranslate when translator is installed/removed.
    // Avoid calling retranslate() here; it can cause UI issues on low-end Linux
    // and rendering problems on Android.
}

void QOpenHD::setFontFamily(QString fontFamily) {
    m_fontFamily = fontFamily;
    emit fontFamilyChanged(m_fontFamily);
    m_font = QFont(m_fontFamily, 11, QFont::Bold, false);

}

bool QOpenHD::speechAvailable() const
{
#ifdef ENABLE_SPEECH
    // BackendError is Qt 5's name; Qt 6 renamed the same state to Error.
    return m_speech && static_cast<int>(m_speech->state()) != 3 && !QTextToSpeech::availableEngines().isEmpty();
#else
    return false;
#endif
}

QStringList QOpenHD::speechVoices() const
{
    QStringList result;
#ifdef ENABLE_SPEECH
    if (speechAvailable()) for (const auto& voice : m_speech->availableVoices())
        if (!result.contains(voice.name())) result.append(voice.name());
#endif
    return result;
}

void QOpenHD::configureSpeech(const QString& voice, double rate, double volume)
{
    rate = qBound(0.5, rate, 2.0);
    volume = qBound(0.0, volume, 1.0);
    QSettings preferences;
    preferences.setValue("speech_voice", voice);
    preferences.setValue("speech_rate", rate);
    preferences.setValue("speech_volume", volume);
#ifdef ENABLE_SPEECH
    if (!m_speechInitialized || !speechAvailable()) return;
    m_speech->setRate(rate - 1.0); // 100% is Qt's normal rate (0).
    m_speech->setVolume(volume);
    m_speech->setVoice(m_defaultSpeechVoice);
    if (!voice.isEmpty()) for (const auto& available : m_speech->availableVoices())
        if (available.name() == voice) { m_speech->setVoice(available); break; }
#endif
}

void QOpenHD::textToSpeech_sayMessage(QString message)
{
    AudioAnnouncements::instance().sayLegacy(message);
}

void QOpenHD::quit_qopenhd()
{
    if (UiSimulator::isActive()) { UiSimulator::instance().recordAction(QStringLiteral("Simulated quit_qopenhd - no host action performed")); return; }
    qDebug()<<"quit_qopenhd() begin";
    QApplication::quit();
    qDebug()<<"quit_qopenhd() end";
}

void QOpenHD::disable_service_and_quit()
{
    if (UiSimulator::isActive()) { UiSimulator::instance().recordAction(QStringLiteral("Simulated disable_service_and_quit - no host action performed")); return; }
#ifdef __linux__
    OHDUtil::run_command("sudo systemctl stop qopenhd",{""},true);
#endif
    quit_qopenhd();
}

void QOpenHD::restart_local_oenhd_service()
{
    if (UiSimulator::isActive()) { UiSimulator::instance().recordAction(QStringLiteral("Simulated restart_local_oenhd_service - no host action performed")); return; }
#ifdef __linux__

    m_commands.run("service", "sudo", {"systemctl", "restart", "openhd"}, tr("OpenHD service restarted"));
#endif
}

void QOpenHD::run_dhclient_eth0()
{
    if (UiSimulator::isActive()) { UiSimulator::instance().recordAction(QStringLiteral("Simulated run_dhclient_eth0 - no host action performed")); return; }
#ifdef __linux__
    m_commands.run("dhcp", "sudo", {"dhclient", "eth0"}, tr("Ethernet address request completed"));
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

QString QOpenHD::widget_preview_image(QObject* grabResult) const
{
    const auto* result=qobject_cast<QQuickItemGrabResult*>(grabResult);
    if(!result)return {};
    const auto image=cropWidgetPreviewImage(result->image());
    if(image.isNull())return {};
    QByteArray bytes;QBuffer buffer(&bytes);buffer.open(QIODevice::WriteOnly);
    if(!image.save(&buffer,"PNG"))return {};
    return QStringLiteral("data:image/png;base64,")+QString::fromLatin1(bytes.toBase64());
}

bool QOpenHD::reset_settings()
{
    if (UiSimulator::isActive() || debugMenuPreview()) return false;
    // Apply before QML Settings loads on the next start. Clearing the live file
    // here would let current QML objects write their old values back on exit.
    return SettingsBackup::stageLocalSettingsReset();
}


QString QOpenHD::show_local_ip()
{
#ifdef __linux__
    m_commands.run("local_ip", "hostname", {"-I"});
    return tr("Reading local IP…");
#elif defined(__macos__)
    m_commands.run("local_ip", "/bin/sh", {"-c", "ifconfig -l | xargs -n1 ipconfig getifaddr"});
    return tr("Reading local IP…");
#else
    return QString("Only works on linux");
#endif
}

QString QOpenHD::write_local_log()
{
#ifdef __linux__
    m_commands.run("ground_log", "journalctl", {}, tr("Groundstation log written"), "/boot/openhd/openhd.log");
    return tr("Writing Ground log…");
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
    QtAndroid::runOnAndroidThread([] {
        const auto activity = QtAndroid::androidActivity();
        if (activity.isValid())
            activity.callMethod<void>("openTetheringSettings", "()V");
    });
#endif
}

void QOpenHD::sysctl_openhd(int task)
{
    if (UiSimulator::isActive()) { UiSimulator::instance().recordAction(QStringLiteral("Simulated sysctl_openhd - no host action performed")); return; }
#ifdef __linux__
    const QStringList actions{"start", "stop", "enable", "disable"};
    if (task < 0 || task >= actions.size()) return;
    m_commands.run("service", "systemctl", {actions.at(task), "openhd"}, tr("OpenHD service action completed"));
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

bool QOpenHD::is_platform_nxp()
{
#ifdef IS_PLATFORM_NXP
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

void QOpenHD::show_error_message(QString message)
{

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

QString QOpenHD::export_color_preview(const QString& json)
{
    QJsonParseError error;
    const auto doc=QJsonDocument::fromJson(json.toUtf8(), &error);
    if(error.error != QJsonParseError::NoError || !doc.isObject()) return QString();
    const auto directory=QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if(directory.isEmpty() || !QDir().mkpath(directory)) return QString();
    const auto path=directory + "/color-preview.json";
    QSaveFile file(path);
    const auto data=doc.toJson();
    if(!file.open(QIODevice::WriteOnly) || file.write(data) != data.size() || !file.commit()) return QString();
    return path;
}
