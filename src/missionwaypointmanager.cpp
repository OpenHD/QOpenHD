
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


void MissionWaypointManager::onStarted()
{
    qDebug() << "MissionWaypointManager::onStarted";
    MavlinkTelemetry* mavlinktelemetry = MavlinkTelemetry::instance();
    connect(mavlinktelemetry, &MavlinkTelemetry::deleteMissionWaypoints, this, &MissionWaypointManager::deleteMissionWaypoints);
    connect(mavlinktelemetry, &MavlinkTelemetry::addMissionWaypoint, this, &MissionWaypointManager::addMissionWaypoint, Qt::QueuedConnection);
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

    qDebug() << "deleteMissionWaypoints count=" << _missionWaypoints.count();
    for (int i=_missionWaypoints.count()-1; i>=0; i--) {

        MissionWaypoint* missionWaypoint = _missionWaypoints.value<MissionWaypoint*>(i);

        _missionWaypoints.removeAt(i);

        _sequenceMap.remove(missionWaypoint->sequence());
        qDebug() << "deleteMissionWaypoints at " << i;
        missionWaypoint->deleteLater();
        emit mapDeleteWaypoints();
    }

}


void MissionWaypointManager::addMissionWaypoint(const MissionWaypoint::WaypointInfo_t waypointInfo)
{
    qDebug() << "MissionWaypointManager::missionWaypointUpdate";

        uint16_t sequence = waypointInfo.sequence;

        qDebug() << "MissionWaypoint seq=" << waypointInfo.sequence;

        if (_sequenceMap.contains(sequence)) {

            qDebug() << "MissionWaypointManager calling update";

            _sequenceMap[sequence]->update(waypointInfo);

        } else {

            MissionWaypoint* missionWaypoint = new MissionWaypoint(waypointInfo, this);

            _sequenceMap[sequence] = missionWaypoint;

            _missionWaypoints.append(missionWaypoint);

            qDebug() << "MissionWaypoint Appended count : " << _missionWaypoints.count();

            qDebug() << "MissionWaypoint Appended index : " << _missionWaypoints.indexOf(missionWaypoint);
        }
}


