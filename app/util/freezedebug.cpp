#include "freezedebug.h"

#include <QDebug>
#include <QCoreApplication>

namespace {
FreezeDebug* g_instance = nullptr;
}

FreezeDebug::FreezeDebug(QObject* parent)
    : QObject(parent)
{
}

FreezeDebug* FreezeDebug::instancePtr()
{
    return g_instance;
}

bool FreezeDebug::envEnabled()
{
    const QByteArray value = qgetenv("QOPENHD_DEBUG_FREEZE");
    if (value.isEmpty()) {
        return false;
    }
    return value != "0";
}

void FreezeDebug::initializeFromEnv(QObject* parent)
{
    if (g_instance != nullptr) {
        return;
    }
    if (!envEnabled()) {
        return;
    }
    g_instance = new FreezeDebug(parent);
    g_instance->start();
}

bool FreezeDebug::enabled()
{
    return g_instance != nullptr;
}

void FreezeDebug::start()
{
    m_elapsed.start();
    m_tick_timer.setInterval(2000);
    connect(&m_tick_timer, &QTimer::timeout, this, &FreezeDebug::onTick);
    m_tick_timer.start();
    qDebug() << "[FreezeDebug] enabled";
}

void FreezeDebug::countTelemetryUpdate()
{
    if (!enabled()) {
        return;
    }
    g_instance->m_telemetry_count.fetch_add(1, std::memory_order_relaxed);
}

void FreezeDebug::countStatusUpdate()
{
    if (!enabled()) {
        return;
    }
    g_instance->m_status_count.fetch_add(1, std::memory_order_relaxed);
}

void FreezeDebug::countVideoUpdate()
{
    if (!enabled()) {
        return;
    }
    g_instance->m_video_count.fetch_add(1, std::memory_order_relaxed);
}

void FreezeDebug::countModelReset()
{
    if (!enabled()) {
        return;
    }
    g_instance->m_model_reset_count.fetch_add(1, std::memory_order_relaxed);
}

void FreezeDebug::countModelDataChanged()
{
    if (!enabled()) {
        return;
    }
    g_instance->m_model_data_changed_count.fetch_add(1, std::memory_order_relaxed);
}

void FreezeDebug::recordConnectionChange(const char* who, bool connected)
{
    if (!enabled()) {
        return;
    }
    const QString msg = QString("[%1] %2")
                            .arg(who)
                            .arg(connected ? "connected" : "disconnected");
    std::lock_guard<std::mutex> lock(g_instance->m_transition_mutex);
    g_instance->m_transitions.push_back(msg);
}

void FreezeDebug::onTick()
{
    const qint64 now_ms = m_elapsed.elapsed();
    const qint64 elapsed_ms = (m_last_tick_ms >= 0) ? (now_ms - m_last_tick_ms) : 2000;
    m_last_tick_ms = now_ms;
    const double elapsed_s = elapsed_ms > 0 ? static_cast<double>(elapsed_ms) / 1000.0 : 2.0;

    const uint64_t telemetry_count = m_telemetry_count.load(std::memory_order_relaxed);
    const uint64_t status_count = m_status_count.load(std::memory_order_relaxed);
    const uint64_t video_count = m_video_count.load(std::memory_order_relaxed);
    const uint64_t model_reset_count = m_model_reset_count.load(std::memory_order_relaxed);
    const uint64_t model_data_changed_count = m_model_data_changed_count.load(std::memory_order_relaxed);

    const uint64_t telemetry_delta = telemetry_count - m_last_telemetry_count;
    const uint64_t status_delta = status_count - m_last_status_count;
    const uint64_t video_delta = video_count - m_last_video_count;
    const uint64_t model_reset_delta = model_reset_count - m_last_model_reset_count;
    const uint64_t model_data_changed_delta = model_data_changed_count - m_last_model_data_changed_count;

    m_last_telemetry_count = telemetry_count;
    m_last_status_count = status_count;
    m_last_video_count = video_count;
    m_last_model_reset_count = model_reset_count;
    m_last_model_data_changed_count = model_data_changed_count;

    QStringList transitions;
    {
        std::lock_guard<std::mutex> lock(m_transition_mutex);
        transitions = m_transitions;
        m_transitions.clear();
    }

    qDebug().nospace()
        << "[FreezeDebug] ui_tick_ms=" << elapsed_ms
        << " telemetry_hz=" << (telemetry_delta / elapsed_s)
        << " status_hz=" << (status_delta / elapsed_s)
        << " video_hz=" << (video_delta / elapsed_s)
        << " model_reset_hz=" << (model_reset_delta / elapsed_s)
        << " model_data_changed_hz=" << (model_data_changed_delta / elapsed_s)
        << " transitions=" << transitions.join(", ");
}
