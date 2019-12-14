#include "openhdsettings.h"

#include <QtNetwork>
#include <QThread>
#include <QtConcurrent>

#include "localmessage.h"

#define SETTINGS_PORT 1011
#define SETTINGS_IP "192.168.2.1"

OpenHDSettings::OpenHDSettings(QObject *parent) : QObject(parent) {
    qDebug() << "OpenHDSettings::OpenHDSettings()";
    initSettings();
}


void OpenHDSettings::initSettings() {
    qDebug() << "OpenHDSettings::initSettings()";
    settingSocket = new QUdpSocket(this);
    settingSocket->bind(QHostAddress::Any, 5115);
    connect(settingSocket, SIGNAL(readyRead()), this, SLOT(processDatagrams()));

    connect(&loadTimer, &QTimer::timeout, this, &OpenHDSettings::checkSettingsLoadTimeout);
    connect(&saveTimer, &QTimer::timeout, this, &OpenHDSettings::checkSettingsSaveTimeout);
}

void OpenHDSettings::set_ground_available(bool ground_available) {
    m_ground_available = ground_available;
    emit ground_available_changed(m_ground_available);
}

void OpenHDSettings::set_loading(bool loading) {
    m_loading = loading;
    emit loadingChanged(m_loading);
}

void OpenHDSettings::set_saving(bool saving) {
    m_saving = saving;
    emit savingChanged(m_saving);
}


void OpenHDSettings::checkSettingsLoadTimeout() {
    qint64 current = QDateTime::currentSecsSinceEpoch();
    //fallback in case the ground pi never sends back "ConfigEnd=ConfigEnd"
    if (current - loadStart > 30) {
        loadTimer.stop();
        set_loading(false);
        emit allSettingsChanged(m_allSettings);
    }
}


void OpenHDSettings::checkSettingsSaveTimeout() {
    qint64 current = QDateTime::currentSecsSinceEpoch();
    //fallback in case the ground pi never sends back "SavedGround" for all
    // the settings we saved
    if (current - saveStart > 30) {
        saveTimer.stop();
        set_saving(false);
        if (settingsCount <= 0) {
            emit savingSettingsFinished();
        } else {
            emit savingSettingsFailed(settingsCount);
        }
    }
}


void OpenHDSettings::reboot() {
    if (m_saving) {
        return;
    }
#if defined(__rasp_pi__)
    QProcess process;
    process.start("/sbin/reboot");
    process.waitForFinished();
#else
    QByteArray r = QByteArray("RequestReboot");
    settingSocket->writeDatagram(r, QHostAddress(groundAddress), SETTINGS_PORT);

#endif
}

void OpenHDSettings::shutdown() {
    if (m_saving) {
        return;
    }
#if defined(__rasp_pi__)
    QProcess process;
    process.start("/sbin/shutdown -h -P now");
    process.waitForFinished();
#else
    QByteArray r = QByteArray("RequestShutdown");
    settingSocket->writeDatagram(r, QHostAddress(groundAddress), SETTINGS_PORT);
#endif
}


void OpenHDSettings::saveSettings(VMap remoteSettings) {
    qDebug() << "OpenHDSettings::saveSettings()";

    // run the real network calls in the background. needs some minor changes to avoid threading related
    // errors
    //QFuture<void> future = QtConcurrent::run(this, &OpenHDSettings::_saveSettings, remoteSettings);
    _saveSettings(remoteSettings);
}

void OpenHDSettings::_saveSettings(VMap remoteSettings) {
    if (m_saving || m_loading) {
        return;
    }
    set_saving(true);

    emit savingSettingsStart();

    QUdpSocket *s = new QUdpSocket(this);
#if defined(__rasp_pi__)
    s->connectToHost(SETTINGS_IP, SETTINGS_PORT);
#else
    s->connectToHost(groundAddress, SETTINGS_PORT);
#endif

    settingsCount = remoteSettings.count();
    saveStart = QDateTime::currentSecsSinceEpoch();
    saveTimer.start(1000);

    QMapIterator<QString, QVariant> i(remoteSettings);
    while (i.hasNext()) {
        i.next();

        QByteArray r = QByteArray("RequestChangeSettings");
        r.append(i.key());
        r.append('=');
        r.append(i.value().toString());
        settingSocket->writeDatagram(r, QHostAddress(groundAddress), SETTINGS_PORT);

        QThread::msleep(30);
    }
}

VMap OpenHDSettings::getAllSettings() {
    return m_allSettings;
}

void OpenHDSettings::fetchSettings() {
    if (m_loading || m_saving) {
        return;
    }
    set_loading(true);

    qDebug() << "OpenHDSettings::fetchSettings()";

    loadStart = QDateTime::currentSecsSinceEpoch();
    loadTimer.start(1000);

    QByteArray r = QByteArray("RequestAllSettings");
    QNetworkDatagram d(r);
    settingSocket->writeDatagram(r, QHostAddress(groundAddress), SETTINGS_PORT);
}


void OpenHDSettings::processDatagrams() {
    QByteArray datagram;

    while (settingSocket->hasPendingDatagrams()) {
        datagram.resize(int(settingSocket->pendingDatagramSize()));

        settingSocket->readDatagram(datagram.data(), datagram.size(), &groundAddress);

        emit groundStationIPUpdated(groundAddress.toString());
        set_ground_available(true);

        if (datagram == "ConfigRespConfigEnd=ConfigEnd") {
            loadTimer.stop();
            emit allSettingsChanged(m_allSettings);
            set_loading(false);
        } else if (datagram.contains("SavedGround")) {
            settingsCount -= 1;
            if (settingsCount <= 0) {
                set_saving(false);
                saveTimer.stop();
                emit savingSettingsFinished();
            }
        } else {
            auto set = datagram.split('=');
            auto key = set.first();         
            // eliminate any zero length keys coming from the server, which aren't real settings
            if (key.length() <= 0) {
                return;
            }

            // ignore non-settings messages
            if (key.compare("GroundIP\n") == 0) {
                continue;
            }

            // remove ConfigResp from the beginning of each key
            datagram.remove(0, 10);
            /*
             * Find the FIRST equals sign in the rest of the datagram. Everything
             * before it is the key and everything after it is the value
             */
            auto split_location = datagram.indexOf("=");
            // copy just the key, without the equals sign and without altering the datagram
            key = datagram.mid(0, split_location);
            // cut the entire key and the equals sign out of the datagram...
            datagram.remove(0, split_location + 1);
            // ... leaving just the value remaining in the datagram
            auto val = datagram;

            m_allSettings.insert(QString(key), QVariant(val));
        }
    }
}

