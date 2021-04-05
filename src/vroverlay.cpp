#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QPainter>

#include "openhd.h"
#include "localmessage.h"

#include "vroverlay.h"

#include <GeographicLib/Geodesic.hpp>




VROverlay::VROverlay(QQuickItem *parent): QQuickPaintedItem(parent) {
    qDebug() << "VROverlay::VROverlay()";
    setRenderTarget(RenderTarget::FramebufferObject);
}

void VROverlay::paint(QPainter* painter) {
    painter->save();

    //QFont font("sans-serif", 10, QFont::Bold, false);
    //painter->setFont(m_font);

    /* not really needed
     * bool vroverlayInvertRoll = m_vroverlayInvertRoll;
    bool vroverlayInvertPitch = m_vroverlayInvertPitch;
    if (vroverlayInvertPitch == true){
        pitch=pitch*-1;
    }
    if (vroverlayInvertRoll == true){
        roll=roll*-1;
    }
    */


    auto x=findX(m_lat, m_lon, m_horizontalFOV);

    auto distance= calculateMeterDistance(m_lat, m_lon);

    auto y=findY(distance, m_alt, m_verticalFOV);

    /*
    qDebug() << "ID IN C=" << m_id;
    qDebug() << "distance=" << distance;
    qDebug() << "alt=" << m_alt;
    qDebug() << "x=" << x;
    qDebug() << "y=" << y;
    */
    auto roll = m_roll;
    auto pitch = m_pitch;
    //weird rounding issue where decimals make ladder dissappear
    roll = round(roll);
    pitch = round(pitch);

    auto pitch_ratio=height()/m_verticalFOV;

    int distance_int;
    distance_int=distance=(round(distance * 100) / 100);
    double distance_ratio;

    auto pos_x= width()/2;
    auto pos_y= height()/2;


    painter->translate(pos_x,pos_y);
    painter->rotate(roll*-1);
    painter->translate(pos_x*-1,pos_y*-1);

    painter->translate(pos_x+(x), pos_y+((pitch_ratio*pitch)+y));
    painter->rotate(roll);

    //----------------HERE IF ADSB VR TRAFFIC && TYPE==ADSB ----------------
    if(m_type=="adsb"){

        //adjust perspective of object size vs distance
        distance_ratio=(5000-distance)/500;

        if (distance_ratio<1){
            distance_ratio=1;
        }
        else if(distance_ratio>40){
            distance_ratio=40;
        }

        //painter->fillRect(QRectF(x, y - 15, 15, 15), m_color);
        painter->setPen(m_color);
        painter->drawRect(QRectF(-5*distance_ratio, -5*distance_ratio,
                                 10*distance_ratio, 10*distance_ratio));

        painter->setPen(m_color);
        QFont m_fontBig = QFont("Font Awesome 5 Free", 12* m_vroverlaySize*1.1, QFont::Bold, false);
        painter->setFont(m_fontBig);
        painter->drawText(-4*distance_ratio, -5*distance_ratio, m_name);

        QFont m_fontSmall = QFont("Font Awesome 5 Free", 9* m_vroverlaySize*1.1, QFont::Bold, false);
        painter->setPen(m_color);
        painter->setFont(m_fontSmall);
        painter->drawText(5*distance_ratio, (-4*distance_ratio)+14, "  Dis: "+QString::number(distance_int));
        painter->drawText(5*distance_ratio, (-4*distance_ratio)+25, "  Alt: "+QString::number(m_alt));
        painter->drawText(5*distance_ratio, (-4*distance_ratio)+36, "  Spd: "+QString::number(m_speed));
        painter->drawText(5*distance_ratio, (-4*distance_ratio)+47, "  Ver: "+QString::number(m_vert));
    }
    //----------------HERE IF VR HOME && TYPE==HOME ----------------
    if(m_type=="home"){
        painter->setPen(m_color);
        QFont m_fontHome = QFont("Font Awesome 5 Free", 14* m_vroverlaySize*1.1, QFont::Bold, false);
        painter->setFont(m_fontHome);

        painter->drawText(-7, 0, "\uf015");
    }
    //----------------HERE IF VR RACE && TYPE==RACE ----------------
    if(m_type=="race"){

        //have to convert qstring "names" to numbers
        if (m_name=="START"){
            m_gate_int=1;
        }
        else if (m_name=="FINISH"){
            m_gate_int=99;
        }
        else{
            //convert intermediate gates
        }

//qDebug() << "current_gate=" << m_current_gate;
//qDebug() << "gate int=" << m_gate_int;
        //get current gate
        if (m_gate_int==m_current_gate){
            //check if we passed gate
            if (m_alt_diff<10 && distance<10){
                if(m_gate_int==1){
                    //start race
                    qDebug() << "-----------START RACE-----------";
                    LocalMessage::instance()->showMessage("RACE STARTED!", 3);
                }
                else if(m_gate_int==99){
                    //end race
                    LocalMessage::instance()->showMessage("RACE ENDED!", 3);
                }
                else {
                    //intermediate gates
                }

                //increment to next gate
                if (m_current_gate<99){
                    m_current_gate=99;
                  OpenHD::instance()->set_hdg(100);
 //need to fix just for testing 2 gates
 //need to add a total gate var so it knows when finish is last
                } else {
                    m_current_gate=1;
                }
            }
        }


        //adjust perspective of object size vs distance
        distance_ratio= 1000/(sqrt((distance)*(distance)+(10)*(10)));

        //qDebug() << "ratio=" << distance_ratio;

        painter->setPen(m_color);

        painter->drawEllipse(QPointF(-5*distance_ratio,-5*distance_ratio), 10*distance_ratio, 10*distance_ratio);        
        QFont thisFont= QFont("Times", 3*distance_ratio,  QFont::Bold, false);
        painter->setFont(thisFont);
        painter->drawText(5*distance_ratio, -4*distance_ratio, m_name);

        QFont m_fontSmall = QFont("Font Awesome 5 Free", 2*distance_ratio, QFont::Bold, false);
        painter->setFont(m_fontSmall);
        painter->drawText(5*distance_ratio, (-4*distance_ratio)+3*distance_ratio, "  Dis: "+QString::number(distance_int));
        painter->drawText(5*distance_ratio, (-4*distance_ratio)+6*distance_ratio, "  Alt: "+QString::number(m_alt));
    }

    painter->restore();
}



QColor VROverlay::color() const {
    return m_color;
}

QColor VROverlay::glow() const {
    return m_glow;
}

void VROverlay::setColor(QColor color) {
    m_color = color;
    emit colorChanged(m_color);
    update();
}

void VROverlay::setGlow(QColor glow) {
    m_glow = glow;
    emit glowChanged(m_glow);
    update();
}

void VROverlay::setVROverlayInvertPitch(bool vroverlayInvertPitch) {
    m_vroverlayInvertPitch = vroverlayInvertPitch;
    emit vroverlayInvertPitchChanged(m_vroverlayInvertPitch);
    update();
}

void VROverlay::setVROverlayInvertRoll(bool vroverlayInvertRoll) {
    m_vroverlayInvertRoll = vroverlayInvertRoll;
    emit vroverlayInvertRollChanged(m_vroverlayInvertRoll);
    update();
}

void VROverlay::setRoll(int roll) {
    m_roll = roll;
    emit rollChanged(m_roll);
    update();
}

void VROverlay::setPitch(int pitch) {
    m_pitch = pitch;
    emit pitchChanged(m_pitch);
    update();
}

void VROverlay::setType(QString type) {
    m_type = type;
    emit typeChanged(m_type);
    update();
}

void VROverlay::setName(QString name) {
    m_name = name;
    emit nameChanged(m_name);
    update();
}

void VROverlay::setLat(double lat) {
    m_lat = lat;
    emit latChanged(m_lat);
    update();
}

void VROverlay::setLon(double lon) {
    m_lon = lon;
    emit lonChanged(m_lon);
    update();
}

void VROverlay::setAlt(int alt) {
    m_alt = alt;
    emit altChanged(m_alt);
    update();
}

void VROverlay::setSpeed(int speed) {
    m_speed = speed;
    emit speedChanged(m_speed);
    update();
}

void VROverlay::setVert(double vert) {
    m_vert = vert;
    emit vertChanged(m_vert);
    update();
}

void VROverlay::setVROverlaySize(double vroverlaySize) {
    m_vroverlaySize = vroverlaySize;
    emit vroverlaySizeChanged(m_vroverlaySize);
    update();
}

void VROverlay::setVerticalFOV(double verticalFOV) {
    m_verticalFOV = verticalFOV;
    emit verticalFOVChanged(m_verticalFOV);
    update();
}

void VROverlay::setHorizontalFOV(double horizontalFOV) {
    m_horizontalFOV = horizontalFOV;
    emit horizontalFOVChanged(m_horizontalFOV);
    update();
}

void VROverlay::setFontFamily(QString fontFamily) {
    m_fontFamily = fontFamily;
    emit fontFamilyChanged(m_fontFamily);
    update();
}

double VROverlay::calculateMeterDistance(double lat_2, double lon_2){
    double lat_1 = OpenHD::instance()->get_lat();
    double lon_1 = OpenHD::instance()->get_lon();

    double latDistance = qDegreesToRadians(lat_1 - lat_2);
    double lngDistance = qDegreesToRadians(lon_1 - lon_2);

    double a = qSin(latDistance / 2) * qSin(latDistance / 2)
            + qCos(qDegreesToRadians(lat_1)) * qCos(qDegreesToRadians(lat_2))
            * qSin(lngDistance / 2) * qSin(lngDistance / 2);

    double c = 2 * qAtan2(qSqrt(a), qSqrt(1 - a));
    double distance = 6371 * c; //radius of earth here

    distance= distance*1000; //convert km to m

    return distance;
}

double VROverlay::deg2rad(double deg){
    return deg * (M_PI/180);
}

int VROverlay::findX( double lat , double lon , int horizontalFOV ){

    //  console.log("id=", id)

    float dx = lon-OpenHD::instance()->get_lon();
    float dy = lat-OpenHD::instance()->get_lat();
    float angle = (M_PI/2) - atan(dy/dx);  //Math.atan
    if (dx < 0) angle += M_PI;
    float azimuth = angle*180/M_PI;
    //qDebug() << "azimuth=" << azimuth;


    int bearing=OpenHD::instance()->get_hdg()-azimuth+360;

    if (bearing>180){
        bearing=bearing-360;
    }

    bearing=bearing*-1;

    //qDebug() << "bearing=" << bearing;

    if (bearing>(horizontalFOV/2)){
        if (m_type=="home"){
            bearing=(width()/2)-50;
        }
        bearing= width(); //send offscreen
        //qDebug() << "too right";
    }
    else if (bearing<((horizontalFOV/2)*-1)){
        if (m_type=="home"){
            bearing=((width()/2)*-1)+50;
        }
        bearing= width()*-1; //send offscreen
        //qDebug() << "too left";
    }
    else{
        bearing = (width()/horizontalFOV)*bearing;
        //console.log("window=",windowWidth);
        //console.log("bearing calculated for screen=",bearing);
    }

    return bearing;

}



int VROverlay::findY (double distance , double altAdsb, int verticalFOV){
    //double distance=round(calculatedDistance);

    if(altAdsb<0){ //correct erronious adsb reported negative numbers
        altAdsb=0;
    }
    //qDebug() << "rounded distance=" << distance;
    double alt= altAdsb-OpenHD::instance()->get_msl_alt();
    m_alt_diff=alt;
    if (m_alt_diff<0){
        m_alt_diff=m_alt_diff*-1;
    }

    float angle=(atan(alt/distance));
    angle= (angle * (180/M_PI))*-1;

    //angle=round(angle * 100) / 100;

    //qDebug() << "raw angle=" << angle;


    if (angle>(verticalFOV/2)){
        if (m_type=="home"){
            angle=((height()/2))-25;
        }
        //qDebug() << "too low";
    }
    else if (angle<((verticalFOV/2)*-1)){
        if (m_type=="home"){
            angle=((height()/2)*-1)+25;
        }
        //qDebug() << "too high";
    }
    else{
        angle = (height()/verticalFOV)*angle;
        //qDebug() << "angle=" << angle;
    }


    int roundedAngle=(round(angle * 100) / 100);


    /*
    if (altDif>0){
        roundedAngle=roundedAngle*-1;
    }
*/
    return roundedAngle;
}
