#include "openhddiscovery.h"

#include <QEventLoop>
#include <QHostAddress>
#include <QHostInfo>
#include <QNetworkInterface>
#include <QSet>
#include <QTimer>
#include <QtConcurrent>
#include <QtEndian>
#include <QHash>
#include <QVariantMap>
#include <QVector>
#include <QStringList>

#include <algorithm>

namespace {

constexpr quint32 kMaxHostsPerInterface = 1024;
constexpr int kLookupTimeoutMs = 3000;
constexpr int kMaxTotalLookups = 1024;

class HostLookupAggregator : public QObject
{
    Q_OBJECT
public:
    explicit HostLookupAggregator(QObject *parent = nullptr) : QObject(parent) {}

    QHash<int, QString> lookupIdToIp;
    QVector<QVariantMap> matches;

public slots:
    void handleLookup(const QHostInfo &info)
    {
        const QString ip = lookupIdToIp.take(info.lookupId());
        if (info.error() == QHostInfo::NoError) {
            const QString hostname = info.hostName();
            if (!hostname.isEmpty() && hostname.contains("openhd", Qt::CaseInsensitive)) {
                QVariantMap map;
                map.insert(QStringLiteral("ip"), ip);
                map.insert(QStringLiteral("hostname"), hostname);
                matches.append(map);
            }
        }
        emit finishedOne();
    }

signals:
    void finishedOne();
};

static QVector<QVariantMap> lookupCandidates(const QStringList &ips)
{
    if (ips.isEmpty()) {
        return {};
    }

    HostLookupAggregator aggregator;
    QEventLoop loop;
    QTimer timer;
    timer.setInterval(kLookupTimeoutMs);
    timer.setSingleShot(true);

    int pendingLookups = 0;

    QObject::connect(&aggregator, &HostLookupAggregator::finishedOne, &loop, [&]() {
        --pendingLookups;
        if (pendingLookups <= 0) {
            if (timer.isActive()) {
                timer.stop();
            }
            loop.quit();
        }
    });

    QObject::connect(&timer, &QTimer::timeout, &loop, [&]() {
        const auto keys = aggregator.lookupIdToIp.keys();
        for (int id : keys) {
            QHostInfo::abortHostLookup(id);
        }
        aggregator.lookupIdToIp.clear();
        pendingLookups = 0;
        loop.quit();
    });

    timer.start();

    for (const QString &ip : ips) {
        const int lookupId = QHostInfo::lookupHost(ip, &aggregator, SLOT(handleLookup(QHostInfo)));
        if (lookupId != -1) {
            aggregator.lookupIdToIp.insert(lookupId, ip);
            ++pendingLookups;
        }
    }

    if (pendingLookups > 0) {
        loop.exec();
    } else {
        timer.stop();
    }

    return aggregator.matches;
}

} // namespace

OpenHDDiscovery::OpenHDDiscovery(QObject *parent)
    : QObject(parent)
{
    connect(&m_watcher, &QFutureWatcher<QVariantList>::finished, this, [this]() {
        m_devices = m_watcher.result();
        m_scanning = false;
        emit devicesChanged();
        emit scanningChanged();
    });
}

OpenHDDiscovery &OpenHDDiscovery::instance()
{
    static OpenHDDiscovery instance;
    return instance;
}

QVariantList OpenHDDiscovery::devices() const
{
    return m_devices;
}

bool OpenHDDiscovery::scanning() const
{
    return m_scanning;
}

void OpenHDDiscovery::refresh()
{
    if (m_scanning) {
        return;
    }

    m_scanning = true;
    emit scanningChanged();

    if (!m_devices.isEmpty()) {
        m_devices.clear();
        emit devicesChanged();
    }

    auto future = QtConcurrent::run([this]() { return performScan(); });
    m_watcher.setFuture(future);
}

QVariantList OpenHDDiscovery::performScan() const
{
    QVariantList result;
    QSet<QString> uniqueCandidates;

    const auto interfaces = QNetworkInterface::allInterfaces();
    for (const QNetworkInterface &iface : interfaces) {
        const auto flags = iface.flags();
        if (!(flags & QNetworkInterface::IsUp) || !(flags & QNetworkInterface::IsRunning) || (flags & QNetworkInterface::IsLoopBack)) {
            continue;
        }

        for (const QNetworkAddressEntry &entry : iface.addressEntries()) {
            const QHostAddress ip = entry.ip();
            if (ip.protocol() != QAbstractSocket::IPv4Protocol || ip.isNull() || ip.isLoopback() || ip.isMulticast()) {
                continue;
            }

            const QHostAddress netmask = entry.netmask();
            if (netmask.isNull()) {
                continue;
            }

            const quint32 ipHostOrder = ip.toIPv4Address();
            const quint32 maskHostOrder = netmask.toIPv4Address();
            if (maskHostOrder == 0) {
                continue;
            }

            const quint32 ipNetworkOrder = qToBigEndian(ipHostOrder);
            const quint32 maskNetworkOrder = qToBigEndian(maskHostOrder);
            const quint32 network = ipNetworkOrder & maskNetworkOrder;
            const quint32 broadcast = network | (~maskNetworkOrder);
            if (broadcast <= network) {
                continue;
            }

            quint32 start = network + 1;
            quint32 end = broadcast - 1;
            if (end < start) {
                continue;
            }

            const quint32 hostCount = end - start + 1;
            if (hostCount == 0 || hostCount > kMaxHostsPerInterface) {
                continue;
            }

            for (quint32 value = start; value <= end; ++value) {
                QHostAddress candidate;
                candidate.setAddress(qFromBigEndian(value));
                if (candidate == ip) {
                    continue;
                }
                const QString ipString = candidate.toString();
                if (!uniqueCandidates.contains(ipString)) {
                    uniqueCandidates.insert(ipString);
                    if (uniqueCandidates.size() >= kMaxTotalLookups) {
                        break;
                    }
                }
            }

            if (uniqueCandidates.size() >= kMaxTotalLookups) {
                break;
            }
        }

        if (uniqueCandidates.size() >= kMaxTotalLookups) {
            break;
        }
    }

    QStringList ipList = uniqueCandidates.values();
    std::sort(ipList.begin(), ipList.end());

    const QVector<QVariantMap> resolved = lookupCandidates(ipList);

    QVector<QVariantMap> sortedMatches = resolved;
    std::sort(sortedMatches.begin(), sortedMatches.end(), [](const QVariantMap &a, const QVariantMap &b) {
        const QString hostA = a.value(QStringLiteral("hostname")).toString();
        const QString hostB = b.value(QStringLiteral("hostname")).toString();
        if (hostA.compare(hostB, Qt::CaseInsensitive) == 0) {
            return a.value(QStringLiteral("ip")).toString() < b.value(QStringLiteral("ip")).toString();
        }
        return hostA.toLower() < hostB.toLower();
    });

    for (const QVariantMap &entry : sortedMatches) {
        result.append(entry);
    }

    return result;
}

#include "openhddiscovery.moc"
