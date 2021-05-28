#pragma once

#include <QObject>
#include <QGeoCoordinate>
#include <QElapsedTimer>

class MissionWaypoint : public QObject
{
    Q_OBJECT

public:

    enum {
        CommandAvailable =      1 << 1,
        LatitudeAvailable =     1 << 2,
        LongitudeAvailable =    1 << 3,
        AltitudeAvailable =     1 << 4,
        HeadingAvailable =      1 << 5,
        AlertAvailable =        1 << 6,
        VelocityAvailable =     1 << 7,
        VerticalVelAvailable =  1 << 8
    };


    typedef struct {
        uint32_t             sequence;    // Required
        int             command;
        double          latitude;
        double          longitude;
        double          altitude;
        double          velocity;
        double          heading;
        bool            alert;
        uint32_t        availableFlags;        
        double          verticalVel;
    } WaypointInfo_t;

    MissionWaypoint(const WaypointInfo_t& waypointInfo, QObject* parent);


    Q_PROPERTY(int              sequence    READ sequence       CONSTANT)
    Q_PROPERTY(int              command     READ command        NOTIFY commandChanged)
    Q_PROPERTY(double           latitude    READ latitude       NOTIFY latitudeChanged)
    Q_PROPERTY(double           longitude   READ longitude      NOTIFY longitudeChanged)
    Q_PROPERTY(double           altitude    READ altitude       NOTIFY altitudeChanged)     // NaN for not available
    Q_PROPERTY(double           velocity    READ velocity       NOTIFY velocityChanged)     // NaN for not available
    Q_PROPERTY(double           heading     READ heading        NOTIFY headingChanged)      // NaN for not available
    Q_PROPERTY(bool             alert       READ alert          NOTIFY alertChanged)        // Collision path
    Q_PROPERTY(double           verticalVel READ verticalVel    NOTIFY verticalVelChanged)

    int             sequence    (void) const { return static_cast<int>(_sequence); }
    int             command     (void) const { return _command; }
    double          latitude    (void) const { return _latitude; }
    double          longitude   (void) const { return _longitude; }
    double          altitude    (void) const { return _altitude; }
    double          velocity    (void) const { return _velocity; }
    double          heading     (void) const { return _heading; }
    bool            alert       (void) const { return _alert; }
    double          verticalVel (void) const { return _verticalVel; }

    void updateWaypoint(const WaypointInfo_t& waypointInfo);

signals:
    void commandChanged     ();
    void latitudeChanged    ();
    void longitudeChanged   ();
    void altitudeChanged    ();
    void velocityChanged    ();
    void headingChanged     ();
    void alertChanged       ();
    void verticalVelChanged ();

private:
    uint32_t        _sequence;
    int             _command;
    double          _latitude;
    double          _longitude;
    double          _altitude;
    double          _velocity;
    double          _heading;
    bool            _alert;
    double          _verticalVel;

};

Q_DECLARE_METATYPE(MissionWaypoint::WaypointInfo_t);

