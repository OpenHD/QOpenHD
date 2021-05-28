#include "missionwaypoint.h"

#include <QDebug>
#include <QtMath>

MissionWaypoint::MissionWaypoint(const WaypointInfo_t& waypointInfo, QObject* parent)
    : QObject       (parent)
    , _sequence  (waypointInfo.sequence)
    , _latitude     (waypointInfo.latitude)
    , _longitude     (waypointInfo.longitude)
    , _altitude     (waypointInfo.altitude)

{
    updateWaypoint(waypointInfo);
}


void MissionWaypoint::updateWaypoint(const WaypointInfo_t& waypointInfo)
{

    qDebug() << "MissionWaypoint::updateWaypoint = " << _sequence << " : " << waypointInfo.sequence;

    if (_sequence != waypointInfo.sequence) {
        qDebug() << "Sequence mismatch expected:actual";
        return;
    }

    if (waypointInfo.availableFlags & CommandAvailable) {
        if (waypointInfo.command != _command) {
            _command = waypointInfo.command;
            emit commandChanged();
        }
    }
    if (waypointInfo.availableFlags & LatitudeAvailable) {
        qDebug() << "lat avail";
        if (_latitude != waypointInfo.latitude) {
            _latitude = waypointInfo.latitude;
            qDebug() << "lat changed";
            emit latitudeChanged();
        }
    }
    if (waypointInfo.availableFlags & LongitudeAvailable) {
        qDebug() << "lon avail";
        if (_longitude != waypointInfo.longitude) {
            _longitude = waypointInfo.longitude;
            qDebug() << "lon changed";
            emit longitudeChanged();
        }
    }
    if (waypointInfo.availableFlags & AltitudeAvailable) {
        if (_altitude != waypointInfo.altitude) {
            _altitude = waypointInfo.altitude;
            emit altitudeChanged();
        }
    }
    if (waypointInfo.availableFlags & HeadingAvailable) {
        if (!(qIsNaN(waypointInfo.heading) && qIsNaN(_heading)) && !qFuzzyCompare(waypointInfo.heading, _heading)) {
            _heading = waypointInfo.heading;
            emit headingChanged();
        }
    }
    if (waypointInfo.availableFlags & AlertAvailable) {
        if (waypointInfo.alert != _alert) {
            _alert = waypointInfo.alert;
            emit alertChanged();
        }
    }
    if (waypointInfo.availableFlags & VelocityAvailable) {
        if (waypointInfo.velocity != _velocity) {
            _velocity = waypointInfo.velocity;
            emit velocityChanged();
        }
    }
    if (waypointInfo.availableFlags & VerticalVelAvailable) {
        if (waypointInfo.verticalVel != _verticalVel) {
            _verticalVel = waypointInfo.verticalVel;
            emit verticalVelChanged();
        }
    }


}


