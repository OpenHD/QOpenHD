/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "ADSBVehicleManager.h"
//#include "localmessage.h"
//#include "logger.h"
#include "../telemetry/models/fcmavlinksystem.h"
#include "qmath.h"

#include <QDebug>

static ADSBVehicleManager* _instance = nullptr;

ADSBVehicleManager* ADSBVehicleManager::instance()
{
    if ( _instance == nullptr ) {
        _instance = new ADSBVehicleManager();
    }
    return _instance;
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
//    MavlinkTelemetry* mavlinktelemetry = MavlinkTelemetry::instance();
//    connect(mavlinktelemetry, &MavlinkTelemetry::adsbVehicleUpdate, this, &ADSBVehicleManager::adsbVehicleUpdate, Qt::QueuedConnection);

    qDebug() << "ADSBVehicleManager::onStarted()";

    connect(&_adsbVehicleCleanupTimer, &QTimer::timeout, this, &ADSBVehicleManager::_cleanupStaleVehicles);
    _adsbVehicleCleanupTimer.setSingleShot(false);
    _adsbVehicleCleanupTimer.start(4500);

    _internetLink = new ADSBInternet();
    connect(_internetLink, &ADSBInternet::adsbVehicleUpdate, this, &ADSBVehicleManager::adsbVehicleUpdate, Qt::QueuedConnection);
    connect(this, &ADSBVehicleManager::mapCenterChanged, _internetLink, &ADSBInternet::mapBoundsChanged, Qt::QueuedConnection);
    connect(_internetLink, &ADSBInternet::adsbClearModelRequest, this, &ADSBVehicleManager::adsbClearModel, Qt::QueuedConnection);

    _sdrLink = new ADSBSdr();
    connect(_sdrLink, &ADSBSdr::adsbVehicleUpdate, this, &ADSBVehicleManager::adsbVehicleUpdate, Qt::QueuedConnection);
    connect(this, &ADSBVehicleManager::mapCenterChanged, _sdrLink, &ADSBSdr::mapBoundsChanged, Qt::QueuedConnection);
    connect(_sdrLink, &ADSBSdr::adsbClearModelRequest, this, &ADSBVehicleManager::adsbClearModel, Qt::QueuedConnection);
}

// called from qml when the map is moved
void ADSBVehicleManager::newMapCenter(QGeoCoordinate center_coord) {
    //qDebug() << "ADSBVehicleManager::newMapCenter";
    _api_center_coord = center_coord;
    emit mapCenterChanged(center_coord);
}

void ADSBVehicleManager::_cleanupStaleVehicles()
{
    // Remove all expired ADSB vehicles
    for (int i=_adsbVehicles.count()-1; i>=0; i--) {
        ADSBVehicle* adsbVehicle = _adsbVehicles.value<ADSBVehicle*>(i);
        if (adsbVehicle->expired()) {
            // qDebug() << "Expired" << QStringLiteral("%1").arg(adsbVehicle->icaoAddress(), 0, 16);
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
    //qDebug() << "_adsbVehicles.clearAndDeleteContents";
    _adsbVehicles.clearAndDeleteContents();
}

void ADSBVehicleManager::adsbVehicleUpdate(const ADSBVehicle::VehicleInfo_t vehicleInfo)
{
    //qDebug() << "ADSBVehicleManager::adsbVehicleUpdate";
    uint32_t icaoAddress = vehicleInfo.icaoAddress;

    //no point in continuing because no location. This is somewhat redundant with parser
    //possible situation where we start to not get location.. and gets stale then removed
    if (vehicleInfo.availableFlags & ADSBVehicle::LocationAvailable) {

        //decide if its new or needs update
        if (_adsbICAOMap.contains(icaoAddress)) {
            _adsbICAOMap[icaoAddress]->update(vehicleInfo);
        }
        else {

            ADSBVehicle* adsbVehicle = new ADSBVehicle(vehicleInfo, this);
            _adsbICAOMap[icaoAddress] = adsbVehicle;
            //qDebug() << "ADSBVehicleManager::adsbVehicleUpdate append vehicle";
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
    int drone_alt = FCMavlinkSystem::instance().altitude_msl_m();

    if (traffic_alt - drone_alt < 300 && traffic_distance < 2) {
//        LocalMessage::instance()->showMessage("Aircraft Traffic", 3);

    } else if (traffic_alt - drone_alt < 500 && traffic_distance < 5) {
//        LocalMessage::instance()->showMessage("Aircraft Traffic", 4);
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
    qDebug() << "------------------>Adsbapi::init()<------------------------";

    QNetworkAccessManager * manager = new QNetworkAccessManager(this);

    m_manager = manager;

    connect(manager, SIGNAL(finished(QNetworkReply*)), this, SLOT(processReply(QNetworkReply*))) ;

    timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &ADSBapi::requestData);

    // How frequently data is requested
    timer->start(timer_interval);
    mapBoundsChanged(QGeoCoordinate(40.48205, -3.35996));
}


void ADSBapi::mapBoundsChanged(QGeoCoordinate center_coord) {
    _api_center_coord= center_coord;

    //qDebug() << "ADSBapi::mapBoundsChanged center cord:" << _api_center_coord;

    qreal adsb_distance_limit = _settings.value("adsb_distance_limit").toInt();

    QGeoCoordinate qgeo_upper_left;
    QGeoCoordinate qgeo_lower_right;

    qgeo_upper_left = center_coord.atDistanceAndAzimuth(adsb_distance_limit, 315, 0.0);
    qgeo_lower_right = center_coord.atDistanceAndAzimuth(adsb_distance_limit, 135, 0.0);

    upperl_lat= QString::number(qgeo_upper_left.latitude());
    upperl_lon= QString::number(qgeo_upper_left.longitude());
    lowerr_lat= QString::number(qgeo_lower_right.latitude());
    lowerr_lon= QString::number(qgeo_lower_right.longitude());
}

void ADSBInternet::requestData(void) {
    // If openskynetwork is disabled by settings don't make the request and return
    if (!_adsb_api_openskynetwork || !_show_adsb_internet) {
        return;
    }
    qDebug() << "------------------>ADSBInternet::requestData<------------------------";
    _adsb_api_openskynetwork = _settings.value("adsb_api_openskynetwork").toBool();
    _show_adsb_internet = _settings.value("show_adsb").toBool();



    adsb_url= "https://opensky-network.org/api/states/all?lamin="+lowerr_lat+"&lomin="+upperl_lon+"&lamax="+upperl_lat+"&lomax="+lowerr_lon;

    QNetworkRequest request;
    QUrl api_request = adsb_url;
    request.setUrl(api_request);
    request.setRawHeader("User-Agent", "MyOwnBrowser 1.0");

    qDebug() << "url=" << api_request;
    m_manager->get(request);
}

void ADSBInternet::processReply(QNetworkReply *reply) {
    qDebug() << "------------------>ADSBInternet::processReply<------------------------";


    if (!_adsb_api_openskynetwork || !_show_adsb_internet) {
        qDebug() << "------------------>ADSBInternet::processReply EARLY RETURN <------------------------";

        return;
    }

    max_distance=(_settings.value("adsb_distance_limit").toInt())/1000;
    unknown_zero_alt=_settings.value("adsb_show_unknown_or_zero_alt").toBool();

    //qDebug() << "MAX adsb distance=" << max_distance;

    if (reply->error()) {
        qDebug() << "ADSB OpenSky request error!";
        qDebug() << reply->errorString();
//        LocalMessage::instance()->showMessage("ADSB OpenSky Reply Error", 4);
        reply->deleteLater();
        return;
    }

    QJsonParseError errorPtr;
    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data, &errorPtr);

    if (doc.isNull()) {
        qDebug() << "ADSB Opensky network response: Parse failed";
//        LocalMessage::instance()->showMessage("ADSB OpenSky Parse Error", 4);
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
        qDebug()<<"ADSB Openskynetwork response: JSON object is empty.";
//        LocalMessage::instance()->showMessage("ADSB OpenSky empty object", 4);
        reply->deleteLater();
        return;
    }

    QJsonValue value = jsonObject.value("states");
    QJsonArray array = value.toArray();

    foreach (const QJsonValue & v, array){

        ADSBVehicle::VehicleInfo_t adsbInfo;
        bool icaoOk;

        QJsonArray innerarray = v.toArray();
        QString icaoAux = innerarray[0].toString();
        adsbInfo.icaoAddress = icaoAux.toUInt(&icaoOk, 16);

        // Skip this element if icao number is not ok
        if (!icaoOk) {
            continue;
        }

        // location comes in lat lon format, but we need it as QGeoCoordinate
        if(innerarray[6].isNull() || innerarray[5].isNull()){ //skip if no lat lon
            continue;
        }
        double lat = innerarray[6].toDouble();
        double lon = innerarray[5].toDouble();
        QGeoCoordinate location(lat, lon);
        adsbInfo.location = location;
        adsbInfo.availableFlags |= ADSBVehicle::LocationAvailable;

        //evaluate distance for INTERNET adsb traffic... this is redundant with sdr
        double lat_1 = _api_center_coord.latitude();
        double lon_1 = _api_center_coord.longitude();

        double latDistance = qDegreesToRadians(lat_1 - lat);
        double lngDistance = qDegreesToRadians(lon_1 - lon);

        double a = qSin(latDistance / 2) * qSin(latDistance / 2)
                + qCos(qDegreesToRadians(lat_1)) * qCos(qDegreesToRadians(lat))
                * qSin(lngDistance / 2) * qSin(lngDistance / 2);

        double c = 2 * qAtan2(qSqrt(a), qSqrt(1 - a));
        double distance = 6371 * c;

        adsbInfo.distance = distance;
        //qDebug() << "adsb internet distance=" << distance;
        adsbInfo.availableFlags |= ADSBVehicle::DistanceAvailable;

        // If aircraft beyond max distance than skip this one
        if(distance>max_distance){
            qDebug() << "Beyond max SKIPPING";
            continue;
        }

        // rest of fields

        // callsign
        adsbInfo.callsign = innerarray[1].toString();
        if (adsbInfo.callsign.length() == 0) {
            adsbInfo.callsign = "N/A";
        }
        adsbInfo.availableFlags |= ADSBVehicle::CallsignAvailable;

        //altitude
        if(innerarray[7].isDouble()){
            adsbInfo.altitude = innerarray[7].toDouble();
            //per setting eliminate all unknown alt
            if (adsbInfo.altitude<5 && unknown_zero_alt==false){
                //skip this traffic
                continue;
            }
        }
        else {
            //per setting eliminate all unknown alt
            if (unknown_zero_alt==false){
                //skip this traffic
                continue;
            }
            else {
                adsbInfo.altitude=99999.9;
            }
        }
        adsbInfo.availableFlags |= ADSBVehicle::AltitudeAvailable;

        //velocity
        if(innerarray[9].isDouble()){
            adsbInfo.velocity = innerarray[9].toDouble() * 3.6; // m/s to km/h
        }
        else {
            adsbInfo.velocity=99999.9;
        }
        adsbInfo.availableFlags |= ADSBVehicle::VelocityAvailable;

        //heading
        if(innerarray[10].isDouble()){
            adsbInfo.heading = innerarray[10].toDouble();
        }
        else {
            adsbInfo.heading=0.0;
        }
        adsbInfo.availableFlags |= ADSBVehicle::HeadingAvailable;

        //last contact
        if(innerarray[4].isNull()){
            adsbInfo.lastContact=0;
        }
        else {
            adsbInfo.lastContact = innerarray[4].toInt();
        }
        adsbInfo.availableFlags |= ADSBVehicle::LastContactAvailable;

        //vertical velocity
        if(innerarray[11].isDouble()){
            adsbInfo.verticalVel = innerarray[11].toDouble();
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
    #if defined(__rasp_pi__)
    _groundAddress = "127.0.0.1";
    #endif

    timer_interval = 2000;
}

void ADSBSdr::requestData(void) {
//    Logger::instance()->logData("request data", 1);
    _adsb_api_sdr = _settings.value("adsb_api_sdr").toBool();
    _show_adsb_sdr = _settings.value("show_adsb").toBool();

    // If sdr is disabled by settings don't make the request and return
    if (!_adsb_api_sdr || !_show_adsb_sdr) {
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
//    Logger::instance()->logData("process reply", 1);
    if (!_adsb_api_sdr || !_show_adsb_sdr) {
        return;
    }

    max_distance=(_settings.value("adsb_distance_limit").toInt())/1000;
    unknown_zero_alt=_settings.value("adsb_show_unknown_or_zero_alt").toBool();

    //qDebug() << "MAX adsb distance=" << max_distance;

    if (reply->error()) {
        qDebug() << "ADSB SDR request error!";
        qDebug() << reply->errorString();
//        LocalMessage::instance()->showMessage("ADSB SDR Reply Error", 4);
        reply->deleteLater();
        return;
    }

    QJsonParseError errorPtr;
    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data, &errorPtr);

    if (doc.isNull()) {
        qDebug() << "ADSB SDR response: Parse failed";
//        LocalMessage::instance()->showMessage("ADSB SDR Parse Error", 4);
        reply->deleteLater();
        return;
    }

    if(!doc.isObject()){
        qDebug()<<"JSON is not an object.";
 //       LocalMessage::instance()->showMessage("ADSB SDR Json not an object", 4);
        reply->deleteLater();
        return;
    }

    QJsonObject jsonObject = doc.object();

    if(jsonObject.isEmpty()){
        qDebug()<<"ADSB Openskynetwork response: JSON object is empty.";
//        LocalMessage::instance()->showMessage("ADSB SDR Json empty", 4);
        reply->deleteLater();
        return;
    }

    QJsonArray array = jsonObject["aircraft"].toArray();

    if(array.isEmpty()){
        qDebug()<<"JSON array is empty.";
//        LocalMessage::instance()->showMessage("ADSB SDR Json array empty", 4);
        reply->deleteLater();
        return;
    }

    foreach (const QJsonValue & val, array){
//        Logger::instance()->logData("For Each Loop... /n", 1);
        ADSBVehicle::VehicleInfo_t adsbInfo;
        bool icaoOk;

        // TODO
        // According to dump1090-mutability, this value can start
        // by "~" in case it isn't a valid ICAO. How this will
        // behave then?
        QString icaoAux = val.toObject().value("hex").toString();
//        Logger::instance()->logData("icaoAux:"+icaoAux, 1);
        adsbInfo.icaoAddress = icaoAux.toUInt(&icaoOk, 16);

        // Only continue if icao number is ok
        if (icaoOk) {
//            Logger::instance()->logData("icao ok!", 1);

            // location comes in lat lon format, but we need it as QGeoCoordinate

            if(val.toObject().value("lat").isNull() || val.toObject().value("lon").isNull()){ //skip if no lat lon
                continue;
            }

            double lat = val.toObject().value("lat").toDouble();
            double lon = val.toObject().value("lon").toDouble();

            QGeoCoordinate location(lat, lon);
            adsbInfo.location = location;
            adsbInfo.availableFlags |= ADSBVehicle::LocationAvailable;

            //evaluate distance for SDR adsb traffic... this is redundant with internet
            double lat_1 = _api_center_coord.latitude();
            double lon_1 = _api_center_coord.longitude();

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
//            Logger::instance()->logData("icao REJECTED! /n", 1);
            qDebug()<<"ICAO number NOT OK!";
        }
    }
    reply->deleteLater();
}
