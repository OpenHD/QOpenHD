#include "asyncping.h"
#include "asynccommandrunner.h"
#include <QCoreApplication>
#include <QSignalSpy>
#include <QtTest>

class AsyncPingTest : public QObject {
    Q_OBJECT
private slots:
    void menuCommandDoesNotBlockHudEvents() {
        AsyncCommandRunner runner;
        QSignalSpy results(&runner, &AsyncCommandRunner::finished);
        QTimer hud;
        int ticks = 0;
        connect(&hud, &QTimer::timeout, this, [&] { ++ticks; });
        hud.start(10);
        QVERIFY(runner.run("service", QCoreApplication::applicationFilePath(), {"--slow-command"}, "DONE"));
        QVERIFY(!runner.run("service", QCoreApplication::applicationFilePath(), {"--slow-command"}));
        QTRY_COMPARE(results.count(), 1);
        QVERIFY(ticks >= 10);
        QCOMPARE(results.at(0).at(1).toString(), QString("DONE"));
        QVERIFY(results.at(0).at(2).toBool());
        QVERIFY(runner.run("service", "qopenhd-nonexistent-command-test", {}));
        QTRY_COMPARE(results.count(), 2);
        QVERIFY(!results.at(1).at(2).toBool());
    }
    void successAndFailure() {
        AsyncPing ping(nullptr, QCoreApplication::applicationFilePath());
        QSignalSpy results(&ping, &AsyncPing::finished);
        QVERIFY(!ping.start("not-an-address"));
        QVERIFY(ping.start("127.0.0.1"));
        QVERIFY(!ping.start("127.0.0.3"));
        QTRY_COMPARE(results.count(), 1);
        QCOMPARE(results.at(0).at(0).toString(), QString("127.0.0.1"));
        QVERIFY(results.at(0).at(1).toBool());
        QVERIFY(ping.start("127.0.0.3"));
        QTRY_COMPARE(results.count(), 2);
        QVERIFY(!results.at(1).at(1).toBool());
    }
    void slowProbeDoesNotBlockHudEvents() {
        AsyncPing ping(nullptr, QCoreApplication::applicationFilePath());
        QSignalSpy results(&ping, &AsyncPing::finished);
        QTimer hud;
        int ticks = 0;
        connect(&hud, &QTimer::timeout, this, [&] { ++ticks; });
        hud.start(10);
        QElapsedTimer elapsed;
        elapsed.start();
        QVERIFY(ping.start("127.0.0.2"));
        QVERIFY(elapsed.elapsed() < 100);
        QTRY_COMPARE(results.count(), 1);
        QVERIFY(!results.at(0).at(1).toBool());
        QVERIFY(ticks >= 5);
        QVERIFY(elapsed.elapsed() < 1500);
    }
    void cancelAndRestart() {
        AsyncPing ping(nullptr, QCoreApplication::applicationFilePath());
        QSignalSpy results(&ping, &AsyncPing::finished);
        QVERIFY(ping.start("127.0.0.2"));
        QTest::qWait(100);
        ping.cancel();
        bool restarted = false;
        QTRY_VERIFY((restarted = restarted || ping.start("127.0.0.1")));
        QTRY_COMPARE(results.count(), 1);
        QCOMPARE(results.at(0).at(0).toString(), QString("127.0.0.1"));
        QVERIFY(results.at(0).at(1).toBool());
        QTest::qWait(450);
        QCOMPARE(results.count(), 1); // No stale timeout/result from the canceled probe.
    }
    void missingProgram() {
        AsyncPing ping(nullptr, "qopenhd-nonexistent-ping-test-program");
        QSignalSpy results(&ping, &AsyncPing::finished);
        QVERIFY(ping.start("127.0.0.1"));
        QTRY_COMPARE(results.count(), 1);
        QVERIFY(!results.at(0).at(1).toBool());
    }
};

int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    const auto args = app.arguments();
    if (args.contains("--slow-command")) {
        QTimer::singleShot(350, &app, [&] { app.exit(0); });
        return app.exec();
    }
    // Child mode substitutes a deterministic slow/success/failure ping process.
    if (args.contains("-n") || args.contains("-c")) {
        const auto ip = args.last();
        QTimer::singleShot(ip == "127.0.0.2" ? 2000 : 80, &app,
                           [&] { app.exit(ip == "127.0.0.3" ? 1 : 0); });
        return app.exec();
    }
    AsyncPingTest test;
    return QTest::qExec(&test, argc, argv);
}
#include "async_ping_test.moc"
