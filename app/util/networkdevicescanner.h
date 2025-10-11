#ifndef NETWORKDEVICESCANNER_H
#define NETWORKDEVICESCANNER_H

#include <QObject>
#include <QVariantList>
#include <QFutureWatcher>
#include <QMutex>

class NetworkDeviceScanner : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList devices READ devices NOTIFY devicesChanged)
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)
public:
    static NetworkDeviceScanner &instance();

    QVariantList devices() const;
    bool scanning() const;

    Q_INVOKABLE void refresh();

signals:
    void devicesChanged();
    void scanningChanged();

private:
    explicit NetworkDeviceScanner(QObject *parent = nullptr);

    void setDevices(const QVariantList &devices);
    void setScanning(bool scanning);
    QVariantList discoverDevices() const;

    mutable QMutex m_mutex;
    QVariantList m_devices;
    bool m_scanning = false;
    QFutureWatcher<QVariantList> m_watcher;
};

#endif // NETWORKDEVICESCANNER_H
