#ifndef OPENSKY_H
#define OPENSKY_H

#include <QObject>
#include <QtQuick>

#include "constants.h"

#include "util.h"



class OpenSky: public QObject {
    Q_OBJECT

public:
    explicit OpenSky(QObject *parent = nullptr);

public slots:
    void onStarted();
};

#endif
