#include "aoagauge.h"

#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QPainter>
#include <math.h>

#include "debug_overdraw.hpp"

AoaGauge::AoaGauge(QQuickItem *parent): QQuickPaintedItem(parent) {
    qDebug() << "AoaGauge::AoaGauge()";
    setRenderTarget(RenderTarget::FramebufferObject);
}

void AoaGauge::paint(QPainter* painter) {
    painter->save();
    if(ENABLE_DEBUG_OVERDRAW){
        setFillColor(QColor::fromRgb(0,255,0,128));
    }

    painter->setFont(m_font);

    auto aoa = m_aoa;

    //weird rounding issue where decimals make ladder dissappear
    aoa = round(aoa);

    // ticks right/left position
    auto x = 24;

    // ladder center up/down..tweak
    auto y_position = height() -7;

    // ladder labels right/left position
    auto x_label = 0;

   // auto ratio_aoa = height() / (m_aoaRange+10);
    auto ratio_aoa = height() / (m_aoaRange+10);

    int k;
    int y;

    painter->setPen(m_color);

    for (k = (-10); k <= (m_aoaRange+10); k++) {
        y =  y_position + (k * ratio_aoa)*-1;

    //draw pointer
        if (k-10==aoa){

            /*set pointer color
            if (aoa<m_aoaCaution){
                painter->setPen(m_color_text);
            }
            else if (aoa=>m_aoaWarn){
                painter->setPen(m_color_warn);
            }
            else {
                painter->setPen(m_color_caution);
            }
*/
            //draw shape
            QFont font("sans-serif", 15, QFont::Bold, false);

            painter->setFont(font);

            //numbers
            painter->drawText(x+10, y+7, "<");

            //reset things
            painter->setPen(m_color);
            painter->setFont(m_font);
        }

        if (k % 5 == 0 && k <= m_aoaRange) {

                // big ticks                
                painter->fillRect(QRectF(x, y, 12, 3), m_color);
                painter->setPen(m_glow);
                painter->drawRect(QRectF(x, y, 12, 3));
                painter->setPen(m_color);

                //numbers
                painter->drawText(x_label, y + 6, QString::number(k-10));

        }
    }

    painter->restore();
}


QColor AoaGauge::color() const {
    return m_color;
}


QColor AoaGauge::glow() const {
    return m_glow;
}


void AoaGauge::setColor(QColor color) {
    m_color = color;
    emit colorChanged(m_color);
    update();
}


void AoaGauge::setGlow(QColor glow) {
    m_glow = glow;
    emit glowChanged(m_glow);
    update();
}



void AoaGauge::setAoaRange(int aoaRange) {
    m_aoaRange = aoaRange;
    emit aoaRangeChanged(m_aoaRange);
    update();
}


void AoaGauge::setAoa(int aoa) {
    m_aoa = aoa;
    emit aoaChanged(m_aoa);
    update();
}


void AoaGauge::setFontFamily(QString fontFamily) {
    m_fontFamily = fontFamily;
    emit fontFamilyChanged(m_fontFamily);
    m_font = QFont(m_fontFamily, 10, QFont::Bold, false);
    update();
}
