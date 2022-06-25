#include "openhdpi.h"

#include <QtNetwork>
#include <QThread>
#include <QtConcurrent>
#include <QProcess>
#include <QProcessEnvironment>
#include <qapplication.h>


OpenHDPi::OpenHDPi(QObject *parent) : QObject(parent) {
    qDebug() << "OpenHDPi::OpenHDPi()";
}


bool OpenHDPi::is_raspberry_pi() {
#if defined (__rasp_pi__)
    return true;
#else
    return false;
#endif
}

void OpenHDPi::activate_console() {
#if defined (__rasp_pi__)
    qDebug() << "OpenHDPi::activate_console()";
    QString program = "/bin/chvt";
    QStringList arguments;
    arguments << "12";
    QProcess *process = new QProcess(this);
    process->start(program, arguments);
    process->waitForFinished();
    #endif
}

void OpenHDPi::stop_app() {
    qDebug()<<"Request stop app";
#if defined (__rasp_pi__)
    qDebug() << "OpenHDPi::stop_app()";
    QString program = "/bin/systemctl";
    QStringList arguments;
    arguments << "stop" << "qopenhd";
    QProcess *process = new QProcess(this);
    process->start(program, arguments);
    process->waitForFinished();
    #endif
    qDebug()<<"Request stop end";
    QApplication::quit();
}


void OpenHDPi::set_boot_mount_rw() {
#if defined (__rasp_pi__)
    qDebug() << "OpenHDPi::set_boot_mount_rw()";
    QString program = "/bin/mount";
    QStringList arguments;
    arguments << "-o" << "remount,rw" << "/boot";
    if (mountProcess != nullptr) {
        delete mountProcess;
    }
    mountProcess = new QProcess(this);
    mountProcess->start(program, arguments);
    mountProcess->waitForFinished();
    #endif
}

void OpenHDPi::set_boot_mount_ro() {
#if defined (__rasp_pi__)
    qDebug() << "OpenHDPi::set_boot_mount_ro()";
    QString program = "/bin/mount";
    QStringList arguments;
    arguments << "-o" << "remount,ro" << "/boot";
    if (mountProcess != nullptr) {
        delete mountProcess;
    }
    mountProcess = new QProcess(this);
    mountProcess->start(program, arguments);
    mountProcess->waitForFinished();
    #endif
}


void OpenHDPi::set_brightness(int brightness) {
    qDebug() << "OpenHDPi::set_brightness()";
    if (brightness > 255) brightness = 255;
    if (brightness < 0) brightness = 0;
    QFile file("/sys/devices/platform/rpi_backlight/backlight/rpi_backlight/brightness");
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        return;
    }
    if (-1 == file.write(QByteArray::number(brightness))) {
        qDebug() << "Failed to set brightness";
        return;
    }
    emit brightness_changed(brightness);
}

int OpenHDPi::get_brightness() {
    qDebug() << "OpenHDPi::get_brightness()";

    QFile file("/sys/devices/platform/rpi_backlight/backlight/rpi_backlight/brightness");
     if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
         return -1;

     QTextStream in(&file);
     while (!in.atEnd()) {
         QString line = in.readLine();
         bool flag;
         int current_brightness = line.toInt(&flag);
         if (flag) {
             return current_brightness;
         }
     }

     return -2;
}


QObject *openHDPiSingletonProvider(QQmlEngine *engine, QJSEngine *scriptEngine) {
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    OpenHDPi *s = new OpenHDPi();
    return s;
}
