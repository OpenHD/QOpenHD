#pragma once
#include <QObject>
#include <QSet>
#include <QStringList>

class AsyncCommandRunner : public QObject {
    Q_OBJECT
public:
    explicit AsyncCommandRunner(QObject* parent = nullptr) : QObject(parent) {}
    bool run(QString id, QString program, QStringList arguments,
             QString successText = {}, QString outputFile = {});
signals:
    void finished(QString id, QString result, bool success);
private:
    QSet<QString> m_running;
};
