#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QPainter>
#include <cmath>

//#include "openhd.h"

#include "../adsb/drawingcanvas.h"
#include "qpainterpath.h"


DrawingCanvas::DrawingCanvas(QQuickItem *parent): QQuickPaintedItem(parent) {
    //qDebug() << "DrawingCanvas::DrawingCanvas()";
    setRenderTarget(RenderTarget::FramebufferObject);

    //set font to pixels size early
    m_font.setPixelSize(14);
    m_fontNormal.setPixelSize(35);
//TODO fix settings reference
//    QSettings settings;
}

void DrawingCanvas::paint(QPainter* painter) {
    painter->save();

   // qDebug() << "DrawingCanvas::paint";

    if (m_draw_request=="adsb"){ //statis for now, but here for future build out
        auto pos_x= 130;//the middle
        auto pos_y= 130;

        painter->setPen(m_color);
        setOpacity(1.0);

        painter->translate(pos_x,pos_y);

        painter->rotate(-90);//glyph is oriented +90


       // bool orientation_setting = settings.value("map_orientation").toBool();
        //TODO fix settings reference
        bool orientation_setting=true;
        if (orientation_setting == true){ //orienting map to drone
            m_orientation = m_heading - m_drone_heading;

            if (m_orientation < 0) m_orientation += 360;
            if (m_orientation >= 360) m_orientation -=360;
            painter->rotate(m_orientation);
        }
        else{ //orienting map to north
            m_orientation=0;
            painter->rotate(m_heading);
        }

        //draw speed tail
        painter->setOpacity(0.5);
        painter->fillRect(QRectF(0, -8, -m_speed/12, 4), "white");
        painter->setPen("grey");
        painter->drawRect(QRectF(0, -8, -m_speed/12, 4));

        //add icon glyph of airplane
        /* //for glow effect
    painter->setOpacity(1.0);
    painter->setPen("grey");
    painter->setFont(m_fontBig);
    painter->drawText(0, 0, "\ue3d0");
    */

        painter->setOpacity(1.0);
        painter->setPen("black");
        painter->setFont(m_fontNormal);

        painter->drawText(0, 0, "\uf072");

        //draw data block

        painter->translate(+50,-60); //+up -down, -left +right

        //de-rotate whatever was done above and the adjustment for the glyph
        if (m_orientation!=0){
            painter->rotate(-m_orientation+90);
        }
        else {
            painter->rotate(-m_heading+90);
        }

        painter->translate(-33,-24); //preposition the text block

        painter->setOpacity(0.5);
        QPainterPath path;
        path.addRoundedRect(QRectF(0, 0, 80, 50), 10, 10);
        QPen pen(Qt::white, 2);
        painter->setPen(pen);
        painter->fillPath(path, Qt::black);
        painter->drawPath(path);

        painter->setOpacity(1.0);
        painter->setPen("white");
        painter->setFont(m_font);

        painter->drawText(5, 15, m_name);
        painter->drawText(10, 30, m_speed_text);
        painter->drawText(10, 45, m_alt_text);

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

void DrawingCanvas::setDroneHeading(int drone_heading) {
    m_drone_heading = drone_heading;
    emit droneHeadingChanged(m_drone_heading);
    update();
}

void DrawingCanvas::setAlt(int alt) {
    m_alt = alt;

    if(alt>9999){
        m_alt_text="---";
    }
    else{
        //TODO fix settings reference
        //imperial = settings.value("enable_imperial").toBool();
        imperial=false;
        if (imperial == false){
            m_alt_text = (QString::number(round(alt)))+" M";
        }
        else{
            m_alt_text = (QString::number(round((alt) * 3.28084)))+" Ft";
        }
    }

    emit altChanged(m_alt);
    emit altTextChanged(m_alt_text);
    update();
}

void DrawingCanvas::setAltText(QString alt_text) {
    m_alt_text = alt_text;
    emit altTextChanged(m_alt_text);
    update();
}

void DrawingCanvas::setDroneAlt(int drone_alt) {
    m_drone_alt = drone_alt;
    emit droneAltChanged(m_drone_alt);
    update();
}

void DrawingCanvas::setSpeed(int speed) {
    if(speed>9999){
        m_speed=0;
        m_speed_text="---";
    }
    else{
        //TODO fix settings reference
        //imperial = settings.value("enable_imperial").toBool();
        imperial=false;
        if (imperial == false){
            m_speed =round(speed* 3.6);
            m_speed_text = (QString::number(round(speed* 3.6)))+" Kph";
        }
        else{
            m_speed = round(speed* 2.23694);
            m_speed_text = (QString::number(round((speed* 2.23694))))+" Mph";
        }
    }

    emit speedTextChanged(m_speed_text);
    emit speedChanged(m_speed);
    update();
}

void DrawingCanvas::setSpeedText(QString speed_text) {
    m_speed_text = speed_text;
    emit speedTextChanged(m_speed_text);
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
