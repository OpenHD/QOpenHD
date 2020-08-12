#include "managesettings.h"

#include <QtNetwork>
#include <QThread>
#include <QtConcurrent>
#include <QProcess>
#include <QProcessEnvironment>
#include <QRegularExpression>
#include <QUrl>

#include <inja.hpp>

#if defined(__rasp__pi__)
#include "openhdpi.h"
#endif

// Just for convenience
using namespace inja;
using json = nlohmann::json;



static ManageSettings* _instance = nullptr;


ManageSettings* ManageSettings::instance() {
    if (_instance == nullptr) {
        _instance = new ManageSettings();
    }
    return _instance;
}


ManageSettings::ManageSettings(QObject *parent) : QObject(parent) {
    qDebug() << "ManageSettings::ManageSettings()";
}


Q_INVOKABLE void ManageSettings::loadSettingsFile(QUrl url) {
    QSettings appSettings;

    QFile file(url.path());

    if (file.open(QIODevice::ReadOnly)) {

        QTextStream in(&file);

        while (!in.atEnd()) {
            QString line = in.readLine();

            if (line.size() < 1) {
                continue;
            }

            // remove whitespace
            line = line.trimmed();

            // ignore comments
            if (line.at(0) == '#') {
                continue;
            }


            auto kv = line.split('=');

            // ignore lines that don't have exactly one properly formed key/value pair
            if (kv.size() != 2) {
                continue;
            }


            auto key = kv.first().trimmed();
            auto value = kv.last().trimmed();


            bool isDouble = false;
            double doubleValue = value.toDouble(&isDouble);

            bool isLongLong = false;
            long long longLongValue = value.toLongLong(&isLongLong);

            bool isInt = false;
            int intValue = value.toInt(&isInt);


            if (isDouble) {
                appSettings.setValue(key, QVariant(doubleValue));
            } else if (isLongLong) {
                appSettings.setValue(key, QVariant(longLongValue));
            } else if (isInt) {
                appSettings.setValue(key, QVariant(intValue));
            } else if (value.contains("true")) {
                appSettings.setValue(key, QVariant(true));
            } else if (value.contains("false")) {
                appSettings.setValue(key, QVariant(false));
            } else {
                appSettings.setValue(key, QVariant(value));
            }
        }

        file.close();
    }
}


Q_INVOKABLE void ManageSettings::loadPiSettings() {
    QDir _p(piSettingsFile);
    QUrl _f = _p.filePath("qopenhd.conf");
    loadSettingsFile(_f);
}


Q_INVOKABLE void ManageSettings::saveSettingsFile(QUrl url) {
    QSettings appSettings;
    Environment env;
    json data;

    QFile file(":/qopenhd.template");
    if (!file.open(QIODevice::ReadOnly)) {
        qDebug() << "error: " << file.errorString();
        return;
    }

    Template temp = env.parse(file.readAll().toStdString());

    for (auto& setting_key : appSettings.allKeys()) {
        auto value = appSettings.value(setting_key);
        auto key = setting_key.toStdString();
        auto key_type = value.type();


        switch (key_type) {
            case QVariant::Bool: {
                data[key] = appSettings.value(setting_key).toBool();
                break;
            }
            case QVariant::Int: {
                data[key] = appSettings.value(setting_key).toInt();
                break;
            }
            case QVariant::UInt: {
                data[key] = appSettings.value(setting_key).toUInt();
                break;
            }
            case QVariant::Double: {
                data[key] = appSettings.value(setting_key).toDouble();
                break;
            }
            case QVariant::String: {
                data[key] = appSettings.value(setting_key).toString().toStdString();
                break;
            }
            case QVariant::LongLong: {
                data[key] = appSettings.value(setting_key).toLongLong();
                break;
            }
            case QVariant::ULongLong: {
                data[key] = appSettings.value(setting_key).toULongLong();
                break;
            }
            case QVariant::DateTime: {
                break;
            }
            case QVariant::StringList: {
                break;
            }
            case QVariant::Map: {
                break;
            }
            case QVariant::List: {
                break;
            }
            default: {
                break;
            }
        }
    }


    env.write(temp, data, url.toLocalFile().toStdString());
}


Q_INVOKABLE void ManageSettings::savePiSettings() {
#if defined(__rasp__pi__)
    OpenHDPi pi;
    pi.set_boot_mount_rw();
    saveSettingsFile(piSettingsFile);
    pi.set_boot_mount_ro();
#endif
}

