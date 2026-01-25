#include "qopenhd.h"
#include "qpixmap.h"
#include <QCoreApplication>
#include <QSettings>
#include <QDebug>
#include <QLocale>
#include <qapplication.h>
#include <QTimer>
#include <QHostAddress>
#include <QDateTime>
#include <QMutex>
#include <QMutexLocker>
#include <QJsonDocument>
#include <QJsonObject>

#include<iostream>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include<fstream>
#include<string>
#include <QProcess>
#include <cmath>
#include <cerrno>
#include <cstring>
#include <QRegularExpression>

#if defined(__linux__) || defined(__macos__)
#include "common/openhd-util.hpp"
#endif

#if defined(__linux__)
#include <QGuiApplication>
#include <QScreen>
#include <QtGui/qpa/qplatformnativeinterface.h>
#include <xf86drm.h>
#include <xf86drmMode.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <poll.h>
#include "telemetry/models/aohdsystem.h"
#include "telemetry/models/openhd_core/platform.hpp"
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

#if defined(__linux__)
namespace {
struct DrmContext {
    int fd = -1;
    bool owns_fd = false;
    uint32_t crtc_id = 0;
    uint32_t connector_id = 0;
    drmModeConnector* connector = nullptr;
    drmModeCrtc* crtc = nullptr;
};

struct SysutilsPlatformInfo {
    int platform_type = -1;
    QString platform_name;
};

static double calc_vrefresh(const drmModeModeInfo& mode) {
    if (mode.htotal == 0 || mode.vtotal == 0) {
        return 0.0;
    }
    double refresh = (mode.clock * 1000.0) / (static_cast<double>(mode.htotal) * static_cast<double>(mode.vtotal));
    if (mode.vscan > 1) {
        refresh /= mode.vscan;
    }
    if (mode.flags & DRM_MODE_FLAG_INTERLACE) {
        refresh *= 2.0;
    }
    return refresh;
}

static QString mode_to_string(const drmModeModeInfo& mode) {
    const double refresh = calc_vrefresh(mode);
    const int refresh_int = static_cast<int>(std::round(refresh));
    return QString("%1x%2@%3").arg(mode.hdisplay).arg(mode.vdisplay).arg(refresh_int);
}

static bool parse_mode_string(const QString& mode_str, int& width, int& height, int& refresh) {
    const QStringList parts = mode_str.split("@");
    if (parts.isEmpty()) {
        return false;
    }
    const QStringList size_parts = parts[0].split("x");
    if (size_parts.size() != 2) {
        return false;
    }
    bool ok_w = false;
    bool ok_h = false;
    width = size_parts[0].toInt(&ok_w);
    height = size_parts[1].toInt(&ok_h);
    if (!ok_w || !ok_h) {
        return false;
    }
    refresh = 0;
    if (parts.size() > 1) {
        bool ok_r = false;
        refresh = parts[1].toInt(&ok_r);
        if (!ok_r) {
            refresh = 0;
        }
    }
    return true;
}

static void release_drm_context(DrmContext& ctx) {
    if (ctx.connector) {
        drmModeFreeConnector(ctx.connector);
        ctx.connector = nullptr;
    }
    if (ctx.crtc) {
        drmModeFreeCrtc(ctx.crtc);
        ctx.crtc = nullptr;
    }
    if (ctx.owns_fd && ctx.fd >= 0) {
        close(ctx.fd);
        ctx.fd = -1;
    }
}

static bool query_sysutils_platform(SysutilsPlatformInfo& info, QString& error_out) {
    constexpr const char* kSocketPath = "/run/openhd/openhd_sys.sock";
    int fd = ::socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) {
        error_out = "sysutils socket failed";
        return false;
    }
    sockaddr_un addr{};
    addr.sun_family = AF_UNIX;
    if (std::strlen(kSocketPath) >= sizeof(addr.sun_path)) {
        error_out = "sysutils socket path too long";
        ::close(fd);
        return false;
    }
    std::strncpy(addr.sun_path, kSocketPath, sizeof(addr.sun_path) - 1);
    if (::connect(fd, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) < 0) {
        error_out = "sysutils connect failed";
        ::close(fd);
        return false;
    }
    constexpr const char* payload = "{\"type\":\"sysutil.platform.request\"}\n";
    const ssize_t sent = ::send(fd, payload, std::strlen(payload), MSG_NOSIGNAL);
    if (sent != static_cast<ssize_t>(std::strlen(payload))) {
        error_out = "sysutils send failed";
        ::close(fd);
        return false;
    }

    pollfd pfd{};
    pfd.fd = fd;
    pfd.events = POLLIN;
    const int poll_ret = ::poll(&pfd, 1, 200);
    if (poll_ret <= 0 || !(pfd.revents & POLLIN)) {
        error_out = "sysutils response timeout";
        ::close(fd);
        return false;
    }

    std::string response;
    char buffer[256];
    while (true) {
        const ssize_t read_bytes = ::recv(fd, buffer, sizeof(buffer), 0);
        if (read_bytes <= 0) {
            break;
        }
        response.append(buffer, buffer + read_bytes);
        if (response.find('\n') != std::string::npos) {
            break;
        }
    }
    ::close(fd);
    const auto newline_pos = response.find('\n');
    if (newline_pos != std::string::npos) {
        response.resize(newline_pos);
    }
    if (response.empty()) {
        error_out = "sysutils empty response";
        return false;
    }
    QJsonParseError parse_error{};
    const QJsonDocument doc = QJsonDocument::fromJson(QByteArray::fromStdString(response), &parse_error);
    if (parse_error.error != QJsonParseError::NoError || !doc.isObject()) {
        error_out = "sysutils json parse failed";
        return false;
    }
    const QJsonObject obj = doc.object();
    if (obj.value("type").toString() != "sysutil.platform.response") {
        error_out = "sysutils response type mismatch";
        return false;
    }
    info.platform_type = obj.value("platform_type").toInt(-1);
    info.platform_name = obj.value("platform_name").toString();
    if (info.platform_type < 0) {
        error_out = "sysutils missing platform_type";
        return false;
    }
    return true;
}

static bool get_sysutils_platform_cached(SysutilsPlatformInfo& info, QString& error_out) {
    static QMutex mutex;
    static SysutilsPlatformInfo cached;
    static qint64 last_ms = 0;
    static bool has_cache = false;
    QMutexLocker lock(&mutex);
    const qint64 now_ms = QDateTime::currentMSecsSinceEpoch();
    if (has_cache && (now_ms - last_ms) < 5000) {
        info = cached;
        return true;
    }
    SysutilsPlatformInfo fresh;
    QString err;
    if (query_sysutils_platform(fresh, err)) {
        cached = fresh;
        last_ms = now_ms;
        has_cache = true;
        info = cached;
        return true;
    }
    error_out = err;
    return false;
}

static bool get_drm_context(DrmContext& ctx, QString& error_out) {
    if (QGuiApplication::platformName().contains("eglfs", Qt::CaseInsensitive)) {
        auto* pni = QGuiApplication::platformNativeInterface();
        if (pni) {
            void* fd_ptr = pni->nativeResourceForIntegration("dri_fd");
            if (fd_ptr) {
                ctx.fd = static_cast<int>(reinterpret_cast<qintptr>(fd_ptr));
            }
            QScreen* screen = QGuiApplication::primaryScreen();
            if (screen) {
                void* crtc_ptr = pni->nativeResourceForScreen("dri_crtcid", screen);
                void* conn_ptr = pni->nativeResourceForScreen("dri_connectorid", screen);
                if (crtc_ptr) {
                    ctx.crtc_id = static_cast<uint32_t>(reinterpret_cast<qintptr>(crtc_ptr));
                }
                if (conn_ptr) {
                    ctx.connector_id = static_cast<uint32_t>(reinterpret_cast<qintptr>(conn_ptr));
                }
            }
        }
    }

    if (ctx.fd < 0) {
        ctx.fd = open("/dev/dri/card0", O_RDONLY | O_CLOEXEC);
        if (ctx.fd < 0) {
            error_out = "open /dev/dri/card0 failed";
            qWarning() << "get_screen_modes: failed to open /dev/dri/card0";
            return false;
        }
        ctx.owns_fd = true;
    }

    drmModeRes* res = drmModeGetResources(ctx.fd);
    if (!res) {
        if (!ctx.owns_fd) {
            // Retry with a fresh /dev/dri/card0 fd if EGLFS fd doesn't work.
            int retry_fd = open("/dev/dri/card0", O_RDONLY | O_CLOEXEC);
            if (retry_fd >= 0) {
                drmModeRes* retry_res = drmModeGetResources(retry_fd);
                if (retry_res) {
                    ctx.fd = retry_fd;
                    ctx.owns_fd = true;
                    res = retry_res;
                } else {
                    close(retry_fd);
                }
            }
        }
        if (!res) {
            error_out = "drmModeGetResources failed";
            qWarning() << "get_screen_modes: drmModeGetResources failed";
            release_drm_context(ctx);
            return false;
        }
    }

    if (ctx.connector_id != 0) {
        ctx.connector = drmModeGetConnector(ctx.fd, ctx.connector_id);
        if (!ctx.connector || ctx.connector->connection != DRM_MODE_CONNECTED) {
            if (ctx.connector) {
                drmModeFreeConnector(ctx.connector);
                ctx.connector = nullptr;
            }
            ctx.connector_id = 0;
        }
    }

    if (ctx.connector_id == 0) {
        for (int i = 0; i < res->count_connectors; ++i) {
            drmModeConnector* conn = drmModeGetConnector(ctx.fd, res->connectors[i]);
            if (!conn) {
                continue;
            }
            if (conn->connection == DRM_MODE_CONNECTED && conn->count_modes > 0) {
                ctx.connector = conn;
                ctx.connector_id = conn->connector_id;
                break;
            }
            drmModeFreeConnector(conn);
        }
    }

    if (ctx.connector && ctx.crtc_id == 0) {
        for (int i = 0; i < ctx.connector->count_encoders; ++i) {
            drmModeEncoder* enc = drmModeGetEncoder(ctx.fd, ctx.connector->encoders[i]);
            if (!enc) {
                continue;
            }
            if (enc->crtc_id) {
                ctx.crtc_id = enc->crtc_id;
                drmModeFreeEncoder(enc);
                break;
            }
            drmModeFreeEncoder(enc);
        }
    }

    drmModeFreeResources(res);

    if (ctx.connector_id == 0 || ctx.crtc_id == 0) {
        error_out = "missing connector/crtc";
        qWarning() << "get_screen_modes: missing connector/crtc";
        release_drm_context(ctx);
        return false;
    }

    if (!ctx.connector) {
        ctx.connector = drmModeGetConnector(ctx.fd, ctx.connector_id);
    }
    if (!ctx.connector) {
        qWarning() << "get_screen_modes: drmModeGetConnector failed";
        error_out = "drmModeGetConnector failed";
        release_drm_context(ctx);
        return false;
    }

    ctx.crtc = drmModeGetCrtc(ctx.fd, ctx.crtc_id);
    if (!ctx.crtc) {
        qWarning() << "get_screen_modes: drmModeGetCrtc failed";
        error_out = "drmModeGetCrtc failed";
        release_drm_context(ctx);
        return false;
    }

    return true;
}

static QStringList get_modes_from_modetest() {
    const QStringList candidates = {
        "/usr/bin/modetest",
        "/usr/local/bin/modetest",
        "modetest"
    };
    QProcess proc;
    for (const QString& path : candidates) {
        proc.start(path, {"-M", "rockchip", "-c"});
        if (!proc.waitForStarted(1000)) {
            continue;
        }
        if (!proc.waitForFinished(2000)) {
            proc.kill();
            proc.waitForFinished();
            continue;
        }
        break;
    }
    if (proc.exitStatus() != QProcess::NormalExit || proc.exitCode() != 0) {
        return {};
    }
    const QString output = QString::fromUtf8(proc.readAllStandardOutput());
    const QStringList lines = output.split('\n');
    QRegularExpression re("^\\s*#?\\d+\\s+(\\d+x\\d+)\\s+([0-9.]+)");
    QStringList modes;
    for (const QString& line : lines) {
        const QRegularExpressionMatch m = re.match(line);
        if (!m.hasMatch()) {
            continue;
        }
        const QString size = m.captured(1);
        const double refresh = m.captured(2).toDouble();
        const int refresh_int = static_cast<int>(std::round(refresh));
        modes.push_back(QString("%1@%2").arg(size).arg(refresh_int));
    }
    modes.removeDuplicates();
    return modes;
}
} // namespace
#endif

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
    if (m_engine) {
        m_engine->retranslate();
    }
    // QML should automatically retranslate when translator is installed/removed
    // Calling retranslate() can cause UI issues in QML applications
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

QString QOpenHD::write_local_log()
{
#ifdef __linux__
    auto res=OHDUtil::run_command_out("journalctl > /boot/openhd/openhd.log");
    return QString("Groundstation Log written !");
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

bool QOpenHD::ping_ip(QString ip)
{
#if defined(__linux__) || defined(__macos__) || defined(_WIN32)
    if(!is_valid_ip(ip)){
        return false;
    }
    QProcess ping_process;
#if defined(_WIN32)
    QStringList arguments = {"-n", "1", "-w", "1000", ip};
#else
    // Use a short timeout to keep the scan responsive
    QStringList arguments = {"-c", "1", "-W", "1", ip};
#endif
    ping_process.start("ping", arguments);
    // Keep the call short so the UI remains responsive while scanning a range
    if(!ping_process.waitForFinished(400)){
        ping_process.kill();
        ping_process.waitForFinished();
        return false;
    }
    return ping_process.exitStatus() == QProcess::NormalExit && ping_process.exitCode() == 0;
#else
    Q_UNUSED(ip);
    return false;
#endif
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
    const auto is_rock_platform = [](int type) {
        return type >= X_PLATFORM_TYPE_ROCKCHIP_RK3566_RADXA_ZERO3W &&
               type < X_PLATFORM_TYPE_ALWINNER_X20;
    };
#if defined(__linux__)
    SysutilsPlatformInfo info;
    QString error;
    if (get_sysutils_platform_cached(info, error)) {
        return is_rock_platform(info.platform_type);
    }
#endif
    const int ground_platform = AOHDSystem::instanceGround().ohd_platform_type();
    const int air_platform = AOHDSystem::instanceAir().ohd_platform_type();
    if (is_rock_platform(ground_platform) || is_rock_platform(air_platform)) {
        return true;
    }
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

QStringList QOpenHD::get_screen_modes()
{
#if defined(__linux__)
    if (!is_platform_rock()) {
        m_screen_modes_last_error = "not rock platform";
        return {};
    }
    DrmContext ctx;
    QString error;
    if (!get_drm_context(ctx, error)) {
        m_screen_modes_last_error = error;
        const auto fallback = get_modes_from_modetest();
        if (!fallback.isEmpty()) {
            m_screen_modes_last_error = "ok (modetest fallback)";
            return fallback;
        }
        const QString current = get_screen_mode_current();
        if (current != "NA") {
            m_screen_modes_last_error = "ok (current mode fallback)";
            return {current};
        }
        return {};
    }
    QStringList modes;
    for (int i = 0; i < ctx.connector->count_modes; ++i) {
        modes.push_back(mode_to_string(ctx.connector->modes[i]));
    }
    modes.removeDuplicates();
    release_drm_context(ctx);
    if (modes.isEmpty()) {
        const auto fallback = get_modes_from_modetest();
        if (!fallback.isEmpty()) {
            m_screen_modes_last_error = "ok (modetest fallback)";
            return fallback;
        }
        m_screen_modes_last_error = "no modes from drm or modetest";
    }
    if (!modes.isEmpty()) {
        m_screen_modes_last_error = "ok";
    }
    return modes;
#else
    m_screen_modes_last_error = "not linux";
    return {};
#endif
}

QString QOpenHD::get_screen_mode_current()
{
#if defined(__linux__)
    if (!is_platform_rock()) {
        m_screen_modes_last_error = "not rock platform";
        return QString("NA");
    }
    DrmContext ctx;
    QString error;
    if (!get_drm_context(ctx, error)) {
        m_screen_modes_last_error = error;
        const auto fallback = get_modes_from_modetest();
        if (!fallback.isEmpty()) {
            m_screen_modes_last_error = "ok (modetest fallback)";
            return fallback.first();
        }
        return QString("NA");
    }
    QString mode = QString("NA");
    if (ctx.crtc && ctx.crtc->mode_valid) {
        mode = mode_to_string(ctx.crtc->mode);
    } else if (ctx.connector && ctx.connector->count_modes > 0) {
        mode = mode_to_string(ctx.connector->modes[0]);
    }
    release_drm_context(ctx);
    if (mode == "NA") {
        const auto fallback = get_modes_from_modetest();
        if (!fallback.isEmpty()) {
            m_screen_modes_last_error = "ok (modetest fallback)";
            return fallback.first();
        }
        m_screen_modes_last_error = "current mode not found";
    } else {
        m_screen_modes_last_error = "ok";
    }
    return mode;
#else
    m_screen_modes_last_error = "not linux";
    return QString("NA");
#endif
}

bool QOpenHD::set_screen_mode(QString mode)
{
#if defined(__linux__)
    if (!is_platform_rock()) {
        return false;
    }
    int width = 0;
    int height = 0;
    int refresh = 0;
    if (!parse_mode_string(mode, width, height, refresh)) {
        qWarning() << "set_screen_mode: invalid mode string" << mode;
        return false;
    }
    DrmContext ctx;
    QString error;
    if (!get_drm_context(ctx, error)) {
        m_screen_modes_last_error = error;
        return false;
    }
    if (!ctx.crtc || !ctx.connector) {
        release_drm_context(ctx);
        return false;
    }
    const drmModeModeInfo* chosen = nullptr;
    for (int i = 0; i < ctx.connector->count_modes; ++i) {
        const drmModeModeInfo& m = ctx.connector->modes[i];
        if (m.hdisplay != width || m.vdisplay != height) {
            continue;
        }
        const int refresh_int = static_cast<int>(std::round(calc_vrefresh(m)));
        if (refresh == 0 || refresh_int == refresh) {
            chosen = &m;
            break;
        }
    }
    if (!chosen) {
        qWarning() << "set_screen_mode: mode not found" << mode;
        release_drm_context(ctx);
        return false;
    }
    if (ctx.crtc->buffer_id == 0) {
        qWarning() << "set_screen_mode: current CRTC has no FB";
        release_drm_context(ctx);
        return false;
    }
    drmModeModeInfo chosen_mode = *chosen;
    const int ret = drmModeSetCrtc(ctx.fd,
                                   ctx.crtc_id,
                                   ctx.crtc->buffer_id,
                                   0,
                                   0,
                                   &ctx.connector_id,
                                   1,
                                   &chosen_mode);
    if (ret != 0) {
        qWarning() << "set_screen_mode: drmModeSetCrtc failed" << strerror(errno);
        release_drm_context(ctx);
        return false;
    }
    QSettings settings;
    settings.setValue("screen_mode_override", mode);
    release_drm_context(ctx);
    return true;
#else
    Q_UNUSED(mode);
    return false;
#endif
}

int QOpenHD::get_ui_fps_cap()
{
#if defined(__linux__)
    if (!is_platform_rock()) {
        return 0;
    }
    QSettings settings;
    return settings.value("ui_fps_cap", 30).toInt();
#else
    return 0;
#endif
}

QString QOpenHD::get_screen_modes_last_error()
{
    return m_screen_modes_last_error;
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
