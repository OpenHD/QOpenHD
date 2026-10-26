#include "map/offlinemaptileprovider.h"
#include <QCoreApplication>
#include <QEventLoop>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QTimer>
#include <iostream>

int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    OfflineMapTileProvider provider;
    QNetworkAccessManager network;
    // These requests must be rejected locally, without an upstream request or key.
    for (const auto& path : {"0/0/0.png", "23/0/0.png", "1/2/0.png", "1/0/4294967296.png", "../settings"}) {
        auto* reply = network.get(QNetworkRequest(QUrl(provider.mapboxBaseUrl() + path)));
        QEventLoop loop;
        QTimer timer;
        timer.setSingleShot(true);
        QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
        QObject::connect(&timer, &QTimer::timeout, &loop, &QEventLoop::quit);
        timer.start(2000);
        loop.exec();
        if (!reply->isFinished() || reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt() != 404
            || reply->rawHeader("Cache-Control") != "no-store") {
            std::cerr << "Invalid or unconfigured map tile request was not rejected\n";
            return 1;
        }
        reply->deleteLater();
    }
    std::cout << "Map raster request validation passed\n";
}
