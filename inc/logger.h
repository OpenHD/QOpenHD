#ifndef LOGGER_H
#define LOGGER_H

#include <QObject>
#include <QtQuick>

#include "constants.h"

class Logger: public QObject {
    Q_OBJECT

public:
    explicit Logger(QObject *parent = nullptr);

    static Logger* instance();

    void logData(QString data, int level);

signals:    

private:
    void init();
    QString filePath;
    //QFile outFile;
};


QObject *loggerSingletonProvider(QQmlEngine *engine, QJSEngine *scriptEngine);

#endif
