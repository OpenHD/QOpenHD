#pragma once

#include <QObject>
#include <QGeoCoordinate>
#include <QElapsedTimer>

class MissionWaypoint : public QObject
{
    Q_OBJECT

public:

    enum {
        CommandAvailable =     1 << 1,
        LocationAvailable =     1 << 2,
        AltitudeAvailable =     1 << 3,
        HeadingAvailable =      1 << 4,
        AlertAvailable =        1 << 5,
        VelocityAvailable =     1 << 6,
        VerticalVelAvailable =  1 << 7
    };


    typedef struct {
        int             sequence;    // Required
        QString         command;
        QGeoCoordinate  location;
        double          altitude;
        double          velocity;
        double          heading;
        bool            alert;
        uint32_t        availableFlags;        
        double          verticalVel;
    } WaypointInfo_t;

    MissionWaypoint(const WaypointInfo_t& waypointInfo, QObject* parent);


    Q_PROPERTY(int              sequence READ sequence    CONSTANT)
    Q_PROPERTY(QString          command    READ command       NOTIFY commandChanged)
    Q_PROPERTY(QGeoCoordinate   coordinate  READ coordinate     NOTIFY coordinateChanged)
    Q_PROPERTY(double           lat         READ lat            NOTIFY coordinateChanged)
    Q_PROPERTY(double           lon         READ lon            NOTIFY coordinateChanged)
    Q_PROPERTY(double           altitude    READ altitude       NOTIFY altitudeChanged)     // NaN for not available
    Q_PROPERTY(double           velocity    READ velocity       NOTIFY velocityChanged)     // NaN for not available
    Q_PROPERTY(double           heading     READ heading        NOTIFY headingChanged)      // NaN for not available
    Q_PROPERTY(bool             alert       READ alert          NOTIFY alertChanged)        // Collision path
    Q_PROPERTY(double           verticalVel READ verticalVel    NOTIFY verticalVelChanged)

    int             sequence (void) const { return static_cast<int>(_sequence); }
    QString         command    (void) const { return _command; }
    QGeoCoordinate  coordinate  (void) const { return _coordinate; }
    double          lat         (void) const { return _coordinate.latitude(); }
    double          lon         (void) const { return _coordinate.longitude(); }
    double          altitude    (void) const { return _altitude; }
    double          velocity    (void) const { return _velocity; }
    double          heading     (void) const { return _heading; }
    bool            alert       (void) const { return _alert; }
    double          verticalVel (void) const { return _verticalVel; }

    void updateWaypoint(const WaypointInfo_t& waypointInfo);

signals:
    void coordinateChanged  ();
    void commandChanged     ();
    void altitudeChanged    ();
    void velocityChanged    ();
    void headingChanged     ();
    void alertChanged       ();
    void verticalVelChanged ();

private:
    int            _sequence;
    QString         _command;
    QGeoCoordinate  _coordinate;
    double          _altitude;
    double          _velocity;
    double          _heading;
    bool            _alert;
    double          _verticalVel;

};

Q_DECLARE_METATYPE(MissionWaypoint::WaypointInfo_t);

