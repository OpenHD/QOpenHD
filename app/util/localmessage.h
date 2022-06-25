#ifndef LOCALMESSAGE_H
#define LOCALMESSAGE_H

#include <QObject>
#include <QtQuick>

/**
 * @brief Consti10 - This class allows the developer to easily log messages that are created during the run time
 * of QOpenHD to be logged into the QOpenHD View itself - aka you can then find them in the messages view
 */
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
