#ifndef RCCHANNELSMODEL_H
#define RCCHANNELSMODEL_H

#include <QAbstractItemModel>
#include <QObject>
#include <qtimer.h>

#include <memory>

#include "../../../lib/lqtutils_master/lqtutils_prop.h"

// The OpenHD ground instance for now broadcasts the rc channel value(s) to QOpenHD for display / debugging.
class RCChannelsModel : public  QAbstractListModel
{
  Q_OBJECT
 public :
    explicit RCChannelsModel(QObject * parent = 0);
    static RCChannelsModel& instanceGround();
    // Considered alive if we got data in the last X seconds
    L_RO_PROP(bool,is_alive,set_is_alive,false)
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
public slots:
    void updateData(int index,int value);
 private:
   QList<int> m_data{-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1};
private:
   std::chrono::steady_clock::time_point m_last_update{};
   std::unique_ptr<QTimer> m_alive_timer;
   void update_alive();
};

#endif // RCCHANNELSMODEL_H
