#ifndef MavlinkSettingsModel_H
#define MavlinkSettingsModel_H

#include <QObject>
#include <QAbstractListModel>

#ifndef X_USE_MAVSDK
#define X_USE_MAVSDK
#endif

#ifdef X_USE_MAVSDK
#include <mavsdk/mavsdk.h>
#include <mavsdk/plugins/param/param.h>
#endif //X_USE_MAVSDK

// A qt wrapper around the mavlink extended / non-extended parameters protocoll.
// Each settings component the user wants to change requires a new instance of this class.
class MavlinkSettingsModel : public QAbstractListModel
{
    Q_OBJECT
public:
    // R.N we have one instance for the camera (system air and comp_id==camera0)
    // and one instance each for air and ground that does the rest (mostly interface)
    static MavlinkSettingsModel& instanceAirCamera();
    // general, air (mostly link)
    static MavlinkSettingsModel& instanceAir();
    // general, ground (mostly link)
    static MavlinkSettingsModel& instanceGround();

    explicit MavlinkSettingsModel(uint8_t sys_id,uint8_t comp_id,QObject *parent = nullptr);
#ifdef X_USE_MAVSDK
public:
    void set_param_client(std::shared_ptr<mavsdk::System> system);
private:
    std::shared_ptr<mavsdk::Param> param_client;
#endif
public:
    Q_INVOKABLE bool try_fetch_all_parameters();

    Q_INVOKABLE void try_fetch_parameter(QString param_id);

    Q_INVOKABLE void try_update_parameter(const QString param_id,QVariant value);

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
    void updateData(std::optional<int> row,MavlinkSettingsModel::SettingData new_data);
    void addData(MavlinkSettingsModel::SettingData data);
private:
    QVector<MavlinkSettingsModel::SettingData> m_data;
    const uint8_t _sys_id;
    const uint8_t _comp_id;
};

#endif // MavlinkSettingsModel_H
