#include "offlinemapbuilder.h"

#include <QBuffer>
#include <QDataStream>
#include <QDir>
#include <QImage>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QPainter>
#include <QSaveFile>
#include <QStandardPaths>
#include <QStorageInfo>
#include <QTimer>
#include <QUrlQuery>
#include <QUuid>
#include <QTcpSocket>
#include <QRegularExpression>
#include <cmath>

namespace {
constexpr double pi = 3.14159265358979323846;
constexpr qint64 maxBytes = 100 * 1024 * 1024;
QPointF project(double lat, double lon, int zoom) {
    const double n = double(1 << zoom);
    return {(lon + 180.0) / 360.0 * n,
            (1.0 - std::asinh(std::tan(qBound(-85.0, lat, 85.0) * pi / 180.0)) / pi) * 0.5 * n};
}
bool validBounds(double s, double w, double n, double e) {
    return std::isfinite(s) && std::isfinite(w) && std::isfinite(n) && std::isfinite(e)
        && -85 <= s && s < n && n <= 85 && -180 <= w && w < e && e <= 180;
}
QRect tileBounds(double s, double w, double n, double e, int z) {
    const auto nw = project(n, w, z), se = project(s, e, z);
    const int limit = (1 << z) - 1;
    return QRect(QPoint(qBound(0, int(std::floor(nw.x())), limit), qBound(0, int(std::floor(nw.y())), limit)),
                 QPoint(qBound(0, int(std::floor(se.x())), limit), qBound(0, int(std::floor(se.y())), limit)));
}
QUrl endpoint(const char* variable, const char* fallback) {
    const auto value = qEnvironmentVariable(variable);
    return QUrl(value.isEmpty() ? QString::fromLatin1(fallback) : value);
}
}

OfflineMapBuilder::OfflineMapBuilder(QObject* parent, const QString& outputDirectory)
    : QObject(parent), m_outputDirectory(outputDirectory) {
    // Qt's raster Mapbox plugin uses the retired v4 API, while some Pi Qt kits
    // omit Mapbox GL. Adapt the current Styles API to Qt's local XYZ source.
    // The public token remains in C++ requests rather than QML-generated URLs.
    m_mapboxServer.listen(QHostAddress::LocalHost, 0);
    connect(&m_mapboxServer, &QTcpServer::newConnection, this, [this] {
        while (auto* socket = m_mapboxServer.nextPendingConnection()) {
            connect(socket, &QTcpSocket::disconnected, socket, &QObject::deleteLater);
            connect(socket, &QTcpSocket::readyRead, this, [this, socket] {
                const auto input = socket->property("request").toByteArray() + socket->readAll();
                socket->setProperty("request", input);
                if (!input.contains("\r\n\r\n") || socket->property("answered").toBool()) return;
                socket->setProperty("answered", true);
                const auto respond = [socket](int status, const QByteArray& body, const QByteArray& type) {
                    if (socket->state() != QAbstractSocket::ConnectedState) return;
                    socket->write("HTTP/1.1 " + QByteArray::number(status) + (status == 200 ? " OK\r\n" : " Error\r\n")
                                  + "Content-Type: " + type + "\r\nContent-Length: " + QByteArray::number(body.size())
                                  + "\r\nCache-Control: private, max-age=3600\r\nConnection: close\r\n\r\n" + body);
                    socket->disconnectFromHost();
                };
                static const QRegularExpression route(QStringLiteral("^GET /([0-9]{1,2})/([0-9]{1,9})/([0-9]{1,9})\\.png HTTP/"));
                const auto match = route.match(QString::fromLatin1(input.left(input.indexOf("\r\n"))));
                if (!match.hasMatch() || m_mapboxKey.isEmpty() || input.size() > 8192) {
                    respond(400, "Mapbox preview requires a valid key", "text/plain"); return;
                }
                const int z = match.captured(1).toInt(), x = match.captured(2).toInt(), y = match.captured(3).toInt();
                if (z > 22 || x >= (1 << z) || y >= (1 << z)) { respond(400, "Invalid tile", "text/plain"); return; }
                QUrl url = endpoint("OPENHD_MAPBOX_TILE_URL", "https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/256/")
                    .resolved(QUrl(QStringLiteral("%1/%2/%3").arg(z).arg(x).arg(y)));
                QUrlQuery query; query.addQueryItem(QStringLiteral("access_token"), m_mapboxKey); url.setQuery(query);
                QNetworkRequest request(url);
                request.setRawHeader("User-Agent", "OpenHD-OfflineMaps/1.0 (+https://openhd.org)");
                auto* reply = m_network.get(request);
                QTimer::singleShot(20000, reply, [reply] { if (reply->isRunning()) reply->abort(); });
                const QPointer<QTcpSocket> client(socket);
                connect(reply, &QNetworkReply::finished, this, [reply, client, respond] {
                    reply->deleteLater();
                    if (!client) return;
                    const auto body = reply->readAll();
                    if (reply->error() != QNetworkReply::NoError || !body.startsWith(QByteArray::fromHex("89504e470d0a1a0a"))) {
                        respond(502, "Mapbox preview unavailable. Check connection and key.", "text/plain"); return;
                    }
                    respond(200, body, "image/png");
                });
                connect(socket, &QTcpSocket::disconnected, reply, [reply] { if (reply->isRunning()) reply->abort(); });
            });
        }
    });
}

QString OfflineMapBuilder::mapboxBaseUrl() const {
    return QStringLiteral("http://127.0.0.1:%1/").arg(m_mapboxServer.serverPort());
}

QString OfflineMapBuilder::mapCacheDirectory(const QString& source) const {
    // Qt's default custom-map cache is shared across unrelated OSM endpoints.
    // Keep preview, online, and local package tiles apart, retaining valid tiles
    // across application restarts rather than bypassing the network cache.
    const QString name = source == QStringLiteral("preview") ? QStringLiteral("preview")
        : source == QStringLiteral("preview_mapbox") ? QStringLiteral("preview-mapbox")
        : source == QStringLiteral("openhd_offline") ? QStringLiteral("offline")
        : source == QStringLiteral("mapbox_raster") ? QStringLiteral("mapbox") : QStringLiteral("online");
    const auto cacheRoot = m_outputDirectory.isEmpty()
        ? QStandardPaths::writableLocation(QStandardPaths::CacheLocation)
        : QDir(m_outputDirectory).filePath(QStringLiteral(".cache"));
    const auto path = QDir(cacheRoot).filePath(QStringLiteral("map-tiles/") + name);
    QDir().mkpath(path);
    return path;
}

QNetworkReply* OfflineMapBuilder::request(const QUrl& url, const QByteArray& body) {
    QNetworkRequest req(url);
    req.setRawHeader("User-Agent", "OpenHD-OfflineMaps/1.0 (+https://openhd.org)");
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
    auto* reply = body.isEmpty() ? m_network.get(req) : m_network.post(req, body);
    QTimer::singleShot(body.isEmpty() ? 20000 : 120000, reply, [reply] { if (reply->isRunning()) reply->abort(); });
    connect(reply, &QNetworkReply::readyRead, this, [reply] {
        if (reply->bytesAvailable() > 32 * 1024 * 1024) reply->abort();
    });
    return reply;
}

void OfflineMapBuilder::search(const QString& input) {
    if (m_searching || m_busy) return;
    const QString query = input.trimmed();
    if (query.isEmpty()) return;
    const auto cacheKey = query.toCaseFolded();
    if (m_searchCache.contains(cacheKey)) {
        m_results = m_searchCache.value(cacheKey);
        m_status = tr("Choose a search result, then draw your area."); emit changed(); return;
    }
    if (m_searchClock.isValid() && m_searchClock.elapsed() < 1100) {
        m_status = tr("Please wait a moment before searching again."); emit changed(); return;
    }
    m_searchClock.start(); m_searching = true; m_results.clear();
    m_status = tr("Finding region..."); emit changed();
    auto url = endpoint("OPENHD_MAP_SEARCH_URL", "https://nominatim.openstreetmap.org/search");
    QUrlQuery params; params.addQueryItem("q", query); params.addQueryItem("format", "jsonv2"); params.addQueryItem("limit", "5");
    url.setQuery(params);
    auto* reply = request(url); m_searchReply = reply;
    connect(reply, &QNetworkReply::finished, this, [this, reply, cacheKey] {
        reply->deleteLater();
        if (m_searchReply != reply) return;
        m_searchReply = nullptr; m_searching = false;
        if (reply->error() != QNetworkReply::NoError) {
            m_status = tr("Search failed. Check the internet connection and try again."); emit changed(); return;
        }
        const auto rows = QJsonDocument::fromJson(reply->readAll()).array();
        for (const auto& value : rows) {
            const auto row = value.toObject(); const auto bbox = row.value("boundingbox").toArray();
            if (bbox.size() != 4) continue;
            bool ok[4]; double b[4];
            for (int i = 0; i < 4; ++i) b[i] = bbox[i].toString().toDouble(&ok[i]);
            if (!ok[0] || !ok[1] || !ok[2] || !ok[3] || !validBounds(b[0], b[2], b[1], b[3])) continue;
            QVariantMap result; result["name"] = row.value("display_name").toString();
            result["south"] = b[0]; result["north"] = b[1]; result["west"] = b[2]; result["east"] = b[3];
            m_results.append(result);
        }
        m_searchCache.insert(cacheKey, m_results);
        m_status = m_results.isEmpty() ? tr("No region found. Try a nearby town.") : tr("Choose a search result, then draw your area.");
        emit changed();
    });
}

int OfflineMapBuilder::tileCount(double s, double w, double n, double e, int maxZoom) const {
    if (!validBounds(s, w, n, e) || maxZoom < 10 || maxZoom > 16) return -1;
    qint64 count = 0;
    for (int z = 10; z <= maxZoom; ++z) {
        const auto b = tileBounds(s, w, n, e, z);
        count += qint64(b.width()) * b.height();
        if (count > 4096) return -1;
    }
    // Keep interactive public Overpass requests to small flying areas.
    const double area = (n-s) * 111.2 * (e-w) * 111.2 * std::cos((s+n) * 0.5 * pi / 180.0);
    return area <= 400.0 ? int(count) : -1;
}

void OfflineMapBuilder::generate(const QString& name, double s, double w, double n, double e, int maxZoom) {
    if (m_busy || m_searching) return;
    const int count = tileCount(s, w, n, e, maxZoom);
    if (count < 1) { fail(tr("Choose a smaller area (up to 400 km² and 4096 tiles).")); return; }
    m_name = name.trimmed().left(60);
    if (m_name.isEmpty()) m_name = tr("Offline map");
    m_south = s; m_west = w; m_north = n; m_east = e; m_maxZoom = maxZoom;
    m_total = count; m_progress = 0; m_busy = true; ++m_job;
    m_ways.clear(); m_tiles.clear();
    m_status = tr("Downloading road geometry..."); emit changed(); fetchGeometry(0);
}

void OfflineMapBuilder::fetchGeometry(int layer, int attempt) {
    const QString query = QStringLiteral("[out:json][timeout:90];way[\"%1\"](%2,%3,%4,%5);out geom;")
        .arg(layer == 0 ? "highway" : "waterway").arg(m_south, 0, 'f', 7).arg(m_west, 0, 'f', 7)
        .arg(m_north, 0, 'f', 7).arg(m_east, 0, 'f', 7);
    QUrlQuery form; form.addQueryItem("data", query);
    auto url = endpoint("OPENHD_MAP_DATA_URL", "https://overpass-api.de/api/interpreter");
    if (attempt == 1 && qEnvironmentVariable("OPENHD_MAP_DATA_URL").isEmpty())
        url = QUrl("https://overpass.private.coffee/api/interpreter");
    auto* reply = request(url, form.query(QUrl::FullyEncoded).toUtf8());
    m_reply = reply; const auto job = m_job;
    connect(reply, &QNetworkReply::finished, this, [this, reply, layer, job, attempt] {
        reply->deleteLater();
        if (job != m_job || !m_busy) return;
        m_reply = nullptr;
        const auto retry = [this, layer, job, attempt] {
            if (attempt != 0 || !qEnvironmentVariable("OPENHD_MAP_DATA_URL").isEmpty()) return false;
            m_status = tr("Map server is busy. Trying another free server..."); emit changed();
            QTimer::singleShot(1000, this, [this, layer, job] { if (job == m_job && m_busy) fetchGeometry(layer, 1); });
            return true;
        };
        if (reply->error() != QNetworkReply::NoError) {
            if (retry()) return;
            fail(tr("Map data download failed: %1. Try a smaller area or retry later.").arg(reply->errorString())); return;
        }
        QJsonParseError error;
        const auto document = QJsonDocument::fromJson(reply->readAll(), &error);
        if (error.error != QJsonParseError::NoError || !document.object().value("elements").isArray()
            || document.object().contains("remark")) {
            if (retry()) return;
            fail(tr("Map service returned incomplete data. Try again later.")); return;
        }
        int points = 0;
        for (const auto& element : document.object().value("elements").toArray()) {
            const auto row = element.toObject(); const auto tags = row.value("tags").toObject();
            Way way; const auto highway = tags.value("highway").toString();
            way.color = layer ? QColor("#71b4d5") : QColor("#eef0df");
            way.width = layer ? 2.0 : (highway == "motorway" || highway == "trunk") ? 4.0
                : (highway == "primary" || highway == "secondary") ? 3.0
                : (highway == "track" || highway == "path" || highway == "footway") ? 1.0 : 2.0;
            for (const auto& point : row.value("geometry").toArray()) {
                const auto p = point.toObject();
                if (!p.value("lat").isDouble() || !p.value("lon").isDouble()) continue;
                const double lat = p.value("lat").toDouble(), lon = p.value("lon").toDouble();
                if (!std::isfinite(lat) || !std::isfinite(lon) || std::abs(lat) > 85 || std::abs(lon) > 180) continue;
                way.points.append(project(lat, lon, m_maxZoom) * 256.0);
                if (++points > 500000) { fail(tr("Too much map detail. Choose a smaller rectangle.")); return; }
            }
            if (way.points.size() > 1) { way.bounds = way.points.boundingRect(); m_ways.append(way); }
        }
        if (layer == 0) { m_status = tr("Downloading waterways..."); emit changed(); fetchGeometry(1); return; }
        m_payload.reset(new QTemporaryFile);
        if (!m_payload->open()) { fail(tr("Cannot create the map download file.")); return; }
        m_z = 10; const auto bounds = tileBounds(m_south, m_west, m_north, m_east, m_z);
        m_x = bounds.left(); m_y = bounds.top();
        m_status = tr("Creating offline map..."); emit changed();
        QTimer::singleShot(0, this, [this, job] { if (job == m_job && m_busy) renderNext(); });
    });
}

void OfflineMapBuilder::renderNext() {
    QImage image(256, 256, QImage::Format_RGB32); image.fill(QColor("#263735"));
    QPainter painter(&image); painter.setRenderHint(QPainter::Antialiasing);
    const double scale = std::pow(2.0, m_z - m_maxZoom);
    const QRectF viewport(m_x * 256.0 / scale, m_y * 256.0 / scale, 256.0 / scale, 256.0 / scale);
    painter.translate(-m_x * 256.0, -m_y * 256.0); painter.scale(scale, scale);
    for (const auto& way : m_ways) {
        if (!way.bounds.adjusted(-5/scale, -5/scale, 5/scale, 5/scale).intersects(viewport)) continue;
        painter.setPen(QPen(way.color, way.width / scale, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin));
        painter.drawPolyline(way.points);
    }
    painter.end();
    QByteArray bytes; QBuffer buffer(&bytes); buffer.open(QIODevice::WriteOnly);
    if (!image.save(&buffer, "PNG") || m_payload->size() + bytes.size() > maxBytes) { fail(tr("Map exceeds the 100 MB limit. Select a smaller area.")); return; }
    const quint64 offset = quint64(m_payload->pos());
    if (m_payload->write(bytes) != bytes.size()) { fail(tr("Not enough storage to create the map.")); return; }
    m_tiles.append({m_z, m_x, m_y, offset, quint32(bytes.size())});
    m_progress = double(m_tiles.size()) / m_total; emit changed();
    const auto bounds = tileBounds(m_south, m_west, m_north, m_east, m_z);
    if (++m_x > bounds.right()) { m_x = bounds.left(); ++m_y; }
    if (m_y > bounds.bottom()) {
        if (++m_z > m_maxZoom) { finishPackage(); return; }
        const auto next = tileBounds(m_south, m_west, m_north, m_east, m_z);
        m_x = next.left(); m_y = next.top();
    }
    const auto job = m_job;
    QTimer::singleShot(0, this, [this, job] { if (job == m_job && m_busy) renderNext(); });
}

void OfflineMapBuilder::finishPackage() {
    m_status = tr("Saving offline map..."); emit changed();
    const QDir directory(m_outputDirectory.isEmpty()
        ? QDir(QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation)).filePath("maps") : m_outputDirectory);
    if (!QDir().mkpath(directory.path())) { fail(tr("Cannot create the offline maps folder.")); return; }
    const QStorageInfo storage(directory.path());
    if (storage.isValid() && storage.bytesAvailable() < m_payload->size() + 1024*1024) { fail(tr("Not enough storage to save the map.")); return; }
    const auto path = directory.filePath("map-" + QUuid::createUuid().toString(QUuid::WithoutBraces) + ".glidemap");
    QSaveFile output(path);
    if (!output.open(QIODevice::WriteOnly)) { fail(tr("Cannot save the offline map.")); return; }
    const auto name = m_name.toUtf8(); const QByteArray attribution("OpenStreetMap contributors (ODbL) | openstreetmap.org/copyright");
    const quint64 dataOffset = 56 + name.size() + attribution.size() + quint64(m_tiles.size()) * 21;
    if (dataOffset + quint64(m_payload->size()) > quint64(maxBytes)) { fail(tr("Map exceeds the 100 MB limit. Select a smaller area.")); return; }
    output.write("GLDMAP1\0", 8);
    QDataStream stream(&output); stream.setByteOrder(QDataStream::LittleEndian); stream.setFloatingPointPrecision(QDataStream::DoublePrecision);
    stream << quint32(1) << quint16(256) << quint8(10) << quint8(m_maxZoom)
           << m_south << m_west << m_north << m_east << quint16(name.size()) << quint16(attribution.size()) << quint32(m_tiles.size());
    output.write(name); output.write(attribution);
    for (const auto& tile : m_tiles) stream << quint8(tile.z) << quint32(tile.x) << quint32(tile.y) << quint64(dataOffset + tile.offset) << tile.size;
    m_payload->seek(0);
    while (!m_payload->atEnd()) {
        const auto chunk = m_payload->read(1024*1024);
        if (chunk.isEmpty() || output.write(chunk) != chunk.size()) { fail(tr("Could not finish saving the map.")); return; }
    }
    if (stream.status() != QDataStream::Ok || !output.commit()) { fail(tr("Could not finish saving the map.")); return; }
    m_busy = false; m_payload.reset(); m_ways.clear(); m_status = tr("Offline map ready."); emit changed(); emit generated(path);
}

void OfflineMapBuilder::cancel() {
    ++m_job; m_busy = false; m_searching = false;
    auto reply = m_reply; auto search = m_searchReply; m_reply = nullptr; m_searchReply = nullptr;
    if (reply) reply->abort(); if (search) search->abort();
    m_payload.reset(); m_tiles.clear(); m_ways.clear(); m_progress = 0;
    m_status = tr("Cancelled."); emit changed();
}

void OfflineMapBuilder::fail(const QString& message) {
    ++m_job; m_busy = false; m_payload.reset(); m_ways.clear(); m_tiles.clear();
    m_status = message; emit changed();
}
