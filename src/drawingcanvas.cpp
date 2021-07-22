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

    //QFont font("sans-serif", 10, QFont::Bold, false);


    auto pos_x= width()/2;
    auto pos_y= height()/2;


    //qDebug() << "hdg ratio=" << heading_ratio;

    painter->setPen(m_color);

    // Has to be awesome font for the glyph
    QFont m_fontNormal = QFont("Font Awesome 5 Free", 20 , QFont::PreferAntialias, false);

    QFont m_fontBig = QFont("Font Awesome 5 Free", 20*1.2, QFont::PreferAntialias, false);
    \

    setOpacity(1.0);


    painter->translate(pos_x,pos_y);

    //painter->rotate(roll);

    painter->setPen("black");
    painter->setFont(m_fontBig);
    painter->drawText(0, 0, "\ue203");


    painter->setPen("white");
    painter->setFont(m_fontNormal);
    painter->drawText(1, -2, "\ue203");



    painter->restore();
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

void DrawingCanvas::setFpvSize(double fpvSize) {
    m_fpvSize = fpvSize;
    emit fpvSizeChanged(m_fpvSize);
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
