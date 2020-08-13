#include "managesettings.h"

#include <QtNetwork>
#include <QThread>
#include <QtConcurrent>
#include <QProcess>
#include <QProcessEnvironment>
#include <QRegularExpression>
#include <QUrl>

#include <inja.hpp>

#if defined(__android__)
#include <QtAndroid>
#endif

#include "openhdpi.h"

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
    qDebug() << "Loading settings file";

    QSettings appSettings;

    #if defined(__android__)
    QFile file(url.toString());
    #elif defined(__rasp__pi__)
    QFile file(url.toString());
    #else
    QFile file(url.toLocalFile());
    #endif


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



            if (isLongLong) {
                emit settingUpdated(key, QVariant(longLongValue));
                appSettings.setValue(key, QVariant(longLongValue));
            } else if (isInt) {
                emit settingUpdated(key, QVariant(intValue));
                appSettings.setValue(key, QVariant(intValue));
            } else if (isDouble) {
                emit settingUpdated(key, QVariant(doubleValue));
                appSettings.setValue(key, QVariant(doubleValue));
            } else if (value.contains("true")) {
                emit settingUpdated(key, QVariant(true));
                appSettings.setValue(key, QVariant(true));
            } else if (value.contains("false")) {
                emit settingUpdated(key, QVariant(false));
                appSettings.setValue(key, QVariant(false));
            } else {
                emit settingUpdated(key, QVariant(value));
                appSettings.setValue(key, QVariant(value));
            }
        }

        file.close();
    }

    emit needRestart();
}


Q_INVOKABLE void ManageSettings::restartApp() {
    #if defined(__android__)
    auto activity = QtAndroid::androidActivity();
    auto packageManager = activity.callObjectMethod("getPackageManager",
                                                    "()Landroid/content/pm/PackageManager;");

    auto activityIntent = packageManager.callObjectMethod("getLaunchIntentForPackage",
                                                          "(Ljava/lang/String;)Landroid/content/Intent;",
                                                          activity.callObjectMethod("getPackageName",
                                                          "()Ljava/lang/String;").object());

    auto pendingIntent = QAndroidJniObject::callStaticObjectMethod("android/app/PendingIntent", "getActivity",
                                                                   "(Landroid/content/Context;ILandroid/content/Intent;I)Landroid/app/PendingIntent;",
                                                                   activity.object(), jint(0), activityIntent.object(),
                                                                   QAndroidJniObject::getStaticField<jint>("android/content/Intent",
                                                                                                           "FLAG_ACTIVITY_CLEAR_TOP"));

    auto alarmManager = activity.callObjectMethod("getSystemService",
                                                  "(Ljava/lang/String;)Ljava/lang/Object;",
                                                  QAndroidJniObject::getStaticObjectField("android/content/Context",
                                                                                          "ALARM_SERVICE",
                                                                                          "Ljava/lang/String;").object());

    alarmManager.callMethod<void>("set",
                                  "(IJLandroid/app/PendingIntent;)V",
                                  QAndroidJniObject::getStaticField<jint>("android/app/AlarmManager", "RTC"),
                                  jlong(QDateTime::currentMSecsSinceEpoch() + 3000), pendingIntent.object());

    qApp->quit();
    #endif
}

Q_INVOKABLE void ManageSettings::loadPiSettings() {
    QUrl url(piSettingsFile);
    loadSettingsFile(url);
}


Q_INVOKABLE bool ManageSettings::saveSettingsFile(QUrl url) {
    qDebug() << "Saving settings file";

    QSettings appSettings;
    Environment env;
    json data;

    QFile file(":/qopenhd.template");
    if (!file.open(QIODevice::ReadOnly)) {
        qDebug() << "error: " << file.errorString();
        return false;
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

    try {
        std::string rendered = env.render(temp, data);

        #if defined(__android__)
        QFile outFile(url.toString());
        #elif defined(__rasp__pi__)
        QFile outFile(url.toString());
        #else
        QFile outFile(url.toLocalFile());
        #endif

        if (!outFile.open(QIODevice::ReadWrite)) {
            qDebug() << "error: " << outFile.errorString();
            return false;
        }

        QByteArray byteArray(rendered.c_str(), rendered.length());
        outFile.write(byteArray);
        return true;
    } catch (std::exception &ex) {
        return false;
    }

    return false;
}


Q_INVOKABLE bool ManageSettings::savePiSettings() {
    OpenHDPi pi;
    pi.set_boot_mount_rw();
    bool success = saveSettingsFile(piSettingsFile);
    pi.set_boot_mount_ro();
    return success;
}

