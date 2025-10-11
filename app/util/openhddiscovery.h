#ifndef OPENHDDISCOVERY_H
#define OPENHDDISCOVERY_H

#include <QObject>
#include <QVariantList>
#include <QFutureWatcher>

class OpenHDDiscovery : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList devices READ devices NOTIFY devicesChanged)
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)
public:
    explicit OpenHDDiscovery(QObject *parent = nullptr);
    static OpenHDDiscovery& instance();

    QVariantList devices() const;
    bool scanning() const;

    Q_INVOKABLE void refresh();

signals:
    void devicesChanged();
    void scanningChanged();

private:
    QVariantList performScan() const;

    QVariantList m_devices;
    bool m_scanning = false;
    QFutureWatcher<QVariantList> m_watcher;
};

#endif // OPENHDDISCOVERY_H
