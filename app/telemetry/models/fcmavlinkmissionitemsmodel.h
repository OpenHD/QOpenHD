#ifndef FCMAVLINKMISSIONSMODEL_H
#define FCMAVLINKMISSIONSMODEL_H

#include <QAbstractListModel>
#include <QVector>
#include <map>
#include <mutex>
#include <qtimer.h>
#include <utility>
#include <vector>
#include <mutex>
#include <optional>

#include "../../../lib/lqtutils_master/lqtutils_prop.h"

#include "../util/mavlink_include.h"

class FCMavlinkMissionHandler: public QObject{
    Q_OBJECT
public:
    explicit FCMavlinkMissionHandler(QObject *parent = nullptr);
    // singleton for accessing the model from c++
    static FCMavlinkMissionHandler& instance();
    void process_message(const mavlink_message_t& msg);

    void opt_send_messages();
public:
    // We expose some variables as read-only for the OSD
    // TODO: We have 2 variables for the OSD to show - the current total n of waypoints and the current waypoint the FC is at. Depending on how things are broadcasted,
    // The user might have to manually request the current total n of waypoints
    // NOTE: the description "waypoints" is not exactly accurate, left in for now due to legacy reasons though
    L_RO_PROP(int,mission_waypoints_current_total,set_mission_waypoints_current_total,-1);
    L_RO_PROP(int,mission_waypoints_current,set_mission_waypoints_current,-1);
    // Current mission type, verbose as string for the user
    L_RO_PROP(QString,mission_current_type,set_mission_current_type,"Unknown");
private:
    struct MItem{
        int mission_index=0;
        double latitude;
        double longitude;
        double altitude_meter=0;
        // Set to true once we got an update for this mission item
        bool updated=false;
    };
    std::mutex m_mutex;
    std::vector<MItem> m_mission_items;
    std::vector<int> m_missing_items;
    void update_mission_count(const mavlink_mission_count_t& mission_count);
    void update_mission(const mavlink_mission_item_int_t& item);
    void update_mission_current(const mavlink_mission_current_t& mission_current);
    static constexpr auto MAX_N_MISSION_ITEMS=200;
    std::chrono::steady_clock::time_point m_last_count_request=std::chrono::steady_clock::now();
    std::chrono::steady_clock::time_point m_last_item_request=std::chrono::steady_clock::now();
    bool m_has_mission_count=false;
    // Needs to be called with lock locked !
    void recalculate_missing();
};

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
    //
    void p_initialize(int total_mission_count);
    void p_update(int mission_index,double lat,double lon,double alt_m);
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
    void signal_qt_ui_resize(int total_mission_count);
private:
    // NOTE: NEEDS TO BE CALLED FROM QT UI THREAD (via signal)
    void qt_ui_update_element(int mission_index,double lat,double lon,double alt_m,bool currently_active);
    void qt_ui_resize(int total_mission_count);
    // Memory safety check
    static constexpr int MAX_N_ELEMENTS=200;
    // save performance if map is not enabled
    bool show_map=false;
};

#endif // FCMAVLINKMISSIONSMODEL_H
