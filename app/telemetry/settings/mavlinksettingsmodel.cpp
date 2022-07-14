#include "mavlinksettingsmodel.h"
#include "qdebug.h"

#include <QVariant>

MavlinkSettingsModel &MavlinkSettingsModel::instanceAir()
{
    static MavlinkSettingsModel* instanceAir=new MavlinkSettingsModel();
    return *instanceAir;
}
MavlinkSettingsModel &MavlinkSettingsModel::instanceGround()
{
    static MavlinkSettingsModel* instanceGround=new MavlinkSettingsModel();
    return *instanceGround;
}

MavlinkSettingsModel::MavlinkSettingsModel(QObject *parent)
    : QAbstractListModel(parent)
{
#ifndef X_USE_MAVSDK
    m_data.push_back({"VIDEO_WIDTH",0});
    m_data.push_back({"VIDEO_HEIGHT",1});
    m_data.push_back({"VIDEO_FPS",1});
#endif
}

#ifdef X_USE_MAVSDK
void MavlinkSettingsModel::set_param_client(std::shared_ptr<mavsdk::Param> param_client1)
{
    // only allow adding the param client once it is discovered, do not overwrite it once discovered.
    assert(this->param_client==nullptr);
    this->param_client=param_client1;
    auto params=param_client1->get_all_params();
    qDebug()<<"Got int params:"<<params.int_params.size();
    for(const auto& int_param:params.int_params){
        MavlinkSettingsModel::SettingData data{QString(int_param.name.c_str()),int_param.value};
        addData(data);
    }
}
#endif

bool MavlinkSettingsModel::try_fetch_all_parameters()
{
    qDebug()<<"MavlinkSettingsModel::try_fetch_all_parameters()";
    if(param_client){
        // first, remove anything the QT model has cached
        while(rowCount()>0){
            removeData(rowCount()-1);
        }
        qDebug()<<"Done removing old params";
        // now fetch all params using mavsdk (this talks to the OHD system(s).
        const auto params=param_client->get_all_params();
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

void MavlinkSettingsModel::try_fetch_parameter(QString param_id)
{
    qDebug()<<"try_fetch_parameter:"<<param_id;
    if(param_client){
        const auto result=param_client->get_param_int(param_id.toStdString());
        if(result.first==mavsdk::Param::Result::Success){
            auto new_value=result.second;
            MavlinkSettingsModel::SettingData tmp{param_id,new_value};
            updateData(std::nullopt,tmp);
        }
    }
}

void MavlinkSettingsModel::try_update_parameter(const QString param_id,QVariant value)
{
    qDebug()<<"try_update_parameter:"<<param_id<<","<<value;
    int row=0;
    for(const auto& parameter: m_data){
        if(parameter.unique_id==param_id){
            // we got this parameter
            if(param_client){
                if(value.canConvert(QVariant::Type::Int)){
                    int value_int=value.toInt();
                    qDebug()<<"Set"<<param_id<<" to "<<value_int;
                    const auto result=param_client->set_param_int(param_id.toStdString(),value_int);
                    if(result==mavsdk::Param::Result::Success){
                        MavlinkSettingsModel::SettingData tmp{param_id,value_int};
                        updateData(std::nullopt,tmp);
                    }else{
                        std::stringstream ss;
                        ss<<result;
                        qDebug()<<"Updating param failed: "<<QString(ss.str().c_str());
                    }
                }
            }
        }
    }
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
    else
        return QVariant();
}

QHash<int, QByteArray> MavlinkSettingsModel::roleNames() const
{
    static QHash<int, QByteArray> mapping {
        {UniqueIdRole, "unique_id"},
        {ValueRole, "value"}
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
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    m_data.push_back(data);
    endInsertRows();
}
