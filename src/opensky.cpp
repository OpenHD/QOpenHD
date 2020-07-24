#include "opensky.h"
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>

#ifndef __windows__
#include <unistd.h>
#endif

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>

#include <QtWebSockets/QtWebSockets>
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
#include <openhd.h>


static OpenSky* _instance = nullptr;

OpenSky* OpenSky::instance() {
    if (_instance == nullptr) {
        _instance = new OpenSky();
    }
    return _instance;
}

OpenSky::OpenSky(QObject *parent): QObject(parent) {
    qDebug() << "OpenSky::OpenSky()";
}

void OpenSky::onStarted() {
    qDebug() << "------------------OpenSky::onStarted()";
    auto markerModel = MarkerModel::instance();
    connect(this, &OpenSky::addMarker, markerModel, &MarkerModel::addMarker);
    connect(this, &OpenSky::doneAddingMarkers, markerModel, &MarkerModel::doneAddingMarkers);
    connect(this, &OpenSky::removeAllMarkers, markerModel, &MarkerModel::removeAllMarkers);

    QNetworkAccessManager * manager = new QNetworkAccessManager(this);

    m_manager = manager;

    connect(manager, SIGNAL(finished(QNetworkReply*)), this, SLOT(processReply(QNetworkReply*))) ;

    QTimer *timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &OpenSky::requestData);
    // How frequently data is requested
    timer->start(10000);
}

void OpenSky::mapBoundsChanged(QGeoCoordinate center_coord) {
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
    qDebug() << "OpenSky::lower right=" << lowerr_lat << " " << lowerr_lon;
    qDebug() << "OpenSky::upper left=" << upperl_lat << " " << upperl_lon;
    qDebug() << "OpenSky::Center=" << center_lat << " " << center_lon;
    */
}

void OpenSky::set_adsb_api_coord(QGeoCoordinate adsb_api_coord){
    m_adsb_api_coord=adsb_api_coord;
    //qDebug() << "adsb_api_coord=" << m_adsb_api_coord;
    emit adsb_api_coord_changed(m_adsb_api_coord);
}

void OpenSky::requestData() {
    //qDebug() << "OpenSky::requestData()";
    auto show_adsb = settings.value("show_adsb", false).toBool();

    if(show_adsb==false){
        emit removeAllMarkers();
        return;
    }

    set_adsb_api_coord(QGeoCoordinate(center_lat,center_lon));

    QNetworkRequest request;
    QUrl api_request= "https://opensky-network.org/api/states/all?lamin="+lowerr_lat+"&lomin="+upperl_lon+"&lamax="+upperl_lat+"&lomax="+lowerr_lon;
    request.setUrl(api_request);
    request.setRawHeader("User-Agent", "MyOwnBrowser 1.0");
        qDebug() << "url=" << api_request;
    QNetworkReply *reply = m_manager->get(request);
}

void OpenSky::processReply(QNetworkReply *reply){
    if (reply->error()) {
        qDebug() << reply->errorString();
        return;
    }

    QString strReply = reply->readAll();
    QJsonDocument jsonDoc = QJsonDocument::fromJson(strReply.toUtf8());

    if(jsonDoc.isNull()){
        qDebug()<<"Failed to create JSON doc.";
        exit(2);
    }
    if(!jsonDoc.isObject()){
        qDebug()<<"JSON is not an object.";
        exit(3);
    }

    QJsonObject object = jsonDoc.object();

    if(object.isEmpty()){
        qDebug()<<"JSON object is empty.";
        exit(4);
    }

    QJsonValue value = object.value("states");
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

        distance= calculateKmDistance(center_lat, center_lon,lat,lon);
        emit addMarker(current_row, last_row, Traffic(callsign,contact,lat,lon,alt,velocity,track,vertical,distance));

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
    emit doneAddingMarkers();
}

int OpenSky::calculateKmDistance(double center_lat, double center_lon,
                                 double marker_lat, double marker_lon) {

    double latDistance = qDegreesToRadians(center_lat - marker_lat);
    double lngDistance = qDegreesToRadians(center_lon - marker_lon);

    double a = qSin(latDistance / 2) * qSin(latDistance / 2)
            + qCos(qDegreesToRadians(center_lat)) * qCos(qDegreesToRadians(marker_lat))
            * qSin(lngDistance / 2) * qSin(lngDistance / 2);

    double c = 2 * qAtan2(qSqrt(a), qSqrt(1 - a));
    int distance=radius_earth_km * c;
    return distance;
}
