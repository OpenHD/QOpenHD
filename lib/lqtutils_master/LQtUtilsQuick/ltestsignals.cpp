#include <QDebug>

#include "lquicksettings.h"
#include "ltestsignals.h"

LTestSignals::LTestSignals(QObject *parent) : QObject(parent)
{
    connect(&LQuickSettings::notifier(), &LQuickSettings::appWidthChanged, this, [] (int width) {
        qDebug() << "C++ app width changed:" << width;
    });
}
