#ifndef OPENHDPI_H
#define OPENHDPI_H

#include <QObject>
#include <QtQuick>
#include <QProcess>
#include <QProcessEnvironment>

/**
 * Please use this class only in case something really needs to be implemented platform-dependent.
 * Utils for performing platform-specific actions and more.
 */
class OpenHDPi : public QObject {
    Q_OBJECT

public:
    explicit OpenHDPi(QObject *parent = nullptr);

    Q_PROPERTY(bool is_raspberry_pi READ is_raspberry_pi NOTIFY is_raspberry_pi_changed)
    bool is_raspberry_pi();

    Q_PROPERTY(int brightness READ get_brightness WRITE set_brightness NOTIFY brightness_changed)
    void set_brightness(int brightness);
    int get_brightness();

    /**
     * This terminates QOpenHD (aka the application itself) such that an advanced user can use the console.
     */
    Q_INVOKABLE void stop_app();

    // These are not needed anymore ?!
    Q_INVOKABLE void set_boot_mount_rw();
    Q_INVOKABLE void set_boot_mount_ro();

private:
#if defined(__rasp_pi__)
    QProcess *mountProcess = nullptr;
#endif

signals:
    void brightness_changed(int brightness);
    void is_raspberry_pi_changed(bool is_raspberry_pi);
};

QObject *openHDPiSingletonProvider(QQmlEngine *engine, QJSEngine *scriptEngine);

#endif // OPENHDPI_H
