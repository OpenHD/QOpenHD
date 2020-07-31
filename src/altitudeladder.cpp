#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QPainter>

#include "openhd.h"

#include "altitudeladder.h"


AltitudeLadder::AltitudeLadder(QQuickItem *parent): QQuickPaintedItem(parent) {
    qDebug() << "AltitudeLadder::AltitudeLadder()";

}

void AltitudeLadder::paint(QPainter* painter) {
    painter->save();

    QFont font("sans-serif", 11, 1, false);

    painter->setFont(font);

    auto openhd = OpenHD::instance();

    auto alt_msl = openhd->m_alt_msl;
    auto alt_rel = openhd->m_alt_rel;

    auto alt = m_imperial ? (m_altitudeRelMsl ? (alt_msl*3.28) : (alt_rel*3.28)) :
                            (m_altitudeRelMsl ? alt_msl : alt_rel);


    //weird rounding issue where decimals make ladder dissappear
    alt = round(alt);

    // ticks right/left position
    auto x = 6;

    // ladder center up/down..tweak
    auto y_position = height() / 2 + 11;

    // ladder labels right/left position
    auto x_label = 25;

    auto ratio_alt = height() / m_altitudeRange;

    int k;
    int y;

    for (k = (alt - m_altitudeRange / 2); k <= alt + m_altitudeRange / 2; k++) {
        y =  y_position + ((k - alt) * ratio_alt) * -1;
        if (k % 10 == 0) {
            if (k >= 0) {
                // big ticks
                painter->fillRect(QRectF(x, y, 12, 3), m_color);

                if (k > alt + 5 || k < alt - 5) {
                    painter->drawText(x_label, y + 6, QString(k));
                }
            }

            if (k < 0) {
                //start position speed (squares) below "0"
                painter->fillRect(QRectF(x, y - 15, 15, 15), m_color);
            }
        }
        else if ((k % 5 == 0) && (k > 0)) {
            //little ticks
            painter->fillRect(QRectF(x, y, 7, 2), m_color);
        }
    }

    painter->restore();
}


QColor AltitudeLadder::color() const {
    return m_color;
}


void AltitudeLadder::setColor(QColor color) {
    m_color = color;
    emit colorChanged(m_color);
    update();
}


void AltitudeLadder::setAltitudeRelMsl(bool altitudeRelMsl) {
    m_altitudeRelMsl = altitudeRelMsl;
    emit altitudeRelMslChanged(m_altitudeRelMsl);
    update();
}


void AltitudeLadder::setImperial(bool imperial) {
    m_imperial = imperial;
    emit imperialChanged(m_imperial);
    update();
}


void AltitudeLadder::setAltitudeRange(int altitudeRange) {
    m_altitudeRange = altitudeRange;
    emit altitudeRangeChanged(m_altitudeRange);
    update();
}

