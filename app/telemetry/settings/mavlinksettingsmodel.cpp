#include "mavlinksettingsmodel.h"
#include "qdebug.h"
#include "documentedparam.h"

#include "../../util/WorkaroundMessageBox.h"
#include "improvedintsetting.h"
#include "improvedstringsetting.h"
#include "util/openhd_defines.hpp"

#include <QSettings>
#include <QVariant>

#include "../action/impl/xparam.h"

MavlinkSettingsModel &MavlinkSettingsModel::instanceAirCamera()
{
    static MavlinkSettingsModel* instanceAirCamera=new MavlinkSettingsModel(OHD_SYS_ID_AIR,OHD_COMP_ID_AIR_CAMERA_PRIMARY);
    return *instanceAirCamera;
}

MavlinkSettingsModel &MavlinkSettingsModel::instanceAirCamera2()
{
    static MavlinkSettingsModel instanceAirCamera2{OHD_SYS_ID_AIR, OHD_COMP_ID_AIR_CAMERA_SECONDARY};
    return instanceAirCamera2;
}

MavlinkSettingsModel &MavlinkSettingsModel::instanceAir()
{
    static MavlinkSettingsModel* instanceAir=new MavlinkSettingsModel(OHD_SYS_ID_AIR,OHD_COMP_ID_LINK_PARAM);
    return *instanceAir;
}
MavlinkSettingsModel &MavlinkSettingsModel::instanceGround()
{
    static MavlinkSettingsModel* instanceGround=new MavlinkSettingsModel(OHD_SYS_ID_GROUND,OHD_COMP_ID_LINK_PARAM);
    return *instanceGround;
}

/*MavlinkSettingsModel &MavlinkSettingsModel::instanceFC()
{
    static MavlinkSettingsModel* instanceFc=new MavlinkSettingsModel(1,1);
    return *instanceFc;
}*/

bool MavlinkSettingsModel::is_param_whitelisted(const std::string param_id)const
{
    QSettings settings;
    const auto dev_show_whitelisted_params =settings.value("dev_show_whitelisted_params", false).toBool();
    if(dev_show_whitelisted_params){
        // no param whitelisted
        return false;
    }
    if(param_id.empty()){
        return false;
    }
    return DocumentedParam::is_param_whitelisted(param_id);
}

MavlinkSettingsModel::MavlinkSettingsModel(uint8_t sys_id,uint8_t comp_id,QObject *parent)
    : QAbstractListModel(parent),m_sys_id(sys_id),m_comp_id(comp_id)
{
    qRegisterMetaType<MavlinkSettingsModel::ParamIntEnum>("ParamIntEnum");
    qRegisterMetaType<MavlinkSettingsModel::ParamStringEnum>("ParamStringEnum");

    qRegisterMetaType<MavlinkSettingsModel::QtParamValue>("QtParamValue");
    qRegisterMetaType<MavlinkSettingsModel::QtParamSet>("QtParamSet");
    //m_data.push_back({"VIDEO_WIDTH",0});
    //m_data.push_back({"VIDEO_HEIGHT",1});
    //m_data.push_back({"VIDEO_FPS",1});
    connect(this, &MavlinkSettingsModel::signal_ui_thread_replace_param_set, this, &MavlinkSettingsModel::ui_thread_replace_param_set);
}

void MavlinkSettingsModel::set_ready()
{
    m_is_ready=true;
}

void MavlinkSettingsModel::try_refetch_all_parameters_async(bool log_result)
{
    qDebug()<<"MavlinkSettingsModel::try_fetch_all_parameters()";
    if(!m_is_ready){
        // not discovered yet
        if(log_result)WorkaroundMessageBox::makePopupMessage("OHD System not found",2);
        return;
    }
    if(m_is_currently_busy){
        if(log_result)WorkaroundMessageBox::makePopupMessage("Busy, please try again later",2);
        return;
    }
    // Fetch the full param set from the server (defined by sys / comp id)
    /*auto param_set_opt=XParam::instance().try_get_param_all_blocking(m_sys_id,m_comp_id);
    if(param_set_opt.has_value()){
        const auto param_set=param_set_opt.value();
        remove_and_replace_param_set(param_set);
        WorkaroundMessageBox::makePopupMessage("Fetch all success",2);
    }else{
        WorkaroundMessageBox::makePopupMessage("Fetch all failed",2);
    }*/
    m_is_currently_busy=true;
    set_ui_is_busy(true);
    set_curr_get_all_progress_perc(0);
    auto cb=[this,log_result](XParam::GetAllParamResult result){
        if(result.success){
            const auto param_set=result.param_set;
            remove_and_replace_param_set(param_set);
            if(log_result)WorkaroundMessageBox::makePopupMessage("Fetch all success",2);
        }else{
            if(log_result)WorkaroundMessageBox::makePopupMessage("Fetch all failed, please check your up / downlink.",2);
        }
        m_is_currently_busy=false;
        set_ui_is_busy(false);
    };
    auto cb_progress=[this](float progress){
        const int progress_int=std::lroundf(progress);
        set_curr_get_all_progress_perc(progress_int);
        //qDebug()<<"Progress:"<<progress<<"%";
    };
    const auto command=XParam::create_cmd_get_all(m_sys_id,m_comp_id);
    XParam::instance().try_get_param_all_async(command,cb,cb_progress);
}

std::string MavlinkSettingsModel::set_param_result_as_string(const SetParamResult &res)
{
    if(res==SetParamResult::NO_CONNECTION)return "NO_CONNECTION";
    if(res==SetParamResult::VALUE_UNSUPPORTED)return "VALUE_UNSUPPORTED";
    if(res==SetParamResult:: SUCCESS)return " SUCCESS";
    return "UNKNOWN";
}

MavlinkSettingsModel::SetParamResult MavlinkSettingsModel::try_set_param_int_impl(const QString param_id, int value)
{
    auto command=XParam::create_cmd_set_int(m_sys_id,m_comp_id,param_id.toStdString(),value);
    m_is_currently_busy=true;
    const auto result=XParam::instance().try_set_param_blocking(command);
    m_is_currently_busy=false;
    return result ? SetParamResult::SUCCESS : SetParamResult::NO_CONNECTION;
}

MavlinkSettingsModel::SetParamResult MavlinkSettingsModel::try_set_param_string_impl(const QString param_id,QString value)
{
    auto command=XParam::create_cmd_set_string(m_sys_id,m_comp_id,param_id.toStdString(),value.toStdString());
    m_is_currently_busy=true;
    const auto result=XParam::instance().try_set_param_blocking(command);
    m_is_currently_busy=false;
    return result ? SetParamResult::SUCCESS : SetParamResult::NO_CONNECTION;
}

QString MavlinkSettingsModel::try_update_parameter_int(const QString param_id,int value)
{
    qDebug()<<"try_update_parameter_int:"<<param_id<<","<<value;
    const auto result=try_set_param_int_impl(param_id,value);
    if(result==SetParamResult::SUCCESS){
        MavlinkSettingsModel::SettingData tmp{param_id,value};
        updateData(std::nullopt,tmp);
        return "";
    }
    qDebug()<<"Failure code:"<<set_param_result_as_string(result).c_str();
    if(result==SetParamResult::VALUE_UNSUPPORTED){
        std::stringstream ss;
        ss<<"Your HW does not support "<<param_id.toStdString()<<"="<<value;
        return ss.str().c_str();
    }
    if(result==SetParamResult::NO_CONNECTION){
        return "Update failed,please try again";
    }
    return "Update failed, unknown error";
}

QString MavlinkSettingsModel::try_update_parameter_string(const QString param_id,QString value)
{
    qDebug()<<"try_update_parameter_string:"<<param_id<<","<<value;
    const auto result=try_set_param_string_impl(param_id,value);
    if(result==SetParamResult::SUCCESS){
        MavlinkSettingsModel::SettingData tmp{param_id,value.toStdString()};
        updateData(std::nullopt,tmp);
        return "";
    }
    qDebug()<<"Failure code:"<<set_param_result_as_string(result).c_str();
    if(result==SetParamResult::VALUE_UNSUPPORTED){
        std::stringstream ss;
        ss<<"Your HW does not support "<<param_id.toStdString()<<"="<<value.toStdString();
        return ss.str().c_str();
    }
    if(result==SetParamResult::NO_CONNECTION){
        return "Update failed,please try again";
    }
    return "Update failed, unknown error";
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
    else if ( role == ValueRole ){
        if(std::holds_alternative<int32_t>(data.value)){
            return std::get<int32_t>(data.value);
        }
        // We have either string or int, but assert to make it clear to someone reading the code
        assert(std::holds_alternative<std::string>(data.value));
        return QString(std::get<std::string>(data.value).c_str());
   } else if (role==ExtraValueRole){
        if(std::holds_alternative<int>(data.value)){
            auto value=std::get<int>(data.value);
            return int_enum_get_readable(data.unique_id,value);
        }
        // We only support int and string
        assert(std::holds_alternative<std::string>(data.value));
        auto value=std::get<std::string>(data.value);
        return string_enum_get_readable(data.unique_id,value.c_str());
    } else if (role==ValueTypeRole){
        if(std::holds_alternative<int>(data.value)){
            return 0;
        }
        return 1;
    } else if(role == ShortDescriptionRole){
        QString ret=DocumentedParam::get_short_description(data.unique_id.toStdString()).c_str();
        return ret;
    } else if(role ==ReadOnlyRole){
        return DocumentedParam::read_only(data.unique_id.toStdString());
    }
    else
        return QVariant();
}

QHash<int, QByteArray> MavlinkSettingsModel::roleNames() const
{
    static QHash<int, QByteArray> mapping {
        {UniqueIdRole, "unique_id"},
        {ValueRole, "value"},
        {ExtraValueRole, "extraValue"},
        {ValueTypeRole,"valueType"},
        {ShortDescriptionRole,"shortDescription"},
        {ReadOnlyRole,"read_only"}
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


void MavlinkSettingsModel::updateData(std::optional<int> row_opt, SettingData new_data)
{
    int row=-1;
    if(row_opt.has_value()){
        row=row_opt.value();
    }else{
        // We need to find the row index for the given string id
        for(int i=0;i<m_data.size();i++){
            if(m_data.at(i).unique_id==new_data.unique_id){
                row=i;
                break;
            }
        }
    }
    if (row < 0 || row >= m_data.count()){
         // Param does not exst
         return;
    }
    if(m_data.at(row).unique_id!=new_data.unique_id){
        qDebug()<<"Argh";
        return;
    }
    m_data[row]=new_data;
    QModelIndex topLeft = createIndex(row,0);
    emit dataChanged(topLeft, topLeft);
}

void MavlinkSettingsModel::addData(MavlinkSettingsModel::SettingData data)
{
    if(is_param_whitelisted(data.unique_id.toStdString())){
        // never add whitelisted params to the simple model, they need synchronization
        return;
    }
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    m_data.push_back(data);
    endInsertRows();
}

QString MavlinkSettingsModel::int_enum_get_readable(QString param_id, int value)const
{
    auto as_enum=DocumentedParam::int_param_to_enum_string_if_known(param_id.toStdString(),value);
    if(as_enum.has_value()){
        return QString(as_enum.value().c_str());
    }
    std::stringstream ss;
    ss<<"{"<<value<<"}";
    return QString(ss.str().c_str());
}

QString MavlinkSettingsModel::string_enum_get_readable(QString param_id,QString value) const
{
    auto as_enum=DocumentedParam::string_param_to_enum_string_if_known(param_id.toStdString(),value.toStdString());
    if(as_enum.has_value()){
        return QString(as_enum.value().c_str());
    }
    std::stringstream ss;
    ss<<"{"<<value.toStdString()<<"}";
    return QString(ss.str().c_str());
}

bool MavlinkSettingsModel::int_param_has_min_max(QString param_id) const
{
    const auto improved_opt=DocumentedParam::get_improved_for_int(param_id.toStdString());
    if(improved_opt.has_value()){
        // min max is a requirement for int param
        return true;
    }
    return false;
}

int MavlinkSettingsModel::int_param_get_min_value(QString param_id)const
{
    const auto improved_opt=DocumentedParam::get_improved_for_int(param_id.toStdString());
    if(improved_opt.has_value()){
        if(improved_opt->has_enum_mapping()){
            return improved_opt->max_value_int;
        }
    }
    return 2147483647;
}

int MavlinkSettingsModel::int_param_get_max_value(QString param_id)const
{
    const auto improved_opt=DocumentedParam::get_improved_for_int(param_id.toStdString());
    if(improved_opt.has_value()){
        if(improved_opt->has_enum_mapping()){
            return improved_opt->min_value_int;
        }
    }
    return -2147483648;
}

bool MavlinkSettingsModel::int_param_has_enum_keys_values(QString param_id)const
{
    const auto improved_opt=DocumentedParam::get_improved_for_int(param_id.toStdString());
    if(improved_opt.has_value()){
        if(improved_opt->has_enum_mapping()){
            return true;
        }
    }
    return false;
}

QStringList MavlinkSettingsModel::int_param_get_enum_keys(QString param_id) const
{
    const auto improved_opt=DocumentedParam::get_improved_for_int(param_id.toStdString());
    if(improved_opt.has_value()){
        const auto improved=improved_opt.value();
        if(improved.has_enum_mapping()){
            return improved.int_enum_keys();
        }
        qDebug()<<"Error no enum mapping for this int param";
    }else{
        qDebug()<<"Error not an int param";
    }
    QStringList ret{"Err(0)"};
    return ret;
}

QList<int> MavlinkSettingsModel::int_param_get_enum_values(QString param_id) const
{
    const auto improved_opt=DocumentedParam::get_improved_for_int(param_id.toStdString());
    if(improved_opt.has_value()){
        const auto improved=improved_opt.value();
        if(improved.has_enum_mapping()){
            return improved.int_enum_values();
        }
    }
    qDebug()<<"Error no enum mapping for this int param";
    QList<int> ret{0};
    return ret;
}

MavlinkSettingsModel::ParamIntEnum MavlinkSettingsModel::int_param_get_enum(QString param_id) const
{
    ParamIntEnum ret{false,{},{}};
    const auto improved_opt=DocumentedParam::get_improved_for_int(param_id.toStdString());
    if(improved_opt.has_value()){
        auto improved=improved_opt.value();
        ret.values=improved.int_enum_values();
        ret.keys=improved.int_enum_keys();
        ret.valid=true;
        return ret;
    }
    qDebug()<<"Error no enum mapping for this int param";
    return ret;
}


bool MavlinkSettingsModel::string_param_has_enum(QString param_id) const
{
    const auto improved_opt=DocumentedParam::get_improved_for_string(param_id.toStdString());
    if(improved_opt.has_value()){
        return true;
    }
    return false;
}

QStringList MavlinkSettingsModel::string_param_get_enum_keys(QString param_id) const
{
    const auto improved_opt=DocumentedParam::get_improved_for_string(param_id.toStdString());
    if(improved_opt.has_value()){
        return improved_opt->enum_keys();
    }
    qDebug()<<"Error no enum mapping for this int param";
    QStringList ret{"ERROR_KEYS"};
    return ret;
}

QStringList MavlinkSettingsModel::string_param_get_enum_values(QString param_id) const
{
    const auto improved_opt=DocumentedParam::get_improved_for_string(param_id.toStdString());
    if(improved_opt.has_value()){
        return improved_opt->enum_values();
    }
    qDebug()<<"Error no enum mapping for this int param";
    QStringList ret{"ERROR_VALUES"};
    return ret;
}

MavlinkSettingsModel::ParamStringEnum MavlinkSettingsModel::string_param_get_enum(QString param_id) const
{
    ParamStringEnum ret{false,{},{}};
    const auto improved_opt=DocumentedParam::get_improved_for_string(param_id.toStdString());
    if(improved_opt.has_value()){
        auto improved=improved_opt.value();
        ret.values=improved.enum_values();
        ret.keys=improved.enum_keys();
        ret.valid=true;
        return ret;
    }
    qDebug()<<"Error no enum mapping for this int param";
    return ret;
}

QString MavlinkSettingsModel::get_warning_before_safe(const QString param_id)
{
    if(param_id=="V_OS_CAM_CONFIG"){
        return "WARNING: Changing this parameter will perform some special operations and then automatically reboot the air pi after a 3second delay";
    }
    return "";
}

bool MavlinkSettingsModel::get_param_requires_manual_reboot(QString param_id)
{
    return DocumentedParam::requires_reboot(param_id.toStdString());
}

void MavlinkSettingsModel::remove_and_replace_param_set(const std::vector<mavlink_param_ext_value_t> &param_set)
{
    // We might not be called from the UI thread, which is why we do the signal hoop to schedule something on
    // the UI thread
    const auto parsed_param_set=XParam::parse_server_param_set(param_set);
    QtParamSet qt_param_set{};
    for(const auto& param:parsed_param_set){
        if(param.int_param.has_value()){
            auto tmp=QtParamValue{param.param_id.c_str(),param.int_param.value(),0};
            qt_param_set.param_set.push_back(tmp);
        }else if(param.string_param.has_value()){
            auto tmp=QtParamValue{param.param_id.c_str(),param.string_param->c_str(),1};
            qt_param_set.param_set.push_back(tmp);
        }
    }
    emit signal_ui_thread_replace_param_set(qt_param_set);
}

void MavlinkSettingsModel::ui_thread_replace_param_set(QtParamSet qt_param_set)
{
    qDebug()<<"Replacing full param set, previous size:"<<rowCount()<<" new size:"<<qt_param_set.param_set.size();
    // first, remove anything the QT model has cached
    while(rowCount()>0){
        removeData(rowCount()-1);
    }
    qDebug()<<"Done removing old params";
    for(int i=0;i<qt_param_set.param_set.size();i++){
        const auto param=qt_param_set.param_set[i];
        const QString param_id=param.param_id;
        std::variant<int32_t,std::string> param_value;
        if(param.type==0){
            int32_t value=param.param_value.value<int>();
            param_value=value;
        }else{
            QString value=param.param_value.value<QString>();
            param_value=value.toStdString();
        }
        MavlinkSettingsModel::SettingData data{param_id,param_value};
        addData(data);
    }
}
