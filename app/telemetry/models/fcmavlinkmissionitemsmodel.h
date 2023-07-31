#ifndef FCMAVLINKMISSIONSMODEL_H
#define FCMAVLINKMISSIONSMODEL_H

#include <QAbstractListModel>
#include <QVector>
#include <map>
#include <mutex>
#include <qtimer.h>
#include <utility>


// To not pollute the FCMavlinkSystem model class too much, we have an extra model for managing the
// dynamically sized mission waypoints. ("Map stuff)
// This model pretty much only exposes mission items (dynamic size) such that we can make use of them
// (draw them in .qml) for the map.
// each mission item is pretty much really easy to define - a lattitude, longitude and mission index
// NOTE: Elements in this model are by increasing mission index - if we don't have the data for a given mission index (yet),
// valid is set to false (aka if valid=false this is just a dummy waiting to be filled with valid mission data)
class FCMavlinkMissionItemsModel : public QAbstractListModel
{
    Q_OBJECT
public:
    explicit FCMavlinkMissionItemsModel(QObject *parent = nullptr);
    static FCMavlinkMissionItemsModel& instance();
    // This emits the proper signal in which we either update the mission
    // or add as many elements as needed, then update the mission
    void update_mission(int mission_index,double lat,double lon,double alt_m,bool currently_active);
private:
    struct Element{
        int mission_index=0;
        double latitude;
        double longitude;
        double altitude_meter=0;
        // Set to true once we got valid lat / lon data for this mission item
        bool valid=false;
        // Set to true if this is the currently active mission
        bool currently_active=false;
    };
    enum Roles {
        IndexRole =Qt::UserRole,
        LatitudeRole,
        LongitudeRole,
        AltitudeRole,
        // This is set to true once we got lat / lon for this mission item -
        // The mission items in this model are sorted by the mission index
        ValidRole,
        // Currently active
        CurrentlyActiveRole
    };
    int rowCount(const QModelIndex& parent= QModelIndex()) const override;
    QVariant data( const QModelIndex& index, int role = Qt::DisplayRole ) const override;
    QHash<int, QByteArray> roleNames() const override;
public slots:
    //void removeData(int row);
    void addData(FCMavlinkMissionItemsModel::Element element);
    void updateData(int row, FCMavlinkMissionItemsModel::Element data);
private:
    QVector<FCMavlinkMissionItemsModel::Element> m_data;
public:
signals:
    void signal_qt_ui_update_element(int mission_index,double lat,double lon,double alt_m,bool currently_active);
private:
    // NOTE: NEEDS TO BE CALLED FROM QT UI THREAD (via signal)
    void qt_ui_update_element(int mission_index,double lat,double lon,double alt_m,bool currently_active);
    // Memory safety check
    static constexpr int MAX_N_ELEMENTS=200;
    // save performance if map is not enabled
    bool show_map=false;
};

#endif // FCMAVLINKMISSIONSMODEL_H
