#ifndef MavlinkSettingsModel_H
#define MavlinkSettingsModel_H

#include <QObject>
#include <QAbstractListModel>
#include <map>
#include <optional>

#include <mavsdk/mavsdk.h>
#include <mavsdk/plugins/param/param.h>

// A QT wrapper around the mavlink extended / non-extended parameters protocoll on the client
// (the side that changes parameter(s) provided by a specific system & component).
// For each of these components, you can use an instance of this class - see the singletons below for
// current OpenHD mavlink settings components.
class MavlinkSettingsModel : public QAbstractListModel
{
    Q_OBJECT
public:
    // R.N we have one instance for the camera (system air only and comp_id==camera0)
    // and one instance each for air and ground that does the rest (mostly interface)
    static MavlinkSettingsModel& instanceAirCamera();
    // general, air (mostly link)
    static MavlinkSettingsModel& instanceAir();
    // general, ground (mostly link)
    static MavlinkSettingsModel& instanceGround();

    // parameters that need to be synchronized are white-listed
    static std::map<std::string,void*> get_whitelisted_params();
    bool is_param_whitelisted(const std::string param_id);

    explicit MavlinkSettingsModel(uint8_t sys_id,uint8_t comp_id,QObject *parent = nullptr);
public:
    void set_param_client(std::shared_ptr<mavsdk::System> system);
private:
    std::shared_ptr<mavsdk::Param> param_client;
public:
    std::optional<int> try_fetch_param_int_impl(const QString param_id);

    // callable from QT
    Q_INVOKABLE bool try_fetch_all_parameters();

    Q_INVOKABLE bool try_fetch_parameter(QString param_id);

    Q_INVOKABLE bool try_update_parameter(const QString param_id,QVariant value);

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
