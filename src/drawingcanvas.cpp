#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QPainter>

#include "openhd.h"

#include "drawingcanvas.h"


DrawingCanvas::DrawingCanvas(QQuickItem *parent): QQuickPaintedItem(parent) {
    qDebug() << "DrawingCanvas::DrawingCanvas()";
    setRenderTarget(RenderTarget::FramebufferObject);
}

void DrawingCanvas::paint(QPainter* painter) {
    painter->save();


    if (m_draw_request=="adsb"){ //statis for now, but here for future build out
    auto pos_x= 100;
    auto pos_y= 100;


    //qDebug() << "hdg ratio=" << heading_ratio;

    painter->setPen(m_color);

    // Has to be awesome font for the glyph
    QFont m_fontNormal = QFont("Font Awesome 5 Free", 20 , QFont::PreferAntialias, false);

    QFont m_fontBig = QFont("Font Awesome 5 Free", 20*1.2, QFont::PreferAntialias, false);
    \

    setOpacity(1.0);


    painter->translate(pos_x,pos_y);

    painter->rotate(m_heading-90);//glyph is oriented +90

    //draw speed tail
    painter->fillRect(QRectF(0, -12, -m_speed/3, 4), "white");
    painter->setPen("grey");
    painter->drawRect(QRectF(0, -12, -m_speed/3, 4));

    //add icon glyph of airplane
    painter->setPen("grey");
    painter->setFont(m_fontBig);
    painter->drawText(0, 0, "\ue203");


    painter->setPen("black");
    painter->setFont(m_fontNormal);
    painter->drawText(1, -2, "\ue203");





    painter->restore();
    }
}



QColor DrawingCanvas::color() const {
    return m_color;
}

QColor DrawingCanvas::glow() const {
    return m_glow;
}

void DrawingCanvas::setColor(QColor color) {
    m_color = color;
    emit colorChanged(m_color);
    update();
}

void DrawingCanvas::setGlow(QColor glow) {
    m_glow = glow;
    emit glowChanged(m_glow);
    update();
}

void DrawingCanvas::setFpvInvertPitch(bool fpvInvertPitch) {
    m_fpvInvertPitch = fpvInvertPitch;
    emit fpvInvertPitchChanged(m_fpvInvertPitch);
    update();
}

void DrawingCanvas::setFpvInvertRoll(bool fpvInvertRoll) {
    m_fpvInvertRoll = fpvInvertRoll;
    emit fpvInvertRollChanged(m_fpvInvertRoll);
    update();
}

void DrawingCanvas::setHeading(int heading) {
    m_heading = heading;
    emit headingChanged(m_heading);
    update();
}

void DrawingCanvas::setAlt(int alt) {
    m_alt = alt;
    emit altChanged(m_alt);
    update();
}

void DrawingCanvas::setSpeed(int speed) {
    m_speed = speed;
    emit speedChanged(m_speed);
    update();
}

void DrawingCanvas::setVertSpd(int vert_spd) {
    m_vert_spd = vert_spd;
    emit vertSpdChanged(m_vert_spd);
    update();
}

void DrawingCanvas::setRoll(int roll) {
    m_roll = roll;
    emit rollChanged(m_roll);
    update();
}

void DrawingCanvas::setPitch(int pitch) {
    m_pitch = pitch;
    emit pitchChanged(m_pitch);
    update();
}

void DrawingCanvas::setLateral(int lateral) {
    m_lateral = lateral;
    emit lateralChanged(m_lateral);
    update();
}

void DrawingCanvas::setVertical(int vertical) {
    m_vertical = vertical;
    emit verticalChanged(m_vertical);
    update();
}

void DrawingCanvas::setHorizonSpacing(int horizonSpacing) {
    m_horizonSpacing = horizonSpacing;
    emit horizonSpacingChanged(m_horizonSpacing);
    update();
}

void DrawingCanvas::setHorizonWidth(double horizonWidth) {
    m_horizonWidth = horizonWidth;
    emit horizonWidthChanged(m_horizonWidth);
    update();
}

void DrawingCanvas::setSize(double size) {
    m_size = size;
    emit sizeChanged(m_size);
    update();
}

void DrawingCanvas::setName(QString name) {
    m_name = name;
    emit nameChanged(m_name);
    update();
}

void DrawingCanvas::setVerticalLimit(double verticalLimit) {
    m_verticalLimit = verticalLimit;
    emit verticalLimitChanged(m_verticalLimit);
    update();
}

void DrawingCanvas::setLateralLimit(double lateralLimit) {
    m_lateralLimit = lateralLimit;
    emit lateralLimitChanged(m_lateralLimit);
    update();
}

void DrawingCanvas::setFontFamily(QString fontFamily) {
    m_fontFamily = fontFamily;
    emit fontFamilyChanged(m_fontFamily);    
    update();
}
