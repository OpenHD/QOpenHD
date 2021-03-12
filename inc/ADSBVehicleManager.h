#pragma once

#include "QmlObjectListModel.h"
#include "ADSBVehicle.h"

#include <QThread>
#include <QTcpSocket>
#include <QTimer>
#include <QGeoCoordinate>

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>

#include <QGeoCoordinate>
#include <QSettings>

// This is a base clase for inheriting the links for 
// SDR and Opensky network apis
class ADSBapi : public QThread
{
    Q_OBJECT

public:
    ADSBapi();
    ~ADSBapi();

signals:
    void adsbVehicleUpdate(const ADSBVehicle::VehicleInfo_t vehicleInfo);

protected: 
    void run(void) final;

public slots:
    void mapBoundsChanged(QGeoCoordinate center_coord);

protected slots:
    virtual void processReply(QNetworkReply *reply) = 0;
    virtual void requestData() = 0;

protected:
    void init();

    // network 
    QNetworkAccessManager * m_manager;
    QString adsb_url;

    // boundingbox parameters
    QString upperl_lat;
    QString upperl_lon;
    QString lowerr_lat;
    QString lowerr_lon;
    
    // timer for requests
    int timer_interval;
    QTimer *timer;

    QSettings _settings;
};

// This class gets the info from Openskynetwork api
class ADSBInternet: public ADSBapi {
    Q_OBJECT

public:
    ADSBInternet() { timer_interval = 10000; }
    ~ADSBInternet() {}

private slots:
    void processReply(QNetworkReply *reply) override;
    void requestData() override;

private: 
    bool _adsb_api_openskynetwork;
};

// This class gets the info from SDR
class ADSBSdr: public ADSBapi {
    Q_OBJECT

public:
    ADSBSdr();
    ~ADSBSdr() {}

    void setGroundIP(QString address) { _groundAddress = address; }

private slots:
    void processReply(QNetworkReply *reply) override;
    void requestData() override;

private:
    QString _groundAddress = "";
    bool _adsb_api_sdr;
};

class ADSBVehicleManager : public QObject {
    Q_OBJECT
    
public:
    ADSBVehicleManager(QObject* parent = nullptr);
    ~ADSBVehicleManager();
    static ADSBVehicleManager* instance();

    Q_PROPERTY(QmlObjectListModel* adsbVehicles READ adsbVehicles CONSTANT)
    Q_PROPERTY(QGeoCoordinate apiMapCenter READ apiMapCenter MEMBER _api_center_coord NOTIFY mapCenterChanged)

    // frontend indicator. 0 inactive, 1 red, 2 green
    Q_PROPERTY(uint status READ status NOTIFY statusChanged)

    QmlObjectListModel* adsbVehicles(void) { return &_adsbVehicles; }
    QGeoCoordinate apiMapCenter(void) { return _api_center_coord; }
    uint status() { return _status; }

    // called from qml when the map has moved
    Q_INVOKABLE void newMapCenter(QGeoCoordinate center_coord);

    Q_INVOKABLE void setGroundIP(QString address) { _sdrLink->setGroundIP(address); }

signals:
    // sent to ADSBapi to make requests based into this
    void mapCenterChanged(QGeoCoordinate center_coord);

    // sent to adsbwidgetform.ui to update the status indicator
    void statusChanged(void);

public slots:
    void adsbVehicleUpdate  (const ADSBVehicle::VehicleInfo_t vehicleInfo);
    void onStarted();

private slots:
    void _cleanupStaleVehicles(void);

private:
    void _evaluateTraffic(double traffic_alt, int traffic_distance);
    int  _calculateKmDistance(QGeoCoordinate coord);

    double radius_earth_km = 6371; // For _calculateKmDistance

    QmlObjectListModel              _adsbVehicles;
    QMap<uint32_t, ADSBVehicle*>    _adsbICAOMap;
    QTimer                          _adsbVehicleCleanupTimer;
    ADSBInternet*                   _internetLink = nullptr;
    ADSBSdr*                        _sdrLink = nullptr;
    QGeoCoordinate                  _api_center_coord;
    QElapsedTimer                   _last_update_timer;
    uint                            _status = 0;
};
