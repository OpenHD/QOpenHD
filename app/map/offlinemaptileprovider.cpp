#include "offlinemaptileprovider.h"

#include <QCoreApplication>
#include <QDataStream>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QSet>
#include <QStandardPaths>
#include <QTcpSocket>

#include <cstring>

namespace {
constexpr char kMagic[8] = { 'G', 'L', 'D', 'M', 'A', 'P', '1', '\0' };

QStringList packageDirectories()
{
    QStringList paths;
    const auto configured = qEnvironmentVariable("GLIDE_MAP_PACKAGE_DIR");
    if (!configured.isEmpty()) paths << configured;
    paths << QStringLiteral("/usr/share/openhd-glide/assets/maps/packages")
          << QStringLiteral("/usr/local/share/openhd-glide/assets/maps/packages")
          << QDir(QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation)).filePath(QStringLiteral("maps"))
          << QDir(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)).filePath(QStringLiteral("openhd-glide/maps"))
          << QDir::home().filePath(QStringLiteral("openhd-glide/assets/maps/packages"))
          << QDir::current().filePath(QStringLiteral("assets/maps/packages"))
          << QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("../share/openhd-glide/assets/maps/packages"));
    paths << QDir::current().filePath(QStringLiteral("../openhd-glide/assets/maps/packages"));
    return paths;
}
}

OfflineMapTileProvider::OfflineMapTileProvider(QObject* parent)
    : QObject(parent)
{
    connect(&m_server, &QTcpServer::newConnection, this, &OfflineMapTileProvider::acceptConnections);
    if (!m_server.listen(QHostAddress::LocalHost, 0)) {
        qWarning() << "Offline map tile server could not listen:" << m_server.errorString();
    }
    reload();
}

QString OfflineMapTileProvider::baseUrl() const
{
    return QStringLiteral("http://127.0.0.1:%1/").arg(m_server.serverPort());
}

QString OfflineMapTileProvider::activePackageName() const
{
    return m_activePackage >= 0 && m_activePackage < m_packages.size() ? m_packages[m_activePackage].name : QString();
}

bool OfflineMapTileProvider::Package::contains(double latitude, double longitude) const
{
    return latitude >= south && latitude <= north && longitude >= west && longitude <= east;
}

double OfflineMapTileProvider::Package::area() const
{
    return (east - west) * (north - south);
}

quint64 OfflineMapTileProvider::tileKey(int zoom, int x, int y)
{
    return (static_cast<quint64>(zoom & 0x3f) << 58U)
        | (static_cast<quint64>(x & 0x1fffffff) << 29U)
        | static_cast<quint64>(y & 0x1fffffff);
}

bool OfflineMapTileProvider::loadPackage(const QString& path, Package& package) const
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) return false;
    char magic[8] {};
    if (file.read(magic, 8) != 8 || std::memcmp(magic, kMagic, 8) != 0) return false;
    QDataStream input(&file);
    input.setByteOrder(QDataStream::LittleEndian);
    input.setFloatingPointPrecision(QDataStream::DoublePrecision);
    quint32 version = 0, tileCount = 0;
    quint16 tileSize = 0, nameLength = 0, attributionLength = 0;
    input >> version >> tileSize >> package.minZoom >> package.maxZoom
          >> package.south >> package.west >> package.north >> package.east
          >> nameLength >> attributionLength >> tileCount;
    if (input.status() != QDataStream::Ok || version != 1 || tileSize != 256 || package.minZoom > package.maxZoom
        || tileCount > 10000000U || nameLength > 4096 || attributionLength > 16384
        || package.south >= package.north || package.west >= package.east) return false;
    package.name = QString::fromUtf8(file.read(nameLength));
    file.read(attributionLength);
    package.path = path;
    package.tiles.reserve(static_cast<int>(tileCount));
    for (quint32 index = 0; index < tileCount; ++index) {
        quint8 zoom = 0;
        quint32 x = 0, y = 0, length = 0;
        quint64 offset = 0;
        input >> zoom >> x >> y >> offset >> length;
        if (input.status() != QDataStream::Ok || length == 0) return false;
        package.tiles.insert(tileKey(zoom, static_cast<int>(x), static_cast<int>(y)), { offset, length });
    }
    return !package.tiles.isEmpty();
}

void OfflineMapTileProvider::reload()
{
    const auto oldName = activePackageName();
    m_packages.clear();
    m_activePackage = -1;
    QSet<QString> seen;
    for (const auto& directory : packageDirectories()) {
        const QDir dir(directory);
        qInfo() << "Searching for OpenHD offline maps in" << dir.absolutePath();
        for (const auto& info : dir.entryInfoList({ QStringLiteral("*.glidemap") }, QDir::Files | QDir::Readable)) {
            const auto canonical = info.canonicalFilePath();
            if (canonical.isEmpty() || seen.contains(canonical)) continue;
            seen.insert(canonical);
            Package package;
            if (loadPackage(canonical, package)) {
                qInfo() << "Loaded OpenHD offline map" << package.name << canonical << package.tiles.size() << "tiles";
                m_packages.push_back(std::move(package));
            } else {
                qWarning() << "Ignored invalid OpenHD offline map" << canonical;
            }
        }
    }
    emit packagesChanged();
    if (oldName != activePackageName()) emit activePackageChanged();
}

void OfflineMapTileProvider::setPosition(double latitude, double longitude)
{
    int best = -1;
    for (int index = 0; index < m_packages.size(); ++index) {
        const auto& candidate = m_packages[index];
        if (!candidate.contains(latitude, longitude)) continue;
        if (best < 0 || candidate.maxZoom > m_packages[best].maxZoom
            || (candidate.maxZoom == m_packages[best].maxZoom && candidate.area() < m_packages[best].area())) best = index;
    }
    if (best != m_activePackage) {
        m_activePackage = best;
        qInfo() << "Active OpenHD offline map:" << activePackageName();
        emit activePackageChanged();
    }
}

QByteArray OfflineMapTileProvider::readTile(int zoom, int x, int y) const
{
    const auto key = tileKey(zoom, x, y);
    QList<int> order;
    if (m_activePackage >= 0) order << m_activePackage;
    for (int index = 0; index < m_packages.size(); ++index) if (index != m_activePackage) order << index;
    for (const auto index : order) {
        const auto found = m_packages[index].tiles.constFind(key);
        if (found == m_packages[index].tiles.cend()) continue;
        QFile file(m_packages[index].path);
        if (!file.open(QIODevice::ReadOnly) || !file.seek(static_cast<qint64>(found->offset))) continue;
        const auto bytes = file.read(found->length);
        if (bytes.size() == static_cast<int>(found->length)) return bytes;
    }
    return {};
}

void OfflineMapTileProvider::acceptConnections()
{
    while (auto* socket = m_server.nextPendingConnection()) {
        socket->setProperty("request", QByteArray {});
        connect(socket, &QTcpSocket::readyRead, this, [this, socket] { consumeRequest(socket); });
        connect(socket, &QTcpSocket::disconnected, socket, &QObject::deleteLater);
    }
}

void OfflineMapTileProvider::consumeRequest(QTcpSocket* socket)
{
    auto request = socket->property("request").toByteArray() + socket->readAll();
    socket->setProperty("request", request);
    if (!request.contains("\r\n\r\n")) return;
    static const QRegularExpression tilePath(QStringLiteral("^GET /([0-9]+)/([0-9]+)/([0-9]+)\\.png(?:\\?[^ ]*)? HTTP/"));
    const auto match = tilePath.match(QString::fromLatin1(request.left(request.indexOf("\r\n"))));
    if (!match.hasMatch()) {
        sendResponse(socket, 404, "Offline tile not found\n");
        return;
    }
    const auto tile = readTile(match.captured(1).toInt(), match.captured(2).toInt(), match.captured(3).toInt());
    if (tile.isEmpty()) sendResponse(socket, 404, "Offline tile not found\n");
    else sendResponse(socket, 200, tile, "image/png");
}

void OfflineMapTileProvider::sendResponse(QTcpSocket* socket, int status, const QByteArray& body, const QByteArray& contentType)
{
    const QByteArray reason = status == 200 ? "OK" : "Not Found";
    QByteArray response = "HTTP/1.1 " + QByteArray::number(status) + " " + reason + "\r\n"
        "Content-Type: " + contentType + "\r\n"
        "Content-Length: " + QByteArray::number(body.size()) + "\r\n"
        "Cache-Control: public, max-age=31536000, immutable\r\n"
        "Connection: close\r\n\r\n" + body;
    socket->write(response);
    socket->disconnectFromHost();
}
