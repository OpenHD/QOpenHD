/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "adsbvehiclemanager.h"
//#include "localmessage.h"
//#include "logger.h"
//#include "openhd.h"
//#include "mavlinktelemetry.h" for traffic from FC
#include <QThread>
#include <QTcpSocket>
#include <QTimer>

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QtMath>

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>

#include <QDebug>


ADSBVehicleManager* ADSBVehicleManager::instance()
{
    // This is the only required c++ code for a thread safe singleton
    static ADSBVehicleManager instance{};
    return &instance;
}

ADSBVehicleManager::ADSBVehicleManager(QObject *parent) : QObject(parent)
{
}

ADSBVehicleManager::~ADSBVehicleManager()
{
    // manually stop the threads
    _internetLink->quit();
    _internetLink->wait();

    _sdrLink->quit();
    _sdrLink->wait();
}

void ADSBVehicleManager::onStarted()
{
    qDebug() << "ADSBVehicleManager::onStarted()";
    // this is for adsb recievers on the FC
    //   MavlinkTelemetry* mavlinktelemetry = MavlinkTelemetry::instance();
    //   connect(mavlinktelemetry, &MavlinkTelemetry::adsbVehicleUpdate, this, &ADSBVehicleManager::adsbVehicleUpdate, Qt::QueuedConnection);

    connect(&_adsbVehicleCleanupTimer, &QTimer::timeout, this, &ADSBVehicleManager::_cleanupStaleVehicles);
    _adsbVehicleCleanupTimer.setSingleShot(false);
    _adsbVehicleCleanupTimer.start(4500);

    _internetLink = new ADSBInternet();
    connect(_internetLink, &ADSBInternet::adsbVehicleUpdate, this, &ADSBVehicleManager::adsbVehicleUpdate, Qt::QueuedConnection);
    //there is probably a better way to get map lat,lon from map component
    //currently map componenet calls adsbvehicle method which then emits signal to slot in adsbapi with lat lon
    connect(this, &ADSBVehicleManager::mapLatChanged, _internetLink, &ADSBInternet::mapLatChanged, Qt::QueuedConnection);
    connect(this, &ADSBVehicleManager::mapLonChanged, _internetLink, &ADSBInternet::mapLonChanged, Qt::QueuedConnection);
    connect(_internetLink, &ADSBInternet::adsbClearModelRequest, this, &ADSBVehicleManager::adsbClearModel, Qt::QueuedConnection);

    _sdrLink = new ADSBSdr();
    connect(_sdrLink, &ADSBSdr::adsbVehicleUpdate, this, &ADSBVehicleManager::adsbVehicleUpdate, Qt::QueuedConnection);
    //TODO COMMENTED TO GET WORKING
    //   connect(this, &ADSBVehicleManager::mapLatChanged, _sdrLink, &ADSBSdr::mapBoundsChanged, Qt::QueuedConnection);
    //   connect(this, &ADSBVehicleManager::mapLonChanged, _sdrLink, &ADSBSdr::mapBoundsChanged, Qt::QueuedConnection);
    connect(_sdrLink, &ADSBSdr::adsbClearModelRequest, this, &ADSBVehicleManager::adsbClearModel, Qt::QueuedConnection);
}

// called from qml when the center of map component changes
void ADSBVehicleManager::newMapLat(double map_lat) {
    _api_lat = map_lat;
    emit mapLatChanged(map_lat);
}

void ADSBVehicleManager::newMapLon(double map_lon) {
    _api_lon = map_lon;
    emit mapLonChanged(map_lon);
}

void ADSBVehicleManager::_cleanupStaleVehicles()
{
    // Remove all expired ADSB vehicles
    for (int i=_adsbVehicles.count()-1; i>=0; i--) {
        ADSBVehicle* adsbVehicle = _adsbVehicles.value<ADSBVehicle*>(i);
        if (adsbVehicle->expired()) {
            qDebug() << "Expired" << QStringLiteral("%1").arg(adsbVehicle->icaoAddress(), 0, 16);
            _adsbVehicles.removeAt(i);
            _adsbICAOMap.remove(adsbVehicle->icaoAddress());
            adsbVehicle->deleteLater();
        }
    }
    // if more than 20 seconds with with no updates, set frontend indicator red
    // if more than 60 seconds with no updates deactivate frontend indicator
    if (_last_update_timer.elapsed() > 60000) {
        _status = 0;
        emit statusChanged();

    } else if (_last_update_timer.elapsed() > 20000) {
        _status = 1;
        emit statusChanged();
    }
}

//currently not used.. was for testing but could have future purpose to turn off display
void ADSBVehicleManager::adsbClearModel(){
    qDebug() << "_adsbVehicles.clearAndDeleteContents";
    _adsbVehicles.clearAndDeleteContents();
}

void ADSBVehicleManager::adsbVehicleUpdate(const ADSBVehicle::VehicleInfo_t vehicleInfo)
{
    uint32_t icaoAddress = vehicleInfo.icaoAddress;

    //no point in continuing because no location. This is somewhat redundant with parser
    //possible situation where we start to not get location.. and gets stale then removed
    if (vehicleInfo.availableFlags & ADSBVehicle::LocationAvailable) {
        //qDebug() << "ADD/Update ADSB Vehicle";
        //decide if its new or needs update
        if (_adsbICAOMap.contains(icaoAddress)) {
            _adsbICAOMap[icaoAddress]->update(vehicleInfo);
        }
        else {

            ADSBVehicle* adsbVehicle = new ADSBVehicle(vehicleInfo, this);
            _adsbICAOMap[icaoAddress] = adsbVehicle;
            _adsbVehicles.append(adsbVehicle);
        }

        // Show warnings if adsb reported traffic is too close
        _evaluateTraffic(vehicleInfo.altitude, vehicleInfo.distance);

        _last_update_timer.restart();
        _status = 2;
        emit statusChanged();
    }
}

void ADSBVehicleManager::_evaluateTraffic(double traffic_alt, int traffic_distance)
{
    /*
     * Centralise traffic threat detection here. Once threat is detected it should be
     * labled and then sent over to the adsb widget
     *
     *  need to calculate azimuth and bearing of any threats so that it can be shared
     *  and depicted in the adsb widget
     */
    //TODO refactor calls to mavlink
    int drone_alt = 0;

    if (traffic_alt - drone_alt < 300 && traffic_distance < 2) {
        //TODO REFACTOR MSG
        //LocalMessage::instance()->showMessage("Aircraft Traffic", 3);

    } else if (traffic_alt - drone_alt < 500 && traffic_distance < 5) {
        //TODO REFACTOR MSG
        //LocalMessage::instance()->showMessage("Aircraft Traffic", 4);
    }
}

ADSBapi::ADSBapi()
    : QThread()
{
    moveToThread(this);
    start();
}

ADSBapi::~ADSBapi(void)
{
    quit();
    wait();
}

void ADSBapi::run(void)
{
    init();
    exec();
}

void ADSBapi::init(void) {
    QNetworkAccessManager * manager = new QNetworkAccessManager(this);
    //qDebug()<<"isStrictTransportSecurityEnabled:"<<(manager->isStrictTransportSecurityEnabled() ? "Y" : "N");

    m_manager = manager;

    connect(manager, SIGNAL(finished(QNetworkReply*)), this, SLOT(processReply(QNetworkReply*))) ;

    timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &ADSBapi::requestData);

    // How frequently data is requested
    timer->start(timer_interval);

    //init a lat lon here jsut in case map doesnt send anything in time
    mapLatChanged(40.4820);
    mapLonChanged(-3.3599);
}

// This is the slot for the singal emitted from adsbvehicle class that map center changed
void ADSBapi::mapLatChanged(double map_lat) {
    m_api_lat=map_lat;
    lat_string=QString::number(m_api_lat);
}
void ADSBapi::mapLonChanged(double map_lon) {
    m_api_lon=map_lon;
    lon_string=QString::number(m_api_lon);
}


void ADSBInternet::requestData(void) {
    _adsb_enable = _settings.value("adsb_enable").toBool();
    _adsb_show_internet_data = _settings.value("adsb_show_internet_data").toBool();
    max_distance = _settings.value("adsb_radius").toInt();

    QString distance_string = QString::number(max_distance/1852); // convert meters to NM for api

    // If adsb or adsb_internet is disabled by settings don't make the internet request and return
    if (!_adsb_enable || !_adsb_show_internet_data) {
           return;
    }
    // TODO - http instead of https ?
    adsb_url="https://api.airplanes.live/v2/point/"+  lat_string +"/"+ lon_string + "/" + distance_string;
    QNetworkRequest request;
    QUrl api_request = adsb_url;
    request.setUrl(api_request);
    request.setRawHeader("User-Agent", "MyOwnBrowser 1.0");

    qDebug() << "url=" << api_request;
    m_manager->get(request);
}

void ADSBInternet::processReply(QNetworkReply *reply) {

    max_distance=(_settings.value("adsb_radius").toInt());
    unknown_zero_alt=_settings.value("adsb_show_unknown_or_zero_alt").toBool();

    qDebug() << "MAX adsb distance=" << max_distance;

    if (reply->error()) {
        qDebug() << "ADSB OpenSky request error!";
        qDebug() << reply->errorString();
        //TODO REFACTOR MSG
        //LocalMessage::instance()->showMessage("ADSB OpenSky Reply Error", 4);
        reply->deleteLater();
        return;
    }
    if(!reply->isFinished()){
        qDebug()<<"We should only get finished replies";
    }


    QJsonParseError errorPtr;
    QByteArray data = reply->readAll();
    //qDebug()<<"Len:"<<data.length()<<" available in reply:"<<reply->bytesAvailable();
    //qDebug()<<"URL was:"<<reply->request().url();
    QJsonDocument doc = QJsonDocument::fromJson(data, &errorPtr);

    if (doc.isNull()) {
        qDebug() << "ADSB internet network response: Parse failed";
        //TODO REFACTOR MSG
        //LocalMessage::instance()->showMessage("ADSB OpenSky Parse Error", 4);
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
        qDebug()<<"ADSB internet json response: JSON object is empty.";
        //TODO REFACTOR MSG
        //LocalMessage::instance()->showMessage("ADSB OpenSky empty object", 4);
        reply->deleteLater();
        return;
    }



    QJsonArray acArray = doc.object()["ac"].toArray();

    qDebug()<<"adsb aircraft count:" << acArray.count();

    // Iterate through the "ac" array
    for (const QJsonValue &aircraftValue : acArray) {
        QJsonObject aircraft = aircraftValue.toObject();

        ADSBVehicle::VehicleInfo_t adsbInfo;

        //Aircraft Hex
        bool icaoOk;
        QString icaoAux = aircraft["hex"].toString();
        adsbInfo.icaoAddress = icaoAux.toUInt(&icaoOk, 16);
        //qDebug() << "Hex:" << aircraft["hex"].toString();
        // Skip this element if icao number is not ok
        if (!icaoOk) {
            qDebug()<<"skipping - icao not ok";
            continue;
        }

        //Aircraft lat/lon
        if(aircraft["lat"].isNull() || aircraft["lon"].isNull()){ //skip if no lat lon
            continue;
        }
        double lat = aircraft["lat"].toDouble();
        double lon = aircraft["lon"].toDouble();
        //qDebug()<<"lat/lon" << lat << " / " << lon;
        //adsbInfo.location = location;
        adsbInfo.lat = lat;
        adsbInfo.lon = lon;
        adsbInfo.availableFlags |= ADSBVehicle::LocationAvailable;
        //qDebug()<<"avail flag:"<< adsbInfo.availableFlags;

        //evaluate distance for INTERNET adsb traffic... this is redundant with sdr
        double lat_1 = m_api_lat;
        double lon_1 = m_api_lon;

        double latDistance = qDegreesToRadians(lat_1 - lat);
        double lngDistance = qDegreesToRadians(lon_1 - lon);

        double a = qSin(latDistance / 2) * qSin(latDistance / 2)
                   + qCos(qDegreesToRadians(lat_1)) * qCos(qDegreesToRadians(lat))
                         * qSin(lngDistance / 2) * qSin(lngDistance / 2);

        double c = 2 * qAtan2(qSqrt(a), qSqrt(1 - a));
        double distance = 6371 * c;

        adsbInfo.distance = distance;
        qDebug() << "adsb internet distance=" << distance;
        adsbInfo.availableFlags |= ADSBVehicle::DistanceAvailable;

        // If aircraft beyond max distance than skip this one
        if(distance>max_distance){
            qDebug() << "Aircraft Beyond max distance... SKIPPING aircraft";
            //TODO commented for testing
            //continue;
        }

        //Aircraft callsign
        adsbInfo.callsign = aircraft["flight"].toString();
        if (adsbInfo.callsign.length() == 0) {
            adsbInfo.callsign = "N/A";
        }
        adsbInfo.availableFlags |= ADSBVehicle::CallsignAvailable;

        //Aircraft altitude
        if(aircraft["alt_baro"].toDouble()){
            adsbInfo.altitude = aircraft["alt_baro"].toDouble();
            qDebug()<<"alt:" << aircraft["alt_baro"].toDouble();
            //per setting eliminate all unknown alt
            if (adsbInfo.altitude<5 && unknown_zero_alt==false){
                qDebug() << "ADSB Skipping aircraft for alt error";
                continue;
            }
        }
        else {
            //per setting eliminate all unknown alt
            if (unknown_zero_alt==false){
                qDebug() << "ADSB Skipping aircraft for alt error";
                continue;
            }
            else {
                adsbInfo.altitude=99999.9;
            }
        }
        adsbInfo.availableFlags |= ADSBVehicle::AltitudeAvailable;

        //Aircraft velocity
        if(aircraft["gs"].toDouble()){
            adsbInfo.velocity = aircraft["gs"].toDouble() * 3.6; // m/s to km/h
        }
        else {
            adsbInfo.velocity=99999.9;
        }
        adsbInfo.availableFlags |= ADSBVehicle::VelocityAvailable;

        //Aircraft heading
        if(aircraft["track"].toDouble()){
            adsbInfo.heading = aircraft["track"].toDouble();
        }
        else {
            adsbInfo.heading=0.0;
        }
        adsbInfo.availableFlags |= ADSBVehicle::HeadingAvailable;

        //last contact
        if(aircraft["seen"].isNull()){
            adsbInfo.lastContact=0;
        }
        else {
            adsbInfo.lastContact = aircraft["seen"].toInt();
        }
        adsbInfo.availableFlags |= ADSBVehicle::LastContactAvailable;

        //vertical velocity
        if(aircraft["baro_rate"].isDouble()){
            adsbInfo.verticalVel = aircraft["baro_rate"].toDouble();
        }
        else {
            adsbInfo.verticalVel=0.0;
        }
        adsbInfo.availableFlags |= ADSBVehicle::VerticalVelAvailable;

        // this is received on adsbvehicleupdate slot
        emit adsbVehicleUpdate(adsbInfo);
    }
    reply->deleteLater();
}

ADSBSdr::ADSBSdr()
    : ADSBapi()
{
// we need to manage this properly
#if defined(__rasp_pi__)|| defined(__jetson__)
    _groundAddress = "127.0.0.1";
#endif

    timer_interval = 2000;
}

void ADSBSdr::requestData(void) {
    //TODO REFACTOR MSG
    //Logger::instance()->logData("request data", 1);
    _adsb_show_sdr_data = _settings.value("adsb_show_sdr_data").toBool();

    // If adsb or sdr adsb is disabled by settings don't make the request and return
    if (!_adsb_enable || !_adsb_show_sdr_data) {
        return;
    }

    adsb_url=  "http://"+_groundAddress+":8080/data/aircraft.json";

    QNetworkRequest request;
    QUrl api_request = adsb_url;
    request.setUrl(api_request);
    request.setRawHeader("User-Agent", "MyOwnBrowser 1.0");

    // qDebug() << "url=" << api_request;
    m_manager->get(request);
}

void ADSBSdr::processReply(QNetworkReply *reply) {
    //TODO
    //Logger::instance()->logData("process reply", 1);

    max_distance=(_settings.value("adsb_distance_limit").toInt())/1000;
    unknown_zero_alt=_settings.value("adsb_show_unknown_or_zero_alt").toBool();

    //qDebug() << "MAX adsb distance=" << max_distance;

    if (reply->error()) {
        qDebug() << "ADSB SDR request error!";
        qDebug() << reply->errorString();
        //TODO REFACTOR MSG
        //LocalMessage::instance()->showMessage("ADSB SDR Reply Error", 4);
        reply->deleteLater();
        return;
    }

    QJsonParseError errorPtr;
    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data, &errorPtr);

    if (doc.isNull()) {
        qDebug() << "ADSB SDR response: Parse failed";
        //TODO REFACTOR MSG
        //LocalMessage::instance()->showMessage("ADSB SDR Parse Error", 4);
        reply->deleteLater();
        return;
    }

    if(!doc.isObject()){
        qDebug()<<"JSON is not an object.";
        //TODO REFACTOR MSG
        //LocalMessage::instance()->showMessage("ADSB SDR Json not an object", 4);
        reply->deleteLater();
        return;
    }

    QJsonObject jsonObject = doc.object();

    if(jsonObject.isEmpty()){
        qDebug()<<"ADSB Openskynetwork response: JSON object is empty.";
        //TODO REFACTOR MSG
        //LocalMessage::instance()->showMessage("ADSB SDR Json empty", 4);
        reply->deleteLater();
        return;
    }

    QJsonArray array = jsonObject["aircraft"].toArray();

    if(array.isEmpty()){
        qDebug()<<"JSON array is empty.";
        //TODO REFACTOR MSG
        //LocalMessage::instance()->showMessage("ADSB SDR Json array empty", 4);
        reply->deleteLater();
        return;
    }

    foreach (const QJsonValue & val, array){
        //Logger::instance()->logData("For Each Loop... /n", 1);
        ADSBVehicle::VehicleInfo_t adsbInfo;
        bool icaoOk;

        // TODO
        // According to dump1090-mutability, this value can start
        // by "~" in case it isn't a valid ICAO. How this will
        // behave then?
        QString icaoAux = val.toObject().value("hex").toString();
        //Logger::instance()->logData("icaoAux:"+icaoAux, 1);
        adsbInfo.icaoAddress = icaoAux.toUInt(&icaoOk, 16);

        // Only continue if icao number is ok
        if (icaoOk) {
            //Logger::instance()->logData("icao ok!", 1);

            // location comes in lat lon format, but we need it as QGeoCoordinate

            if(val.toObject().value("lat").isNull() || val.toObject().value("lon").isNull()){ //skip if no lat lon
                continue;
            }

            double lat = val.toObject().value("lat").toDouble();
            double lon = val.toObject().value("lon").toDouble();

            //QGeoCoordinate location(lat, lon);
            //adsbInfo.location = location;
            adsbInfo.lat = lat;
            adsbInfo.lon = lon;
            adsbInfo.availableFlags |= ADSBVehicle::LocationAvailable;

            //evaluate distance for SDR adsb traffic... this is redundant with internet
            double lat_1 = m_api_lat;
            double lon_1 = m_api_lon;

            double latDistance = qDegreesToRadians(lat_1 - lat);
            double lngDistance = qDegreesToRadians(lon_1 - lon);

            double a = qSin(latDistance / 2) * qSin(latDistance / 2)
                       + qCos(qDegreesToRadians(lat_1)) * qCos(qDegreesToRadians(lat))
                             * qSin(lngDistance / 2) * qSin(lngDistance / 2);

            double c = 2 * qAtan2(qSqrt(a), qSqrt(1 - a));
            double distance = 6371 * c;

            adsbInfo.distance = distance;
            adsbInfo.availableFlags |= ADSBVehicle::DistanceAvailable;

            // If aircraft beyond max distance than skip this one
            if(distance>max_distance){
                //qDebug() << "Beyond max SKIPPING";
                continue;
            }

            // callsign
            adsbInfo.callsign = val.toObject().value("flight").toString();

            if (adsbInfo.callsign.length() == 0) {
                adsbInfo.callsign = "N/A";
            } else {
                adsbInfo.availableFlags |= ADSBVehicle::CallsignAvailable;
            }

            //altitude
            if(val.toObject().value("altitude").isNull()){
                //per setting eliminate unknown alt traffic
                if (unknown_zero_alt==false){
                    //skip this traffic
                    continue;
                } else {
                    adsbInfo.altitude=99999.9;
                }
            }
            else {
                adsbInfo.altitude = val.toObject().value("altitude").toInt() * 0.3048;//feet to meters
                //per setting eliminate all unknown alt
                if (adsbInfo.altitude<5 && unknown_zero_alt==false){
                    //skip this traffic
                    continue;
                }
            }
            adsbInfo.availableFlags |= ADSBVehicle::AltitudeAvailable;

            //velocity
            if(val.toObject().value("speed").isNull()){
                adsbInfo.velocity=99999.9;
            }
            else {
                adsbInfo.velocity = round(val.toObject().value("speed").toDouble() * 1.852); // knots to km/h
            }
            adsbInfo.availableFlags |= ADSBVehicle::VelocityAvailable;

            //heading
            if(val.toObject().value("track").isNull()){
                adsbInfo.heading=0.0;
            }
            else {
                adsbInfo.heading = val.toObject().value("track").toDouble();
            }
            adsbInfo.availableFlags |= ADSBVehicle::HeadingAvailable;

            //last contact
            if(val.toObject().value("seen_pos").isNull()){
                adsbInfo.lastContact=0;
            }
            else {
                adsbInfo.lastContact = val.toObject().value("seen_pos").toInt();
            }
            adsbInfo.availableFlags |= ADSBVehicle::LastContactAvailable;

            //vertical velocity
            if(val.toObject().value("vert_rate").isNull()){
                adsbInfo.verticalVel=0.0;
            }
            else {
                adsbInfo.verticalVel = round(val.toObject().value("vert_rate").toDouble() * 0.00508); //feet/min to m/s
            }
            adsbInfo.availableFlags |= ADSBVehicle::VerticalVelAvailable;


            // this is received on adsbvehicleupdate slot
            emit adsbVehicleUpdate(adsbInfo);
        }
        else {
            //Logger::instance()->logData("icao REJECTED! /n", 1);
            qDebug()<<"ICAO number NOT OK!";
        }
    }
    reply->deleteLater();
}
