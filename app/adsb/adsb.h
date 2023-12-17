#ifndef ADSB_H
#define ADSB_H

#include <QObject>
#include <QtQuick>

//#include "constants.h"

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>

//#include "util.h"
#include "common/openhd-util.hpp"

#include "../telemetry/models/markermodel.h"


class Adsb: public QObject {
    Q_OBJECT

public:
    explicit Adsb(QObject *parent = nullptr);
    static Adsb* instance();

    Q_PROPERTY(double adsb_lat MEMBER m_adsb_lat WRITE setAdsbLat NOTIFY adsbLatChanged);
    void setAdsbLat(double map_lat);
    Q_PROPERTY(double adsb_lon MEMBER m_adsb_lon WRITE setAdsbLon NOTIFY adsbLonChanged);
    void setAdsbLon(double map_lon);


signals:
    void addMarker(int current_row, int total_rows, const Traffic &traffic);
    void doneAddingMarkers();
    void removeAllMarkers();
    void adsbLatChanged(double map_lat);
    void adsbLonChanged(double map_lon);

public slots:
    void onStarted();
    //from old api where you eneded a bound rectangle
    //void mapBoundsChanged(double map_lat, double map_lon);

    Q_INVOKABLE void setGroundIP(QString address);

private slots:
    void processReply(QNetworkReply *reply);
    void requestData();
    int calculateKmDistance(double center_lat, double center_lon,
                            double marker_lat, double marker_lon);
    void evaluateTraffic(QString callsign,int contact,double lat,double lon,double alt,double velocity,
                         double track,double vertical,double distance);

private:
    int m_msl_alt;
    double m_api_lat;
    double m_api_lon;
    double m_adsb_lat;
    double m_adsb_lon;
    QNetworkAccessManager * m_manager;
    //QString upperl_lat;
    //QString upperl_lon;
    //QString lowerr_lat;
    //QString lowerr_lon;
    double m_map_lat;
    double m_map_lon;
    QSettings settings;
    double radius_earth_km = 6371;
    QString adsb_url;
    int timer_interval = 1000; //get reset later if api or sdr selected
    QTimer *timer;
    bool adsb_api_sdr;
    QString groundAddress;
};



#endif
