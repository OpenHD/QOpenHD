#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QPainter>

#include "openhd.h"

#include "flightpathvector.h"


FlightPathVector::FlightPathVector(QQuickItem *parent): QQuickPaintedItem(parent) {
    qDebug() << "FlightPathVector::FlightPathVector()";
    setRenderTarget(RenderTarget::FramebufferObject);
}

void FlightPathVector::paint(QPainter* painter) {
    painter->save();

    //QFont font("sans-serif", 10, QFont::Bold, false);

    painter->setFont(m_font);

    bool fpvInvertPitch = m_fpvInvertPitch;

    auto vertical_max = m_verticalLimit;
    auto vertical_min = m_verticalLimit*-1;
    auto lateral_max = m_lateralLimit;
    auto lateral_min = m_lateralLimit*-1;

    auto roll = m_roll;
    auto pitch = m_pitch;

    auto lateral = m_lateral;
    auto vertical = m_vertical*-1;

    /* not really needed
     * bool fpvInvertRoll = m_fpvInvertRoll;
    if (fpvInvertRoll == true){
        roll=roll*-1;
    }
    */
    if (fpvInvertPitch == true){
        pitch=pitch*-1;
    }

    //weird rounding issue where decimals make ladder dissappear
    roll = round(roll);
    pitch = round(pitch);
    lateral = round(lateral);
    vertical = round(vertical);

    //qDebug() << "pitch=" << pitch;
    //qDebug() << "vertical=" << vertical;
    //qDebug() << "lateral=" << lateral;

    auto pos_x= width()/2;
    auto pos_y= height()/2;

    auto pitch_ratio = height() / m_horizonSpacing;
    auto heading_ratio = (m_horizonWidth*100*2.5)/180; //180 is the heading range that is fixed ATM

    //qDebug() << "hdg ratio=" << heading_ratio;

    painter->setPen(m_color);

    //fpv size handled here rather than transform. Has to be awesome font for the glyph
    QFont m_fontAwesome = QFont("Font Awesome 5 Free", 14* m_fpvSize , QFont::Bold, false);
    setOpacity(1.0);

    if (vertical>vertical_max ){
        setOpacity(.5);
        QFont m_fontAwesome = QFont("Font Awesome 5 Free", 14* m_fpvSize , QFont::ExtraLight, false);
        vertical=vertical_max;
    }
    if(vertical<vertical_min ){
        setOpacity(.5);
        QFont m_fontAwesome = QFont("Font Awesome 5 Free", 14* m_fpvSize , QFont::ExtraLight, false);
        vertical=vertical_min;
    }
    if(lateral>lateral_max ){
        setOpacity(.5);
        QFont m_fontAwesome = QFont("Font Awesome 5 Free", 14* m_fpvSize , QFont::ExtraLight, false);
        lateral=lateral_max;
    }
    if(lateral<lateral_min ){
        setOpacity(.5);
        QFont m_fontAwesome = QFont("Font Awesome 5 Free", 14* m_fpvSize , QFont::ExtraLight, false);
        lateral=lateral_min;
    }

    painter->translate(pos_x,pos_y);
    painter->rotate(roll*-1);
    painter->translate(pos_x*-1,pos_y*-1);

    painter->translate(pos_x+(lateral*heading_ratio), pos_y+(pitch+vertical)*pitch_ratio);
    painter->rotate(roll);

    painter->setPen(m_glow);
    QFont m_fontBig = QFont("Font Awesome 5 Free", 14* m_fpvSize*1.1, QFont::Bold, false);
    QFontMetrics fm(painter->font());
    painter->setFont(m_fontBig);
    painter->drawText(0, 0, "\ufdd5");

    painter->setPen(m_color);
    painter->setFont(m_fontAwesome);

    painter->drawText(0, 0, "\ufdd5");



    painter->restore();
}



QColor FlightPathVector::color() const {
    return m_color;
}

QColor FlightPathVector::glow() const {
    return m_glow;
}

void FlightPathVector::setColor(QColor color) {
    m_color = color;
    emit colorChanged(m_color);
    update();
}

void FlightPathVector::setGlow(QColor glow) {
    m_glow = glow;
    emit glowChanged(m_glow);
    update();
}

void FlightPathVector::setFpvInvertPitch(bool fpvInvertPitch) {
    m_fpvInvertPitch = fpvInvertPitch;
    emit fpvInvertPitchChanged(m_fpvInvertPitch);
    update();
}

void FlightPathVector::setFpvInvertRoll(bool fpvInvertRoll) {
    m_fpvInvertRoll = fpvInvertRoll;
    emit fpvInvertRollChanged(m_fpvInvertRoll);
    update();
}

void FlightPathVector::setRoll(int roll) {
    m_roll = roll;
    emit rollChanged(m_roll);
    update();
}

void FlightPathVector::setPitch(int pitch) {
    m_pitch = pitch;
    emit pitchChanged(m_pitch);
    update();
}

void FlightPathVector::setLateral(int lateral) {
    m_lateral = lateral;
    emit lateralChanged(m_lateral);
    update();
}

void FlightPathVector::setVertical(int vertical) {
    m_vertical = vertical;
    emit verticalChanged(m_vertical);
    update();
}

void FlightPathVector::setHorizonSpacing(int horizonSpacing) {
    m_horizonSpacing = horizonSpacing;
    emit horizonSpacingChanged(m_horizonSpacing);
    update();
}

void FlightPathVector::setHorizonWidth(double horizonWidth) {
    m_horizonWidth = horizonWidth;
    emit horizonWidthChanged(m_horizonWidth);
    update();
}

void FlightPathVector::setFpvSize(double fpvSize) {
    m_fpvSize = fpvSize;
    emit fpvSizeChanged(m_fpvSize);
    update();
}

void FlightPathVector::setVerticalLimit(double verticalLimit) {
    m_verticalLimit = verticalLimit;
    emit verticalLimitChanged(m_verticalLimit);
    update();
}

void FlightPathVector::setLateralLimit(double lateralLimit) {
    m_lateralLimit = lateralLimit;
    emit lateralLimitChanged(m_lateralLimit);
    update();
}

void FlightPathVector::setFontFamily(QString fontFamily) {
    m_fontFamily = fontFamily;
    emit fontFamilyChanged(m_fontFamily);    
    update();
}
