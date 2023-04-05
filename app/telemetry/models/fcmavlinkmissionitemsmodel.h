#ifndef FCMAVLINKMISSIONSMODEL_H
#define FCMAVLINKMISSIONSMODEL_H

#include <QAbstractListModel>
#include <QVector>
#include <map>
#include <qtimer.h>
#include <utility>


// To not pollute the FCMavlinkSystem model class too much, we have an extra model for managing the
// dynamically sized mission waypoints. ("Map stuff)
// This model pretty much only exposes mission items (dynamic size) such that we can make use of them
// (draw them in .qml) for the map.
// each mission item is pretty much really easy to define - a lattitude and longitude
class FCMavlinkMissionItemsModel : public QAbstractListModel
{
    Q_OBJECT
public:
    explicit FCMavlinkMissionItemsModel(QObject *parent = nullptr);
    static FCMavlinkMissionItemsModel& instance();
    struct Element{
        double latitude;
        double longitude;
    };
    Q_INVOKABLE void add_element(FCMavlinkMissionItemsModel::Element el);
    // To avoid duplicates, we keep a map of already added mission waypoints and only add them if they don't exist already
    void hack_add_el_if_nonexisting(double lat,double lon);
    void test_add();
private:
    enum Roles {
        LatitudeRole =Qt::UserRole,
        LongitudeRole
    };
    int rowCount(const QModelIndex& parent= QModelIndex()) const override;
    QVariant data( const QModelIndex& index, int role = Qt::DisplayRole ) const override;
    QHash<int, QByteArray> roleNames() const override;
    // workaround signals
    void do_not_call_me_add_element(double lat,double lon);
public slots:
    void removeData(int row);
    void addData(FCMavlinkMissionItemsModel::Element logMessageData);
private:
    QVector<FCMavlinkMissionItemsModel::Element> m_data;
public:
signals:
    void signalAddElement(double lat,double lon);
private:
    std::map<std::pair<double,double>,void*> m_map;
    double last=0;
    QTimer* m_timer = nullptr;
    void timercb();
};

#endif // FCMAVLINKMISSIONSMODEL_H
