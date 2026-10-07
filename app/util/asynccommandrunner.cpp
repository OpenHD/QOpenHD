#include "asynccommandrunner.h"
#include <QProcess>
#include <memory>

bool AsyncCommandRunner::run(QString id, QString program, QStringList arguments,
                             QString successText, QString outputFile)
{
    if (m_running.contains(id)) return false;
    m_running.insert(id);
    auto process = new QProcess(this);
    if (!outputFile.isEmpty()) process->setStandardOutputFile(outputFile);
    auto completed = std::make_shared<bool>(false);
    auto finish = [this, process, id, successText, completed](bool success) {
        if (*completed) return;
        *completed = true;
        m_running.remove(id);
        QString result = successText;
        if (success && result.isEmpty()) result = QString::fromLocal8Bit(process->readAllStandardOutput()).trimmed();
        if (!success) {
            auto reason = QString::fromLocal8Bit(process->readAllStandardError()).trimmed();
            if (reason.isEmpty()) reason = process->errorString();
            result = tr("Command failed: %1").arg(reason);
        }
        process->deleteLater();
        emit finished(id, result, success);
    };
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [finish](int code, QProcess::ExitStatus status) { finish(code == 0 && status == QProcess::NormalExit); });
    connect(process, &QProcess::errorOccurred, this, [finish](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart) finish(false);
    });
    process->start(program, arguments);
    return true;
}
