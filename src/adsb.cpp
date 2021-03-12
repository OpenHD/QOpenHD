#include "adsb.h"
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>

#ifndef __windows__
#include <unistd.h>
#endif

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>

#include <QSslSocket>

#include <QCoreApplication>
#include <QFile>


#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>

#include <GeographicLib/Geodesic.hpp>
#include <QtMath>

#include "util.h"
#include "constants.h"
#include <QAbstractListModel>
#include <QGeoCoordinate>
#include "markermodel.h"
#include <QTimer>
#include "openhd.h"
#include "localmessage.h"


static Adsb* _instance = nullptr;

Adsb* Adsb::instance() {
    if (_instance == nullptr) {
        _instance = new Adsb();
    }
    return _instance;
}

Adsb::Adsb(QObject *parent): QObject(parent) {
    qDebug() << "Adsb::Adsb()";
}

void Adsb::onStarted() {
    qDebug() << "------------------Adsb::onStarted()";

    #if defined(__rasp_pi__)
    groundAddress = "127.0.0.1";
    #endif

    auto markerModel = MarkerModel::instance();
    connect(this, &Adsb::addMarker, markerModel, &MarkerModel::addMarker);
    connect(this, &Adsb::doneAddingMarkers, markerModel, &MarkerModel::doneAddingMarkers);
    connect(this, &Adsb::removeAllMarkers, markerModel, &MarkerModel::removeAllMarkers);

    QNetworkAccessManager * manager = new QNetworkAccessManager(this);

    m_manager = manager;

    connect(manager, SIGNAL(finished(QNetworkReply*)), this, SLOT(processReply(QNetworkReply*))) ;

    timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &Adsb::requestData);
    // How frequently data is requested
    timer->start(timer_interval);
}

void Adsb::setGroundIP(QString address) {
    groundAddress = address;
}

void Adsb::mapBoundsChanged(QGeoCoordinate center_coord) {
    center_lat= center_coord.latitude();
    center_lon= center_coord.longitude();

    // api_request_center_lat=setLatitude(center_lat);
    //api_request_center_lon=setLongitude(center_lon);

    /*
      need to limit the map bounds to a distance and
      when map orients to drone it breaks api as it expects a box oriented north.
      So defining our own bound box for the api...
    */

    auto adsb_distance_limit = settings.value("adsb_distance_limit").toInt();

    QGeoCoordinate qgeo_upper_left;
    QGeoCoordinate qgeo_lower_right;

    qgeo_upper_left = center_coord.atDistanceAndAzimuth(adsb_distance_limit, 315, 0.0);
    qgeo_lower_right = center_coord.atDistanceAndAzimuth(adsb_distance_limit, 135, 0.0);

    upperl_lat= QString::number(qgeo_upper_left.latitude());
    upperl_lon= QString::number(qgeo_upper_left.longitude());
    lowerr_lat= QString::number(qgeo_lower_right.latitude());
    lowerr_lon= QString::number(qgeo_lower_right.longitude());

    /*
    qDebug() << "Adsb::lower right=" << lowerr_lat << " " << lowerr_lon;
    qDebug() << "Adsb::upper left=" << upperl_lat << " " << upperl_lon;
    qDebug() << "Adsb::Center=" << center_lat << " " << center_lon;
*/
}

void Adsb::set_adsb_api_coord(QGeoCoordinate adsb_api_coord){
    m_adsb_api_coord=adsb_api_coord;
    //qDebug() << "adsb_api_coord=" << m_adsb_api_coord;
    emit adsb_api_coord_changed(m_adsb_api_coord);
}

void Adsb::requestData() {

    //qDebug() << "Adsb::requestData()";
    auto show_adsb = settings.value("show_adsb", false).toBool();

    adsb_api_sdr = settings.value("adsb_api_sdr").toBool();


    if (adsb_api_sdr == true){
        //qDebug() << "timer 1";
        timer->stop();
        timer->start(1000);

        if (groundAddress.isEmpty()) {
            LocalMessage::instance()->showMessage("No ADSB Ground Address", 4);
            return;
        }

        adsb_url= "http://"+groundAddress+":8080/data/aircraft.json";
    }
    else {
        //qDebug() << "timer 10";
        timer->stop();
        timer->start(10000);
        set_adsb_api_coord(QGeoCoordinate(center_lat,center_lon));
        adsb_url= "https://opensky-network.org/api/states/all?lamin="+lowerr_lat+"&lomin="+upperl_lon+"&lamax="+upperl_lat+"&lomax="+lowerr_lon;
    }

    if(show_adsb==false){
        emit removeAllMarkers();
        return;
    }
    //qDebug() << "URL REQUEST:" << adsb_url;
    QNetworkRequest request;
    QUrl api_request= adsb_url;
    request.setUrl(api_request);
    request.setRawHeader("User-Agent", "MyOwnBrowser 1.0");
    //qDebug() << "url=" << api_request;
    QNetworkReply *reply = m_manager->get(request);
}

void Adsb::processReply(QNetworkReply *reply){

    QString callsign;
    int contact;
    double lat;
    double lon;
    int alt;
    int track;
    int velocity;
    double vertical;
    qreal distance;

    if (reply->error()) {
        qDebug() << "ADSB request error!";
        qDebug() << reply->errorString();
        LocalMessage::instance()->showMessage("ADSB Reply Error", 4);
        reply->deleteLater();
        return;
    }

    QByteArray data = reply->readAll();

    QJsonParseError errorPtr;
    QJsonDocument doc = QJsonDocument::fromJson(data, &errorPtr);

    if (doc.isNull()) {
        qDebug() << "Parse failed";
        LocalMessage::instance()->showMessage("ADSB Parse Error", 4);
    }

    if(doc.isNull()){
        qDebug()<<"Failed to create JSON doc.";
        reply->deleteLater();
        return;
    }
    if(!doc.isObject()){
        qDebug()<<"JSON is not an object.";
        reply->deleteLater();
        return;
    }

    QJsonObject jsonObject = doc.object();

    if(jsonObject.isEmpty()){
        qDebug()<<"JSON object is empty.";
        reply->deleteLater();
        return;
    }

    // --------------- PARSE FOR SDR ---------------------------------

    if (adsb_api_sdr == true){

        QJsonArray array = jsonObject["aircraft"].toArray();

        //QJsonArray array = doc.array();

        if(array.isEmpty()){
            qDebug()<<"JSON array is empty.";
        }

        //qDebug() << "MYARRAY COUNT=" << array.count();

        int current_row=0;
        int last_row=array.count();

        emit removeAllMarkers();

        if (last_row==0){
            //no markers to add..
            reply->deleteLater();
            return;
        }


        foreach (const QJsonValue & val, array){

            callsign=val.toObject().value("flight").toString();
            if (callsign.length() == 0) {
                callsign = "N/A";
            }

            //sdr defaults to imperial and something wacky for speed from dump1090

            contact=val.toObject().value("seen_pos").toInt();
            lat=val.toObject().value("lat").toDouble();
            lon=val.toObject().value("lon").toDouble();
            alt=val.toObject().value("altitude").toInt();
            alt=alt*0.3048;
            velocity=val.toObject().value("speed").toDouble();
            velocity=round(velocity*.51418);
            track=val.toObject().value("track").toDouble();
            vertical=val.toObject().value("vert_rate").toDouble();
            vertical=round(vertical*0.3048);




            //calculate distance from center of map so we can sort in marker model
            distance = calculateKmDistance(OpenHD::instance()->get_lat(), OpenHD::instance()->get_lon(), lat, lon);
            emit addMarker(current_row, last_row, Traffic(callsign,contact,lat,lon,alt,velocity,track,vertical,distance));
            current_row=current_row+1;

            if (lat!=0 || lon!=0) {
                /*dont evaluate marker if position msg is missing
                    above we are adding markers with 0 lat lon cuz we dont know the last row count at loop start
                    those "0 position" aircraft are being eliminated in mapcomponent
                    */
                evaluateTraffic(callsign, contact, lat, lon, alt, velocity, track, vertical, distance);
            }
/*
            qDebug() << "callsign=" << callsign;
            qDebug() << "last_contact=" << contact;
            qDebug() << "lat=" << lat;
            qDebug() << "lon=" << lon;
            qDebug() << "alt=" << alt;
            qDebug() << "velocity=" << velocity;
            qDebug() << "track=" << track;
            qDebug() << "vertical=" << vertical;
            qDebug() << "distance=" << distance;

            qDebug() << "----------------------------------------------------------";
*/



        }

    }
    // --------------- PARSE FOR API ---------------------------------
    else {

        QJsonValue value = jsonObject.value("states");
        QJsonArray array = value.toArray();

        //qDebug() << "MYARRAY COUNT=" << array.count();

        int current_row=0;
        int last_row=array.count();

        QString callsign;
        int contact;
        double lat;
        double lon;
        int alt;
        int track;
        int velocity;
        double vertical;
        qreal distance;

        emit removeAllMarkers();

        if (last_row==0){
            //no markers to add.. either the api is not happy (too zoomed out) or no traffic to report
            reply->deleteLater();
            return;
        }

        foreach (const QJsonValue & v, array){
            QJsonArray innerarray = v.toArray();

            callsign=innerarray[1].toString();
            if (callsign.length() == 0) {
                callsign = "N/A";
            }
            contact=innerarray[4].toInt();
            lat=innerarray[6].toDouble();
            lon=innerarray[5].toDouble();
            alt=innerarray[7].toDouble();
            velocity=innerarray[9].toDouble();
            track=innerarray[10].toDouble();
            vertical=innerarray[11].toDouble();

            //calculate distance from center of map so we can sort in marker model

            distance = calculateKmDistance(OpenHD::instance()->get_lat(), OpenHD::instance()->get_lon(), lat, lon);
            emit addMarker(current_row, last_row, Traffic(callsign,contact,lat,lon,alt,velocity,track,vertical,distance));

            evaluateTraffic(callsign, contact, lat, lon, alt, velocity, track, vertical, distance);

            current_row=current_row+1;

/*
             qDebug() << "callsign=" << innerarray[1].toString();
             qDebug() << "last_contact=" << innerarray[4].toInt();
             qDebug() << "lat=" << innerarray[6].toDouble();
             qDebug() << "lon=" << innerarray[5].toDouble();
             qDebug() << "alt=" << innerarray[7].toDouble();
             qDebug() << "velocity=" << innerarray[9].toDouble();
             qDebug() << "track=" << innerarray[10].toDouble();
             qDebug() << "vertical=" << innerarray[11].toDouble();
             qDebug() << "distance=" << distance;
             qDebug() << "----------------------------------------------------------";
*/
        }

    }
    //emit doneAddingMarkers();
    reply->deleteLater();
}

void Adsb::evaluateTraffic(QString traffic_callsign,
                           int traffic_contact,
                           double traffic_lat,
                           double traffic_lon,
                           double traffic_alt,
                           double traffic_velocity,
                           double traffic_track,
                           double traffic_vertical,
                           double traffic_distance) {

    /*
     * Centralise traffic threat detection here. Once threat is detected it should be
     * labled and then sent over to the adsb widget
     *
     *  need to calculate azimuth and bearing of any threats so that it can be shared
     *  and depicted in the adsb widget
     */
    int drone_alt = OpenHD::instance()->get_msl_alt();

    if (traffic_alt - drone_alt < 300 && traffic_distance < 2) {
        LocalMessage::instance()->showMessage("Aircraft Traffic", 3);
    } else if (traffic_alt - drone_alt < 500 && traffic_distance < 5) {
        LocalMessage::instance()->showMessage("Aircraft Traffic", 4);
    }
}

int Adsb::calculateKmDistance(double lat_1, double lon_1,
                              double lat_2, double lon_2) {

    double latDistance = qDegreesToRadians(lat_1 - lat_2);
    double lngDistance = qDegreesToRadians(lon_1 - lon_2);

    double a = qSin(latDistance / 2) * qSin(latDistance / 2)
            + qCos(qDegreesToRadians(center_lat)) * qCos(qDegreesToRadians(lat_2))
            * qSin(lngDistance / 2) * qSin(lngDistance / 2);

    double c = 2 * qAtan2(qSqrt(a), qSqrt(1 - a));
    int distance=radius_earth_km * c;
    return distance;
}
