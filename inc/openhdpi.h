#ifndef OPENHDPI_H
#define OPENHDPI_H

#include <QObject>
#include <QtQuick>
#include <QProcess>
#include <QProcessEnvironment>

class OpenHDPi : public QObject {
    Q_OBJECT

public:
    explicit OpenHDPi(QObject *parent = nullptr);

    Q_PROPERTY(bool is_raspberry_pi READ is_raspberry_pi NOTIFY is_raspberry_pi_changed)
    bool is_raspberry_pi();

    Q_PROPERTY(int brightness READ get_brightness WRITE set_brightness NOTIFY brightness_changed)
    void set_brightness(int brightness);
    int get_brightness();


    Q_PROPERTY(bool undervolt MEMBER m_undervolt NOTIFY undervolt_changed)

    Q_INVOKABLE void activate_console();
    Q_INVOKABLE void stop_app();
    Q_INVOKABLE void set_boot_mount_rw();
    Q_INVOKABLE void set_boot_mount_ro();

    Q_INVOKABLE void update_ground();

    int ground_load = 0;
    int ground_temp = 0;

private:
    QProcess *mountProcess = nullptr;

    bool m_undervolt = false;
    long double a[4], b[4];

signals:
    void brightness_changed(int brightness);
    void is_raspberry_pi_changed(bool is_raspberry_pi);
     void undervolt_changed(bool undervolt);
};

QObject *openHDPiSingletonProvider(QQmlEngine *engine, QJSEngine *scriptEngine);

#endif // OPENHDPI_H
