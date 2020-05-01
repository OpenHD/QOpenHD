#include "localmessage.h"


#if defined(__rasp_pi__)
#include <stdio.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#endif

#include <QThread>
#include <QtConcurrent>
#include <QFutureWatcher>
#include <QFuture>

#include "constants.h"

#include "localmessage_t.h"

static LocalMessage* _instance = new LocalMessage();


LocalMessage::LocalMessage(QObject *parent): QObject(parent) {
    qDebug() << "LocalMessage::LocalMessage()";
    init();
}


LocalMessage* LocalMessage::instance() {
    return _instance;
}


void LocalMessage::init() {
    qDebug() << "LocalMessage::init()";
}

void LocalMessage::showMessage(QString message, int level) {
    emit messageReceived(message, level);
}

QObject *localMessageSingletonProvider(QQmlEngine *engine, QJSEngine *scriptEngine) {
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    return _instance;
}
