#include "localmessage.h"

#include <stdio.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <QThread>
#include <QtConcurrent>
#include <QFutureWatcher>
#include <QFuture>

#include "constants.h"

#include "localmessage_t.h"

LocalMessage::LocalMessage(QObject *parent): QObject(parent) {
    qDebug() << "LocalMessage::LocalMessage()";
    init();
}

void LocalMessage::init() {
    qDebug() << "LocalMessage::init()";
#if defined(__rasp_pi__)
    restartFifo();
#endif
}


#if defined(__rasp_pi__)
void LocalMessage::restartFifo() {
    qDebug() << "LocalMessage::restartFifo()";
    fifoFuture = QtConcurrent::run(this, &LocalMessage::processMessageFifo);
    watcher.cancel();
    disconnect(&watcher, &QFutureWatcherBase::finished, this, &LocalMessage::restartFifo);
    connect(&watcher, &QFutureWatcherBase::finished, this, &LocalMessage::restartFifo);
    watcher.setFuture(fifoFuture);
}

void LocalMessage::processMessageFifo() {
    int fifoFP = open(MESSAGE_FIFO, O_RDONLY);
    if (fifoFP == -1) {
        sleep(1);
        return;
    }
    localmessage_t message;

    read(fifoFP, &message, sizeof(message));

    const char * m = (const char*)message.message;

    emit messageReceived(QString(m), message.level);
    close(fifoFP);
}
#endif

QObject *localMessageSingletonProvider(QQmlEngine *engine, QJSEngine *scriptEngine) {
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    LocalMessage *s = new LocalMessage();
    return s;
}
