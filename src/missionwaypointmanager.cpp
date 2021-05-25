
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
   connect(mavlinktelemetry, &MavlinkTelemetry::addMissionWaypoint, this, &MissionWaypointManager::addMissionWaypoint);
}


void MissionWaypointManager::addMissionWaypoint(const MissionWaypoint::WaypointInfo_t waypointInfo)
{

    qDebug() << "MissionWaypointManager::missionWaypointUpdate";

    int sequence = waypointInfo.sequence;

    if (_sequenceMap.contains(sequence)) {
        _sequenceMap[sequence]->updateWaypoint(waypointInfo);
        qDebug() << "MissionWaypoint Update";
    } else {
        if (waypointInfo.availableFlags & MissionWaypoint::LocationAvailable) {

            MissionWaypoint::WaypointInfo_t waypointInfo; //added this- not sure if needed

            MissionWaypoint* missionWaypoint = new MissionWaypoint(waypointInfo, this);
            _sequenceMap[sequence] = missionWaypoint;
            _waypoints.append(missionWaypoint);

            qDebug() << "MissionWaypoint Appended";
        }
    }
}






