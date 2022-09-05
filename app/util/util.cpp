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

uint OpenHDUtil::map(double input, double input_start, double input_end, uint16_t output_start, uint16_t output_end) {
    double input_range = input_end - input_start;
    int output_range = output_end - output_start;

    return (input - input_start)*output_range / input_range + output_start;
}


float OpenHDUtil::pt1FilterApply4(OpenHDUtil::pt1Filter_t *filter, float input, float f_cut, float dT)
{
    // Pre calculate and store RC
    if (!filter->RC) {
        filter->RC = 1.0f / ( 2.0f * M_PIf * f_cut );
    }

    filter->dT = dT;    // cache latest dT for possible use in pt1FilterApply
    filter->state = filter->state + dT / (filter->RC + dT) * (input - filter->state);
    return filter->state;
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
