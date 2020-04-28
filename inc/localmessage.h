#ifndef LOCALMESSAGE_H
#define LOCALMESSAGE_H

#include <QObject>
#include <QtQuick>

#include "constants.h"

class LocalMessage: public QObject {
    Q_OBJECT

public:
    explicit LocalMessage(QObject *parent = nullptr);

    static LocalMessage* instance();

    void showMessage(QString message, int level);

signals:
    void messageReceived(QString message, int level);

private:
    void init();
};


QObject *localMessageSingletonProvider(QQmlEngine *engine, QJSEngine *scriptEngine);

#endif
