#include "../../inc/telemetry/statuslogmodel.h"


static StatusLogModel* _instance = nullptr;

StatusLogModel* StatusLogModel::instance() {
    if (_instance == nullptr) {
        _instance = new StatusLogModel();
    }
    return _instance;
}


StatusLogModel::StatusLogModel(QObject *parent) {
    qDebug() << "StatusLogModel::StatusLogModel()";
}


void StatusLogModel::addMessage(StatusMessage message) {
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    m_messages.append(message);
    endInsertRows();
}


int StatusLogModel::rowCount(const QModelIndex & parent) const {
    Q_UNUSED(parent)
    return m_messages.count();
}


int StatusLogModel::columnCount(const QModelIndex &parent) const {
    Q_UNUSED(parent);
    return 5;
}


QHash<int, QByteArray> StatusLogModel::roleNames() const {
    QHash<int, QByteArray> roles;

    roles[0] = "message";
    roles[1] = "sysid";
    roles[2] = "compid";
    roles[3] = "severity";
    roles[4] = "timestamp";

    return roles;
}


QVariant StatusLogModel::data(const QModelIndex &index, int role) const {

    if (index.row() < 0 || index.row() >= m_messages.size()) {
        return QVariant();
    }

    const StatusMessage entry = m_messages[index.row()];

    if (role == 0) {
        return QVariant::fromValue(entry.message);
    } else if (role == 1) {
        return QVariant::fromValue(entry.sysid);
    } else if (role == 2) {
        return QVariant::fromValue(entry.compid);
    } else if (role == 3) {
        return QVariant::fromValue(entry.severity);
    } else if (role == 4) {
        return QVariant::fromValue(entry.timestamp);
    }

    return QVariant();
}
