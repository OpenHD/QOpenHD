#ifndef RCCHANNELSMODEL_H
#define RCCHANNELSMODEL_H

#include <QAbstractItemModel>
#include <QObject>

class RCChannelsModel : public  QAbstractListModel
{
  Q_OBJECT
 public :
    explicit RCChannelsModel(QObject * parent = 0);
    static RCChannelsModel& instanceGround();
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
};

#endif // RCCHANNELSMODEL_H
