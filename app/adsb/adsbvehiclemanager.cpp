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
    if (_internetLink) {
        _internetLink->quit();
        _internetLink->wait();
    }

    if (_sdrLink) {
        _sdrLink->quit();
        _sdrLink->wait();
    }
}

void ADSBVehicleManager::onStarted()
{
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
    connect(_sdrLink, &ADSBSdr::sourceStatusChanged, this, &ADSBVehicleManager::setSourceStatus, Qt::QueuedConnection);
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
    _adsbVehicles.clearAndDeleteContents();
}

void ADSBVehicleManager::adsbVehicleUpdate(const ADSBVehicle::VehicleInfo_t vehicleInfo)
{
    uint32_t icaoAddress = vehicleInfo.icaoAddress;

    // Keep position-less reports as well: dump1090 can receive identity and RSSI
    // before it has decoded a position, and the traffic widget can still rank them.
    if (icaoAddress != 0) {
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
        if ((vehicleInfo.availableFlags & ADSBVehicle::AltitudeAvailable) &&
            (vehicleInfo.availableFlags & ADSBVehicle::DistanceAvailable)) {
            _evaluateTraffic(vehicleInfo.altitude, vehicleInfo.distance);
        }

        _last_update_timer.restart();
        _status = 2;
        emit statusChanged();
    }
}

void ADSBVehicleManager::setSourceStatus(uint status)
{
    if (_status == status) {
        return;
    }
    _status = status;
    emit statusChanged();
}

void ADSBVehicleManager::processMavlinkVehicle(const mavlink_adsb_vehicle_t& vehicle)
{
    constexpr uint16_t kOpenHdRssiFlag = 1U << 15;
    ADSBVehicle::VehicleInfo_t info{};
    info.icaoAddress = vehicle.ICAO_address;

    if (vehicle.flags & ADSB_FLAGS_VALID_CALLSIGN) {
        info.callsign = QString::fromLatin1(vehicle.callsign, sizeof(vehicle.callsign)).trimmed();
        info.availableFlags |= ADSBVehicle::CallsignAvailable;
    }
    if (vehicle.flags & ADSB_FLAGS_VALID_COORDS) {
        info.lat = vehicle.lat / 1e7;
        info.lon = vehicle.lon / 1e7;
        info.availableFlags |= ADSBVehicle::LocationAvailable;

        const double latDistance = qDegreesToRadians(_api_lat - info.lat);
        const double lonDistance = qDegreesToRadians(_api_lon - info.lon);
        const double a = qSin(latDistance / 2) * qSin(latDistance / 2)
                + qCos(qDegreesToRadians(_api_lat)) * qCos(qDegreesToRadians(info.lat))
                * qSin(lonDistance / 2) * qSin(lonDistance / 2);
        info.distance = 6371.0 * 2.0 * qAtan2(qSqrt(a), qSqrt(1.0 - a));
        info.availableFlags |= ADSBVehicle::DistanceAvailable;
    }
    if (vehicle.flags & ADSB_FLAGS_VALID_ALTITUDE) {
        info.altitude = vehicle.altitude / 1000.0;
        info.availableFlags |= ADSBVehicle::AltitudeAvailable;
    }
    if (vehicle.flags & ADSB_FLAGS_VALID_HEADING) {
        info.heading = vehicle.heading / 100.0;
        info.availableFlags |= ADSBVehicle::HeadingAvailable;
    }
    if (vehicle.flags & ADSB_FLAGS_VALID_VELOCITY) {
        info.velocity = vehicle.hor_velocity * 0.036;
        info.verticalVel = vehicle.ver_velocity / 100.0;
        info.availableFlags |= ADSBVehicle::VelocityAvailable | ADSBVehicle::VerticalVelAvailable;
    }
    info.lastContact = vehicle.tslc;
    info.availableFlags |= ADSBVehicle::LastContactAvailable;
    if (vehicle.flags & kOpenHdRssiFlag) {
        info.rssi = vehicle.squawk / 100.0 - 100.0;
        info.availableFlags |= ADSBVehicle::RssiAvailable;
    }

    adsbVehicleUpdate(info);
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

ADSBapi::ADSBapi(int requestIntervalMs)
    : QThread()
    , timer_interval(requestIntervalMs)
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
    QObject::connect(m_manager, SIGNAL(sslErrors(QNetworkReply*,QList<QSslError>)), this, SLOT(dirty_onSslError(QNetworkReply*, QList<QSslError>)));

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

    m_manager->get(request);
}

void ADSBInternet::processReply(QNetworkReply *reply) {

    max_distance=(_settings.value("adsb_radius").toInt());
    unknown_zero_alt=_settings.value("adsb_show_unknown_or_zero_alt").toBool();


    if (reply->error()) {
        //TODO REFACTOR MSG
        //LocalMessage::instance()->showMessage("ADSB OpenSky Reply Error", 4);
        reply->deleteLater();
        return;
    }
    if(!reply->isFinished()){
    }


    QJsonParseError errorPtr;
    QByteArray data = reply->readAll();
    //qDebug()<<"Len:"<<data.length()<<" available in reply:"<<reply->bytesAvailable();
    //qDebug()<<"URL was:"<<reply->request().url();
    QJsonDocument doc = QJsonDocument::fromJson(data, &errorPtr);

    if (doc.isNull()) {
        //TODO REFACTOR MSG
        //LocalMessage::instance()->showMessage("ADSB OpenSky Parse Error", 4);
        reply->deleteLater();
        return;
    }

    if(!doc.isObject()){
        reply->deleteLater();
        return;
    }

    QJsonObject jsonObject = doc.object();

    if(jsonObject.isEmpty()){
        //TODO REFACTOR MSG
        //LocalMessage::instance()->showMessage("ADSB OpenSky empty object", 4);
        reply->deleteLater();
        return;
    }



    QJsonArray acArray = doc.object()["ac"].toArray();


    // Iterate through the "ac" array
    for (const QJsonValue &aircraftValue : acArray) {
        QJsonObject aircraft = aircraftValue.toObject();

        ADSBVehicle::VehicleInfo_t adsbInfo{};

        //Aircraft Hex
        bool icaoOk;
        QString icaoAux = aircraft["hex"].toString();
        adsbInfo.icaoAddress = icaoAux.toUInt(&icaoOk, 16);
        //qDebug() << "Hex:" << aircraft["hex"].toString();
        // Skip this element if icao number is not ok
        if (!icaoOk) {
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
        adsbInfo.availableFlags |= ADSBVehicle::DistanceAvailable;

        // If aircraft beyond max distance than skip this one
        if(distance > max_distance / 1000.0){
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
            //per setting eliminate all unknown alt
            if (adsbInfo.altitude<5 && unknown_zero_alt==false){
                continue;
            }
        }
        else {
            //per setting eliminate all unknown alt
            if (unknown_zero_alt==false){
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

void ADSBInternet::dirty_onSslError(QNetworkReply *reply, QList<QSslError> errors)
{
    // Consti10: Dang openssl - just ignore all SSL errors !
    //qDebug()<<"got some ssl errors";
    reply->ignoreSslErrors();
}

ADSBSdr::ADSBSdr()
    : ADSBapi(2000)
{
}

void ADSBSdr::requestData(void) {
    //TODO REFACTOR MSG
    //Logger::instance()->logData("request data", 1);
    _adsb_show_sdr_data = _settings.value("adsb_show_sdr_data").toBool();
    _adsb_enable = _settings.value("adsb_enable").toBool();

    // If adsb or sdr adsb is disabled by settings don't make the request and return
    if (!_adsb_enable || !_adsb_show_sdr_data) {
        emit sourceStatusChanged(0);
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

    max_distance = _settings.value("adsb_radius").toInt() / 1000;
    unknown_zero_alt=_settings.value("adsb_show_unknown_or_zero_alt").toBool();

    //qDebug() << "MAX adsb distance=" << max_distance;

    if (reply->error()) {
        emit sourceStatusChanged(1);
        //TODO REFACTOR MSG
        //LocalMessage::instance()->showMessage("ADSB SDR Reply Error", 4);
        reply->deleteLater();
        return;
    }

    QJsonParseError errorPtr;
    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data, &errorPtr);

    if (doc.isNull()) {
        emit sourceStatusChanged(1);
        //TODO REFACTOR MSG
        //LocalMessage::instance()->showMessage("ADSB SDR Parse Error", 4);
        reply->deleteLater();
        return;
    }

    if(!doc.isObject()){
        emit sourceStatusChanged(1);
        //TODO REFACTOR MSG
        //LocalMessage::instance()->showMessage("ADSB SDR Json not an object", 4);
        reply->deleteLater();
        return;
    }

    QJsonObject jsonObject = doc.object();

    if(jsonObject.isEmpty()){
        emit sourceStatusChanged(1);
        //TODO REFACTOR MSG
        //LocalMessage::instance()->showMessage("ADSB SDR Json empty", 4);
        reply->deleteLater();
        return;
    }

    QJsonArray array = jsonObject["aircraft"].toArray();
    emit sourceStatusChanged(2);

    if(array.isEmpty()){
        //TODO REFACTOR MSG
        //LocalMessage::instance()->showMessage("ADSB SDR Json array empty", 4);
        reply->deleteLater();
        return;
    }

    foreach (const QJsonValue & val, array){
        //Logger::instance()->logData("For Each Loop... /n", 1);
        ADSBVehicle::VehicleInfo_t adsbInfo{};
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

            const QJsonObject aircraft = val.toObject();
            const bool hasPosition = aircraft.value("lat").isDouble() && aircraft.value("lon").isDouble();
            if (hasPosition) {
                const double lat = aircraft.value("lat").toDouble();
                const double lon = aircraft.value("lon").toDouble();

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
            }

            if (aircraft.value("rssi").isDouble()) {
                adsbInfo.rssi = aircraft.value("rssi").toDouble();
                adsbInfo.availableFlags |= ADSBVehicle::RssiAvailable;
            }

            // callsign
            adsbInfo.callsign = val.toObject().value("flight").toString();

            if (adsbInfo.callsign.length() == 0) {
                adsbInfo.callsign = "N/A";
            } else {
                adsbInfo.availableFlags |= ADSBVehicle::CallsignAvailable;
            }

            // dump1090 variants use either altitude or alt_baro (feet).
            QJsonValue altitude = aircraft.value("alt_baro");
            if (!altitude.isDouble()) altitude = aircraft.value("altitude");
            if (altitude.isDouble() && (unknown_zero_alt || altitude.toDouble() >= 5)) {
                adsbInfo.altitude = altitude.toDouble() * 0.3048;
                adsbInfo.availableFlags |= ADSBVehicle::AltitudeAvailable;
            }

            //velocity
            QJsonValue speed = aircraft.value("gs");
            if (!speed.isDouble()) speed = aircraft.value("speed");
            if (speed.isDouble()) {
                adsbInfo.velocity = round(speed.toDouble() * 1.852); // knots to km/h
                adsbInfo.availableFlags |= ADSBVehicle::VelocityAvailable;
            }

            //heading
            if (aircraft.value("track").isDouble()) {
                adsbInfo.heading = aircraft.value("track").toDouble();
                adsbInfo.availableFlags |= ADSBVehicle::HeadingAvailable;
            }

            //last contact
            QJsonValue seen = aircraft.value("seen_pos");
            if (!seen.isDouble()) seen = aircraft.value("seen");
            if (seen.isDouble()) {
                adsbInfo.lastContact = seen.toInt();
                adsbInfo.availableFlags |= ADSBVehicle::LastContactAvailable;
            }

            //vertical velocity
            QJsonValue verticalRate = aircraft.value("baro_rate");
            if (!verticalRate.isDouble()) verticalRate = aircraft.value("vert_rate");
            if (verticalRate.isDouble()) {
                adsbInfo.verticalVel = round(verticalRate.toDouble() * 0.00508); //feet/min to m/s
                adsbInfo.availableFlags |= ADSBVehicle::VerticalVelAvailable;
            }


            // this is received on adsbvehicleupdate slot
            emit adsbVehicleUpdate(adsbInfo);
        }
        else {
            //Logger::instance()->logData("icao REJECTED! /n", 1);
        }
    }
    reply->deleteLater();
}
