#ifndef RPI_CHECK_FKMS_H
#define RPI_CHECK_FKMS_H

#include <QTextStream>
#include <qfile.h>

#include <qdir.h>
#include <qstring.h>


namespace rpi::check_mmal {


//From https://github.com/moonlight-stream/moonlight-qt/blob/8a224fbae467771a127492f94fdd7127d71a5fe8/app/streaming/video/ffmpeg-renderers/mmal.cpp#L244
static bool getDtDeviceStatus(QString name, bool ifUnknown)
{
    QDir dir("/sys/firmware/devicetree/base/soc");
    QStringList matchingDir = dir.entryList(QStringList(name + "@*"), QDir::Dirs);
    if (matchingDir.length() != 1) {
        Q_ASSERT(matchingDir.isEmpty());
        return ifUnknown;
    }

    if (!dir.cd(matchingDir.first())) {
        return ifUnknown;
    }

    QFile statusFile(dir.filePath("status"));
    if (!statusFile.open(QFile::ReadOnly)) {
        // Per Device Tree docs, missing 'status' means enabled
        return true;
    }

    QByteArray statusData = statusFile.readAll();
    QString statusString(statusData);

    // Per Device Tree docs, 'okay' and 'ok' are both acceptable
    return statusString == "okay" || statusString == "ok";
}


static bool is_fkms_enabled(){
    if (getDtDeviceStatus("firmwarekms", true)) {
        return true;
    }
    return false;
}

/*static bool is_fksm_enabled(){
    QFile file("/boot/config.txt");
    if(!file.open(QIODevice::ReadOnly)) {
        return false;
    }
    bool ret=false;
    QTextStream in(&file);
    while(!in.atEnd()) {
        QString line = in.readLine();
        if(line.contains(""))
        QStringList fields = line.split(",");
        model->appendRow(fields);
    }

    file.close();
}*/


}
#endif // RPI_CHECK_FKMS_H
