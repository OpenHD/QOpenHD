#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QPainter>

#include "openhd.h"

#include "speedladder.h"


SpeedLadder::SpeedLadder(QQuickItem *parent): QQuickPaintedItem(parent) {
    qDebug() << "SpeedLadder::SpeedLadder()";
    setRenderTarget(RenderTarget::FramebufferObject);
}

void SpeedLadder::paint(QPainter* painter) {
    painter->save();

    painter->setFont(m_font);

    auto speed = m_imperial ? (m_useGroundspeed ? (m_speed * 0.621371) : (m_airspeed * 0.621371)) :
                              (m_useGroundspeed ? m_speed : m_airspeed);

    //weird rounding issue where decimals make ladder dissappear
    speed = round(speed);

    // ticks right/left position
    auto x = 32;

    // ladder center up/down..tweak
    auto y_position = height() / 2 + 11;

    // ladder labels right/left position
    auto x_label = 9;

    auto ratio_speed = height() / m_speedRange;

    int k;
    int y;

    painter->setPen(m_color);

    for (k = (speed - m_speedRange / 2); k <= speed + m_speedRange / 2; k++) {
        y =  y_position + ((k - speed) * ratio_speed) * -1;
        if (k % 10 == 0) {
            if (k >= 0) {
                // big ticks                
                painter->fillRect(QRectF(x, y, 12, 3), m_color);
                painter->setPen(m_glow);
                painter->drawRect(QRectF(x, y, 12, 3));
                painter->setPen(m_color);

                if (k > speed + 5 || k < speed - 5) {
                    if (QString::number(k).count()>2){ //workaround cuz qfont does not have align
                        painter->drawText(x_label-10, y + 6, QString::number(k));
                    }
                    else {
                        painter->drawText(x_label, y + 6, QString::number(k));
                    }
                }
            }
            if (k < m_speedMinimum) {
                //start position speed (squares) below "0"
                painter->fillRect(QRectF(x, y - 12, 15, 15), m_color);
                painter->setPen(m_glow);
                painter->drawRect(QRectF(x, y - 12, 15, 15));
                painter->setPen(m_color);
            }
        }
        else if ((k % 5 == 0) && (k > m_speedMinimum)) {
            //little ticks
            painter->fillRect(QRectF(x + 5, y, 7, 2), m_color);
            painter->setPen(m_glow);
            painter->drawRect(QRectF(x + 5, y, 7, 2));
            painter->setPen(m_color);
        }
    }

    painter->restore();
}


QColor SpeedLadder::color() const {
    return m_color;
}


QColor SpeedLadder::glow() const {
    return m_glow;
}


void SpeedLadder::setColor(QColor color) {
    m_color = color;
    emit colorChanged(m_color);
    update();
}


void SpeedLadder::setGlow(QColor glow) {
    m_glow = glow;
    emit glowChanged(m_glow);
    update();
}


void SpeedLadder::setUseGroundspeed(bool useGroundspeed) {
    m_useGroundspeed = useGroundspeed;
    emit useGroundspeedChanged(m_useGroundspeed);
    update();
}


void SpeedLadder::setImperial(bool imperial) {
    m_imperial = imperial;
    emit imperialChanged(m_imperial);
    update();
}


void SpeedLadder::setSpeedMinimum(int speedMinimum) {
    m_speedMinimum = speedMinimum;
    emit speedMinimumChanged(m_speedMinimum);
    update();
}


void SpeedLadder::setSpeedRange(int speedRange) {
    m_speedRange = speedRange;
    emit speedRangeChanged(m_speedRange);
    update();
}


void SpeedLadder::setSpeed(int speed) {
    m_speed = speed;
    emit speedChanged(m_speed);
    update();
}


void SpeedLadder::setAirspeed(int airspeed) {
    m_airspeed = airspeed;
    emit airspeedChanged(m_airspeed);
    update();
}

void SpeedLadder::setFontFamily(QString fontFamily) {
    m_fontFamily = fontFamily;
    emit fontFamilyChanged(m_fontFamily);
    m_font = QFont(m_fontFamily, 10, QFont::Bold, false);
    update();
}
