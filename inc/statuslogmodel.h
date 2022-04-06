#ifndef STATUSLOGMODEL_H
#define STATUSLOGMODEL_H

#include <QObject>
#include <QtQuick>

#include "mavlinkbase.h"


// matches struct defined in OpenHDMicroservice::StatusMicroservice
struct StatusMessage {
    QString message;
    int sysid;
    int compid;
    int severity;
    uint64_t timestamp;
};


class StatusLogModel : public QAbstractListModel {
    Q_OBJECT

public:
    explicit StatusLogModel(QObject *parent = nullptr);

    static StatusLogModel* instance();


    void addMessage(StatusMessage message);

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    int columnCount(const QModelIndex &parent = QModelIndex()) const;
    //QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const;
    //QModelIndex parent(const QModelIndex &child) const;

protected :
      QHash<int, QByteArray> roleNames() const;

private:
    QList<StatusMessage> m_messages;
};

#endif // STATUSLOGMODEL_H
