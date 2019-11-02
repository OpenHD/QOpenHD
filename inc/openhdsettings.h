#ifndef OPENHDSETTINGS_H
#define OPENHDSETTINGS_H

#include <map>
#include <string>

#include <QObject>
#include <QMap>
#include <QVariant>
#include <QtQuick>
#include <QQmlPropertyMap>

class QUdpSocket;

typedef QMap<QString, QVariant> VMap;

Q_DECLARE_METATYPE(VMap);

class OpenHDSettings : public QObject {
    Q_OBJECT
public:
    explicit OpenHDSettings(QObject *parent = nullptr);
    void initSettings();

    Q_PROPERTY(VMap allSettings MEMBER m_allSettings NOTIFY allSettingsChanged)

    Q_PROPERTY(bool busy MEMBER m_busy WRITE set_busy NOTIFY busyChanged)
    void set_busy(bool busy);


    Q_INVOKABLE void fetchSettings();
    Q_INVOKABLE VMap getAllSettings();

    Q_INVOKABLE void saveSettings(VMap remoteSettings);

    Q_INVOKABLE void reboot();

signals:
    void allSettingsChanged(VMap allSettings);
    void busyChanged(bool busy);
    void savingSettingsStart();
    void savingSettingsFinish();

public slots:
    void processDatagrams();


private slots:
    void _savingSettingsStart();
    void _savingSettingsFinish();

private:
    void init();
    void _saveSettings(VMap remoteSettings);
    QUdpSocket *settingSocket = nullptr;

    VMap m_allSettings;
    qint64 start = 0;
    QTimer timer;
    void check();

    bool m_busy = false;

    QHostAddress groundAddress;
};



#endif // OPENHDSETTINGS_H
