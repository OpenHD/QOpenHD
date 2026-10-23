#include "util/advancedmenudiagnostics.h"
#include <QGuiApplication>
#include <QTemporaryDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QThread>
#include <cstdlib>

static void check(bool value, const char* message) {
    if (!value) qFatal("%s", message);
}
static QList<QJsonObject> records(const QString& path) {
    QFile file(path);
    check(file.open(QIODevice::ReadOnly), "log exists");
    QList<QJsonObject> result;
    for (const auto& line : file.readAll().split('\n')) {
        if (line.isEmpty()) continue;
        const auto doc = QJsonDocument::fromJson(line);
        check(doc.isObject(), "valid JSON record");
        result.append(doc.object());
    }
    return result;
}
static QList<QJsonObject> waitFor(const QString& path, const QString& event) {
    for (int i = 0; i < 100; ++i) {
        auto rows = records(path);
        if (!rows.isEmpty() && rows.last()["event"] == event) return rows;
        QThread::msleep(10);
    }
    qFatal("Timed out waiting for %s", qPrintable(event));
    return {};
}
int main(int argc, char** argv) {
    QGuiApplication app(argc, argv);
    QTemporaryDir directory;
    const auto path = directory.filePath("timing.jsonl");
    QQuickWindow window;
    AdvancedMenuDiagnostics diagnostics(path, 200);
    int snapshots = 0;
    diagnostics.setSnapshotProvider([&] {
        check(QThread::currentThread() == app.thread(), "snapshot stays on GUI thread");
        ++snapshots;
        return QVariantMap{{"parameters_air", QVariantMap{{"busy", true}, {"progress_percent", 17}}}};
    });
    diagnostics.begin(&window, false, "null");
    diagnostics.stage("page_loader", "PanelStatus.qml");
    // Do not pump events: the independent worker must diagnose a blocked GUI.
    QThread::msleep(1350);
    bool stalled = false;
    for (const auto& row : records(path)) {
        if (row["event"] == "still_loading" && row["gui_gap_ms"].toInt() >= 1000) {
            stalled = row["observation"] == "gui_thread_stalled";
            check(row["parameters_air"].toObject()["progress_percent"] == 17, "cached parameter state");
            check(row["snapshot_age_ms"].toInt() >= 1000, "stale snapshot is identified");
        }
    }
    check(stalled, "watchdog reports while GUI is blocked");
    check(snapshots == 1, "watchdog does not call snapshot provider");
    diagnostics.ready();
    QMetaObject::invokeMethod(&window, "frameSwapped", Qt::DirectConnection);
    waitFor(path, "page_ready");
    QMetaObject::invokeMethod(&window, "beforeSynchronizing", Qt::DirectConnection);
    QMetaObject::invokeMethod(&window, "frameSwapped", Qt::DirectConnection);
    auto rows = waitFor(path, "first_frame");
    check(rows.last()["event"] == "first_frame", "completion after ready frame sync");
    check(rows.last()["elapsed_ms"].toInt() >= 1350, "monotonic elapsed time");
    check(rows.last()["max_gui_gap_ms"].toInt() >= 1350, "maximum GUI stall retained");
    diagnostics.begin(&window, true, "ready");
    diagnostics.cancel("menu_closed");
    waitFor(path, "cancelled");
    diagnostics.begin(&window, true, "ready");
    diagnostics.stage("page_loader", "broken.qml", true);
    diagnostics.ready();
    QMetaObject::invokeMethod(&window, "beforeSynchronizing", Qt::DirectConnection);
    QMetaObject::invokeMethod(&window, "frameSwapped", Qt::DirectConnection);
    rows = waitFor(path, "failed");
    check(rows.last()["event"] == "failed", "failure cannot complete later");
    check(rows.last()["open_id"] == 3, "reopens have distinct IDs");
    QFile large(path);
    check(large.open(QIODevice::WriteOnly), "prepare rotation");
    large.write(QByteArray(512 * 1024, 'x'));
    large.close();
    diagnostics.begin(&window, true, "ready");
    diagnostics.cancel("rotation_test");
    for (int i = 0; i < 100 && !QFile::exists(path + ".1"); ++i) QThread::msleep(10);
    waitFor(path, "cancelled");
    check(QFile::exists(path + ".1"), "bounded log rotates");
    check(QFileInfo(path).size() < 4096, "new log is bounded");
    qInfo("Advanced menu diagnostics tests passed");
}
