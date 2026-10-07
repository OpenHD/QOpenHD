#include "adsbvehiclemanager.h"
#include <QCoreApplication>
#include <QPointer>
#include <QSignalSpy>
#include <QSslSocket>
#include <QTemporaryDir>
#include <QtTest>
#include <QAbstractItemModelTester>
#include <cstring>

class JsonReply : public QNetworkReply {
public:
    explicit JsonReply(QByteArray data) : bytes(std::move(data)) {
        open(QIODevice::ReadOnly);
        setFinished(true);
    }
    void abort() override {}
    qint64 bytesAvailable() const override { return bytes.size() - offset; }
protected:
    qint64 readData(char* data, qint64 maximum) override {
        const qint64 count = qMin(maximum, bytes.size() - offset);
        if (!count) return -1;
        std::memcpy(data, bytes.constData() + offset, size_t(count));
        offset += count;
        return count;
    }
private:
    QByteArray bytes;
    qint64 offset = 0;
};

class InternetTest : public QObject {
    Q_OBJECT
private slots:
    void workerLifecycle() {
        QSettings settings;
        settings.setValue("adsb_enable", false);
        settings.sync();
        for (int i = 0; i < 200; ++i) {
            ADSBInternet internet;
            ADSBSdr sdr;
            QVERIFY(!internet.isRunning());
            QVERIFY(!sdr.isRunning());
            internet.start();
            sdr.start();
            sdr.setGroundIP("127.0.0.2");
            QVERIFY(QMetaObject::invokeMethod(&internet, "requestData", Qt::BlockingQueuedConnection));
            QVERIFY(QMetaObject::invokeMethod(&sdr, "requestData", Qt::BlockingQueuedConnection));
            // Destruct while their timers/event loops are still active.
        }
        ADSBVehicleManager manager;
        manager.setGroundIP("127.0.0.1"); // QML may call before startup.
        manager.onStarted();
        manager.onStarted();
    }
    void mavlinkTrafficChurn() {
        QSettings settings;
        settings.setValue("adsb_enable", true);
        settings.setValue("adsb_source", 1);
        settings.sync();
        ADSBVehicleManager manager;
        QAbstractItemModelTester tester(manager.adsbVehicles(), QAbstractItemModelTester::FailureReportingMode::QtTest);
        for (int cycle = 0; cycle < 20; ++cycle) {
            QThread* receiver = QThread::create([&] {
                for (int i = 1; i <= 250; ++i) {
                    mavlink_adsb_vehicle_t vehicle{};
                    vehicle.ICAO_address = uint32_t(i);
                    vehicle.flags = ADSB_FLAGS_VALID_COORDS | ADSB_FLAGS_VALID_CALLSIGN;
                    vehicle.lat = 512500000;
                    vehicle.lon = 71500000;
                    std::memcpy(vehicle.callsign, "TRAFFIC", 7);
                    manager.processMavlinkVehicle(vehicle);
                    manager.processMavlinkVehicle(vehicle);
                }
            });
            receiver->start();
            QVERIFY(receiver->wait(5000));
            delete receiver;
            QTRY_COMPARE(manager.adsbVehicles()->count(), 250);
            auto aircraft = qobject_cast<ADSBVehicle*>(manager.adsbVehicles()->get(0));
            QCOMPARE(aircraft->thread(), manager.thread());
            QVERIFY(qIsNaN(aircraft->property("distance").toDouble()));
            manager.adsbClearModel();
            QCoreApplication::sendPostedEvents(nullptr, QEvent::DeferredDelete);
        }
        manager.setReferencePosition(51.25, 7.15);
        mavlink_adsb_vehicle_t vehicle{};
        vehicle.ICAO_address = 1;
        vehicle.flags = ADSB_FLAGS_VALID_COORDS;
        vehicle.lat = 512500000;
        vehicle.lon = 71500000;
        manager.processMavlinkVehicle(vehicle);
        QCOMPARE(manager.adsbVehicles()->get(0)->property("distance").toDouble(), 0.0);
    }
    void modelInsertions() {
        QmlObjectListModel model;
        QAbstractItemModelTester tester(&model, QAbstractItemModelTester::FailureReportingMode::QtTest);
        QObject first, second, third;
        int oldCount = -1;
        connect(&model, &QAbstractItemModel::rowsAboutToBeInserted, this,
                [&] { oldCount = model.count(); });
        model.append(&first);
        QCOMPARE(oldCount, 0);
        model.insert(0, QList<QObject*>{&second, &third});
        QCOMPARE(oldCount, 1);
        QCOMPARE(model.get(0), &second);
        QCOMPARE(model.get(1), &third);
        QCOMPARE(model.get(2), &first);
        model.removeAt(1);
        model.clear();
    }
    void resetThenReceiveSameAircraft() {
        ADSBVehicleManager manager;
        ADSBVehicle::VehicleInfo_t info{};
        info.icaoAddress = 0xabcdef;
        manager.adsbVehicleUpdate(info);
        QPointer<QObject> old = manager.adsbVehicles()->get(0);
        QSignalSpy resets(manager.adsbVehicles(), &QAbstractItemModel::modelReset);
        manager.adsbClearModel();
        QCOMPARE(resets.count(), 1);
        QCoreApplication::sendPostedEvents(nullptr, QEvent::DeferredDelete);
        QVERIFY(old.isNull());
        info.callsign = "NEW";
        info.availableFlags = ADSBVehicle::CallsignAvailable;
        manager.adsbVehicleUpdate(info);
        QCOMPARE(manager.adsbVehicles()->count(), 1);
        QCOMPARE(manager.adsbVehicles()->get(0)->property("callsign").toString(), QString("NEW"));
    }
    void waitingAndFeedValidation() {
        QSettings settings;
        settings.setValue("adsb_enable", true);
        settings.setValue("adsb_source", 0);
        settings.setValue("adsb_show_unknown_or_zero_alt", true);
        settings.setValue("adsb_radius", 50000);
        settings.sync();
        ADSBInternet worker;
        worker.start();
        QSignalSpy status(&worker, &ADSBapi::sourceStatusChanged);
        QSignalSpy traffic(&worker, &ADSBapi::adsbVehicleUpdate);
        auto request = [&] {
            QMetaObject::invokeMethod(&worker, "requestData", Qt::BlockingQueuedConnection);
        };
        request();
        QCOMPARE(status.takeLast().at(0).toUInt(), 3u);
        QMetaObject::invokeMethod(&worker, [&] { worker.setReferencePosition(51.25, 7.15); }, Qt::BlockingQueuedConnection);
        auto feed = [&](const QByteArray& bytes) {
            QMetaObject::invokeMethod(&worker, [&] {
                auto reply = new JsonReply(bytes);
                QMetaObject::invokeMethod(&worker, "processReply", Qt::DirectConnection,
                                          Q_ARG(QNetworkReply*, reply));
            }, Qt::BlockingQueuedConnection);
        };
        feed(R"({"ac":[]})");
        QCOMPARE(status.takeLast().at(0).toUInt(), 2u);
        feed(R"({"error":"unavailable"})");
        QCOMPARE(status.takeLast().at(0).toUInt(), 1u);
        feed(R"({"ac":[
            {"hex":"abcdef","lat":51.251,"lon":7.151,"seen_pos":1,"alt_baro":10000},
            {"hex":"000001","lon":7.15,"seen_pos":1},
            {"hex":"000002","lat":51.25,"lon":7.15,"seen_pos":30},
            {"hex":"000003","lat":55.0,"lon":7.15,"seen_pos":1},
            {"hex":"000004","lat":"bad","lon":7.15,"seen_pos":1}
        ]})");
        QCOMPARE(traffic.count(), 1);
        const auto info = qvariant_cast<ADSBVehicle::VehicleInfo_t>(traffic.first().at(0));
        QCOMPARE(info.icaoAddress, uint32_t(0xabcdef));
        QVERIFY(info.distance < 1);
        settings.setValue("adsb_enable", false);
        settings.sync();
        request();
        QCOMPARE(status.takeLast().at(0).toUInt(), 0u);
    }
};

// Optional integration check: obtain an IP position and live traffic, with no
// map, GPS, MAVLink connection or SDR. Run from the deployed DLL directory.
static int liveCheck(QCoreApplication& app) {
    if (!QSslSocket::supportsSsl()) return 10;
    QSettings settings;
    settings.setValue("adsb_enable", true);
    settings.setValue("adsb_source", 0);
    settings.setValue("adsb_radius", 200000);
    settings.setValue("adsb_show_unknown_or_zero_alt", true);
    settings.sync();
    ADSBInternet worker;
    worker.start();
    QNetworkAccessManager network;
    int count = 0;
    QObject::connect(&worker, &ADSBapi::adsbVehicleUpdate, &app, [&](const ADSBVehicle::VehicleInfo_t&) { ++count; });
    QObject::connect(&worker, &ADSBapi::sourceStatusChanged, &app, [&](uint status) {
        if (status == 2) QTimer::singleShot(100, &app, [&] {
            qInfo() << "Internet position -> live ADS-B: aircraft=" << count;
            app.exit(count > 0 ? 0 : 12);
        });
        if (status == 1) app.exit(11);
    });
    auto reply = network.get(QNetworkRequest(QUrl("https://ipwho.is/?fields=success,latitude,longitude")));
    QObject::connect(reply, &QNetworkReply::finished, &app, [&, reply] {
        const auto json = QJsonDocument::fromJson(reply->readAll()).object();
        if (reply->error() || !json.value("success").toBool() ||
                !json.value("latitude").isDouble() || !json.value("longitude").isDouble()) {
            qWarning() << "Internet position failed:" << reply->errorString();
            app.exit(13);
            return;
        }
        const double latitude = json.value("latitude").toDouble();
        const double longitude = json.value("longitude").toDouble();
        qInfo() << "Internet approximation available; GPS/SDR absent; TLS=" << QSslSocket::sslLibraryVersionString();
        QMetaObject::invokeMethod(&worker, [&, latitude, longitude] { worker.setReferencePosition(latitude, longitude); }, Qt::QueuedConnection);
        QMetaObject::invokeMethod(&worker, "requestData", Qt::QueuedConnection);
        reply->deleteLater();
    });
    QTimer::singleShot(25000, &app, [&] { app.exit(14); });
    return app.exec();
}

int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    QTemporaryDir settingsDirectory;
    QCoreApplication::setOrganizationName("QOpenHD-test");
    QCoreApplication::setApplicationName("adsb-internet");
    QSettings::setDefaultFormat(QSettings::IniFormat);
    QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, settingsDirectory.path());
    qRegisterMetaType<ADSBVehicle::VehicleInfo_t>();
    if (app.arguments().contains("--live")) return liveCheck(app);
    InternetTest test;
    return QTest::qExec(&test, argc, argv);
}
#include "adsb_internet_test.moc"
