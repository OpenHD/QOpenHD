#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QPainter>

#include "openhd.h"

#include "headingladder.h"


HeadingLadder::HeadingLadder(QQuickItem *parent): QQuickPaintedItem(parent) {
    qDebug() << "HeadingLadder::HeadingLadder()";

}

void HeadingLadder::paint(QPainter* painter) {
    painter->save();

    QFont fontMain("sans-serif", 11, 1, false);

    QFont fontAwesome("Font Awesome 5 Free", 14, 1, false);


    auto openhd = OpenHD::instance();

    // ticks up/down position
    auto y = 25;

    // labels up/down position
    auto y_label = 22;

    // ladder center up/down..tweak
    auto y_position = height() / 2;

    // ladder center left/right..tweak
    auto x_position= width() / 2;

    auto home_heading = 0;
    QString compass_direction = "";
    auto draw_text = false;

    auto range = 180;
    auto ratio_heading = width() / range;
    auto heading = openhd->m_hdg;

    int x;
    int i;
    int j;
    int h;

    //is home outside of compass "range"
    auto h_drawn = true;


    for (i = (heading - range / 2); i <= heading + range / 2; i++) {
        x =  x_position + ((i - heading) * ratio_heading);

        h = i;
        if (h > 360) {
            h = h - 360;
        }

        if (h < 0) {
            h = 360 + h;
        }

        if (h == openhd->m_home_heading && m_showHorizonHome) {
            painter->setFont(fontAwesome);
            painter->drawText(x, y_label, "\uf015");
            painter->setFont(fontMain);

            h_drawn = false;
        }


        if (i % 30 == 0 && m_showHorizonHeadingLadder) {
            //big ticks
            painter->fillRect(QRectF(x, y, 3, 8), m_color);
        } else if (i % 15 == 0 && m_showHorizonHeadingLadder) {
            //little ticks
            painter->fillRect(QRectF(x, y + 3, 2, 5), m_color);
        } else {
            continue;
        }

        // leftover from "dont draw thru compass"
        j = i;
        if (j < 0)    j += 360;
        if (j >= 360) j -= 360;

        switch (j) {
            case 0: {
                draw_text = true;
                compass_direction = m_showHeadingLadderText ? tr("N") : QString(j);
                break;
            }
            case 45: {
                draw_text = true;
                compass_direction = m_showHeadingLadderText ? tr("NE") : QString(j);
                break;
            }
            case 90: {
                draw_text = true;
                compass_direction = m_showHeadingLadderText ? tr("E") : QString(j);
                break;
            }
            case 135: {
                draw_text = true;
                compass_direction = m_showHeadingLadderText ? tr("SE") : QString(j);
                break;
            }
            case 180: {
                draw_text = true;
                compass_direction = m_showHeadingLadderText ? tr("S") : QString(j);
                break;
            }
            case 225: {
                draw_text = true;
                compass_direction = m_showHeadingLadderText ? tr("SW") : QString(j);
                break;
            }
            case 270: {
                draw_text = true;
                compass_direction = m_showHeadingLadderText ? tr("W") : QString(j);
                break;
            }
            case 315: {
                draw_text = true;
                compass_direction = m_showHeadingLadderText ? tr("NW") : QString(j);
                break;
            }
        }

        if (draw_text == true && m_showHorizonHeadingLadder) {
            painter->drawText(x, y_label, compass_direction);

            draw_text = false;
        }
    }

    // home is offscreen, out of compass range
    if (h_drawn == true && m_showHorizonHome) {
        // find if home should be on left or right edge of compass
        auto left = openhd->m_hdg - openhd->m_home_heading;
        auto right = openhd->m_home_heading - openhd->m_hdg;

        if (left < 0) left += 360;
        if (right < 0) right += 360;

        painter->setFont(fontAwesome);

        if (left < right){
            painter->drawText(7, y_label, "\uf015");

        } else{
            painter->drawText(width() - 7, y_label, "\uf015");
        }
    }


    painter->restore();
}


QColor HeadingLadder::color() const {
    return m_color;
}


void HeadingLadder::setColor(QColor color) {
    m_color = color;
    emit colorChanged(m_color);
    update();
}

void HeadingLadder::setImperial(bool imperial) {
    m_imperial = imperial;
    emit imperialChanged(m_imperial);
    update();
}


void HeadingLadder::setShowHeadingLadderText(bool showHeadingLadderText) {
    m_showHeadingLadderText = showHeadingLadderText;
    emit showHeadingLadderTextChanged(m_showHeadingLadderText);
    update();
}


void HeadingLadder::setShowHorizonHome(bool showHorizonHome) {
    m_showHorizonHome = showHorizonHome;
    emit showHorizonHomeChanged(m_showHorizonHome);
    update();
}


void HeadingLadder::setShowHorizonHeadingLadder(bool showHorizonHeadingLadder) {
    m_showHorizonHeadingLadder = showHorizonHeadingLadder;
    emit showHorizonHeadingLadderChanged(m_showHorizonHeadingLadder);
    update();
}
