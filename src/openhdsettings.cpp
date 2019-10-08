#include "openhdsettings.h"

#include <QtNetwork>
#include <QThread>
#include <QtConcurrent>

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

    connect(&timer, &QTimer::timeout, this, &OpenHDSettings::check);

    // internal signal from background thread
    connect(this, &OpenHDSettings::savingSettingsStart, this, &OpenHDSettings::_savingSettingsStart);
    connect(this, &OpenHDSettings::savingSettingsFinish, this, &OpenHDSettings::_savingSettingsFinish);
}

void OpenHDSettings::set_busy(bool busy) {
    m_busy = busy;
    emit busyChanged(m_busy);
}

void OpenHDSettings::check() {
    qint64 current = QDateTime::currentSecsSinceEpoch();
    //fallback in case the ground pi never sends back "ConfigEnd=ConfigEnd"
    if (current - start > 10) {
        timer.stop();
        emit allSettingsChanged(m_allSettings);
        set_busy(false);
    }
}

void OpenHDSettings::_savingSettingsStart() {
    set_busy(true);
}

void OpenHDSettings::_savingSettingsFinish() {
    set_busy(false);
}

void OpenHDSettings::saveSettings(VMap remoteSettings) {
    qDebug() << "OpenHDSettings::saveSettings()";

    // run the real network calls in the background. needs some minor changes to avoid threading related
    // errors
    //QFuture<void> future = QtConcurrent::run(this, &OpenHDSettings::_saveSettings, remoteSettings);
    _saveSettings(remoteSettings);
}

void OpenHDSettings::_saveSettings(VMap remoteSettings) {
    if (m_busy) {
        return;
    }
    set_busy(true);
    //emit savingSettingsStart();
    QUdpSocket *s = new QUdpSocket(this);
    s->connectToHost(SETTINGS_IP, SETTINGS_PORT);

    QMapIterator<QString, QVariant> i(remoteSettings);
    while (i.hasNext()) {
        i.next();

        QByteArray r = QByteArray("RequestChangeSettings");
        r.append(i.key());
        r.append('=');
        r.append(i.value().toString());
        QNetworkDatagram d(r);
        s->writeDatagram(d);

        QThread::msleep(30);
    }
    set_busy(false);
    //emit savingSettingsFinish();
}

VMap OpenHDSettings::getAllSettings() {
    return m_allSettings;
}

void OpenHDSettings::fetchSettings() {
    qDebug() << "OpenHDSettings::fetchSettings()";
    if (m_busy) {
        return;
    }
    set_busy(true);
    start = QDateTime::currentSecsSinceEpoch();
    timer.start(1000);

    QByteArray r = QByteArray("RequestAllSettings");

    QNetworkDatagram d(r);
    QUdpSocket *s = new QUdpSocket(this);
    s->connectToHost(SETTINGS_IP, SETTINGS_PORT);
    s->writeDatagram(d);
}


void OpenHDSettings::processDatagrams() {
    QByteArray datagram;

    while (settingSocket->hasPendingDatagrams()) {
        datagram.resize(int(settingSocket->pendingDatagramSize()));
        settingSocket->readDatagram(datagram.data(), datagram.size());

        if (datagram == "ConfigEnd=ConfigEnd") {
            timer.stop();
            emit allSettingsChanged(m_allSettings);
            set_busy(false);
        } else {
            auto set = datagram.split('=');
            auto key = set.first();
            // remove ConfigResp from the beginning of each key
            key.remove(0, 10);
            // eliminate any zero length keys coming from the server, which aren't real settings
            if (key.length() <= 0) {
                return;
            }
            auto val = set.last();

            m_allSettings.insert(QString(key), QVariant(val));
        }
    }
}

