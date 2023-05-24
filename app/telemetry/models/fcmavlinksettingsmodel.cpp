#include "fcmavlinksettingsmodel.h"



FCMavlinkSettingsModel::FCMavlinkSettingsModel(QObject *parent)
{

}

FCMavlinkSettingsModel &FCMavlinkSettingsModel::instance()
{
    static FCMavlinkSettingsModel instance(nullptr);
    return instance;
}

void FCMavlinkSettingsModel::set_system(std::shared_ptr<mavsdk::System> system)
{
    m_system=system;
    param_client=std::make_shared<mavsdk::Param>(system,1,false);
}

bool FCMavlinkSettingsModel::set_ardupilot_message_rates()
{
    bool res=false;
    res=param_client->set_param_int("SR1_EXT_STAT",2)==mavsdk::Param::Result::Success;
    if(!res)return false;
    return true;
}


