#include "mavlinksettingsmodel.h"
#include "qdebug.h"
#include "../openhd_defines.hpp"
//temporary
#include "../../openhd_systems/aohdsystem.h"

#include "../../util/WorkaroundMessageBox.h"
#include "documentedsetting.hpp"
#include <QSettings>
#include <QVariant>


MavlinkSettingsModel &MavlinkSettingsModel::instanceAirCamera()
{
    static MavlinkSettingsModel* instanceAirCamera=new MavlinkSettingsModel(OHD_SYS_ID_AIR,OHD_COMP_ID_AIR_CAMERA);
    return *instanceAirCamera;
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

std::map<std::string, void *> MavlinkSettingsModel::get_whitelisted_params()
{
    std::map<std::string,void*> ret{};
    //dev_show_whitelisted_params
    QSettings settings;
    const auto dev_show_whitelisted_params =settings.value("dev_show_whitelisted_params", false).toBool();
    if(dev_show_whitelisted_params){
        // no param whitelisted
        return ret;
    }
    ret["WB_FREQUENCY"]=nullptr;
    ret["WB_CHANNEL_W"]=nullptr;
    ret["WB_MCS_INDEX"]=nullptr;
    //ret[""]=nullptr;
    return ret;
}

bool MavlinkSettingsModel::is_param_whitelisted(const std::string param_id)
{
    if(param_id.empty()){
        return false;
    }
    const auto tmp=get_whitelisted_params();
    if(tmp.find(param_id)!=tmp.end()){
        return true;
    }
    return false;
}

static std::optional<ImprovedIntSetting> get_improved_for_int(const std::string param_id){
    std::map<std::string,ImprovedIntSetting> map_improved_params;
    map_improved_params["TEST_INT_0"]=ImprovedIntSetting::createEnumEnableDisable();
    {
        std::vector<std::string> values{};
        values.push_back("enum0");
        values.push_back("enum1");
        values.push_back("enum2");
        values.push_back("enum3");
        map_improved_params["TEST_INT_1"]=ImprovedIntSetting::createEnum(values);
    }
    {
        map_improved_params["VIDEO_CODEC"]=ImprovedIntSetting::createEnum( std::vector<std::string>{"h264","h265","mjpeg"});
        map_improved_params["V_AIR_RECORDING"]=ImprovedIntSetting::createEnumEnableDisable();
        map_improved_params["V_E_STREAMING"]=ImprovedIntSetting::createEnumEnableDisable();
        auto fc_uart_conn_values=std::vector<std::string>{"serial0","serial1","ttyUSB0","ttyACM0","ttyACM1"};
        map_improved_params["FC_UART_CONN"]=ImprovedIntSetting::createEnum(fc_uart_conn_values);

    }
    if(map_improved_params.find(param_id)!=map_improved_params.end()){
        return map_improved_params[param_id];
    }
    return std::nullopt;
}

static std::optional<std::string> int_param_to_enum_string_if_known(const std::string param_id,int value){
    const auto improved_opt=get_improved_for_int(param_id);
    if(improved_opt.has_value()){
        const auto& improved=improved_opt.value();
        if(improved.has_enum_mapping()){
            return improved.enum_value_to_string(value);
        }
    }
    return std::nullopt;
}


MavlinkSettingsModel::MavlinkSettingsModel(uint8_t sys_id,uint8_t comp_id,QObject *parent)
    : QAbstractListModel(parent),_sys_id(sys_id),_comp_id(comp_id)
{
    //m_data.push_back({"VIDEO_WIDTH",0});
    //m_data.push_back({"VIDEO_HEIGHT",1});
    //m_data.push_back({"VIDEO_FPS",1});
}

void MavlinkSettingsModel::set_param_client(std::shared_ptr<mavsdk::System> system)
{
    // only allow adding the param client once it is discovered, do not overwrite it once discovered.
    assert(this->param_client==nullptr);
    assert(system->get_system_id()==_sys_id);
    this->param_client=std::make_shared<mavsdk::Param>(system,_comp_id,true);
    try_fetch_all_parameters();
}

bool MavlinkSettingsModel::try_fetch_all_parameters()
{
    qDebug()<<"MavlinkSettingsModel::try_fetch_all_parameters()";
    if(param_client==nullptr){
        // not discovered yet
        workaround::makePopupMessage("OHD System not found");
    }
    if(param_client){
        // first, remove anything the QT model has cached
        while(rowCount()>0){
            removeData(rowCount()-1);
        }
        qDebug()<<"Done removing old params";
        // now fetch all params using mavsdk (this talks to the OHD system(s).
        const auto params=param_client->get_all_params(true);
        for(const auto& int_param:params.int_params){
            MavlinkSettingsModel::SettingData data{QString(int_param.name.c_str()),int_param.value};
            addData(data);
        }
        for(const auto& string_param:params.custom_params){
            MavlinkSettingsModel::SettingData data{QString(string_param.name.c_str()),string_param.value};
            addData(data);
        }
        if(!params.int_params.empty()){
            return true;
        }
    }else{
        // not dscovered yet
    }
    return false;
}

std::optional<int> MavlinkSettingsModel::try_get_param_int_impl(const QString param_id)
{
    qDebug()<<"try_get_param_int_impl:"<<param_id;
    if(param_client){
        const auto result=param_client->get_param_int(param_id.toStdString());
        if(result.first==mavsdk::Param::Result::Success){
             auto new_value=result.second;
             return new_value;
        }
    }
    return std::nullopt;
}

std::optional<std::string> MavlinkSettingsModel::try_get_param_string_impl(const QString param_id)
{
    qDebug()<<"try_get_param_string_impl:"<<param_id;
    if(param_client){
        const auto result=param_client->get_param_custom(param_id.toStdString());
        if(result.first==mavsdk::Param::Result::Success){
             auto new_value=result.second;
             return new_value;
        }
    }
    return std::nullopt;
}

bool MavlinkSettingsModel::try_set_param_int_impl(const QString param_id, int value)
{
    if(param_client){
        const auto result=param_client->set_param_int(param_id.toStdString(),value);
        if(result==mavsdk::Param::Result::Success){
            return true;
        }
    }
    return false;
}

bool MavlinkSettingsModel::try_set_param_string_impl(const QString param_id,QString value)
{
    if(param_client){
        const auto result=param_client->set_param_custom(param_id.toStdString(),value.toStdString());
        if(result==mavsdk::Param::Result::Success){
            return true;
        }
    }
    return false;
}

bool MavlinkSettingsModel::try_refetch_parameter_int(QString param_id)
{
    qDebug()<<"try_fetch_parameter:"<<param_id;
    auto new_value=try_get_param_int_impl(param_id);
    if(new_value.has_value()){
        MavlinkSettingsModel::SettingData tmp{param_id,new_value.value()};
        updateData(std::nullopt,tmp);
        return true;
    }
    return false;
}
bool MavlinkSettingsModel::try_refetch_parameter_string(QString param_id)
{
    qDebug()<<"try_fetch_parameter:"<<param_id;
    auto new_value=try_get_param_string_impl(param_id);
    if(new_value.has_value()){
        MavlinkSettingsModel::SettingData tmp{param_id,new_value.value()};
        updateData(std::nullopt,tmp);
        return true;
    }
    return false;
}


bool MavlinkSettingsModel::try_update_parameter_int(const QString param_id,int value)
{
    qDebug()<<"try_update_parameter_int:"<<param_id<<","<<value;
    const auto result=try_set_param_int_impl(param_id,value);
    if(result){
        MavlinkSettingsModel::SettingData tmp{param_id,value};
        updateData(std::nullopt,tmp);
        return true;
    }
    return false;
}

bool MavlinkSettingsModel::try_update_parameter_string(const QString param_id,QString value)
{
    qDebug()<<"try_update_parameter_string:"<<param_id<<","<<value;
    const auto result=try_set_param_string_impl(param_id,value);
    if(result){
        MavlinkSettingsModel::SettingData tmp{param_id,value.toStdString()};
        updateData(std::nullopt,tmp);
        return true;
    }
    return false;
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
            auto as_enum=int_param_to_enum_string_if_known(data.unique_id.toStdString(),value);
            if(as_enum.has_value()){
                return QString(as_enum.value().c_str());
            }
            std::stringstream ss;
            ss<<"{"<<value<<"}";
            return QString(ss.str().c_str());
        }
        auto value=std::get<std::string>(data.value);
        return QString(value.c_str());
    } else if (role==ValueTypeRole){
        if(std::holds_alternative<int>(data.value)){
            return 0;
        }
        return 1;
    } else if(role == ShortDescriptionRole){
        return "?";
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
        {ShortDescriptionRole,"shortDescription"}
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

// hacky, temporary
static void hacky_set_video_codec_in_qopenhd(const MavlinkSettingsModel::SettingData& data){
    if(data.unique_id=="VIDEO_CODEC"){
        // Check if the param is still an int (should always be the case, but we don't want to crash in c++)
        if(!std::holds_alternative<int32_t>(data.value)){
            qDebug()<<"ERROR video codec setting messed up, fixme";
            return;
        }
        const int video_codec_in_openhd=std::get<int32_t>(data.value);
        AOHDSystem::instanceAir().set_curr_set_video_codec_int(video_codec_in_openhd);
        if(video_codec_in_openhd==0 || video_codec_in_openhd==1 || video_codec_in_openhd==2){
            QSettings settings;
            const int tmp_video_codec = settings.value("selectedVideoCodecPrimary", 0).toInt();
            if(tmp_video_codec!=video_codec_in_openhd){
                // video codec mismatch, update the QOpenHD settings
                settings.setValue("selectedVideoCodecPrimary",video_codec_in_openhd);
                qDebug()<<"Changed video codec in QOpenHD to "<<video_codec_in_openhd;
                workaround::makePopupMessage("Changed VideoCodec in QOpenHD");
            }
        }
    }
}

static void hacky_set_curr_selected_video_bitrate_in_qopenhd(const MavlinkSettingsModel::SettingData& data){
    if(data.unique_id=="V_BITRATE_MBITS"){
        if(!std::holds_alternative<int32_t>(data.value)){
            qDebug()<<"ERROR video_bitrate setting messed up, fixme";
            return;
        }
        AOHDSystem::instanceAir().set_curr_set_video_bitrate_int(std::get<int32_t>(data.value));
    }
}


void MavlinkSettingsModel::updateData(std::optional<int> row_opt, SettingData new_data)
{
    {
        // temporary, dirty
        hacky_set_curr_selected_video_bitrate_in_qopenhd(new_data);
        hacky_set_video_codec_in_qopenhd(new_data);
    }
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
    {
        // temporary, dirty
        hacky_set_curr_selected_video_bitrate_in_qopenhd(data);
        hacky_set_video_codec_in_qopenhd(data);
    }
    if(is_param_whitelisted(data.unique_id.toStdString())){
        // never add whitelisted params to the simple model, they need synchronization
        return;
    }
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    m_data.push_back(data);
    endInsertRows();
}

bool MavlinkSettingsModel::has_int_enum_mapping(QString param_id)const
{
    const auto improved_opt=get_improved_for_int(param_id.toStdString());
    if(improved_opt.has_value()){
        if(improved_opt->has_enum_mapping()){
            return true;
        }
    }
    return false;
}

QString MavlinkSettingsModel::int_enum_get_readable(QString param_id, int value)const
{
    auto as_enum=int_param_to_enum_string_if_known(param_id.toStdString(),value);
    if(as_enum.has_value()){
        return QString(as_enum.value().c_str());
    }
    std::stringstream ss;
    ss<<"{"<<value<<"}";
    return QString(ss.str().c_str());
}

int MavlinkSettingsModel::int_enum_get_max(QString param_id)const
{
    const auto improved_opt=get_improved_for_int(param_id.toStdString());
    if(improved_opt.has_value()){
        if(improved_opt->has_enum_mapping()){
            return improved_opt->max_value_int;
        }
    }
    return 2147483647;
}

int MavlinkSettingsModel::int_enum_get_min(QString param_id)const
{
    const auto improved_opt=get_improved_for_int(param_id.toStdString());
    if(improved_opt.has_value()){
        if(improved_opt->has_enum_mapping()){
            return improved_opt->min_value_int;
        }
    }
    return -2147483648;
}
