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

    Q_PROPERTY(bool loading MEMBER m_loading WRITE set_loading NOTIFY loadingChanged)
    void set_loading(bool loading);

    Q_PROPERTY(bool saving MEMBER m_saving WRITE set_saving NOTIFY savingChanged)
    void set_saving(bool saving);

    Q_INVOKABLE void fetchSettings();
    Q_INVOKABLE VMap getAllSettings();

    Q_INVOKABLE void saveSettings(VMap remoteSettings);

    Q_INVOKABLE void reboot();

    Q_INVOKABLE void shutdown();

    Q_PROPERTY(bool ground_available MEMBER m_ground_available WRITE set_ground_available NOTIFY ground_available_changed)
    void set_ground_available(bool ground_available);

signals:
    void allSettingsChanged(VMap allSettings);
    void loadingChanged(bool loading);
    void savingChanged(bool saving);
    void savedChanged(bool saved);

    void savingSettingsStart();
    void savingSettingsFinished();
    void savingSettingsFailed(qint64 failCount);

    void groundStationIPUpdated(QString address);

    void ground_available_changed(bool ground_available);

public slots:
    void processDatagrams();

private:
    void init();
    void _saveSettings(VMap remoteSettings);

    QUdpSocket *settingSocket = nullptr;

    bool m_ground_available = false;

    VMap m_allSettings;

    qint64 loadStart = 0;

    qint64 saveStart = 0;

    QTimer loadTimer;
    QTimer saveTimer;

    void checkSettingsLoadTimeout();
    void checkSettingsSaveTimeout();

    QTimer savedTimer;

    // used to keep track of how many settings need to be saved so we can compare it to
    // the number of save confirmations we get back from the ground side
    int settingsCount = 0;

    bool m_loading = false;
    bool m_saving = false;

    QHostAddress groundAddress;
};



#endif // OPENHDSETTINGS_H
