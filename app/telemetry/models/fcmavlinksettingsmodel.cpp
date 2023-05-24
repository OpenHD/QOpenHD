#include "fcmavlinksettingsmodel.h"
#include "util/WorkaroundMessageBox.h"


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
    if(param_client==nullptr){
        WorkaroundMessageBox::instance().set_text_and_show("No FC");
        return false;
    }
    bool res=false;
    res=param_client->set_param_int("SR1_EXTRA2",2)==mavsdk::Param::Result::Success;
    if(!res)return false;
    return true;
}


