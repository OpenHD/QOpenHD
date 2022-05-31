#ifndef LOGGER_H
#define LOGGER_H

#include <QObject>
#include <QtQuick>

class Logger: public QObject {
    Q_OBJECT

public:
    explicit Logger(QObject *parent = nullptr);

    static Logger* instance();

    void logData(QString data, int level);

    QFile *outFile;

signals:    

private:
    void init();
    QString filePath;


};


QObject *loggerSingletonProvider(QQmlEngine *engine, QJSEngine *scriptEngine);

#endif
