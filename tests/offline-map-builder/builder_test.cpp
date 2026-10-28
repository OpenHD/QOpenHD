#include "offlinemapbuilder.h"
#include "offlinemaptileprovider.h"
#include <QCoreApplication>
#include <QDir>
#include <QElapsedTimer>
#include <QEventLoop>
#include <QFile>
#include <QImage>
#include <QNetworkReply>
#include <QTcpServer>
#include <QTcpSocket>
#include <QTemporaryDir>
#include <QThread>
#include <cmath>
#include <functional>
#include <iostream>

static bool waitFor(const std::function<bool()>& condition, int timeout = 10000) {
    QElapsedTimer timer; timer.start();
    while (!condition() && timer.elapsed() < timeout) {
        QCoreApplication::processEvents(QEventLoop::AllEvents, 20);
        QThread::msleep(1);
    }
    return condition();
}
#define CHECK(test) do { if (!(test)) { std::cerr << "Failed at line " << __LINE__ << ": " #test "\n"; return 1; } } while(false)

int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    QTemporaryDir output; CHECK(output.isValid());
    if (argc > 1 && QByteArray(argv[1]) == "--live") {
        qunsetenv("OPENHD_MAP_SEARCH_URL"); qunsetenv("OPENHD_MAP_DATA_URL");
        OfflineMapBuilder live(nullptr, output.path());
        QObject::connect(&live, &OfflineMapBuilder::changed, &app, [&] {
            std::cout << live.status().toStdString() << std::endl;
        });
        live.search("Wuppertal, Germany");
        CHECK(waitFor([&] { return !live.searching(); }, 25000));
        CHECK(!live.searchResults().isEmpty());
        QString path;
        QObject::connect(&live, &OfflineMapBuilder::generated, &app, [&](const QString& value) { path = value; });
        live.generate("Live smoke test", 51.2567, 7.148, 51.2587, 7.152, 15);
        CHECK(waitFor([&] { return !live.busy(); }, 250000));
        CHECK(!path.isEmpty());
        std::cout << "Live search and Overpass generation passed.\n";
        return 0;
    }
    QTcpServer server; CHECK(server.listen(QHostAddress::LocalHost, 0));
    bool invalidData = false;
    int requests = 0;
    QByteArray fixtureTile;
    bool tileTokenReceived = false;
    QObject::connect(&server, &QTcpServer::newConnection, &app, [&] {
        while (auto* socket = server.nextPendingConnection()) {
            QObject::connect(socket, &QTcpSocket::disconnected, socket, &QObject::deleteLater);
            QObject::connect(socket, &QTcpSocket::readyRead, socket, [&, socket] {
                auto data = socket->property("request").toByteArray() + socket->readAll();
                socket->setProperty("request", data);
                if (!data.contains("\r\n\r\n") || socket->property("answered").toBool()) return;
                const int headerEnd = data.indexOf("\r\n\r\n");
                int contentLength = 0;
                for (const auto& line : data.left(headerEnd).split('\n'))
                    if (line.toLower().startsWith("content-length:")) contentLength = line.mid(15).trimmed().toInt();
                if (data.size() < headerEnd + 4 + contentLength) return;
                socket->setProperty("answered", true); ++requests;
                if (data.startsWith("GET /tiles/")) tileTokenReceived = data.contains("access_token=pk.fixture");
                const QByteArray body = data.startsWith("GET /tiles/") ? fixtureTile : data.startsWith("GET /search")
                    ? QByteArray("[{\"display_name\":\"Test region\",\"boundingbox\":[\"49.999\",\"50.001\",\"7.999\",\"8.001\"]}]")
                    : invalidData ? QByteArray("{\"remark\":\"timeout\",\"elements\":[]}")
                    : QByteArray("{\"elements\":[{\"tags\":{\"highway\":\"primary\"},\"geometry\":[{\"lat\":49.998,\"lon\":7.998},{\"lat\":50.002,\"lon\":8.002}]}]}");
                socket->write("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: "
                              + QByteArray::number(body.size()) + "\r\nConnection: close\r\n\r\n" + body);
                socket->disconnectFromHost();
            });
        }
    });
    const auto base = QByteArray("http://127.0.0.1:") + QByteArray::number(server.serverPort());
    qputenv("OPENHD_MAP_SEARCH_URL", base + "/search");
    qputenv("OPENHD_MAP_DATA_URL", base + "/data");
    qputenv("OPENHD_MAPBOX_TILE_URL", base + "/tiles/");
    OfflineMapBuilder builder(nullptr, output.path());
    CHECK(builder.previewCacheDirectory() != builder.mapCacheDirectory("osm"));
    CHECK(builder.mapCacheDirectory("osm") != builder.mapCacheDirectory("openhd_offline"));
    CHECK(QDir(builder.previewCacheDirectory()).exists());
    CHECK(builder.tileCount(50, 8, 50, 9, 15) == -1);
    CHECK(builder.tileCount(49, 7, 51, 9, 15) == -1);
    CHECK(builder.tileCount(49.999, 7.999, 50.001, 8.001, 15) > 0);
    CHECK(builder.tileCount(49.999, 7.999, 50.001, 8.001, 99) == -1);
    CHECK(builder.tileCount(49.55, 7.30, 50.45, 8.70, 14) > 0); // 50 km radius bounding box
    CHECK(builder.tileCount(49.55, 7.30, 50.45, 8.70, 16) > 0);
    builder.search("Test region");
    CHECK(waitFor([&] { return !builder.searching(); }));
    CHECK(builder.searchResults().size() == 1);
    CHECK(builder.searchResults()[0].toMap()["name"].toString() == "Test region");
    QString path;
    QObject::connect(&builder, &OfflineMapBuilder::generated, &app, [&](const QString& result) { path = result; });
    builder.generate("Test field", 49.999, 7.999, 50.001, 8.001, 15);
    CHECK(waitFor([&] { return !builder.busy(); }));
    CHECK(!path.isEmpty()); CHECK(builder.progress() == 1.0);
    QFile package(path); CHECK(package.open(QIODevice::ReadOnly)); CHECK(package.read(8) == QByteArray("GLDMAP1\0", 8)); package.close();
    qputenv("GLIDE_MAP_PACKAGE_DIR", output.path().toUtf8());
    OfflineMapTileProvider provider; provider.setPosition(50, 8);
    CHECK(provider.activePackageName() == "Test field");
    CHECK(!provider.packages().isEmpty());
    CHECK(provider.packages().first().toMap()["name"] == "Test field");
    CHECK(provider.packages().first().toMap()["south"].toDouble() == 49.999);
    const int x = int((8.0 + 180) / 360 * (1 << 15));
    const int y = int((1.0 - std::asinh(std::tan(50.0 * 3.141592653589793 / 180)) / 3.141592653589793) * 0.5 * (1 << 15));
    QNetworkAccessManager network;
    auto* tile = network.get(QNetworkRequest(QUrl(provider.baseUrl() + QString("15/%1/%2.png").arg(x).arg(y))));
    CHECK(waitFor([&] { return tile->isFinished(); }));
    CHECK(tile->error() == QNetworkReply::NoError);
    fixtureTile = tile->readAll();
    const QImage image = QImage::fromData(fixtureTile, "PNG");
    CHECK(image.size() == QSize(256, 256));
    bool colored = false;
    for (int row = 0; row < 256; ++row) for (int col = 0; col < 256; ++col)
        if (image.pixelColor(col, row) != QColor("#263735")) colored = true;
    CHECK(colored); // Real geometry was rendered, rather than just a valid empty PNG.
    builder.setMapboxKey("pk.fixture");
    auto* preview = network.get(QNetworkRequest(QUrl(builder.mapboxBaseUrl() + QString("15/%1/%2.png").arg(x).arg(y))));
    CHECK(waitFor([&] { return preview->isFinished(); }));
    CHECK(preview->error() == QNetworkReply::NoError);
    CHECK(preview->readAll() == fixtureTile);
    CHECK(tileTokenReceived);
    builder.setMapboxKey(QString());
    auto* missingKey = network.get(QNetworkRequest(QUrl(builder.mapboxBaseUrl() + "15/1/1.png")));
    CHECK(waitFor([&] { return missingKey->isFinished(); }));
    CHECK(missingKey->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt() == 400);
    path.clear(); invalidData = true;
    builder.generate("Incomplete", 49.999, 7.999, 50.001, 8.001, 15);
    CHECK(waitFor([&] { return !builder.busy(); })); CHECK(path.isEmpty());
    CHECK(QDir(output.path()).entryList({"*.glidemap"}, QDir::Files).size() == 1);
    builder.generate("Cancelled", 49.999, 7.999, 50.001, 8.001, 15); builder.cancel();
    CHECK(!builder.busy()); CHECK(path.isEmpty());
    CHECK(QDir(output.path()).entryList({"*.glidemap"}, QDir::Files).size() == 1);
    invalidData = false;
    path.clear();
    const int requestsBeforeRadius = requests;
    builder.generate("50 km radius", 49.55, 7.30, 50.45, 8.70, 14);
    CHECK(waitFor([&] { return !builder.busy(); }, 60000));
    if (path.isEmpty()) std::cerr << builder.status().toStdString() << "\n";
    CHECK(!path.isEmpty());
    CHECK(builder.progress() == 1.0);
    CHECK(requests - requestsBeforeRadius > 2); // Large geometry is fetched in sections.
    std::cout << "Search, bounds, generation, GLDMAP1 playback, invalid data, and cancellation passed (" << requests << " fixture requests).\n";
    return 0;
}
