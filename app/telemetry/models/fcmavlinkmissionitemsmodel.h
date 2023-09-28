#ifndef FCMAVLINKMISSIONSMODEL_H
#define FCMAVLINKMISSIONSMODEL_H

#include <QAbstractListModel>
#include <QVector>
#include <map>
#include <mutex>
#include <utility>
#include <vector>
#include <mutex>
#include <optional>

// NOTE: Even though placed here, this model is updated by mission handler (which deals with all the nasty reordering, requesting, ...) stuff
// This model INTENTIONALLY only offers the following public functionalities:
// initialize: Set a new size / count of mission (waypoints / items), resets all elements
// update: update a (valid) mission item by index.
// This way the changes that need to be propagated via QT are minimal - a reset only happens once the total mission count is known / changes (rarely)
// And an update is a relatively light operation.
class FCMavlinkMissionItemsModel : public QAbstractListModel
{
    Q_OBJECT
public:
    explicit FCMavlinkMissionItemsModel(QObject *parent = nullptr);
    static FCMavlinkMissionItemsModel& instance();
    // This model INTENTIONALLY only offers the following public functionalities:
    // initialize: Set a new size / count of mission (waypoints / items), resets all elements
    // update: update a (valid) mission item by index.
    // This way the changes that need to be propagated via QT are minimal - a reset only happens once the total mission count is known / changes (rarely)
    // And an update is a relatively light operation.
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
};

#endif // FCMAVLINKMISSIONSMODEL_H
