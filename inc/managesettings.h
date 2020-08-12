#ifndef MANAGESETTINGS_H
#define MANAGESETTINGS_H

#include <QObject>
#include <QUrl>
#include <QVariant>

class ManageSettings : public QObject
{
    Q_OBJECT

public:
    explicit ManageSettings(QObject *parent = nullptr);
    static ManageSettings* instance();


    Q_INVOKABLE void loadPiSettings();

    Q_INVOKABLE void savePiSettings();

    Q_INVOKABLE void loadSettingsFile(QUrl url);
    Q_INVOKABLE void saveSettingsFile(QUrl url);


signals:
    void settingUpdated(QString key, QVariant value);

private:
    QString piSettingsFile = "/boot/qopenhd.conf";
};


#endif // MANAGESETTINGS_H
