#ifndef MavlinkSettingsModel_H
#define MavlinkSettingsModel_H

#include <QObject>
#include <QAbstractListModel>


// A qt wrapper around the mavlink extended / non-extended parameters protocoll.
// Each settings component the user wants to change requires a new instance of this class.
class MavlinkSettingsModel : public QAbstractListModel
{
    Q_OBJECT
public:
    static MavlinkSettingsModel& instance();
    explicit MavlinkSettingsModel(QObject *parent = nullptr);
public:
    void fetch_all_parameters();
    //
    Q_INVOKABLE void try_update_parameter(QString param_id,qint32 value);

    enum Roles {
        UniqueIdRole = Qt::UserRole,
        ValueRole
    };
    int rowCount(const QModelIndex& parent= QModelIndex()) const override;
    QVariant data( const QModelIndex& index, int role = Qt::DisplayRole ) const override;
    QHash<int, QByteArray> roleNames() const override;
    struct SettingData{
        QString unique_id;
        qint32 value;
    };
public slots:
    void removeData(int row);
    void addData(MavlinkSettingsModel::SettingData data);
private:
    QVector< MavlinkSettingsModel::SettingData > m_data;
};

#endif // MavlinkSettingsModel_H
