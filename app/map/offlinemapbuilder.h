#pragma once

#include <QObject>
#include <QSet>
#include <QNetworkAccessManager>
#include <QPointer>
#include <QElapsedTimer>
#include <QTemporaryFile>
#include <QVariantList>
#include <QPolygonF>
#include <QColor>
#include <QHash>
#include <QTcpServer>
#include <memory>

class QNetworkReply;

// Kept identical in QOpenHD and ImageWriter: generates GLDMAP1 from OSM geometry,
// without bulk-downloading public raster tiles or requiring Python on the device.
class OfflineMapBuilder : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY changed)
    Q_PROPERTY(bool searching READ searching NOTIFY changed)
    Q_PROPERTY(QString status READ status NOTIFY changed)
    Q_PROPERTY(double progress READ progress NOTIFY changed)
    Q_PROPERTY(QVariantList searchResults READ searchResults NOTIFY changed)
    Q_PROPERTY(QString previewCacheDirectory READ previewCacheDirectory CONSTANT)
    Q_PROPERTY(QString mapboxBaseUrl READ mapboxBaseUrl CONSTANT)
public:
    explicit OfflineMapBuilder(QObject* parent = nullptr, const QString& outputDirectory = QString());
    bool busy() const { return m_busy; }
    bool searching() const { return m_searching; }
    QString status() const { return m_status; }
    double progress() const { return m_progress; }
    QVariantList searchResults() const { return m_results; }
    QString previewCacheDirectory() const { return mapCacheDirectory(QStringLiteral("preview")); }
    Q_INVOKABLE QString mapCacheDirectory(const QString& source) const;
    QString mapboxBaseUrl() const;
    Q_INVOKABLE void setMapboxKey(const QString& key) { m_mapboxKey = key.trimmed(); }
    Q_INVOKABLE void search(const QString& query);
    Q_INVOKABLE int tileCount(double south, double west, double north, double east, int maxZoom) const;
    Q_INVOKABLE void generate(const QString& name, double south, double west, double north, double east, int maxZoom);
    Q_INVOKABLE void cancel();
signals:
    void changed();
    void generated(const QString& filePath);
private:
    struct Way { QPolygonF points; QRectF bounds; QColor color; double width; };
    struct Tile { int z, x, y; quint64 offset; quint32 size; };
    void fetchGeometry(int layer, int attempt = 0);
    void renderNext();
    void finishPackage();
    void fail(const QString& message);
    QNetworkReply* request(const QUrl& url, const QByteArray& body = {});
    QNetworkAccessManager m_network;
    QTcpServer m_mapboxServer;
    QString m_mapboxKey;
    QPointer<QNetworkReply> m_reply;
    QPointer<QNetworkReply> m_searchReply;
    QElapsedTimer m_searchClock;
    QVariantList m_results;
    QHash<QString, QVariantList> m_searchCache;
    bool m_busy = false, m_searching = false;
    QString m_status, m_name, m_outputDirectory;
    double m_progress = 0, m_south = 0, m_west = 0, m_north = 0, m_east = 0;
    int m_maxZoom = 15, m_total = 0, m_z = 10, m_x = 0, m_y = 0;
    quint64 m_job = 0;
    QVector<QRectF> m_geometryRegions;
    int m_geometryRegion = 0, m_geometryPoints = 0;
    QSet<qint64> m_geometryIds;
    QVector<int> m_rowWays;
    QVector<Way> m_ways;
    QVector<Tile> m_tiles;
    std::unique_ptr<QTemporaryFile> m_payload;
};
