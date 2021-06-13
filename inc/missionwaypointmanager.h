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
    //~MissionWaypointManager(); // this was causing compiler error
    static MissionWaypointManager* instance();


    Q_PROPERTY(QmlObjectListModel* missionWaypoints READ missionWaypoints CONSTANT)

    QmlObjectListModel* missionWaypoints(void) { return &_missionWaypoints; }


signals:
    // sent to adsbwidgetform.ui to update the status indicator
    //void statusChanged(void);
    void mapDeleteWaypoints();

public slots:
    void deleteMissionWaypoints();
    void addMissionWaypoint (const MissionWaypoint::WaypointInfo_t waypointInfo);
    void onStarted();

private slots:
    //void _cleanupStaleVehicles(void);

private:
    QmlObjectListModel              _missionWaypoints;
    QMap<uint16_t, MissionWaypoint*>    _sequenceMap;

};
