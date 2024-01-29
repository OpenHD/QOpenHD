#include "horizonladder.h"

#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QPainter>
#include <math.h>

#include "debug_overdraw.hpp"

static constexpr int DEFAULT_FONT_PIXEL_SIZE=11;

HorizonLadder::HorizonLadder(QQuickItem *parent): QQuickPaintedItem(parent) {
    qDebug() << "HorizonLadder::HorizonLadder()";
    setRenderTarget(RenderTarget::FramebufferObject);

    //m_font.setPixelSize(14);
    m_font.setPointSize(14);
}

void HorizonLadder::paint(QPainter* painter) {
    painter->save();
    //const auto before_paint=std::chrono::steady_clock::now();
    if(ENABLE_DEBUG_OVERDRAW){
        setFillColor(QColor::fromRgb(0,255,0,200));
    }

    painter->setRenderHint(QPainter::Antialiasing);
    //painter->setRenderHint(QPainter::TextAntialiasing);
    // according to this: https://bugreports.qt.io/browse/QTBUG-93475, this should fix the weird artifacts on text - but it doesn't
    // make a difference in my case
    painter->setRenderHint(QPainter::SmoothPixmapTransform);

    painter->setFont(m_font);

    const bool horizonInvertPitch = m_horizonInvertPitch;
    const bool horizonInvertRoll = m_horizonInvertRoll;
    const double horizonWidth = m_horizonWidth;
    const int horizonSpacing = m_horizonSpacing;
    const bool horizonShowLadder = m_horizonShowLadder;
    const int horizonRange = m_horizonRange;
    const int horizonStep = m_horizonStep;
    const bool show_center_indicator = m_show_center_indicator;
    // we use fillRect for the ladder lines, this adjust how big the linesize is (e.g. how strong the stroke)
    const double ladder_stroke_faktor=1.0;

    auto roll_degree = m_roll;
    auto pitch_degree = m_pitch;

    if (horizonInvertRoll == true){
        roll_degree=roll_degree*-1;
    }
    if (horizonInvertPitch == true){
        pitch_degree=pitch_degree*-1;
    }
    //weird rounding issue where decimals make ladder dissappear
    roll_degree = round(roll_degree);
    pitch_degree = round(pitch_degree);
    //qDebug()<<"Roll:"<<roll_degree<<" Pitch:"<<pitch_degree;

    if(show_center_indicator){
        painter->setPen(m_color);
        // Line always drawn in the center to have some orientation where the center is
        //const auto line_w= 100*horizonWidth * 0.2;
        const auto circle_r= 100*horizonWidth * 0.05;
        //painter->drawLine(width()/2-(line_w/2),height()/2,width()/2+(line_w/2),height()/2);
        painter->drawEllipse(QPointF(width()/2,height()/2),circle_r,circle_r);
    }

    painter->translate(width()/2,height()/2);
    painter->rotate(roll_degree*-1);
    painter->translate((width()/2)*-1,(height()/2)*-1);

    const auto pos_x= width()/2;
    const auto pos_y= height()/2;
    const auto width_ladder= 100*horizonWidth;

    auto px = pos_x - width_ladder / 2;

    auto ratio = horizonSpacing; //pixels per degree
    auto vrange = horizonRange; //total vertical range in degrees
    auto step = horizonStep; //degrees per line
    if (step == 0) step = 10;  // avoid div by 0
    if (ratio == 0) ratio = 1; // avoid div by 0

    int i;
    int k;
    int y;
    int n;
    int startH;
    int stopH;
    startH = pitch_degree - vrange/2;
    stopH = pitch_degree + vrange/2;
    if (startH<-90) startH = -90;
    if (stopH>90) stopH = 90;

    painter->setPen(m_color);

    for (i = startH/step; i <= stopH/step; i++) {

        if (i>0 && i*ratio<30 && m_showHorizonHeadingLadder ) i=i+ 30/ratio;

        k = i*step;
        y = pos_y - (i - 1.0*pitch_degree/step)*ratio;
        if (horizonShowLadder == true) {
            if (i != 0) {

                //fix pitch line wrap around at extreme nose up/down
                n=k;
                if (n>90){
                    n=180-k;
                }
                if (n<-90){
                    n=-k-180;
                }

                //left numbers
                painter->setPen(m_color);
                painter->drawText(px-30, y+6, QString::number(n));

                //right numbers
                painter->drawText((px + width_ladder)+8, y+6, QString::number(n));
                painter->setPen(m_color);

                if ((i > 0)) {
                    //Upper ladders
                    // default to stroke strength of 2 (I think it is pixels)
                    const auto stroke_s=2*ladder_stroke_faktor;

                    //left upper cap
                    painter->setPen(m_color);
                    painter->fillRect(QRectF(px , y , stroke_s , width_ladder/24), m_color);
                    painter->setPen(m_glow);
                    painter->drawRect(QRectF(px , y , stroke_s , width_ladder/24));

                    //left upper line
                    painter->setPen(m_color);
                    painter->fillRect(QRectF(px , y , width_ladder/3 , stroke_s), m_color);
                    painter->setPen(m_glow);
                    painter->drawRect(QRectF(px , y , width_ladder/3 , stroke_s));

                    //right upper cap
                    painter->setPen(m_color);
                    painter->fillRect(QRectF(px+width_ladder-2 , y , stroke_s , width_ladder/24), m_color);
                    painter->setPen(m_glow);
                    painter->drawRect(QRectF(px+width_ladder-2 , y , stroke_s , width_ladder/24));

                    //right upper line
                    painter->setPen(m_color);
                    painter->fillRect(QRectF(px+width_ladder*2/3 , y , width_ladder/3 , stroke_s), m_color);
                    painter->setPen(m_glow);
                    painter->drawRect(QRectF(px+width_ladder*2/3 , y , width_ladder/3 , stroke_s));
                    painter->setPen(m_color);

                } else if (i < 0) {
                    // Lower ladders
                    // default to stroke strength of 2 (I think it is pixels)
                    const auto stroke_s=2*ladder_stroke_faktor;

                    //left to right
                    //left lower cap
                    painter->setPen(m_color);
                    painter->fillRect(QRectF(px , y-(width_ladder/24)+2 , stroke_s , width_ladder/24), m_color);
                    painter->setPen(m_glow);
                    painter->drawRect(QRectF(px , y-(width_ladder/24)+2 , stroke_s , width_ladder/24));
                    //1l
                    painter->setPen(m_color);
                    painter->fillRect(QRectF(px , y , width_ladder/12 , stroke_s), m_color);
                    painter->setPen(m_glow);
                    painter->drawRect(QRectF(px , y , width_ladder/12 , stroke_s));
                    //2l
                    painter->setPen(m_color);
                    painter->fillRect(QRectF(px+(width_ladder/12)*1.5 , y , width_ladder/12 , stroke_s), m_color);
                    painter->setPen(m_glow);
                    painter->drawRect(QRectF(px+(width_ladder/12)*1.5 , y , width_ladder/12 , stroke_s));
                    //3l
                    painter->setPen(m_color);
                    painter->fillRect(QRectF(px+(width_ladder/12)*3 , y , width_ladder/12 , stroke_s), m_color);
                    painter->setPen(m_glow);
                    painter->drawRect(QRectF(px+(width_ladder/12)*3 , y , width_ladder/12 , stroke_s));

                    //right lower cap
                    painter->setPen(m_color);
                    painter->fillRect(QRectF(px+width_ladder-2 , y-(width_ladder/24)+2 , stroke_s , width_ladder/24), m_color);
                    painter->setPen(m_glow);
                    painter->drawRect(QRectF(px+width_ladder-2 , y-(width_ladder/24)+2 , stroke_s , width_ladder/24));
                    //1r ///spacing on these might be a bit off
                    painter->setPen(m_color);
                    painter->fillRect(QRectF(px+(width_ladder/12)*8 , y , width_ladder/12 , stroke_s), m_color);
                    painter->setPen(m_glow);
                    painter->drawRect(QRectF(px+(width_ladder/12)*8 , y , width_ladder/12 , stroke_s));
                    //2r ///spacing on these might be a bit off
                    painter->setPen(m_color);
                    painter->fillRect(QRectF(px+(width_ladder/12)*9.5 , y , width_ladder/12 , stroke_s), m_color);
                    painter->setPen(m_glow);
                    painter->drawRect(QRectF(px+(width_ladder/12)*9.5 , y , width_ladder/12 , stroke_s));
                    //3r  ///spacing on these might be a bit off tried a decimal here
                    painter->setPen(m_color);
                    painter->fillRect(QRectF(px+(width_ladder*.9166) , y , width_ladder/12 , stroke_s), m_color);
                    painter->setPen(m_glow);
                    painter->drawRect(QRectF(px+(width_ladder*.9166) , y , width_ladder/12 , stroke_s));
                    painter->setPen(m_color);


                }
            } else { // i==0
                // default to stroke strength of 3 - a bit bigger than the non center lines
                const auto stroke_s=3*ladder_stroke_faktor;

                //Center line
                painter->fillRect(QRectF(pos_x-width_ladder*2.5/2, y, width_ladder*2.5, stroke_s), m_color);
                painter->setPen(m_glow);
                painter->drawRect(QRectF(pos_x-width_ladder*2.5/2, y, width_ladder*2.5, stroke_s));
            }
        }
    }


    //-------------------------------END HORIZON LADDER PAINT------------------------------------


    // ticks up/down position
    y = pos_y + (1.0*pitch_degree/step * ratio)-8;

    // labels up/down position
    auto y_label = y - 4;

    QString compass_direction = "";
    auto draw_text = false;

    auto range = 180;
    //auto ratio_heading = width() / range;
    auto ratio_heading = (width_ladder*2.5) / range;

    int x;
    int j;
    int h;

    //is home outside of compass "range"
    auto h_drawn = true;

    painter->setPen(m_color);

    for (i = (m_heading - range / 2); i <= m_heading + range / 2; i++) {
        x =  pos_x + ((i - m_heading) * ratio_heading);
        auto no_house = true;
        h = i;
        if (h > 360) {
            h = h - 360;
        }

        if (h < 0) {
            h = 360 + h;
        }

        if (h == m_homeHeading && m_showHorizonHome) {

            painter->setFont(m_fontAwesome);
            QFontMetrics fm(painter->font());
            auto tw = fm.horizontalAdvance("\uf015");
            painter->drawText(x-tw/2, y_label, "\uf015");
            painter->setFont(m_font);

            no_house = false; //avoid printing compass on house
            h_drawn = false;

            painter->setFont(m_font);
        }

        auto big_tick_width = 3;
        auto little_tick_width = 2;
        if (i % 30 == 0 && m_showHorizonHeadingLadder) {
            //big ticks
            painter->fillRect(QRectF(x-big_tick_width/2, y, big_tick_width, 8), m_color);
            painter->setPen(m_glow);
            painter->drawRect(QRectF(x-big_tick_width/2, y, big_tick_width, 8));
            painter->setPen(m_color);
        } else if (i % 15 == 0 && m_showHorizonHeadingLadder) {
            //little ticks
            painter->fillRect(QRectF(x-little_tick_width/2, y + 3, little_tick_width, 5), m_color);
            painter->setPen(m_glow);
            painter->drawRect(QRectF(x-little_tick_width/2, y + 3, little_tick_width, 5));
            painter->setPen(m_color);
        } else {
            continue;
        }

        // leftover from "dont draw thru compass"
        j = i;
        if (j < 0)    j += 360;
        if (j >= 360) j -= 360;

        if (no_house) {
           switch (j) {
            case 0: {
                draw_text = true;
                compass_direction = m_showHeadingLadderText ? tr("N") : QString::number(j);
                break;
            }
            case 45: {
                draw_text = true;
                compass_direction = m_showHeadingLadderText ? tr("NE") : QString::number(j);
                break;
            }
            case 90: {
                draw_text = true;
                compass_direction = m_showHeadingLadderText ? tr("E") : QString::number(j);
                break;
            }
            case 135: {
                draw_text = true;
                compass_direction = m_showHeadingLadderText ? tr("SE") : QString::number(j);
                break;
            }
            case 180: {
                draw_text = true;
                compass_direction = m_showHeadingLadderText ? tr("S") : QString::number(j);
                break;
            }
            case 225: {
                draw_text = true;
                compass_direction = m_showHeadingLadderText ? tr("SW") : QString::number(j);
                break;
            }
            case 270: {
                draw_text = true;
                compass_direction = m_showHeadingLadderText ? tr("W") : QString::number(j);
                break;
            }
            case 315: {
                draw_text = true;
                compass_direction = m_showHeadingLadderText ? tr("NW") : QString::number(j);
                break;
            }
            }
        }
        if (draw_text == true && m_showHorizonHeadingLadder && no_house) {
            painter->setFont(m_font);
            QFontMetrics fm(painter->font());
            auto tw = fm.horizontalAdvance(compass_direction);
            painter->drawText(x-tw/2, y_label, compass_direction);
            draw_text = false;
        }
    }

    // home is offscreen, out of compass range
    if (h_drawn == true && m_showHorizonHome) {
        // find if home should be on left or right edge of compass
        auto left = m_heading - m_homeHeading;
        auto right = m_homeHeading - m_heading;

        if (left < 0) left += 360;
        if (right < 0) right += 360;

        painter->setFont(m_fontAwesome);

        if (left < right){
            painter->drawText(pos_x-width_ladder*2.5/2+1, y_label, "\uf015");

        } else{
            painter->drawText(pos_x+width_ladder*2.5/2-22, y_label, "\uf015");
        }
        painter->setFont(m_font);
    }
    //painter->drawPoint(QPoint(width()/2,height()/2));

    painter->restore();
    //const auto paint_delta=std::chrono::steady_clock::now()-before_paint;
    //qDebug()<<"CPU time draw horizon:"<<MyTimeHelper::R(paint_delta).c_str();
}



QColor HorizonLadder::color() const {
    return m_color;
}

QColor HorizonLadder::glow() const {
    return m_glow;
}


void HorizonLadder::setColor(QColor color) {
    m_color = color;
    emit colorChanged(m_color);
    update();
}


void HorizonLadder::setGlow(QColor glow) {
    m_glow = glow;
    emit glowChanged(m_glow);
    update();
}


void HorizonLadder::setHorizonInvertPitch(bool horizonInvertPitch) {
    m_horizonInvertPitch = horizonInvertPitch;
    emit horizonInvertPitchChanged(m_horizonInvertPitch);
    update();
}


void HorizonLadder::setHorizonInvertRoll(bool horizonInvertRoll) {
    m_horizonInvertRoll = horizonInvertRoll;
    emit horizonInvertRollChanged(m_horizonInvertRoll);
    update();
}


void HorizonLadder::setHorizonWidth(double horizonWidth) {
    m_horizonWidth = horizonWidth;
    emit horizonWidthChanged(m_horizonWidth);
    update();
}


void HorizonLadder::setHorizonSpacing(int horizonSpacing) {
    m_horizonSpacing = horizonSpacing;
    emit horizonSpacingChanged(m_horizonSpacing);
    update();
}


void HorizonLadder::setHorizonShowLadder(bool horizonShowLadder) {
    m_horizonShowLadder = horizonShowLadder;
    emit horizonShowLadderChanged(m_horizonShowLadder);
    update();
}


void HorizonLadder::setHorizonRange(int horizonRange) {
    m_horizonRange = horizonRange;
    emit horizonRangeChanged(m_horizonRange);
    update();
}

void HorizonLadder::setHorizonStep(int horizonStep) {
    m_horizonStep = horizonStep;
    emit horizonStepChanged(m_horizonStep);
    update();
}

void HorizonLadder::setRoll(int roll) {
    m_roll = roll;
    emit rollChanged(m_roll);
    update();
}


void HorizonLadder::setPitch(int pitch) {
    m_pitch = pitch;
    emit pitchChanged(m_pitch);
    update();
}


void HorizonLadder::setHeading(int heading) {
    m_heading = heading;
    emit headingChanged(m_heading);
    update();
}


void HorizonLadder::setHomeHeading(int homeHeading) {
    m_homeHeading = homeHeading;
    emit homeHeadingChanged(m_homeHeading);
    update();
}


void HorizonLadder::setShowHeadingLadderText(bool showHeadingLadderText) {
    m_showHeadingLadderText = showHeadingLadderText;
    emit showHeadingLadderTextChanged(m_showHeadingLadderText);
    update();
}


void HorizonLadder::setShowHorizonHeadingLadder(bool showHorizonHeadingLadder) {
    m_showHorizonHeadingLadder = showHorizonHeadingLadder;
    emit showHorizonHeadingLadderChanged(m_showHorizonHeadingLadder);
    update();
}


void HorizonLadder::setShowHorizonHome(bool showHorizonHome) {
    m_showHorizonHome = showHorizonHome;
    emit showHorizonHomeChanged(m_showHorizonHome);
    update();
}


void HorizonLadder::setFontFamily(QString fontFamily) {
    m_fontFamily = fontFamily;
    emit fontFamilyChanged(m_fontFamily);
    m_font = QFont(m_fontFamily, DEFAULT_FONT_PIXEL_SIZE*m_custom_font_scale, QFont::Bold, false);
    update();
}

void HorizonLadder::set_custom_font_scale(double custom_font_scale)
{
    m_custom_font_scale=custom_font_scale;
    m_font.setPointSize(DEFAULT_FONT_PIXEL_SIZE*m_custom_font_scale);
    update();
}
