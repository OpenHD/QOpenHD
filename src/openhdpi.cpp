#include "openhdpi.h"

#include <QtNetwork>
#include <QThread>
#include <QtConcurrent>
#include <QProcess>
#include <QProcessEnvironment>


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
    qDebug() << "OpenHDPi::activate_console()";
    QString program = "/bin/chvt";
    QStringList arguments;
    arguments << "12";
    QProcess *process = new QProcess(this);
    process->start(program, arguments);
    process->waitForFinished();
}

void OpenHDPi::stop_app() {
    qDebug() << "OpenHDPi::stop_app()";
    QString program = "/bin/systemctl";
    QStringList arguments;
    arguments << "stop" << "qopenhd";
    QProcess *process = new QProcess(this);
    process->start(program, arguments);
    process->waitForFinished();
}


void OpenHDPi::set_boot_mount_rw() {
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
}

void OpenHDPi::set_boot_mount_ro() {
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

void OpenHDPi::update_ground() {
    FILE *fp;
    FILE *fp2;
    FILE *fp3;

    int undervolt_gnd = 0;
    int _ground_temp = 0;

    fp2 = fopen("/sys/class/thermal/thermal_zone0/temp", "r");
    fscanf(fp2, "%d", &_ground_temp);
    fclose(fp2);
    ground_temp = _ground_temp / 1000;

    fp = fopen("/proc/stat","r");
    fscanf(fp, "%*s %Lf %Lf %Lf %Lf", &a[0], &a[1], &a[2], &a[3]);
    fclose(fp);

    ground_load = (((b[0]+b[1]+b[2]) - (a[0]+a[1]+a[2])) / ((b[0]+b[1]+b[2]+b[3]) - (a[0]+a[1]+a[2]+a[3]))) * 100;

    fp = fopen("/proc/stat","r");
    fscanf(fp, "%*s %Lf %Lf %Lf %Lf", &b[0], &b[1], &b[2], &b[3]);
    fclose(fp);

    fp3 = fopen("/tmp/undervolt", "r");
    if (fp3 == nullptr) {
        return;
    }
    fscanf(fp3,"%d", &undervolt_gnd);
    fclose(fp3);
    m_undervolt = undervolt_gnd;
    emit undervolt_changed(m_undervolt);
}

QObject *openHDPiSingletonProvider(QQmlEngine *engine, QJSEngine *scriptEngine) {
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    OpenHDPi *s = new OpenHDPi();
    return s;
}
