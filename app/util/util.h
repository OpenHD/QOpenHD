#ifndef UTIL_H
#define UTIL_H

#include <QObject>


class OpenHDUtil: public QObject {
    Q_OBJECT
private:
    explicit OpenHDUtil(QObject *parent = nullptr);
public:
    // Use singleton
    static OpenHDUtil& instance();

    #if defined(__android__)
    Q_INVOKABLE void keep_screen_on(bool on);
    #endif
};

#endif // UTIL_H
