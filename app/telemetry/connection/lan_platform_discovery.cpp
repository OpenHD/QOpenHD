#include "lan_platform_discovery.h"

#include <QNetworkDatagram>
#include <utility>

namespace {
// Keep in sync with OpenHD's LanPlatformAnnouncer.
constexpr quint16 discoveryPort = 42042;
constexpr qint64 expiryMs = 12000;
}

LanPlatformDiscovery::LanPlatformDiscovery(std::function<void(const QVariantList&)> onChanged)
    : m_onChanged(std::move(onChanged))
{
    if (!m_socket.bind(QHostAddress::AnyIPv4, discoveryPort,
                       QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint)) {
        qWarning("Cannot listen for OpenHD LAN announcements: %s", qPrintable(m_socket.errorString()));
        return;
    }

    m_clock.start();
    QObject::connect(&m_socket, &QUdpSocket::readyRead, &m_socket,
                     [this] { receiveAnnouncements(); });
    QObject::connect(&m_expiryTimer, &QTimer::timeout, &m_expiryTimer,
                     [this] { expireAnnouncements(); });
    m_expiryTimer.start(1000);
}

void LanPlatformDiscovery::receiveAnnouncements()
{
    bool changed = false;
    while (m_socket.hasPendingDatagrams()) {
        const auto datagram = m_socket.receiveDatagram(64);
        const auto fields = datagram.data().split(':');
        if (fields.size() != 3 || fields[0] != "PLATFORM" ||
            (fields[1] != "AIR" && fields[1] != "GROUND")) {
            continue;
        }

        const auto sender = datagram.senderAddress();
        const auto ip = sender.toString();
        if (sender.protocol() != QAbstractSocket::IPv4Protocol || fields[2] != ip.toLatin1()) {
            continue;
        }

        const auto role = QString::fromLatin1(fields[1]);
        auto platform = m_platforms.find(ip);
        if (platform == m_platforms.end()) {
            m_platforms.insert(ip, {role, m_clock.elapsed()});
            changed = true;
        } else {
            changed |= platform->role != role;
            *platform = {role, m_clock.elapsed()};
        }
    }
    if (changed) publish();
}

void LanPlatformDiscovery::expireAnnouncements()
{
    const auto cutoff = m_clock.elapsed() - expiryMs;
    bool changed = false;
    for (auto platform = m_platforms.begin(); platform != m_platforms.end();) {
        if (platform->lastSeen <= cutoff) {
            platform = m_platforms.erase(platform);
            changed = true;
        } else {
            ++platform;
        }
    }
    if (changed) publish();
}

void LanPlatformDiscovery::publish()
{
    QVariantList platforms;
    for (auto platform = m_platforms.cbegin(); platform != m_platforms.cend(); ++platform) {
        platforms.append(QVariantMap{{QStringLiteral("ip"), platform.key()},
                                     {QStringLiteral("role"), platform->role}});
    }
    m_onChanged(platforms);
}
