#include "map/offlinemaptileprovider.h"

#include <QCoreApplication>
#include <QEventLoop>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QTimer>
#include <QUrl>

#include <cmath>
#include <iostream>

int main(int argc, char** argv)
{
    QCoreApplication application(argc, argv);
    if (argc != 2 && argc != 5) {
        std::cerr << "usage: qopenhd-offline-map-test <package-directory> [latitude longitude expected-name]\n";
        return 2;
    }
    const double latitude = argc == 5 ? QString::fromLocal8Bit(argv[2]).toDouble() : 50.3192371;
    const double longitude = argc == 5 ? QString::fromLocal8Bit(argv[3]).toDouble() : 6.3570094;
    const QString expectedName = argc == 5 ? QString::fromLocal8Bit(argv[4]) : QStringLiteral("Revival Ranch");
    qputenv("GLIDE_MAP_PACKAGE_DIR", argv[1]);
    OfflineMapTileProvider provider;
    provider.setPosition(latitude, longitude);
    if (!provider.available() || !provider.activePackageName().contains(expectedName)) {
        std::cerr << "Expected package was not discovered or selected\n";
        return 3;
    }

    constexpr int zoom = 15;
    const int tileX = static_cast<int>((longitude + 180.0) / 360.0 * (1 << zoom));
    const double latitudeRadians = latitude * 3.14159265358979323846 / 180.0;
    const int tileY = static_cast<int>((1.0 - std::asinh(std::tan(latitudeRadians)) / 3.14159265358979323846) * 0.5 * (1 << zoom));
    const QUrl url(provider.baseUrl() + QStringLiteral("%1/%2/%3.png").arg(zoom).arg(tileX).arg(tileY));

    QNetworkAccessManager network;
    auto* reply = network.get(QNetworkRequest(url));
    QEventLoop loop;
    QTimer timeout;
    timeout.setSingleShot(true);
    QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
    QObject::connect(&timeout, &QTimer::timeout, &loop, &QEventLoop::quit);
    timeout.start(5000);
    loop.exec();
    const auto payload = reply->readAll();
    const bool validPng = reply->error() == QNetworkReply::NoError
        && payload.startsWith(QByteArray::fromHex("89504e470d0a1a0a"));
    if (!validPng) {
        std::cerr << "Tile request failed: " << reply->errorString().toStdString() << " bytes=" << payload.size() << "\n";
        return 4;
    }
    std::cout << provider.activePackageName().toStdString() << ": " << payload.size() << " PNG bytes from "
              << url.toString().toStdString() << "\n";
    return 0;
}
