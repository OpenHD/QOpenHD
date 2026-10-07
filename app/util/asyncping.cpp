#include "asyncping.h"

#include <QHostAddress>
#include <utility>

AsyncPing::AsyncPing(QObject* parent, QString program)
    : QObject(parent), m_program(std::move(program))
{
    m_timeout.setSingleShot(true);
    m_timeout.setInterval(400);
    connect(&m_timeout, &QTimer::timeout, this, [this] {
        m_timedOut = true;
        m_process.kill(); // Completion arrives asynchronously through finished().
    });
    connect(&m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this](int code, QProcess::ExitStatus status) {
        complete(!m_timedOut && status == QProcess::NormalExit && code == 0);
    });
    connect(&m_process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart) complete(false);
    });
}

bool AsyncPing::start(const QString& ip)
{
    QHostAddress address;
    if (m_active || m_process.state() != QProcess::NotRunning || !address.setAddress(ip)) return false;
    m_ip = ip;
    m_active = true;
    m_timedOut = false;
#ifdef _WIN32
    const QStringList arguments{"-n", "1", "-w", "1000", ip};
#else
    const QStringList arguments{"-c", "1", "-W", "1", ip};
#endif
    m_timeout.start();
    m_process.start(m_program, arguments);
    return true;
}

void AsyncPing::cancel()
{
    m_active = false;
    m_timeout.stop();
    if (m_process.state() != QProcess::NotRunning) m_process.kill();
}

void AsyncPing::complete(bool reachable)
{
    m_timeout.stop();
    if (!m_active) return;
    m_active = false;
    emit finished(m_ip, reachable);
}
