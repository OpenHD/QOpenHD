/****************************************************************************
 *
 * This file has been ported from QGroundControl project <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QObject>
#include <QGeoCoordinate>
#include <QElapsedTimer>

class ADSBVehicle : public QObject
{
    Q_OBJECT

public:
    enum {
        CallsignAvailable =     1 << 1,
        LocationAvailable =     1 << 2,
        AltitudeAvailable =     1 << 3,
        HeadingAvailable =      1 << 4,
        AlertAvailable =        1 << 5,
        VelocityAvailable =     1 << 6,
        VerticalVelAvailable =  1 << 7,
        LastContactAvailable =  1 << 8
    };

    typedef struct {
        uint32_t        icaoAddress;    // Required
        QString         callsign;
        QGeoCoordinate  location;
        double          altitude;
        double          velocity;
        double          heading;
        bool            alert;
        uint32_t        availableFlags;
        int             lastContact;
        double          verticalVel;
    } VehicleInfo_t;

    ADSBVehicle(const VehicleInfo_t& vehicleInfo, QObject* parent);

    Q_PROPERTY(int              icaoAddress READ icaoAddress    CONSTANT)
    Q_PROPERTY(QString          callsign    READ callsign       NOTIFY callsignChanged)
    Q_PROPERTY(QGeoCoordinate   coordinate  READ coordinate     NOTIFY coordinateChanged)
    Q_PROPERTY(double           lat         READ lat            NOTIFY coordinateChanged)
    Q_PROPERTY(double           lon         READ lon            NOTIFY coordinateChanged)
    Q_PROPERTY(double           altitude    READ altitude       NOTIFY altitudeChanged)     // NaN for not available
    Q_PROPERTY(double           velocity    READ velocity       NOTIFY velocityChanged)     // NaN for not available
    Q_PROPERTY(double           heading     READ heading        NOTIFY headingChanged)      // NaN for not available
    Q_PROPERTY(bool             alert       READ alert          NOTIFY alertChanged)        // Collision path
    Q_PROPERTY(int              lastContact READ lastContact    NOTIFY lastContactChanged)
    Q_PROPERTY(double           verticalVel READ verticalVel    NOTIFY verticalVelChanged)

    int             icaoAddress (void) const { return static_cast<int>(_icaoAddress); }
    QString         callsign    (void) const { return _callsign; }
    QGeoCoordinate  coordinate  (void) const { return _coordinate; }
    double          lat         (void) const { return _coordinate.latitude(); }
    double          lon         (void) const { return _coordinate.longitude(); }
    double          altitude    (void) const { return _altitude; }
    double          velocity    (void) const { return _velocity; }
    double          heading     (void) const { return _heading; }
    bool            alert       (void) const { return _alert; }
    int             lastContact (void) const { return _lastContact; }
    double          verticalVel (void) const { return _verticalVel; }

    void update(const VehicleInfo_t& vehicleInfo);

    /// check if the vehicle is expired and should be removed
    bool expired();

signals:
    void coordinateChanged  ();
    void callsignChanged    ();
    void altitudeChanged    ();
    void velocityChanged    ();
    void headingChanged     ();
    void alertChanged       ();
    void lastContactChanged ();
    void verticalVelChanged ();

private:
    // This is the time in ms our vehicle will expire and thus removed from map
    static constexpr qint64 expirationTimeoutMs = 120000;

    uint32_t        _icaoAddress;
    QString         _callsign;
    QGeoCoordinate  _coordinate;
    double          _altitude;
    double          _velocity;
    double          _heading;
    bool            _alert;
    int             _lastContact;
    double          _verticalVel;

    QElapsedTimer   _lastUpdateTimer;
};

Q_DECLARE_METATYPE(ADSBVehicle::VehicleInfo_t)

