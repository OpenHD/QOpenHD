#pragma once

#include <QElapsedTimer>
#include <QMap>
#include <QTimer>
#include <QUdpSocket>
#include <QVariant>
#include <functional>

class LanPlatformDiscovery {
public:
    explicit LanPlatformDiscovery(std::function<void(const QVariantList&)> onChanged);

private:
    struct Platform {
        QString role;
        qint64 lastSeen;
    };

    void receiveAnnouncements();
    void expireAnnouncements();
    void publish();

    std::function<void(const QVariantList&)> m_onChanged;
    QElapsedTimer m_clock;
    QMap<QString, Platform> m_platforms;
    QUdpSocket m_socket;
    QTimer m_expiryTimer;
};
