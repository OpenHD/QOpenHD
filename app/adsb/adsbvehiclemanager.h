#pragma once

#include "qmlobjectlistmodel.h"
#include "adsbvehicle.h"

#include <QThread>
#include <QTcpSocket>
#include <QTimer>

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>

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

    void adsbClearModelRequest();

protected:
    void run(void) final;

public slots:
    void mapLatChanged(double map_lat);
    void mapLonChanged(double map_lon);

protected slots:
    virtual void processReply(QNetworkReply *reply) = 0;
    virtual void requestData() = 0;

protected:
    void init();

    bool _adsb_enable;

    // network
    QNetworkAccessManager * m_manager;
    QString adsb_url;


    QString lat_string;
    QString lon_string;


    // timer for requests
    int timer_interval;
    QTimer *timer;

    QSettings _settings;

    double m_api_lat; //private but duplicated across classes
    double m_api_lon; //private but duplicated across classes

    qreal max_distance;
    bool unknown_zero_alt;
};

// This class gets the info from Openskynetwork api
class ADSBInternet: public ADSBapi {
    Q_OBJECT

public:
    ADSBInternet() { timer_interval = 10000; }
    ~ADSBInternet() {}

private slots:
    void processReply(QNetworkReply *reply) override;
    void dirty_onSslError(QNetworkReply* reply, QList<QSslError> errors);
    void requestData() override;
private:
    bool _adsb_show_internet_data;
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
    bool _adsb_show_sdr_data;
};

class ADSBVehicleManager : public QObject {
    Q_OBJECT

public:
    ADSBVehicleManager(QObject* parent = nullptr);
    ~ADSBVehicleManager();
    static ADSBVehicleManager* instance();

    Q_PROPERTY(QmlObjectListModel* adsbVehicles READ adsbVehicles CONSTANT)
    Q_PROPERTY(double apiLat READ apiLat MEMBER _api_lat NOTIFY mapLatChanged)
    Q_PROPERTY(double apiLon READ apiLon MEMBER _api_lon NOTIFY mapLonChanged)

    // frontend indicator. 0 inactive, 1 red, 2 green
    Q_PROPERTY(uint status READ status NOTIFY statusChanged)

    QmlObjectListModel* adsbVehicles(void) { return &_adsbVehicles; }
    double apiLat(void) { return _api_lat; }
    double apiLon(void) { return _api_lon; }
    uint status() { return _status; }

    // called from qml when the map has moved
    Q_INVOKABLE void newMapLat(double map_lat);
    Q_INVOKABLE void newMapLon(double map_lon);

    Q_INVOKABLE void setGroundIP(QString address) { _sdrLink->setGroundIP(address); }

signals:
    // sent to ADSBapi to make requests based into this
    void mapLatChanged(double map_lat);
    void mapLonChanged(double map_lon);

    // sent to adsbwidgetform.ui to update the status indicator
    void statusChanged(void);

public slots:
    void adsbVehicleUpdate  (const ADSBVehicle::VehicleInfo_t vehicleInfo);
    void onStarted();
    void adsbClearModel();

private slots:
    void _cleanupStaleVehicles(void);

private:
    void _evaluateTraffic(double traffic_alt, int traffic_distance);

    QmlObjectListModel              _adsbVehicles;
    QMap<uint32_t, ADSBVehicle*>    _adsbICAOMap;
    QTimer                          _adsbVehicleCleanupTimer;
    ADSBInternet*                   _internetLink = nullptr;
    ADSBSdr*                        _sdrLink = nullptr;
    double                          _api_lat;
    double                          _api_lon;
    QElapsedTimer                   _last_update_timer;
    uint                            _status = 0;

    qreal distance = 0;
    QSettings _settings;
};
