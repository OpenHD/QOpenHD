#include "opensky.h"
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#ifndef __windows__
#include <unistd.h>
#endif

#include <QtNetwork>

#include "util.h"
#include "constants.h"

OpenSky::OpenSky(QObject *parent): QObject(parent) {
    qDebug() << "OpenSky::OpenSky()";
}

void OpenSky::onStarted() {
    qDebug() << "OpenSky::onStarted()";

}
