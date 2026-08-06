#pragma once

#include <QObject>
#include <QHash>
#include <QHostAddress>
#include <QList>
#include <QString>
#include <QTcpServer>

class QTcpSocket;

// Serves OpenHD GLDMAP1 packages as a localhost-only XYZ source for QtLocation.
// Keeping the adapter here means QOpenHD and OpenHD Glide consume exactly the
// same offline map files without a conversion or an internet tile fallback.
class OfflineMapTileProvider final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY packagesChanged)
    Q_PROPERTY(QString baseUrl READ baseUrl CONSTANT)
    Q_PROPERTY(QString activePackageName READ activePackageName NOTIFY activePackageChanged)
    Q_PROPERTY(int packageCount READ packageCount NOTIFY packagesChanged)

public:
    explicit OfflineMapTileProvider(QObject* parent = nullptr);

    bool available() const { return !m_packages.isEmpty(); }
    QString baseUrl() const;
    QString activePackageName() const;
    int packageCount() const { return m_packages.size(); }

    Q_INVOKABLE void reload();
    Q_INVOKABLE void setPosition(double latitude, double longitude);

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

        bool contains(double latitude, double longitude) const;
        double area() const;
    };

    static quint64 tileKey(int zoom, int x, int y);
    bool loadPackage(const QString& path, Package& package) const;
    QByteArray readTile(int zoom, int x, int y) const;
    void acceptConnections();
    void consumeRequest(QTcpSocket* socket);
    void sendResponse(QTcpSocket* socket, int status, const QByteArray& body, const QByteArray& contentType = "text/plain");

    QTcpServer m_server;
    QList<Package> m_packages;
    int m_activePackage { -1 };
};
