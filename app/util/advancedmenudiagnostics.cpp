#include "advancedmenudiagnostics.h"

#include <QCoreApplication>
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QStandardPaths>
#include <chrono>

namespace {
QString defaultTimingLogPath() {
#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
    // Match OpenHD's persistent_log_directory()/getVideoPath() selection.
    auto directory = qEnvironmentVariable("OPENHD_PERSISTENT_LOG_DIR");
    if (directory.isEmpty()) {
        const QString video = QFile::exists("/Videos/external_video_part.txt") ? "/Videos"
            : QFile::exists("/external/Videos/external_video_part.txt") ? "/external/Videos"
            : "/Video";
        directory = video + "/logs/openhd";
    }
    return QDir(directory).filePath("qopenhd-advanced-menu-timing.jsonl");
#else
    return QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation)
        + "/logs/advanced-menu-timing.jsonl";
#endif
}
}

AdvancedMenuDiagnostics::AdvancedMenuDiagnostics(QString path, int slowReportMs)
    : m_logPath(path.isEmpty() ? defaultTimingLogPath() : path),
      m_slowReportMs(qMax(100, slowReportMs)) {
    m_guiTimer.setInterval(100);
    connect(&m_guiTimer, &QTimer::timeout, this, [this] { guiTick(); });
}

AdvancedMenuDiagnostics::~AdvancedMenuDiagnostics() {
    disconnect(m_frameConnection);
    disconnect(m_syncConnection);
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_stop = true;
    }
    m_wake.notify_all();
    if (m_worker.joinable()) m_worker.join();
}

qint64 AdvancedMenuDiagnostics::nowMs() {
    return std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::steady_clock::now().time_since_epoch()).count();
}

QString AdvancedMenuDiagnostics::logPath() const { return m_logPath; }

void AdvancedMenuDiagnostics::setSnapshotProvider(std::function<QVariantMap()> provider) {
    m_snapshotProvider = std::move(provider);
}

void AdvancedMenuDiagnostics::begin(QQuickWindow* window, bool cached, const QString& loaderState) {
    cancel("superseded");
    if (m_window != window) {
        disconnect(m_frameConnection);
        disconnect(m_syncConnection);
        m_window = window;
        if (window) {
            m_frameConnection = connect(window, &QQuickWindow::frameSwapped, this,
                [this] { presentedFrame(); }, Qt::DirectConnection);
            m_syncConnection = connect(window, &QQuickWindow::beforeSynchronizing, this,
                [this] {
                    std::lock_guard<std::mutex> lock(m_mutex);
                    if (m_state.active && m_state.ready) m_state.readyFrameSynced = true;
                }, Qt::DirectConnection);
        }
    }
    const auto snapshot = m_snapshotProvider ? m_snapshotProvider() : QVariantMap{};
    QVariantMap record;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        const auto id = m_state.id + 1;
        m_state = State{};
        m_state.id = id;
        m_state.active = true;
        m_state.cached = cached;
        m_state.start = m_state.lastGui = m_state.lastFrame = nowMs();
        m_state.lastReport = m_state.lastSnapshot = m_state.start;
        m_state.phase = "root_" + loaderState;
        m_state.snapshot = snapshot;
        record = recordLocked("open_requested", m_state.start);
        record["log_file"] = m_logPath;
    }
    writeRecord(record);
    if (!m_worker.joinable()) m_worker = std::thread([this] { watchdog(); });
    m_guiTimer.start();
    m_wake.notify_all();
}

QVariantMap AdvancedMenuDiagnostics::recordLocked(const QString& event, qint64 now) const {
    auto result = m_state.snapshot;
    const auto guiGap = now - m_state.lastGui;
    const auto frameGap = now - m_state.lastFrame;
    result["event"] = event;
    result["open_id"] = QVariant::fromValue(m_state.id);
    result["pid"] = QCoreApplication::applicationPid();
    result["utc"] = QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs);
    result["elapsed_ms"] = now - m_state.start;
    result["phase"] = m_state.phase;
    result["cached_root"] = m_state.cached;
    result["ready_ms"] = m_state.readyMs;
    result["gui_gap_ms"] = guiGap;
    result["frame_gap_ms"] = frameGap;
    result["max_gui_gap_ms"] = qMax(guiGap, m_state.maxGuiGap);
    result["max_frame_gap_ms"] = qMax(frameGap, m_state.maxFrameGap);
    result["snapshot_age_ms"] = now - m_state.lastSnapshot;
    if (event == "still_loading") {
        result["observation"] = guiGap >= 1000 ? "gui_thread_stalled"
            : frameGap >= 2000 ? "no_presented_frames"
            : m_state.ready ? "waiting_for_first_frame" : "qml_not_ready";
    }
    return result;
}

void AdvancedMenuDiagnostics::stage(const QString& name, const QString& detail, bool failed) {
    QVariantMap record;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_state.active) return;
        m_state.phase = name;
        record = recordLocked(failed ? "failed" : "stage", nowMs());
        record["detail"] = detail;
        if (failed) m_state.active = false;
    }
    writeRecord(record);
}

void AdvancedMenuDiagnostics::ready() {
    const auto snapshot = m_snapshotProvider ? m_snapshotProvider() : QVariantMap{};
    QVariantMap record;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_state.active || m_state.ready) return;
        const auto now = nowMs();
        m_state.snapshot = snapshot;
        m_state.lastSnapshot = now;
        m_state.ready = true;
        m_state.readyMs = now - m_state.start;
        m_state.phase = "waiting_for_first_frame";
        record = recordLocked("page_ready", now);
    }
    writeRecord(record);
    if (m_window) m_window->update();
}

void AdvancedMenuDiagnostics::cancel(const QString& reason) {
    QVariantMap record;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_state.active) return;
        record = recordLocked("cancelled", nowMs());
        record["detail"] = reason;
        m_state.active = false;
    }
    writeRecord(record);
}

void AdvancedMenuDiagnostics::guiTick() {
    bool refresh;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_state.active) { m_guiTimer.stop(); return; }
        const auto now = nowMs();
        m_state.maxGuiGap = qMax(m_state.maxGuiGap, now - m_state.lastGui);
        m_state.lastGui = now;
        refresh = now - m_state.lastSnapshot >= 1000;
    }
    if (refresh && m_snapshotProvider) {
        const auto snapshot = m_snapshotProvider(); // GUI thread only.
        std::lock_guard<std::mutex> lock(m_mutex);
        m_state.snapshot = snapshot;
        m_state.lastSnapshot = nowMs();
    }
}

void AdvancedMenuDiagnostics::presentedFrame() {
    QVariantMap record;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_state.active) return;
        const auto now = nowMs();
        m_state.maxFrameGap = qMax(m_state.maxFrameGap, now - m_state.lastFrame);
        m_state.lastFrame = now;
        if (!m_state.readyFrameSynced) return;
        record = recordLocked("first_frame", now);
        m_state.active = false;
    }
    writeRecord(record);
}

void AdvancedMenuDiagnostics::watchdog() {
    std::unique_lock<std::mutex> lock(m_mutex);
    while (true) {
        if (m_records.empty() && !m_stop) {
            if (m_state.active)
                m_wake.wait_for(lock, std::chrono::milliseconds(100),
                    [this] { return m_stop || !m_records.empty(); });
            else
                m_wake.wait(lock, [this] { return m_stop || m_state.active || !m_records.empty(); });
        }
        const auto now = nowMs();
        if (!m_stop && m_state.active && now - m_state.lastReport >= m_slowReportMs) {
            m_state.lastReport = now;
            m_records.push_back(recordLocked("still_loading", now));
        }
        std::deque<QVariantMap> records;
        records.swap(m_records);
        if (m_stop && records.empty()) break;
        lock.unlock();
        for (const auto& record : records) writeRecordToDisk(record);
        lock.lock();
    }
}

void AdvancedMenuDiagnostics::writeRecord(QVariantMap record) {
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_records.push_back(std::move(record));
    }
    m_wake.notify_all();
}

void AdvancedMenuDiagnostics::writeRecordToDisk(const QVariantMap& record) {
    // A small rotating file works on Windows/Android as well as journald-based
    // images. Keep this separate from the state lock and never read UI objects.
    const auto json = QJsonDocument::fromVariant(record).toJson(QJsonDocument::Compact);
    QDir().mkpath(QFileInfo(m_logPath).absolutePath());
    if (QFileInfo(m_logPath).size() >= 512 * 1024) {
        QFile::remove(m_logPath + ".1");
        QFile::rename(m_logPath, m_logPath + ".1");
    }
    QFile file(m_logPath);
    if (file.open(QIODevice::WriteOnly | QIODevice::Append)) {
        const auto line = json + '\n';
        if (file.write(line) != line.size() || !file.flush()) {
            if (!m_fileErrorReported)
                qWarning() << "Cannot write advanced menu timing file:" << m_logPath << file.errorString();
            m_fileErrorReported = true;
        } else m_fileErrorReported = false;
    } else if (!m_fileErrorReported) {
        qWarning() << "Cannot open advanced menu timing file:" << m_logPath << file.errorString();
        m_fileErrorReported = true;
    }
    const auto line = "ADVANCED_MENU_TIMING " + QString::fromUtf8(json);
    if (record["event"] == "still_loading" || record["event"] == "failed")
        qWarning().noquote() << line;
    else qInfo().noquote() << line;
}
