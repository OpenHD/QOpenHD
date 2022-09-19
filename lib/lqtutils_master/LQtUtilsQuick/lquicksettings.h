#ifndef LQUICKSETTINGS_H
#define LQUICKSETTINGS_H

#include <QObject>

#include "../lqtutils_settings.h"
#include "../lqtutils_prop.h"
#include "../lqtutils_string.h"

Q_NAMESPACE

L_DECLARE_SETTINGS(LQuickSettings, new QSettings(QSL("settings.ini"), QSettings::IniFormat))
L_DEFINE_VALUE(int, appWidth, 200, toInt)
L_DEFINE_VALUE(int, appHeight, 200, toInt)
L_DEFINE_VALUE(int, appX, 100, toInt)
L_DEFINE_VALUE(int, appY, 100, toInt)
L_END_CLASS

#endif // LQUICKSETTINGS_H
