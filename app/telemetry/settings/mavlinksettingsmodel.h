#ifndef MavlinkSettingsModel_H
#define MavlinkSettingsModel_H

#include <QObject>
#include <QAbstractListModel>
#include <map>
#include <optional>
#include <thread>
#include <mutex>

#include "../util/mavlink_include.h"
#include "../../../lib/lqtutils_master/lqtutils_prop.h"

// A QT wrapper around the mavlink extended / non-extended parameters protocoll on the client
// (the side that changes parameter(s) provided by a specific system & component).
// For each of these components, you can use an instance of this class - see the singletons below for
// current OpenHD mavlink settings components.
// NOTE: R.n the enum / parameter validation needs to be duplicated in both OpenHD and QOpenHD.
// Eventually we'l migrate to the proper way, which is fetching something like this:
// https://github.com/mavlink/mavlink/blob/master/component_metadata/parameter.schema.json
// https://mavlink.io/en/services/parameter.html
class MavlinkSettingsModel : public QAbstractListModel
{
    Q_OBJECT
public:
    // R.N we have one or two instances for the camera(s) (system air only and comp_id==camera0)
    // and one instance each for air and ground that does the rest (mostly interface)
    static MavlinkSettingsModel& instanceAirCamera();
    static MavlinkSettingsModel& instanceAirCamera2();
    // general, air (mostly link)
    static MavlinkSettingsModel& instanceAir();
    // general, ground (mostly link)
    static MavlinkSettingsModel& instanceGround();
    // TODO theoretically, we could allow the user to change parameters on the FC itself
    // (aka what for example mission planner would show)
    //static MavlinkSettingsModel& instanceFC();
    explicit MavlinkSettingsModel(uint8_t sys_id,uint8_t comp_id,QObject *parent = nullptr);
public:
    L_RO_PROP(int, curr_get_all_progress_perc,set_curr_get_all_progress_perc,-1);
    // NOTE: This is only for the UI, not for c++ usage (non-atomic)
    L_RO_PROP(bool,ui_is_busy,set_ui_is_busy,false)
public:
    void set_ready();
public:
    // callable from QT.
    // async with progress bar and result being prompted to the user
    // re-fetches the complete param set - any changed values, types, ... are catched from it
    Q_INVOKABLE void try_refetch_all_parameters_async(bool log_result=true);

    // first updates the parameter on the server via XParam (unless server rejects / rare timeout)
    // then updates the internal cached parameter
    // return is kinda dirty, but since we use it from QML - returns an empty string "" on success, an error code otherwise
    Q_INVOKABLE QString try_update_parameter_int(const QString param_id,int value);
    Q_INVOKABLE QString try_update_parameter_string(const QString param_id,QString value);

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
        // A description for this parameter. Not all parameters are documented yet, in this case this will return "TODO"
        ShortDescriptionRole,
        // Weather this parameter is read-only (we repurpose the malink parameter protocoll in this regard here)
        // Default false, only if a parameter is in the read-only whitelist it is marked as read-only
        ReadOnlyRole,
        // Weather this parameter is whitelisted
        WhitelistedRole
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
    };
public slots:
    void removeData(int row);
    void updateData(std::optional<int> row,MavlinkSettingsModel::SettingData new_data);
    void addData(MavlinkSettingsModel::SettingData data);
private:
    QVector<MavlinkSettingsModel::SettingData> m_data;
    const uint8_t m_sys_id;
    const uint8_t m_comp_id;
    bool is_param_whitelisted(const std::string param_id)const;
    enum class SetParamResult{
        BUSY, // Too many params queued up
        NO_CONNECTION, // Most likely all retransmitts failed, cannot be completely avoided
        VALUE_UNSUPPORTED, // (openhd) rejected the param value, it is not valid / not supported by the HW
        SUCCESS, //Param was successfully updated
    };
    static std::string set_param_result_as_string(const SetParamResult& res);
    SetParamResult try_set_param_int_impl(const QString param_id,int value);
    SetParamResult try_set_param_string_impl(const QString param_id,QString value);
public:
    struct ParamIntEnum{
        bool valid;
        QStringList keys;
        QList<int>  values;
    };
    struct ParamStringEnum{
        bool valid;
        QStringList keys;
        QStringList values;
    };
public:
    // These are for the UI to query more data about a specific params
    Q_INVOKABLE QString int_enum_get_readable(QString param_id,int value)const;
    Q_INVOKABLE QString string_enum_get_readable(QString param_id,QString value)const;
    // if possible, the UI should populate for a full enum key-value int parameter if possible,
    // and only fall back to the min max checking if such a mapping is not available.
    Q_INVOKABLE bool int_param_has_min_max(QString param_id)const;
    Q_INVOKABLE int int_param_get_min_value(QString param_id)const;
    Q_INVOKABLE int int_param_get_max_value(QString param_id)const;
    // enum key - value mapping
    Q_INVOKABLE bool int_param_has_enum_keys_values(QString param_id)const;
    // TODO find a better solution
    // R.n we return 2 lists of the same size (strings for the keys, ints for the values that correspond to the keys)
    //aka both lists always have the same size
    // Should only be called when we actually have an enum mapping for this param
    Q_INVOKABLE QStringList int_param_get_enum_keys(QString param_id)const;
    Q_INVOKABLE QList<int> int_param_get_enum_values(QString param_id)const;
    Q_INVOKABLE ParamIntEnum int_param_get_enum(QString param_id)const;

    // similar to above, find a better solution
    Q_INVOKABLE bool string_param_has_enum(QString param_id)const;
    Q_INVOKABLE QStringList string_param_get_enum_keys(QString param_id)const;
    Q_INVOKABLE QStringList string_param_get_enum_values(QString param_id)const;
    Q_INVOKABLE ParamStringEnum string_param_get_enum(QString param_id)const;

    // For some parameters, we have a string that is displayed to the user when he wants to edit this param
    // just too be sure he understands the risks
    // When there is no need for a warning, this method just returns an empty string
    Q_INVOKABLE QString get_warning_before_safe(QString param_id);

    Q_INVOKABLE bool get_param_requires_manual_reboot(QString param_id);
private:
    void remove_and_replace_param_set(const std::vector<mavlink_param_ext_value_t>& param_set);
public:
    struct QtParamValue{
        QString param_id;
        QVariant param_value;
        int type;
    };
    struct QtParamSet{
        QVector<QtParamValue> param_set;
    };
    //void ui_thread_replace_param_set(QVector<QtParamValue> param_set);
    void ui_thread_replace_param_set(QtParamSet param_set);
signals:
    void signal_ui_thread_replace_param_set(QtParamSet param_set);
private:
    std::atomic<bool> m_is_ready=false;
    std::atomic_bool m_is_currently_busy=false;
};

Q_DECLARE_METATYPE(MavlinkSettingsModel::ParamIntEnum);
Q_DECLARE_METATYPE(MavlinkSettingsModel::ParamStringEnum);
Q_DECLARE_METATYPE(MavlinkSettingsModel::QtParamValue);
Q_DECLARE_METATYPE(MavlinkSettingsModel::QtParamSet);

#endif // MavlinkSettingsModel_H
