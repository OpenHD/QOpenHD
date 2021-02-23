/****************************************************************************
 *
 * This file has been ported from QGroundControl project <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "ADSBVehicle.h"

#include <QDebug>
#include <QtMath>

ADSBVehicle::ADSBVehicle(const VehicleInfo_t& vehicleInfo, QObject* parent)
    : QObject       (parent)
    , _icaoAddress  (vehicleInfo.icaoAddress)
    , _altitude     (qQNaN())
    , _heading      (qQNaN())
    , _alert        (false)
{
    update(vehicleInfo);
}

void ADSBVehicle::update(const VehicleInfo_t& vehicleInfo)
{
    if (_icaoAddress != vehicleInfo.icaoAddress) {
        qDebug() << "ICAO address mismatch expected:actual" << _icaoAddress << vehicleInfo.icaoAddress;
        return;
    }
    if (vehicleInfo.availableFlags & CallsignAvailable) {
        if (vehicleInfo.callsign != _callsign) {
            _callsign = vehicleInfo.callsign;
            emit callsignChanged();
        }
    }
    if (vehicleInfo.availableFlags & LocationAvailable) {
        if (_coordinate != vehicleInfo.location) {
            _coordinate = vehicleInfo.location;
            emit coordinateChanged();
        }
    }
    if (vehicleInfo.availableFlags & AltitudeAvailable) {
        if (!(qIsNaN(vehicleInfo.altitude) && qIsNaN(_altitude)) && !qFuzzyCompare(vehicleInfo.altitude, _altitude)) {
            _altitude = vehicleInfo.altitude;
            emit altitudeChanged();
        }
    }
    if (vehicleInfo.availableFlags & HeadingAvailable) {
        if (!(qIsNaN(vehicleInfo.heading) && qIsNaN(_heading)) && !qFuzzyCompare(vehicleInfo.heading, _heading)) {
            _heading = vehicleInfo.heading;
            emit headingChanged();
        }
    }
    if (vehicleInfo.availableFlags & AlertAvailable) {
        if (vehicleInfo.alert != _alert) {
            _alert = vehicleInfo.alert;
            emit alertChanged();
        }
    }
    if (vehicleInfo.availableFlags & VelocityAvailable) {
        if (vehicleInfo.velocity != _velocity) {
            _velocity = vehicleInfo.velocity;
            emit velocityChanged();
        }
    }
    if (vehicleInfo.availableFlags & VerticalVelAvailable) {
        if (vehicleInfo.verticalVel != _verticalVel) {
            _verticalVel = vehicleInfo.verticalVel;
            emit verticalVelChanged();
        }
    }
    if (vehicleInfo.availableFlags & LastContactAvailable) {
        if (vehicleInfo.lastContact != _lastContact) {
            _lastContact = vehicleInfo.lastContact;
            emit lastContactChanged();
        }
    }
    _lastUpdateTimer.restart();
}

bool ADSBVehicle::expired()
{
    return _lastUpdateTimer.hasExpired(expirationTimeoutMs);
}
