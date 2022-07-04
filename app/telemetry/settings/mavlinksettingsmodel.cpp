#include "mavlinksettingsmodel.h"
#include "qdebug.h"

MavlinkSettingsModel &MavlinkSettingsModel::instance()
{
    static MavlinkSettingsModel* instance=new MavlinkSettingsModel();
    return *instance;
}

MavlinkSettingsModel::MavlinkSettingsModel(QObject *parent)
    : QAbstractListModel(parent)
{
    m_data.push_back({"VIDEO_WIDTH",0});
    m_data.push_back({"VIDEO_HEIGHT",1});
    m_data.push_back({"VIDEO_FPS",1});
}

void MavlinkSettingsModel::try_update_parameter(QString param_id, qint32 value)
{
    qDebug()<<"try_update_parameter:"<<param_id<<","<<value;
}

int MavlinkSettingsModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;

    return m_data.count();
}

QVariant MavlinkSettingsModel::data(const QModelIndex &index, int role) const
{
    if ( !index.isValid() )
        return QVariant();

    const auto& data = m_data.at(index.row());
    if ( role == UniqueIdRole ){
        return data.unique_id;
    }
    else if ( role == ValueRole )
        return data.value;
    else
        return QVariant();
}

QHash<int, QByteArray> MavlinkSettingsModel::roleNames() const
{
    static QHash<int, QByteArray> mapping {
        {UniqueIdRole, "unique_id"},
        {ValueRole, "value"}
    };
    return mapping;
}


void MavlinkSettingsModel::removeData(int row)
{
    if (row < 0 || row >= m_data.count())
        return;

    beginRemoveRows(QModelIndex(), row, row);
    m_data.removeAt(row);
    endRemoveRows();
}

void MavlinkSettingsModel::addData(MavlinkSettingsModel::SettingData data)
{
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    m_data.push_back(data);
    endInsertRows();
}
