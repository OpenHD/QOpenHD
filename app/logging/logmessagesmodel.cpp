#include "logmessagesmodel.h"

#include <QByteArray>
#include <QTimer>
#include <cstdlib>

LogMessagesModel &LogMessagesModel::instance()
{
    static LogMessagesModel* instance=new LogMessagesModel();
    return *instance;
}

LogMessagesModel::LogMessagesModel(QObject *parent) :
    QAbstractListModel(parent)
{
    m_data
        << LogMessageData{"tag1", "qrc:images/denmark.jpg"}
        << LogMessageData{"tag2", "qrc:images/sweden.jpg"}
        << LogMessageData{"tag3", "qrc:images/iceland.jpg"};

    QTimer *growthTimer = new QTimer(this);
    connect(growthTimer, &QTimer::timeout, this, &LogMessagesModel::growPopulation);
    growthTimer->start(2000);
}

int LogMessagesModel::rowCount( const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;

    return m_data.count();
}

QVariant LogMessagesModel::data(const QModelIndex &index, int role) const
{
    if ( !index.isValid() )
        return QVariant();

    const LogMessageData &data = m_data.at(index.row());
    if ( role == TagRole ){
        return data.tag;
    }
    else if ( role == MessageRole )
        return data.message;
    else if ( role == TimestampRole )
        return data.timestamp;
    else if ( role == SeverityColorRole)
        return data.severity_color;
    else
        return QVariant();
}

//--> slide
QHash<int, QByteArray> LogMessagesModel::roleNames() const
{
    static QHash<int, QByteArray> mapping {
        {TagRole, "tag"},
        {MessageRole, "message"},
        {TimestampRole, "timestamp"},
        {SeverityColorRole,"severity_color"}
    };
    return mapping;
}
//<-- slide

void LogMessagesModel::duplicateData(int row)
{
    if (row < 0 || row >= m_data.count())
        return;

    const LogMessageData data = m_data[row];
    const int rowOfInsert = row + 1;

    beginInsertRows(QModelIndex(), rowOfInsert, rowOfInsert);
    m_data.insert(rowOfInsert, data);
    endInsertRows();
}

void LogMessagesModel::removeData(int row)
{
    if (row < 0 || row >= m_data.count())
        return;

    beginRemoveRows(QModelIndex(), row, row);
    m_data.removeAt(row);
    endRemoveRows();
}

void LogMessagesModel::growPopulation()
{
    /*const double growthFactor = 0.01 / RAND_MAX;

    const int count = m_data.count();
    for (int i = 0; i < count; ++i) {
        m_data[i].population += m_data[i].population * qrand() * growthFactor;
    }

    // we've just updated all rows...
    const QModelIndex startIndex = index(0, 0);
    const QModelIndex endIndex   = index(count - 1, 0);

    // ...but only the population field
    emit dataChanged(startIndex, endIndex, QVector<int>() << PopulationRole);*/
}
