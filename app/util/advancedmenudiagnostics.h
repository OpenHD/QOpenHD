#pragma once

#include <QObject>
#include <QPointer>
#include <QQuickWindow>
#include <QTimer>
#include <QVariantMap>
#include <condition_variable>
#include <functional>
#include <deque>
#include <mutex>
#include <thread>

// Observes loading; never fetches parameters or waits on telemetry. The worker
// only reads a cached snapshot, so it can report a blocked GUI thread safely.
class AdvancedMenuDiagnostics : public QObject {
public:
    explicit AdvancedMenuDiagnostics(QString logPath = {}, int slowReportMs = 5000);
    ~AdvancedMenuDiagnostics() override;
    void setSnapshotProvider(std::function<QVariantMap()> provider);
    void begin(QQuickWindow* window, bool cached, const QString& loaderState);
    void stage(const QString& name, const QString& detail = {}, bool failed = false);
    void ready();
    void cancel(const QString& reason);
    QString logPath() const;

private:
    struct State {
        bool active = false;
        bool ready = false;
        bool readyFrameSynced = false;
        bool cached = false;
        quint64 id = 0;
        qint64 start = 0, lastGui = 0, lastFrame = 0;
        qint64 maxGuiGap = 0, maxFrameGap = 0, readyMs = -1;
        qint64 lastReport = 0, lastSnapshot = 0;
        QString phase;
        QVariantMap snapshot;
    };
    static qint64 nowMs();
    QVariantMap recordLocked(const QString& event, qint64 now) const;
    void writeRecord(QVariantMap record);
    void writeRecordToDisk(const QVariantMap& record);
    void guiTick();
    void presentedFrame();
    void watchdog();

    mutable std::mutex m_mutex;
    std::deque<QVariantMap> m_records;
    std::condition_variable m_wake;
    bool m_stop = false;
    bool m_fileErrorReported = false; // Worker thread only.
    State m_state;
    const QString m_logPath;
    const int m_slowReportMs;
    std::thread m_worker;
    std::function<QVariantMap()> m_snapshotProvider;
    QTimer m_guiTimer;
    QPointer<QQuickWindow> m_window;
    QMetaObject::Connection m_frameConnection;
    QMetaObject::Connection m_syncConnection;
};
