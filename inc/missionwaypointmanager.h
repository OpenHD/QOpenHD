#pragma once

#include "QmlObjectListModel.h"
#include "missionwaypoint.h"

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


class MissionWaypointManager : public QObject {
    Q_OBJECT
    
public:
    MissionWaypointManager(QObject* parent = nullptr);
    ~MissionWaypointManager(); // this was causing compiler error
    static MissionWaypointManager* instance();

    Q_PROPERTY(QmlObjectListModel* waypoints READ waypoints CONSTANT)

    QmlObjectListModel* waypoints(void) { return &_waypoints; }


signals:
    // sent to adsbwidgetform.ui to update the status indicator
    //void statusChanged(void);

public slots:
    void deleteMissionWaypoints();
    void addMissionWaypoint (int seq,int cmd,double lat,double lon,
                             double alt,double spd, double hdg,bool alert,double vert);
    void onStarted();

private slots:
    //void _cleanupStaleVehicles(void);

private:
    QmlObjectListModel              _waypoints;
    QMap<int, MissionWaypoint*>    _sequenceMap;


};
