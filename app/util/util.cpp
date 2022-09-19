#ifndef UTIL_CPP
#define UTIL_CPP

#include <QObject>

#include "util.h"

#if defined(__android__)
#include <QtAndroidExtras/QtAndroid>
#include <QAndroidJniEnvironment>
#endif

OpenHDUtil::OpenHDUtil(QObject *parent): QObject(parent) { }

OpenHDUtil &OpenHDUtil::instance()
{
    static OpenHDUtil util{};
    return util;
}

#if defined(__android__)
void OpenHDUtil::keep_screen_on(bool on) {
    QtAndroid::runOnAndroidThread([on] {
        QAndroidJniObject activity = QtAndroid::androidActivity();
        if (activity.isValid()) {
            QAndroidJniObject window = activity.callObjectMethod("getWindow", "()Landroid/view/Window;");

            if (window.isValid()) {
                const int FLAG_KEEP_SCREEN_ON = 128;
                if (on) {
                    window.callMethod<void>("addFlags", "(I)V", FLAG_KEEP_SCREEN_ON);
                } else {
                    window.callMethod<void>("clearFlags", "(I)V", FLAG_KEEP_SCREEN_ON);
                }
            }
        }
        QAndroidJniEnvironment env;
        if (env->ExceptionCheck()) {
            env->ExceptionClear();
        }
    });
}
#endif


#endif // UTIL_CPP
