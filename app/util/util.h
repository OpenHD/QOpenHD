#ifndef UTIL_H
#define UTIL_H

#include <QObject>

#define M_PIf       3.14159265358979323846f


class OpenHDUtil: public QObject {
    Q_OBJECT
private:
    explicit OpenHDUtil(QObject *parent = nullptr);
public:
    // Use singleton
    static OpenHDUtil& instance();

    Q_INVOKABLE uint map(double input, double input_start, double input_end, uint16_t output_start, uint16_t output_end);

    typedef struct pt1Filter_s {
        float state;
        float RC;
        float dT;
    } pt1Filter_t;

    Q_INVOKABLE static float pt1FilterApply4(OpenHDUtil::pt1Filter_t *filter, float input, float f_cut, float dT);

    #if defined(__android__)
    Q_INVOKABLE void keep_screen_on(bool on);
    #endif
};

#endif // UTIL_H
