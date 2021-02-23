/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "ADSBVehicleManager.h"
#include "localmessage.h"
#include "openhd.h"
#include "mavlinktelemetry.h"

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
    MavlinkTelemetry* mavlinktelemetry = MavlinkTelemetry::instance();
    connect(mavlinktelemetry, &MavlinkTelemetry::adsbVehicleUpdate, this, &ADSBVehicleManager::adsbVehicleUpdate, Qt::QueuedConnection);

    connect(&_adsbVehicleCleanupTimer, &QTimer::timeout, this, &ADSBVehicleManager::_cleanupStaleVehicles);
    _adsbVehicleCleanupTimer.setSingleShot(false);
    _adsbVehicleCleanupTimer.start(1000);

    _internetLink = new ADSBInternet();
    connect(_internetLink, &ADSBInternet::adsbVehicleUpdate, this, &ADSBVehicleManager::adsbVehicleUpdate, Qt::QueuedConnection);
    connect(this, &ADSBVehicleManager::mapCenterChanged, _internetLink, &ADSBInternet::mapBoundsChanged, Qt::QueuedConnection);
    
    _sdrLink = new ADSBSdr();
    connect(_sdrLink, &ADSBSdr::adsbVehicleUpdate, this, &ADSBVehicleManager::adsbVehicleUpdate, Qt::QueuedConnection);
    connect(this, &ADSBVehicleManager::mapCenterChanged, _sdrLink, &ADSBSdr::mapBoundsChanged, Qt::QueuedConnection);
}

// called from qml when the map is moved
void ADSBVehicleManager::newMapCenter(QGeoCoordinate center_coord) {
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

// we evaluate traffic here!!
void ADSBVehicleManager::adsbVehicleUpdate(const ADSBVehicle::VehicleInfo_t vehicleInfo)
{
    uint32_t icaoAddress = vehicleInfo.icaoAddress;

    if (_adsbICAOMap.contains(icaoAddress)) {
        _adsbICAOMap[icaoAddress]->update(vehicleInfo);
    } else {
        if (vehicleInfo.availableFlags & ADSBVehicle::LocationAvailable) {
            ADSBVehicle* adsbVehicle = new ADSBVehicle(vehicleInfo, this);
            _adsbICAOMap[icaoAddress] = adsbVehicle;
            _adsbVehicles.append(adsbVehicle);
        }
    }

    // Show warnings if adsb reported traffic is too close
    if (vehicleInfo.availableFlags & ADSBVehicle::LocationAvailable) {
        qreal distance = _calculateKmDistance(vehicleInfo.location);
        _evaluateTraffic(vehicleInfo.altitude, distance);
    }

    _last_update_timer.restart();
    _status = 2;
    emit statusChanged();
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
    int drone_alt = OpenHD::instance()->get_msl_alt();

    if (traffic_alt - drone_alt < 300 && traffic_distance < 2) {
        LocalMessage::instance()->showMessage("Aircraft Traffic", 3);

    } else if (traffic_alt - drone_alt < 500 && traffic_distance < 5) {
        LocalMessage::instance()->showMessage("Aircraft Traffic", 4);
    }
}

int ADSBVehicleManager::_calculateKmDistance(QGeoCoordinate coord)
{
    double lat_1 = OpenHD::instance()->get_lat(); 
    double lon_1 = OpenHD::instance()->get_lon();
    double lat_2 = coord.latitude();
    double lon_2 = coord.longitude();

    double latDistance = qDegreesToRadians(lat_1 - lat_2);
    double lngDistance = qDegreesToRadians(lon_1 - lon_2);

    double a = qSin(latDistance / 2) * qSin(latDistance / 2)
            + qCos(qDegreesToRadians(_api_center_coord.latitude())) * qCos(qDegreesToRadians(lat_2))
            * qSin(lngDistance / 2) * qSin(lngDistance / 2);

    double c = 2 * qAtan2(qSqrt(a), qSqrt(1 - a));
    int distance = radius_earth_km * c;

    return distance;
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
    // qDebug() << "------------------Adsbapi::init()";

    QNetworkAccessManager * manager = new QNetworkAccessManager(this);

    m_manager = manager;

    connect(manager, SIGNAL(finished(QNetworkReply*)), this, SLOT(processReply(QNetworkReply*))) ;

    timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &ADSBapi::requestData);

    // How frequently data is requested
    timer->start(timer_interval);
    mapBoundsChanged(QGeoCoordinate(40.48205, -3.35996)); // this shouldn't be necesary
}

// this is duplicated
void ADSBapi::mapBoundsChanged(QGeoCoordinate center_coord) {
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
    _adsb_api_openskynetwork = _settings.value("adsb_api_openskynetwork").toBool();

    // If openskynetwork is disabled by settings don't make the request and return
    if (!_adsb_api_openskynetwork) {
        return;
    }

    adsb_url= "https://opensky-network.org/api/states/all?lamin="+lowerr_lat+"&lomin="+upperl_lon+"&lamax="+upperl_lat+"&lomax="+lowerr_lon;

    QNetworkRequest request;
    QUrl api_request = adsb_url;
    request.setUrl(api_request);
    request.setRawHeader("User-Agent", "MyOwnBrowser 1.0");

    // qDebug() << "url=" << api_request;
    m_manager->get(request);
}

void ADSBInternet::processReply(QNetworkReply *reply) {

    if (reply->error()) {
        qDebug() << "ADSB request error!";
        qDebug() << reply->errorString();
        LocalMessage::instance()->showMessage("ADSB Reply Error", 4);
        reply->deleteLater();
        return;
    }

    QJsonParseError errorPtr;
    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data, &errorPtr);

    if (doc.isNull()) {
        qDebug() << "ADSB Openskynetwork response: Parse failed";
        LocalMessage::instance()->showMessage("ADSB Parse Error", 4);
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

        // calsign
        adsbInfo.callsign = innerarray[1].toString();

        if (adsbInfo.callsign.length() == 0) {
            adsbInfo.callsign = "N/A";
        } else {
            adsbInfo.availableFlags |= ADSBVehicle::CallsignAvailable;
        }

        // location comes in lat lon format, but we need it as QGeoCoordinate
        double lat = innerarray[6].toDouble();
        double lon = innerarray[5].toDouble();
        QGeoCoordinate location(lat, lon);
        adsbInfo.location = location;
        adsbInfo.availableFlags |= ADSBVehicle::LocationAvailable;  

        // rest of fields
        adsbInfo.altitude = innerarray[7].toDouble();
        adsbInfo.availableFlags |= ADSBVehicle::AltitudeAvailable;
        adsbInfo.velocity = innerarray[9].toDouble() * 3.6; // m/s to km/h
        adsbInfo.availableFlags |= ADSBVehicle::VelocityAvailable;
        adsbInfo.heading = innerarray[10].toDouble();
        adsbInfo.availableFlags |= ADSBVehicle::HeadingAvailable;
        adsbInfo.lastContact = innerarray[4].toInt();
        adsbInfo.availableFlags |= ADSBVehicle::LastContactAvailable;
        adsbInfo.verticalVel = innerarray[11].toDouble();
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

    timer_interval = 1000;
}

void ADSBSdr::requestData(void) {
    _adsb_api_sdr = _settings.value("adsb_api_sdr").toBool();

    // If sdr is disabled by settings don't make the request and return
    if (!_adsb_api_sdr) {
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

    if (reply->error()) {
        qDebug() << "ADSB request error!";
        qDebug() << reply->errorString();
        LocalMessage::instance()->showMessage("ADSB Reply Error", 4);
        reply->deleteLater();
        return;
    }

    QJsonParseError errorPtr;
    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data, &errorPtr);

    if (doc.isNull()) {
        qDebug() << "ADSB Openskynetwork response: Parse failed";
        LocalMessage::instance()->showMessage("ADSB Parse Error", 4);
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
        reply->deleteLater();
        return;
    }

    QJsonArray array = jsonObject["aircraft"].toArray();

    if(array.isEmpty()){
        qDebug()<<"JSON array is empty.";
        reply->deleteLater();
        return;
    }

    foreach (const QJsonValue & val, array){

        ADSBVehicle::VehicleInfo_t adsbInfo;
        bool icaoOk;

        // TODO
        // According to dump1090-mutability, this value can start 
        // by "~" in case it isn't a valid ICAO. How this will 
        // behave then?
        QString icaoAux = val.toObject().value("hex").toString();
        adsbInfo.icaoAddress = icaoAux.toUInt(&icaoOk, 16);
        
        // Skip this element if icao number is not ok
        if (!icaoOk) {
            continue;
        }

        // calsign
        adsbInfo.callsign = val.toObject().value("flight").toString();

        if (adsbInfo.callsign.length() == 0) {
            adsbInfo.callsign = "N/A";
        } else {
            adsbInfo.availableFlags |= ADSBVehicle::CallsignAvailable;
        }

        // location comes in lat lon format, but we need it as QGeoCoordinate
        double lat = val.toObject().value("lat").toDouble();
        double lon = val.toObject().value("lon").toDouble();
        QGeoCoordinate location(lat, lon);
        adsbInfo.location = location;
        adsbInfo.availableFlags |= ADSBVehicle::LocationAvailable;  

        // TODO - we must review the units here
        // rest of fields
        adsbInfo.altitude = (val.toObject().value("altitude").toInt() * 0.3048); //feet to meters
        adsbInfo.availableFlags |= ADSBVehicle::AltitudeAvailable;
        adsbInfo.velocity = round(val.toObject().value("speed").toDouble() * 1.852); // knots to km/h
        adsbInfo.availableFlags |= ADSBVehicle::VelocityAvailable;
        adsbInfo.heading = val.toObject().value("track").toDouble();
        adsbInfo.availableFlags |= ADSBVehicle::HeadingAvailable;
        adsbInfo.lastContact = val.toObject().value("seen_pos").toInt();
        adsbInfo.availableFlags |= ADSBVehicle::LastContactAvailable;
        adsbInfo.verticalVel = round(val.toObject().value("vert_rate").toDouble() * 0.00508); //feet/min to m/s
        adsbInfo.availableFlags |= ADSBVehicle::VerticalVelAvailable;

        // this is received on adsbvehicleupdate slot
        emit adsbVehicleUpdate(adsbInfo);
    }
    reply->deleteLater();
}