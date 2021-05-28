
#include "missionwaypointmanager.h"
#include "localmessage.h"
#include "openhd.h"
#include "mavlinktelemetry.h"

#include <QDebug>

static MissionWaypointManager* _instance = nullptr;

MissionWaypointManager* MissionWaypointManager::instance()
{
    if ( _instance == nullptr ) {
        _instance = new MissionWaypointManager();
    }
    return _instance;
}


MissionWaypointManager::MissionWaypointManager(QObject *parent) : QObject(parent)
{
    qDebug() << "MissionWaypointManager::MissionWaypointManager()";
}


MissionWaypointManager::~MissionWaypointManager()
{
    // manually stop the threads

}


void MissionWaypointManager::onStarted()
{
    qDebug() << "MissionWaypointManager::onStarted";
    MavlinkTelemetry* mavlinktelemetry = MavlinkTelemetry::instance();
    connect(mavlinktelemetry, &MavlinkTelemetry::deleteMissionWaypoints, this, &MissionWaypointManager::deleteMissionWaypoints);
    connect(mavlinktelemetry, &MavlinkTelemetry::addMissionWaypoint, this, &MissionWaypointManager::addMissionWaypoint);
}

void MissionWaypointManager::deleteMissionWaypoints()
{
    qDebug() << "MissionWaypointManager::deleteMissionWaypoints";

    /*
    _waypoints.beginReset();
    _waypoints.clear();
    _waypoints.endReset();
    _sequenceMap.clear();
    */

    //must adjust the counter since the model index starts at 0

    qDebug() << "deleteMissionWaypoints count=" << _waypoints.count();
    for (int i=_waypoints.count()-1; i>=0; i--) {

        MissionWaypoint* missionWaypoint = _waypoints.value<MissionWaypoint*>(i);

        _waypoints.removeAt(i);

        _sequenceMap.remove(missionWaypoint->sequence());
        qDebug() << "deleteMissionWaypoints at " << i;
        missionWaypoint->deleteLater();
    }

}


void MissionWaypointManager::addMissionWaypoint(int seq,int cmd,double lat,double lon,double alt,
                                                double spd, double hdg,bool alert,double vert)
{
    //qDebug() << "MissionWaypointManager::missionWaypointUpdate";

        MissionWaypoint::WaypointInfo_t waypointInfo;

        waypointInfo.availableFlags = 0;
        waypointInfo.sequence = seq;

        uint32_t sequence = waypointInfo.sequence;



        qDebug() << "MissionWaypoint seq=" << waypointInfo.sequence;

        if (_sequenceMap.contains(sequence)) {

            _sequenceMap[sequence]->updateWaypoint(waypointInfo);

        } else {

            MissionWaypoint* missionWaypoint = new MissionWaypoint(waypointInfo, this);


            _sequenceMap[sequence] = missionWaypoint;


            qDebug() << "MissionWaypoint lat=" << lat;
            qDebug() << "MissionWaypoint lon=" << lon;

            waypointInfo.latitude = lat;
            waypointInfo.availableFlags |= MissionWaypoint::LatitudeAvailable;

            waypointInfo.longitude = lon;
            waypointInfo.availableFlags |= MissionWaypoint::LongitudeAvailable;

            waypointInfo.command = cmd;
            waypointInfo.availableFlags |= MissionWaypoint::CommandAvailable;

            qDebug() << "MissionWaypoint cmd=" << cmd;

            waypointInfo.altitude = alt;
            waypointInfo.availableFlags |= MissionWaypoint::AltitudeAvailable;

            waypointInfo.velocity = spd;
            waypointInfo.availableFlags |= MissionWaypoint::VelocityAvailable;

            waypointInfo.heading = hdg;
            waypointInfo.availableFlags |= MissionWaypoint::HeadingAvailable;

            waypointInfo.alert = alert;
            waypointInfo.availableFlags |= MissionWaypoint::AlertAvailable;

            waypointInfo.verticalVel = vert;
            waypointInfo.availableFlags |= MissionWaypoint::VerticalVelAvailable;


            //_waypoints.insert(seq, missionWaypoint);

            _waypoints.append(missionWaypoint);

            qDebug() << "MissionWaypoint Appended count : " << _waypoints.count();

            qDebug() << "MissionWaypoint Appended index : " << _waypoints.indexOf(missionWaypoint);
        }
}






