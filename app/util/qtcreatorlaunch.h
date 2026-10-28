#pragma once

#include <QCoreApplication>
#include <QFileInfo>
#include <QSet>
#include <QString>
#ifdef Q_OS_WIN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <tlhelp32.h>
#else
#include <QProcess>
#endif

namespace qopenhd {
// Check ancestry, not build type, debugger attachment or an opt-in environment
// variable: those would also expose the control outside a Qt Creator launch.
inline bool launchedFromQtCreator() {
#ifdef Q_OS_ANDROID
    return false;
#elif defined(Q_OS_WIN)
    const HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snapshot == INVALID_HANDLE_VALUE) return false;
    QSet<DWORD> seen;
    DWORD pid = GetCurrentProcessId();
    bool found = false;
    for (int depth = 0; pid && depth < 32 && !seen.contains(pid); ++depth) {
        seen.insert(pid);
        PROCESSENTRY32W entry{};
        entry.dwSize = sizeof(entry);
        bool matched = false;
        if (Process32FirstW(snapshot, &entry)) do {
            if (entry.th32ProcessID != pid) continue;
            const auto name = QString::fromWCharArray(entry.szExeFile);
            found = name.compare(QStringLiteral("qtcreator.exe"), Qt::CaseInsensitive) == 0;
            pid = entry.th32ParentProcessID;
            matched = true;
            break;
        } while (Process32NextW(snapshot, &entry));
        if (found || !matched) break;
    }
    CloseHandle(snapshot);
    return found;
#else
    qint64 pid = QCoreApplication::applicationPid();
    QSet<qint64> seen;
    for (int depth = 0; pid > 1 && depth < 32 && !seen.contains(pid); ++depth) {
        seen.insert(pid);
        QProcess ps;
        ps.start(QStringLiteral("/bin/ps"), {QStringLiteral("-p"), QString::number(pid),
                 QStringLiteral("-o"), QStringLiteral("ppid="), QStringLiteral("-o"), QStringLiteral("comm=")});
        if (!ps.waitForFinished(250) || ps.exitCode() != 0) return false;
        const auto line = QString::fromLocal8Bit(ps.readAllStandardOutput()).trimmed();
        const auto space = line.indexOf(QLatin1Char(' '));
        if (space < 0) return false;
        const auto name = QFileInfo(line.mid(space).trimmed()).fileName();
        if (name.compare(QStringLiteral("qtcreator"), Qt::CaseInsensitive) == 0) return true;
        bool ok = false;
        pid = line.left(space).toLongLong(&ok);
        if (!ok) return false;
    }
    return false;
#endif
}
}
