#ifndef FCMISSIONHANDLER_H
#define FCMISSIONHANDLER_H

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

/**
 * Simple class to (semi-reliably) get all the mission waypoints from the FC and more.
 */
class FCMissionHandler: public QObject{
    Q_OBJECT
public:
    explicit FCMissionHandler(QObject *parent = nullptr);
    // singleton for accessing the model from c++
    static FCMissionHandler& instance();
    // Returns true if the message was "consumed" and does not need to be processed by anybody else, e.g. the main fc model
    bool process_message(const mavlink_message_t& msg);
    // Should be called every time a msg from the FC is received - this class takes care to not pollute the link
    void opt_send_messages();
    Q_INVOKABLE void resync();
public:
    // We expose some variables as read-only for the OSD+
    // NOTE: the description "waypoints" is not exactly accurate, left in for now due to legacy reasons though
    L_RO_PROP(int,mission_waypoints_current_total,set_mission_waypoints_current_total,-1);
    L_RO_PROP(int,mission_waypoints_current,set_mission_waypoints_current,-1);
    // Current mission type, verbose as string for the user
    L_RO_PROP(QString,mission_current_type,set_mission_current_type,"Unknown");
    // For the user to
    L_RO_PROP(QString,current_status,set_current_status,"N/A");
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
    static constexpr auto MAX_N_MISSION_ITEMS=200;
    std::chrono::steady_clock::time_point m_last_count_request=std::chrono::steady_clock::now();
    std::chrono::steady_clock::time_point m_last_item_request=std::chrono::steady_clock::now();
    bool m_has_mission_count=false;
    void update_mission_count(const mavlink_mission_count_t& mission_count);
    void update_mission(const mavlink_mission_item_int_t& item);
    void update_mission_current(const mavlink_mission_current_t& mission_current);
    // Needs to be called with lock locked !
    void recalculate_missing();
};

#endif // FCMISSIONHANDLER_H
