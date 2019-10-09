#ifndef LOCALMESSAGE_H
#define LOCALMESSAGE_H

#include <QObject>
#include <QtQuick>

#include "constants.h"

class LocalMessage: public QObject {
    Q_OBJECT

public:
    explicit LocalMessage(QObject *parent = nullptr);



signals:
    void messageReceived(QString message, int level);

private slots:
#if defined(__rasp_pi__)
    void processMessageFifo();
    void restartFifo();
#endif

private:
    void init();

#if defined(__rasp_pi__)
    QFuture<void> fifoFuture;
    QFutureWatcher<void> watcher;
#endif
};


QObject *localMessageSingletonProvider(QQmlEngine *engine, QJSEngine *scriptEngine);

#endif
