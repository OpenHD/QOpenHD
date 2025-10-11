#include "networkdevicescanner.h"

#include <QHostAddress>
#include <QHostInfo>
#include <QMutexLocker>
#include <QNetworkAddressEntry>
#include <QNetworkInterface>
#include <QSet>
#include <QStringList>
#include <QtConcurrent>
#include <QVariantMap>

#include <algorithm>

namespace {
constexpr quint32 kMaxHostsPerSubnet = 512;

quint32 maskFromPrefix(int prefixLength)
{
    if (prefixLength <= 0) {
        return 0u;
    }
    if (prefixLength >= 32) {
        return 0xFFFFFFFFu;
    }
    return (~quint32(0)) << (32 - prefixLength);
}

struct DeviceInfo {
    QString hostname;
    QString ip;
};

QVariantList buildVariantList(const QList<DeviceInfo> &devices)
{
    QVariantList result;
    result.reserve(devices.size());
    for (const auto &device : devices) {
        QVariantMap map;
        map.insert(QStringLiteral("hostname"), device.hostname);
        map.insert(QStringLiteral("ip"), device.ip);
        result.append(map);
    }
    return result;
}

} // namespace

NetworkDeviceScanner &NetworkDeviceScanner::instance()
{
    static NetworkDeviceScanner instance;
    return instance;
}

NetworkDeviceScanner::NetworkDeviceScanner(QObject *parent)
    : QObject(parent)
{
    connect(&m_watcher, &QFutureWatcher<QVariantList>::finished, this, [this]() {
        setDevices(m_watcher.result());
        setScanning(false);
    });
}

QVariantList NetworkDeviceScanner::devices() const
{
    QMutexLocker locker(&m_mutex);
    return m_devices;
}

bool NetworkDeviceScanner::scanning() const
{
    QMutexLocker locker(&m_mutex);
    return m_scanning;
}

void NetworkDeviceScanner::refresh()
{
    {
        QMutexLocker locker(&m_mutex);
        if (m_scanning) {
            return;
        }
        m_scanning = true;
    }
    emit scanningChanged();

    auto future = QtConcurrent::run([this]() {
        return discoverDevices();
    });
    m_watcher.setFuture(future);
}

void NetworkDeviceScanner::setDevices(const QVariantList &devices)
{
    {
        QMutexLocker locker(&m_mutex);
        if (m_devices == devices) {
            return;
        }
        m_devices = devices;
    }
    emit devicesChanged();
}

void NetworkDeviceScanner::setScanning(bool scanning)
{
    bool changed = false;
    {
        QMutexLocker locker(&m_mutex);
        if (m_scanning != scanning) {
            m_scanning = scanning;
            changed = true;
        }
    }
    if (changed) {
        emit scanningChanged();
    }
}

QVariantList NetworkDeviceScanner::discoverDevices() const
{
    QList<DeviceInfo> discovered;
    QSet<QString> seenIps;

    const auto interfaces = QNetworkInterface::allInterfaces();
    for (const QNetworkInterface &iface : interfaces) {
        if (!(iface.flags() & QNetworkInterface::IsUp) ||
            !(iface.flags() & QNetworkInterface::IsRunning) ||
            (iface.flags() & QNetworkInterface::IsLoopBack)) {
            continue;
        }

        const auto entries = iface.addressEntries();
        for (const QNetworkAddressEntry &entry : entries) {
            const QHostAddress address = entry.ip();
            if (address.protocol() != QAbstractSocket::IPv4Protocol) {
                continue;
            }

            const int prefix = entry.prefixLength();
            if (prefix <= 0 || prefix >= 32) {
                continue;
            }

            const quint32 ownAddress = address.toIPv4Address();
            quint32 mask = maskFromPrefix(prefix);
            if (mask == 0u) {
                continue;
            }
            const quint32 network = ownAddress & mask;
            const quint32 broadcast = network | (~mask);
            if (broadcast <= network) {
                continue;
            }

            quint32 start = network + 1;
            quint32 end = broadcast - 1;
            if (end < start) {
                continue;
            }

            const auto clampRange = [&](quint32 &rangeStart, quint32 &rangeEnd) {
                const quint32 available = rangeEnd >= rangeStart ? (rangeEnd - rangeStart + 1) : 0u;
                if (available <= kMaxHostsPerSubnet) {
                    return;
                }

                quint32 adjustedStart = rangeStart;
                quint32 adjustedEnd = rangeEnd;

                const quint32 halfRange = kMaxHostsPerSubnet / 2u;
                if (ownAddress > rangeStart) {
                    if (ownAddress - rangeStart > halfRange) {
                        adjustedStart = ownAddress - halfRange;
                    }
                }

                if (adjustedStart < rangeStart) {
                    adjustedStart = rangeStart;
                }

                adjustedEnd = adjustedStart + kMaxHostsPerSubnet - 1u;
                if (adjustedEnd > rangeEnd) {
                    adjustedEnd = rangeEnd;
                    if (adjustedEnd >= kMaxHostsPerSubnet) {
                        adjustedStart = adjustedEnd - (kMaxHostsPerSubnet - 1u);
                    }
                }

                rangeStart = adjustedStart;
                rangeEnd = adjustedEnd;
            };

            clampRange(start, end);

            for (quint32 host = start; host <= end; ++host) {
                if (host == ownAddress) {
                    continue;
                }
                const QString ipString = QHostAddress(host).toString();
                if (seenIps.contains(ipString)) {
                    continue;
                }
                seenIps.insert(ipString);

                const QHostInfo info = QHostInfo::fromName(ipString);
                if (info.error() != QHostInfo::NoError) {
                    continue;
                }

                QStringList hostnames;
                if (!info.hostName().isEmpty()) {
                    hostnames.append(info.hostName());
                }
                const auto aliases = info.aliases();
                for (const QString &alias : aliases) {
                    if (!hostnames.contains(alias)) {
                        hostnames.append(alias);
                    }
                }

                QString matchedName;
                for (const QString &name : hostnames) {
                    if (name.contains(QStringLiteral("openhd"), Qt::CaseInsensitive)) {
                        matchedName = name;
                        break;
                    }
                }

                if (matchedName.isEmpty()) {
                    continue;
                }

                discovered.append(DeviceInfo{matchedName, ipString});
            }
        }
    }

    std::sort(discovered.begin(), discovered.end(), [](const DeviceInfo &lhs, const DeviceInfo &rhs) {
        const int cmp = QString::compare(lhs.hostname, rhs.hostname, Qt::CaseInsensitive);
        if (cmp == 0) {
            return lhs.ip < rhs.ip;
        }
        return cmp < 0;
    });

    return buildVariantList(discovered);
}
