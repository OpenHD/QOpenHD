#ifndef RCCHANNELSMODEL_H
#define RCCHANNELSMODEL_H

#include <QAbstractItemModel>
#include <QObject>
#include <qtimer.h>
#include <array>

#include <memory>
#include <mutex>

#include "../../../lib/lqtutils_master/lqtutils_prop.h"

// Don't get confused - we have 2 instances of this model:
// instanceGround()-> The OpenHD ground instance for now broadcasts the rc channel value(s) to QOpenHD for display / debugging.
// Aka these are the same channels that are sent to the FC as MAVLINK_MSG_ID_RC_CHANNELS_OVERRIDE
// instanceFC() -> Some FCs (for example ARDUPILOT) broadcast the current rc channel values. Aka this could be what's set via MAVLINK_MSG_ID_RC_CHANNELS_OVERRIDE  but
// otherwise is most likely what the FC gets from an RC receiver connected via serial for example.
// Both are valuable information for debugging
class RCChannelsModel : public  QAbstractListModel
{
  Q_OBJECT
 public :
    explicit RCChannelsModel(QObject * parent = 0);
    static RCChannelsModel& instanceGround();
    static RCChannelsModel& instanceFC();
    // Considered alive if we got an update in the last X seconds
    L_RO_PROP(bool,is_alive,set_is_alive,false)
    // This is extra for the "controls" widget
    // Assumes AETR
    L_RO_PROP(double,control_yaw,set_control_yaw,-1)
    L_RO_PROP(double,control_roll,set_control_roll,-1)
    L_RO_PROP(double,control_pitch,set_control_pitch,-1)
    L_RO_PROP(double,control_throttle,set_control_throttle,-1)
public:
    enum Roles {
        // The current value for this channel
        CurrValueRole = Qt::UserRole,
    };
    int rowCount(const QModelIndex& parent= QModelIndex()) const override;
    QVariant data( const QModelIndex& index, int role = Qt::DisplayRole ) const override;
    QHash<int, QByteArray> roleNames() const override;
    using RC_CHANNELS=std::array<int,18>;
    void update_all_channels(const RC_CHANNELS& channels);
    // Sets the first channel to 1000 and adds 20 to all the remaining channels (ascending)
    void set_channels_debug();
public slots:
    void updateData(int index,int value);
 private:
   QList<int> m_data{-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1};
private:
   // We need thread saftey on the alive
   std::atomic<int64_t> m_last_update_ms = -1;
   std::unique_ptr<QTimer> m_alive_timer;
   void update_alive();
};

#endif // RCCHANNELSMODEL_H
