#include "mavlinksettingsmodel.h"
#include "qdebug.h"
#include "../openhd_defines.hpp"
//temporary
#include "../../openhd_systems/aohdsystem.h"

#include <QMessageBox>
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

MavlinkSettingsModel::MavlinkSettingsModel(uint8_t sys_id,uint8_t comp_id,QObject *parent)
    : QAbstractListModel(parent),_sys_id(sys_id),_comp_id(comp_id)
{
    //m_data.push_back({"VIDEO_WIDTH",0});
    //m_data.push_back({"VIDEO_HEIGHT",1});
    //m_data.push_back({"VIDEO_FPS",1});
}

static void makePopupMessage(QString message){
    QMessageBox msgBox;
    msgBox.setText(message);
    msgBox.exec();
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
        makePopupMessage("OHD System not found");
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
        if(!params.int_params.empty()){
            return true;
        }
    }else{
        // not dscovered yet
    }
    return false;
}

std::optional<int> MavlinkSettingsModel::try_fetch_param_int_impl(const QString param_id)
{
    qDebug()<<"try_fetch_param_implementation:"<<param_id;
    if(param_client){
        const auto result=param_client->get_param_int(param_id.toStdString());
        if(result.first==mavsdk::Param::Result::Success){
             auto new_value=result.second;
             return new_value;
        }
    }
    return std::nullopt;
}

bool MavlinkSettingsModel::try_fetch_parameter(QString param_id)
{
    qDebug()<<"try_fetch_parameter:"<<param_id;
    auto new_value=try_fetch_param_int_impl(param_id);
    if(new_value.has_value()){
        MavlinkSettingsModel::SettingData tmp{param_id,new_value.value()};
        updateData(std::nullopt,tmp);
        return true;
    }
    return false;
}

bool MavlinkSettingsModel::try_update_parameter(const QString param_id,QVariant value)
{
    qDebug()<<"try_update_parameter:"<<param_id<<","<<value;
    /*int row=0;
    bool found=false;
    for(const auto& parameter: m_data){
        if(parameter.unique_id==param_id){
            found=true;
            // we got this parameter
            if(param_client){
                if(value.canConvert(QVariant::Type::Int)){
                    int value_int=value.toInt();
                    qDebug()<<"Set"<<param_id<<" to "<<value_int;
                    const auto result=param_client->set_param_int(param_id.toStdString(),value_int);
                    if(result==mavsdk::Param::Result::Success){
                        MavlinkSettingsModel::SettingData tmp{param_id,value_int};
                        updateData(std::nullopt,tmp);
                        return true;
                    }else{
                        std::stringstream ss;
                        ss<<"Updating "<<param_id.toStdString()<<" to "<<value_int<<" failed: "<<result;
                        qDebug()<<QString(ss.str().c_str());
                        makePopupMessage(ss.str().c_str());
                        return false;
                    }
                }
            }
        }
    }
    return false;*/
    if(value.canConvert(QVariant::Type::Int)){
        const int value_int=value.toInt();
        qDebug()<<"Set"<<param_id<<" to "<<value_int;
        const auto result=param_client->set_param_int(param_id.toStdString(),value_int);
        if(result==mavsdk::Param::Result::Success){
            MavlinkSettingsModel::SettingData tmp{param_id,value_int};
            updateData(std::nullopt,tmp);
            return true;
        }else{
            std::stringstream ss;
            ss<<"Updating "<<param_id.toStdString()<<" to "<<value_int<<" failed: "<<result;
            qDebug()<<QString(ss.str().c_str());
            makePopupMessage(ss.str().c_str());
            return false;
        }
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
    else if ( role == ValueRole )
        return data.value;
    else if (role ==ExtraRole){
        if(data.unique_id=="WB_TX_POWER_MW"){
            //return true;
            return "yes";
        }else{
            //return false;
            return "no";
        }
    }
    else
        return QVariant();
}

QHash<int, QByteArray> MavlinkSettingsModel::roleNames() const
{
    static QHash<int, QByteArray> mapping {
        {UniqueIdRole, "unique_id"},
        {ValueRole, "value"},
        {ExtraRole, "extra"}
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
        const int video_codec_in_openhd=data.value;
        AOHDSystem::instanceAir().set_curr_set_video_codec_int(video_codec_in_openhd);
        if(video_codec_in_openhd==0 || video_codec_in_openhd==1 || video_codec_in_openhd==2){
            QSettings settings;
            const int tmp_video_codec = settings.value("selectedVideoCodecPrimary", 0).toInt();
            if(tmp_video_codec!=video_codec_in_openhd){
                // video codec mismatch, update the QOpenHD settings
                settings.setValue("selectedVideoCodecPrimary",video_codec_in_openhd);
                qDebug()<<"Changed video codec in QOpenHD to "<<video_codec_in_openhd;
            }
        }
    }
}
static void hacky_set_curr_selected_video_bitrate_in_qopenhd(const MavlinkSettingsModel::SettingData& data){
    if(data.unique_id=="V_BITRATE_MBITS"){
        AOHDSystem::instanceAir().set_curr_set_video_bitrate_int(data.value);
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
        for(int i=0;i<m_data.size();i++){
            if(m_data.at(i).unique_id==new_data.unique_id){
                row=i;
                break;
            }
        }
    }
    if (row < 0 || row >= m_data.count())
        return;
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
