#ifndef OPENSKY_H
#define OPENSKY_H

#include <QObject>
#include <QtQuick>

#include "constants.h"

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>

#include "util.h"

#include "markermodel.h"


class OpenSky: public QObject {
    Q_OBJECT

public:
    explicit OpenSky(QObject *parent = nullptr);
    static OpenSky* instance();

    Q_PROPERTY(QGeoCoordinate adsb_api_coord MEMBER m_adsb_api_coord WRITE set_adsb_api_coord NOTIFY adsb_api_coord_changed)
    void set_adsb_api_coord(QGeoCoordinate adsb_api_coord);

signals:
    void addMarker(int current_row, int total_rows, const Traffic &traffic);
    void doneAddingMarkers();
    void removeAllMarkers();
    void adsb_api_coord_changed(QGeoCoordinate adsb_api_coord);

public slots:
    void onStarted();
    void mapBoundsChanged(QGeoCoordinate center_coord);

private slots:
    void processReply(QNetworkReply *reply);
    void requestData();
    int calculateKmDistance(double center_lat, double center_lon,
        double marker_lat, double marker_lon);

private:
    QGeoCoordinate m_adsb_api_coord;
    QNetworkAccessManager * m_manager;
    QString upperl_lat;
    QString upperl_lon;
    QString lowerr_lat;
    QString lowerr_lon;
    double center_lat;
    double center_lon;
    QSettings settings;
    double radius_earth_km = 6371;
};



#endif
