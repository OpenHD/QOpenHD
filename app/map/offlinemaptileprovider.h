#pragma once

#include <QObject>
#include <QHash>
#include <QHostAddress>
#include <QList>
#include <QVariantList>
#include <QString>
#include <QUrl>
#include <QTcpServer>
#include <QNetworkAccessManager>

class QTcpSocket;

// Serves local vector MBTiles and legacy GLDMAP1 tiles over loopback.
class OfflineMapTileProvider final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY packagesChanged)
    Q_PROPERTY(QString baseUrl READ baseUrl CONSTANT)
    Q_PROPERTY(QString vectorStyleUrl READ vectorStyleUrl NOTIFY packagesChanged)
    Q_PROPERTY(bool rasterAvailable READ rasterAvailable NOTIFY packagesChanged)
    Q_PROPERTY(QString osmBaseUrl READ osmBaseUrl CONSTANT)
    Q_PROPERTY(QString mapboxBaseUrl READ mapboxBaseUrl CONSTANT)
    Q_PROPERTY(QString mapboxCacheDirectory READ mapboxCacheDirectory CONSTANT)
    Q_PROPERTY(QString activePackageName READ activePackageName NOTIFY activePackageChanged)
    Q_PROPERTY(QVariantList packages READ packages NOTIFY packagesChanged)
    Q_PROPERTY(int packageCount READ packageCount NOTIFY packagesChanged)

public:
    explicit OfflineMapTileProvider(QObject* parent = nullptr);
    ~OfflineMapTileProvider() override;

    bool available() const { return !m_packages.isEmpty(); }
    QString baseUrl() const;
    QString vectorStyleUrl() const;
    bool rasterAvailable() const;
    QString mapboxBaseUrl() const;
    QString osmBaseUrl() const;
    QString mapboxCacheDirectory() const;
    Q_INVOKABLE void setMapboxKey(const QString& key) { m_mapboxKey = key.trimmed(); }
    QString activePackageName() const;
    QVariantList packages() const;
    int packageCount() const { return m_packages.size(); }

    Q_INVOKABLE QString tileCacheDirectory(const QString& provider) const;
    Q_INVOKABLE void reload();
    Q_INVOKABLE void setPosition(double latitude, double longitude);
    Q_INVOKABLE QUrl mapDirectory() const;

signals:
    void packagesChanged();
    void activePackageChanged();

private:
    struct TileEntry {
        quint64 offset {};
        quint32 length {};
    };
    struct Package {
        QString path;
        QString name;
        double south {};
        double west {};
        double north {};
        double east {};
        quint8 minZoom {};
        quint8 maxZoom {};
        QHash<quint64, TileEntry> tiles;
        QString databaseName;

        bool contains(double latitude, double longitude) const;
        double area() const;
    };

    static quint64 tileKey(int zoom, int x, int y);
    bool loadPackage(const QString& path, Package& package) const;
    bool loadVectorPackage(const QString& path, Package& package) const;
    void clearPackages();
    QByteArray vectorStyle() const;
    QByteArray readVectorTile(int zoom, int x, int y) const;
    QByteArray readTile(int zoom, int x, int y) const;
    void acceptConnections();
    void consumeRequest(QTcpSocket* socket);
    void sendResponse(QTcpSocket* socket, int status, const QByteArray& body,
                      const QByteArray& contentType = "text/plain", bool gzip = false);

    void consumeMapboxRequest(QTcpSocket* socket);
    QTcpServer m_mapboxServer;
    QNetworkAccessManager m_mapboxNetwork;
    QString m_mapboxKey;
    int m_mapboxRequests { 0 };
    QTcpServer m_server;
    QList<Package> m_packages;
    int m_activePackage { -1 };
    int m_revision { 0 };
};
