#ifndef FCMAVLINKMISSIONSMODEL_H
#define FCMAVLINKMISSIONSMODEL_H


// To not pollute the FCMavlinkSystem model class too much, we have an extra model for managing the
// dynamically sized mission waypoints. ("Map stuff)
// This model pretty much only exposes mission items (dynamic size) such that we can make use of them
// (draw them in .qml) for the map.
// each mission item is pretty much really easy to define - a lattitude and longitude
class FCMavlinkMissionItemsModel
{
public:
    FCMavlinkMissionItemsModel();
    // We have a single instance of this model - for one FC mission.
    static FCMavlinkMissionItemsModel& instance();
};

#endif // FCMAVLINKMISSIONSMODEL_H
