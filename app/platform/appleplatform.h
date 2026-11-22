#ifndef APPLEPLATFORM_H
#define APPLEPLATFORM_H

#include <QObject>

class ApplePlatform: public QObject {
    Q_OBJECT

public:
    explicit ApplePlatform(QObject *parent = nullptr);
    static ApplePlatform* instance();

signals:
    void willEnterForeground();
    void didEnterBackground();

public:

    void disableScreenLock();

    void registerNotifications();
};

#endif // APPLEPLATFORM_H
