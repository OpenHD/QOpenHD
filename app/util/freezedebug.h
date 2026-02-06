#ifndef FREEZEDEBUG_H
#define FREEZEDEBUG_H

#include <QObject>
#include <QElapsedTimer>
#include <QTimer>
#include <QStringList>
#include <atomic>
#include <mutex>

class FreezeDebug : public QObject
{
    Q_OBJECT
public:
    static void initializeFromEnv(QObject* parent = nullptr);
    static bool enabled();

    static void countTelemetryUpdate();
    static void countStatusUpdate();
    static void countVideoUpdate();
    static void countModelReset();
    static void countModelDataChanged();
    static void recordConnectionChange(const char* who, bool connected);

private:
    explicit FreezeDebug(QObject* parent = nullptr);
    void start();
    void onTick();

    static bool envEnabled();
    static FreezeDebug* instancePtr();

private:
    QTimer m_tick_timer;
    QElapsedTimer m_elapsed;
    qint64 m_last_tick_ms = -1;

    std::atomic<uint64_t> m_telemetry_count{0};
    std::atomic<uint64_t> m_status_count{0};
    std::atomic<uint64_t> m_video_count{0};
    std::atomic<uint64_t> m_model_reset_count{0};
    std::atomic<uint64_t> m_model_data_changed_count{0};

    uint64_t m_last_telemetry_count = 0;
    uint64_t m_last_status_count = 0;
    uint64_t m_last_video_count = 0;
    uint64_t m_last_model_reset_count = 0;
    uint64_t m_last_model_data_changed_count = 0;

    std::mutex m_transition_mutex;
    QStringList m_transitions;
};

#endif // FREEZEDEBUG_H
