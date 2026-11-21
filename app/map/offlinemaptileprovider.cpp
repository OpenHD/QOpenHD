#include "offlinemaptileprovider.h"

#include <QCoreApplication>
#include <QDataStream>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QSet>
#include <QStandardPaths>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QTcpSocket>
#include <QNetworkReply>
#include <QNetworkDiskCache>
#include <QPointer>
#include <QTimer>
#include <QUrlQuery>
#include <QUuid>

#include <cstring>

namespace {
constexpr char kMagic[8] = { 'G', 'L', 'D', 'M', 'A', 'P', '1', '\0' };

QStringList packageDirectories()
{
    QStringList paths;
    const auto vectorDirectory = qEnvironmentVariable("OPENHD_MAP_PACKAGE_DIR");
    if (!vectorDirectory.isEmpty()) paths << vectorDirectory;
    const auto configured = qEnvironmentVariable("GLIDE_MAP_PACKAGE_DIR");
    if (!configured.isEmpty()) paths << configured;
    // ImageWriter places selected ground-station packages on the Config partition.
    paths << QStringLiteral("/Config/openhd/maps")
          << QStringLiteral("/Config/maps");
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
    auto* cache = new QNetworkDiskCache(&m_mapboxNetwork);
    cache->setCacheDirectory(QDir(QStandardPaths::writableLocation(QStandardPaths::CacheLocation)).filePath("online-http-tiles"));
    cache->setMaximumCacheSize(128 * 1024 * 1024);
    m_mapboxNetwork.setCache(cache);
    connect(&m_server, &QTcpServer::newConnection, this, &OfflineMapTileProvider::acceptConnections);
    if (!m_server.listen(QHostAddress::LocalHost, 0)) {
        qWarning() << "Offline map tile server could not listen:" << m_server.errorString();
    }
    connect(&m_mapboxServer, &QTcpServer::newConnection, this, [this] {
        while (auto* socket = m_mapboxServer.nextPendingConnection()) {
            connect(socket, &QTcpSocket::readyRead, this, [this, socket] { consumeMapboxRequest(socket); });
            connect(socket, &QTcpSocket::disconnected, socket, &QObject::deleteLater);
            QTimer::singleShot(15000, socket, &QTcpSocket::disconnectFromHost);
        }
    });
    m_mapboxServer.listen(QHostAddress::LocalHost, 0);
    reload();
}

OfflineMapTileProvider::~OfflineMapTileProvider()
{
    clearPackages();
}

QString OfflineMapTileProvider::baseUrl() const
{
    return QStringLiteral("http://127.0.0.1:%1/").arg(m_server.serverPort());
}

QString OfflineMapTileProvider::vectorStyleUrl() const
{
    for (const auto& package : m_packages) {
        if (!package.databaseName.isEmpty())
            return baseUrl() + QStringLiteral("vector/%1/style.json").arg(m_revision);
    }
    return {};
}

bool OfflineMapTileProvider::rasterAvailable() const
{
    for (const auto& package : m_packages)
        if (package.databaseName.isEmpty()) return true;
    return false;
}

QUrl OfflineMapTileProvider::mapDirectory() const
{
    const auto configured = qEnvironmentVariable("OPENHD_MAP_PACKAGE_DIR");
    const QDir directory(configured.isEmpty()
        ? QDir(QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation)).filePath("maps")
        : configured);
    return QDir().mkpath(directory.absolutePath()) ? QUrl::fromLocalFile(directory.absolutePath()) : QUrl();
}

// The OSM plugin is present even in the static Pi Qt kit, which omits Mapbox GL.
// Expose modern Mapbox raster tiles locally without putting the access token in QML URLs.
QString OfflineMapTileProvider::mapboxBaseUrl() const
{
    return QStringLiteral("http://127.0.0.1:%1/").arg(m_mapboxServer.serverPort());
}

QString OfflineMapTileProvider::mapboxCacheDirectory() const
{
    return QDir(QStandardPaths::writableLocation(QStandardPaths::CacheLocation)).filePath(QStringLiteral("mapbox-raster"));
}

QString OfflineMapTileProvider::tileCacheDirectory(const QString& provider) const
{
    const auto directory = provider == QStringLiteral("openhd_offline")
        ? QStringLiteral("offline-map-tiles") : QStringLiteral("openstreetmap-tiles");
    return QDir(QStandardPaths::writableLocation(QStandardPaths::CacheLocation)).filePath(directory);
}

void OfflineMapTileProvider::consumeMapboxRequest(QTcpSocket* socket)
{
    if (socket->property("handled").toBool()) return;
    auto input = socket->property("request").toByteArray() + socket->readAll();
    socket->setProperty("request", input);
    if (input.size() > 8192) {
        socket->setProperty("handled", true);
        sendResponse(socket, 404, "Invalid tile request");
        return;
    }
    if (!input.contains("\r\n\r\n")) return;
    socket->setProperty("handled", true);
    static const QRegularExpression path(QStringLiteral("^GET /([0-9]{1,2})/([0-9]{1,10})/([0-9]{1,10})\\.png(?:\\?[^ ]*)? HTTP/"));
    auto requestLine = QString::fromLatin1(input.left(input.indexOf("\r\n")));
    const bool osm = requestLine.startsWith("GET /osm/");
    if (osm) requestLine.replace(4,5,"/");
    const auto match = path.match(requestLine);
    bool xOk = false, yOk = false;
    const int z = match.captured(1).toInt();
    const auto x = match.captured(2).toULongLong(&xOk);
    const auto y = match.captured(3).toULongLong(&yOk);
    if (!match.hasMatch() || z > 22 || !xOk || !yOk || x >= (1ULL << z) || y >= (1ULL << z)
        || (!osm && m_mapboxKey.isEmpty()) || m_mapboxRequests >= 32) {
        sendResponse(socket, 404, "Tile unavailable");
        return;
    }
    QUrl url(osm ? QStringLiteral("https://tile.openstreetmap.org/%1/%2/%3.png").arg(z).arg(x).arg(y)
                 : QStringLiteral("https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/256/%1/%2/%3").arg(z).arg(x).arg(y));
    if (!osm) {
        QUrlQuery query; query.addQueryItem(QStringLiteral("access_token"), m_mapboxKey); url.setQuery(query);
    }
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("QOpenHD/3.0 (+https://openhd.org)"));
    request.setAttribute(QNetworkRequest::CacheLoadControlAttribute, QNetworkRequest::PreferCache);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    auto* reply = m_mapboxNetwork.get(request);
    ++m_mapboxRequests;
    QTimer::singleShot(12000, reply, &QNetworkReply::abort);
    connect(socket, &QTcpSocket::disconnected, reply, &QNetworkReply::abort);
    QPointer<QTcpSocket> client(socket);
    connect(reply, &QNetworkReply::finished, this, [this, reply, client] {
        --m_mapboxRequests;
        const auto bytes = reply->readAll();
        if (client && client->state() == QAbstractSocket::ConnectedState) {
            if (reply->error() == QNetworkReply::NoError && bytes.startsWith("\x89PNG"))
                sendResponse(client, 200, bytes, "image/png");
            else {
                qWarning() << "Online raster tile failed: HTTP" << reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt()
                           << "network error" << int(reply->error()) << "bytes" << bytes.size();
                sendResponse(client, 404, "Tile unavailable");
            }
        }
        reply->deleteLater();
    });
}

QString OfflineMapTileProvider::osmBaseUrl() const {
    return QStringLiteral("http://127.0.0.1:%1/osm/").arg(m_mapboxServer.serverPort());
}

QString OfflineMapTileProvider::activePackageName() const
{
    return m_activePackage >= 0 && m_activePackage < m_packages.size() ? m_packages[m_activePackage].name : QString();
}

QVariantList OfflineMapTileProvider::packages() const
{
    QVariantList result;
    for (const auto& p : m_packages)
        result.append(QVariantMap{{"name", p.name}, {"south", p.south}, {"west", p.west},
                                  {"north", p.north}, {"east", p.east},
                                  {"minZoom", int(p.minZoom)}, {"maxZoom", int(p.maxZoom)},
                                  {"vector", !p.databaseName.isEmpty()}});
    return result;
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

bool OfflineMapTileProvider::loadVectorPackage(const QString& path, Package& package) const
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly) || file.read(16) != QByteArray("SQLite format 3\0", 16))
        return false;
    file.close();
    const auto connection = QUuid::createUuid().toString();
    QHash<QString, QString> metadata;
    {
        auto database = QSqlDatabase::addDatabase("QSQLITE", connection);
        database.setConnectOptions("QSQLITE_OPEN_READONLY");
        database.setDatabaseName(path);
        if (database.open()) {
            QSqlQuery query(database);
            if (query.exec("SELECT name, value FROM metadata WHERE name IN "
                           "('name','format','bounds','minzoom','maxzoom','json') LIMIT 32")) {
                while (query.next()) metadata.insert(query.value(0).toString(), query.value(1).toString());
            }
            if (!query.exec("SELECT tile_data FROM tiles LIMIT 1") || !query.next()) metadata.clear();
        }
    }
    const auto bounds = metadata.value("bounds").split(',');
    bool minOk = false, maxOk = false;
    const int minZoom = metadata.value("minzoom").toInt(&minOk);
    const int maxZoom = metadata.value("maxzoom").toInt(&maxOk);
    double coordinates[4] {};
    bool boundsOk = bounds.size() == 4;
    for (int index = 0; boundsOk && index < 4; ++index)
        coordinates[index] = bounds[index].toDouble(&boundsOk);
    QSet<QString> layers;
    const auto tileJson = QJsonDocument::fromJson(metadata.value("json").toUtf8()).object();
    for (const auto& layer : tileJson.value("vector_layers").toArray())
        layers.insert(layer.toObject().value("id").toString());
    if (metadata.value("format") != "pbf" || !layers.contains("streets") || (!layers.contains("place_labels") && !layers.contains("street_labels"))
        || !boundsOk || !(coordinates[0] >= -180 && coordinates[0] < coordinates[2] && coordinates[2] <= 180
                          && coordinates[1] >= -90 && coordinates[1] < coordinates[3] && coordinates[3] <= 90)
        || !minOk || !maxOk || minZoom < 0 || maxZoom < minZoom || maxZoom > 22) {
        QSqlDatabase::removeDatabase(connection);
        return false;
    }
    package.path = path;
    package.databaseName = connection;
    package.name = metadata.value("name").left(128);
    if (package.name.isEmpty() || package.name == "Shortbread")
        package.name = QFileInfo(path).completeBaseName();
    package.west = coordinates[0];
    package.south = coordinates[1];
    package.east = coordinates[2];
    package.north = coordinates[3];
    package.minZoom = static_cast<quint8>(minZoom);
    package.maxZoom = static_cast<quint8>(maxZoom);
    return true;
}

void OfflineMapTileProvider::clearPackages()
{
    for (const auto& package : m_packages)
        if (!package.databaseName.isEmpty()) QSqlDatabase::removeDatabase(package.databaseName);
    m_packages.clear();
}

void OfflineMapTileProvider::reload()
{
    const auto oldName = activePackageName();
    clearPackages();
    m_activePackage = -1;
    ++m_revision;
    QSet<QString> seen;
    for (const auto& directory : packageDirectories()) {
        const QDir dir(directory);
        qInfo() << "Searching for OpenHD offline maps in" << dir.absolutePath();
        for (const auto& info : dir.entryInfoList({QStringLiteral("*.mbtiles"), QStringLiteral("*.glidemap")},
                                                  QDir::Files | QDir::Readable)) {
            const auto canonical = info.canonicalFilePath();
            if (canonical.isEmpty() || seen.contains(canonical)) continue;
            seen.insert(canonical);
            Package package;
            const bool vector = info.suffix().compare("mbtiles", Qt::CaseInsensitive) == 0;
            if (vector ? loadVectorPackage(canonical, package) : loadPackage(canonical, package)) {
                qInfo() << "Loaded OpenHD offline map" << package.name << canonical;
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
        if (best < 0) {
            best = index;
            continue;
        }
        const auto& current = m_packages[best];
        const bool vector = !candidate.databaseName.isEmpty();
        const bool currentVector = !current.databaseName.isEmpty();
        if ((vector && !currentVector) || (vector == currentVector &&
            (candidate.maxZoom > current.maxZoom ||
             (candidate.maxZoom == current.maxZoom && candidate.area() < current.area())))) best = index;
    }
    if (best != m_activePackage) {
        m_activePackage = best;
        qInfo() << "Active OpenHD offline map:" << activePackageName();
        emit activePackageChanged();
    }
}

QByteArray OfflineMapTileProvider::vectorStyle() const
{
    QFile file(":/offline-vector/style.json");
    if (!file.open(QIODevice::ReadOnly)) return {};
    auto style = QJsonDocument::fromJson(file.readAll()).object();
    const auto url = baseUrl();
    int minZoom = 22, maxZoom = 0;
    for (const auto& package : m_packages) {
        if (package.databaseName.isEmpty()) continue;
        minZoom = qMin(minZoom, int(package.minZoom));
        maxZoom = qMax(maxZoom, int(package.maxZoom));
    }
    style.insert("glyphs", url + "vector/glyphs/{fontstack}/{range}.pbf");
    style.insert("sources", QJsonObject{{"shortbread", QJsonObject{
        {"type", "vector"}, {"minzoom", minZoom}, {"maxzoom", maxZoom},
        {"tiles", QJsonArray{url + QStringLiteral("vector/%1/{z}/{x}/{y}.pbf").arg(m_revision)}}
    }}});
    return QJsonDocument(style).toJson(QJsonDocument::Compact);
}

QByteArray OfflineMapTileProvider::readVectorTile(int zoom, int x, int y) const
{
    const int tmsY = (1 << zoom) - 1 - y;
    for (const auto& package : m_packages) {
        if (package.databaseName.isEmpty() || zoom < package.minZoom || zoom > package.maxZoom) continue;
        QSqlQuery query(QSqlDatabase::database(package.databaseName, false));
        query.prepare("SELECT tile_data FROM tiles WHERE zoom_level=? AND tile_column=? AND tile_row=? "
                      "AND length(tile_data) <= 4194304 LIMIT 1");
        query.addBindValue(zoom);
        query.addBindValue(x);
        query.addBindValue(tmsY);
        if (query.exec() && query.next()) return query.value(0).toByteArray();
    }
    return {};
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
        QTimer::singleShot(5000, socket, &QTcpSocket::disconnectFromHost);
    }
}

void OfflineMapTileProvider::consumeRequest(QTcpSocket* socket)
{
    auto request = socket->property("request").toByteArray() + socket->readAll();
    if (request.size() > 8192) {
        sendResponse(socket, 404, "Invalid tile request");
        return;
    }
    socket->setProperty("request", request);
    if (!request.contains("\r\n\r\n")) return;
    const auto line = QString::fromLatin1(request.left(request.indexOf("\r\n")));
    const auto vectorPrefix = QStringLiteral("GET /vector/%1/").arg(m_revision);
    if (line.startsWith(vectorPrefix + "style.json HTTP/") && !vectorStyleUrl().isEmpty()) {
        sendResponse(socket, 200, vectorStyle(), "application/json");
        return;
    }
    static const QRegularExpression glyphPath("^GET /vector/glyphs/(?:OpenHD%20Sans|OpenHD Sans)/([0-9]{1,5}-[0-9]{1,5})\\.pbf HTTP/");
    const auto glyph = glyphPath.match(line);
    if (glyph.hasMatch()) {
        QFile file(":/offline-vector/glyphs/" + glyph.captured(1) + ".pbf");
        sendResponse(socket, 200, file.open(QIODevice::ReadOnly) ? file.readAll() : QByteArray{},
                     "application/x-protobuf");
        return;
    }
    static const QRegularExpression vectorPath("^(\\d{1,2})/(\\d{1,7})/(\\d{1,7})\\.pbf(?:\\?[^ ]*)? HTTP/");
    if (line.startsWith(vectorPrefix)) {
        const auto match = vectorPath.match(line.mid(vectorPrefix.size()));
        if (match.hasMatch()) {
            const int z = match.captured(1).toInt(), x = match.captured(2).toInt(), y = match.captured(3).toInt();
            if (z <= 22 && x < (1 << z) && y < (1 << z)) {
                const auto tile = readVectorTile(z, x, y);
                sendResponse(socket, 200, tile, "application/x-protobuf", tile.startsWith("\x1f\x8b"));
                return;
            }
        }
    }
    static const QRegularExpression tilePath(QStringLiteral("^GET /([0-9]+)/([0-9]+)/([0-9]+)\\.png(?:\\?[^ ]*)? HTTP/"));
    const auto match = tilePath.match(line);
    if (!match.hasMatch()) {
        sendResponse(socket, 404, "Offline tile not found\n");
        return;
    }
    const auto tile = readTile(match.captured(1).toInt(), match.captured(2).toInt(), match.captured(3).toInt());
    if (tile.isEmpty()) sendResponse(socket, 404, "Offline tile not found\n");
    else sendResponse(socket, 200, tile, "image/png");
}

void OfflineMapTileProvider::sendResponse(QTcpSocket* socket, int status, const QByteArray& body,
                                          const QByteArray& contentType, bool gzip)
{
    const QByteArray reason = status == 200 ? "OK" : "Not Found";
    QByteArray response = "HTTP/1.1 " + QByteArray::number(status) + " " + reason + "\r\n"
        "Content-Type: " + contentType + "\r\n"
        "Content-Length: " + QByteArray::number(body.size()) + "\r\n"
        + (gzip ? QByteArray("Content-Encoding: gzip\r\n") : QByteArray())
        + (status == 200 ? QByteArray("Cache-Control: public, max-age=604800\r\n")
                         : QByteArray("Cache-Control: no-store\r\n")) +
        "Connection: close\r\n\r\n" + body;
    socket->write(response);
    socket->disconnectFromHost();
}
