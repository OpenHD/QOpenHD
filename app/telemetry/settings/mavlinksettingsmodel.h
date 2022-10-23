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
    bool is_param_whitelisted(const std::string param_id)const;
    // workaround read only
    bool is_param_read_only(const std::string param_id)const;

    explicit MavlinkSettingsModel(uint8_t sys_id,uint8_t comp_id,QObject *parent = nullptr);
public:
    void set_param_client(std::shared_ptr<mavsdk::System> system);
private:
    std::shared_ptr<mavsdk::Param> param_client;
public:
    // Fetch a param value using mavsdk. Returns std::nullopt on failure,
    // The param value otherwise.
    // Does not update the cached parameter !
    std::optional<int> try_get_param_int_impl(const QString param_id);
    std::optional<std::string> try_get_param_string_impl(const QString param_id);
    // Set a param value using mavsd. This means we send the "SET" command to the server
    // and get its response (ok or rejected) or - in rare -cases - timeout.
    // Returns true on success, false otherwise
    bool try_set_param_int_impl(const QString param_id,int value);
    bool try_set_param_string_impl(const QString param_id,QString value);

    // callable from QT.
    // re-fetch all parameters from the server. Clears the cache, then re-fetches the whole parameter set.
    Q_INVOKABLE bool try_fetch_all_parameters();
    // re-fetch a specific parameter from the server, Updates the parameter set accordingly.
    Q_INVOKABLE bool try_refetch_parameter_int(QString param_id);
    Q_INVOKABLE bool try_refetch_parameter_string(QString param_id);

    // updates the parameter on the server (unless server rejects / rare timeout)
    // then updates the internal cached parameter, if successfull.
    Q_INVOKABLE bool try_update_parameter_int(const QString param_id,int value);
    Q_INVOKABLE bool try_update_parameter_string(const QString param_id,QString value);
    // dirty
    Q_INVOKABLE bool try_parse_and_update_parameter_int(const QString param_id,QVariant value){
        if(value.canConvert(QVariant::Type::Int)){
            const int value_int=value.toInt();
            return try_update_parameter_int(param_id,value_int);
        }
        return false;
    }

    enum Roles {
        // The unique string id of this param
        UniqueIdRole = Qt::UserRole,
        // The value of this param, can be int or std::string (returns qint or qstring)
        ValueRole,
        // if possible, convert the internal value (e.g. a integer that responds to an enum) to a more readable
        // value, e.g. the string for this enum.
        // In case the param is an int and we don't have enum mapping -> return the int as an string
        // In case the param is an int and we do have enum mapping -> convert the int to the enum string, then return
        // In case the param is an string, just return the string
        ExtraValueRole,
        // The internally stored type. 0==int, 1==std::string
        ValueTypeRole,
        // A description for this parameter. Not all parameters are documented yet, in this case this will return "?"
        ShortDescriptionRole,
        // Weather this parameter is read-only (we repurpose the malink parameter protocoll in this regard here)
        // Default true, only if a parameter is in the read-only whitelist it is marked as read-only
        ReadOnlyRole
    };
    int rowCount(const QModelIndex& parent= QModelIndex()) const override;
    QVariant data( const QModelIndex& index, int role = Qt::DisplayRole ) const override;
    QHash<int, QByteArray> roleNames() const override;
    struct SettingData{
        // The unique parameter identifier
        QString unique_id;
        // We support int and string values - NOTHING ELSE ! Please keep it this way, there are reasons for it.
        // On a side node, PX4 / ardupilot do it the same !
        std::variant<int32_t,std::string> value;
        //qint32 value;
    };
public slots:
    void removeData(int row);
    void updateData(std::optional<int> row,MavlinkSettingsModel::SettingData new_data);
    void addData(MavlinkSettingsModel::SettingData data);
private:
    QVector<MavlinkSettingsModel::SettingData> m_data;
    const uint8_t _sys_id;
    const uint8_t _comp_id;
public:
    // These are for the UI to query more data about a specific param
    Q_INVOKABLE bool has_int_enum_mapping(QString param_id)const;
    Q_INVOKABLE QString int_enum_get_readable(QString param_id,int value)const;
    Q_INVOKABLE int int_enum_get_max(QString param_id)const;
    Q_INVOKABLE int int_enum_get_min(QString param_id)const;
};

#endif // MavlinkSettingsModel_H
