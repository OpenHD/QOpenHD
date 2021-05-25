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

    Q_PROPERTY(QmlObjectListModel* waypointModel READ waypointModel CONSTANT)

    QmlObjectListModel* waypointModel(void) { return &_waypoints; }


signals:
    // sent to adsbwidgetform.ui to update the status indicator
    //void statusChanged(void);

public slots:
    void addMissionWaypoint  (const MissionWaypoint::WaypointInfo_t waypointInfo);
    void onStarted();

private slots:
    //void _cleanupStaleVehicles(void);

private:
    QmlObjectListModel              _waypoints;
    QMap<int, MissionWaypoint*>    _sequenceMap;


};
