#pragma once

#include <QObject>
#include <QProcess>
#include <QTimer>

// A single asynchronous probe: never wait for a process on the HUD thread.
class AsyncPing : public QObject {
    Q_OBJECT
public:
    explicit AsyncPing(QObject* parent = nullptr, QString program = QStringLiteral("ping"));
    bool start(const QString& ip);
    void cancel();
signals:
    void finished(QString ip, bool reachable);
private:
    void complete(bool reachable);
    QProcess m_process;
    QTimer m_timeout;
    QString m_program;
    QString m_ip;
    bool m_active = false;
    bool m_timedOut = false;
};
