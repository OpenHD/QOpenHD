#include "openhdsettings.h"

#include <QtNetwork>
#include <QThread>
#include <QtConcurrent>

#include "util/localmessage.h"

#define SETTINGS_PORT 1011

OpenHDSettings::OpenHDSettings(QObject *parent) : QObject(parent) {
    qDebug() << "OpenHDSettings::OpenHDSettings()";

    #if defined(__rasp_pi__)|| defined(__jetson__)
    groundAddress = "127.0.0.1";
    set_ground_available(true);
    #endif

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
        emit allSettingsChanged();
    }
}


void OpenHDSettings::checkSettingsSaveTimeout() {
    qint64 current = QDateTime::currentSecsSinceEpoch();
    /*fallback in case the ground pi never sends back "SavedGround" for all
       the settings we saved*/
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


void OpenHDSettings::saveSettings(QVariantMap remoteSettings) {
    qDebug() << "OpenHDSettings::saveSettings()";

    /* run the real network calls in the background. needs some minor changes to avoid threading related
       errors
      QFuture<void> future = QtConcurrent::run(this, &OpenHDSettings::_saveSettings, remoteSettings);
      */
    _saveSettings(remoteSettings);
}

void OpenHDSettings::_saveSettings(QVariantMap remoteSettings) {
    if (m_saving || m_loading) {
        return;
    }
    // shortcut if there aren't any modified settings
    if (remoteSettings.size() == 0) {
        emit savingSettingsFinished();
        return;
    }
    set_saving(true);

    emit savingSettingsStart();

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

QVariantMap OpenHDSettings::getAllSettings() {
    return m_allSettings;
}

void OpenHDSettings::fetchSettings() {
    if (m_loading || m_saving) {
        return;
    }

    //TODO
    /* this is probably important to set
          groundAddress = ip4Address.toString(); //this was from udp datagram host/sender

          emit groundStationIPUpdated(groundAddress);

   */
  emit groundStationIPUpdated("127.0.0.1"); // this was made up for testing
  set_ground_available(true);

    set_loading(true);

    qDebug() << "OpenHDSettings::fetchSettings()";

    loadStart = QDateTime::currentSecsSinceEpoch();
    loadTimer.start(1000);

    fetchHelper("/usr/local/share/openhd/general.template", 0,"general_");
    fetchHelper("/conf/openhd/ground/wifi.conf", 0,"wifi_");
    fetchHelper("/conf/openhd/ground/camera.conf", 0,"cam_");
    fetchHelper("/conf/openhd/ground/ethernet.conf", 0,"ethernet_");


    emit allSettingsChanged(); // also configend=configend look into

}

void OpenHDSettings::fetchHelper(QString file, int id, QString setting_prepend) {
    QFile inputFile(file);
    if (inputFile.open(QIODevice::ReadOnly))
    {
       QTextStream in(&inputFile);
       while (!in.atEnd())
       {
          QString line = in.readLine();
          qDebug() << "line:" << line;

          //to keep handle multiples of hardware (wifi cards, cameras)
          if (line.contains( "WiFi Card" )) {
              id=id+1;
              qDebug() << "found a card or cam line: " << id;
          }

          //find the values
          if (line.contains("=")){
              QString id_string = "";
          if (id>1){
              id_string = QString::number(id)+"_";
          }
          processLines(line, id_string, setting_prepend);
          }
       }
       inputFile.close();
    }
}


void OpenHDSettings::processLines(QString line, QString id_string, QString setting_prepend) {




            auto set = line.split('=');
            auto key = set.first();         
            // eliminate any zero length keys coming from the server, which aren't real settings
            if (key.length() <= 0) {
                return;
            }



            // remove ConfigResp from the beginning of each key
            //line.remove(0, 10);
            /*
             * Find the FIRST equals sign in the rest of the datagram. Everything
             * before it is the key and everything after it is the value
             */
            auto split_location = line.indexOf("=");
            // copy just the key, without the equals sign and without altering the datagram
            key = line.mid(0, split_location);
            // cut the entire key and the equals sign out of the datagram...
            line.remove(0, split_location + 1);
            // ... leaving just the value remaining in the datagram
            auto val = line;
qDebug() << "key=" << setting_prepend+id_string+key << " val=" << val;
            m_allSettings.insert(QString(setting_prepend+id_string+key), QVariant(val));


}

