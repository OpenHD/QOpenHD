#include "synchronizedsettings.h"

#include "../../openhd_systems/aohdsystem.h"
#include "mavlinksettingsmodel.h"

#include <qmessagebox.h>
#include <sstream>


SynchronizedSettings::SynchronizedSettings(QObject *parent)
    : QObject{parent}
{

}

SynchronizedSettings& SynchronizedSettings::instance()
{
    static SynchronizedSettings tmp;
    return tmp;
}

int SynchronizedSettings::get_param_int_air_and_ground_value(QString param_id)
{
    qDebug()<<"get_param_air_and_ground_value "<<param_id;
    auto value_ground=MavlinkSettingsModel::instanceGround().try_fetch_param_int_impl(param_id);
    if(value_ground.has_value()){
        return value_ground.value();
    }
    return -1;
}

static void makePopupMessage(QString message){
    QMessageBox msgBox;
    msgBox.setText(message);
    msgBox.exec();
}

void SynchronizedSettings::change_param_air_and_ground(QString param_id,int value)
{
    qDebug()<<"SynchronizedSettings::change_param_air_and_ground: "<<param_id<<":"<<value;
    // sanity checking
    const bool air_and_ground_alive=AOHDSystem::instanceAir().is_alive() && AOHDSystem::instanceGround().is_alive();
    if(!air_and_ground_alive){
        makePopupMessage("Precondition: Air and Ground running and alive not given. Change not possible.");
        return;
    }
    // First change it on the air and wait for ack - if failed, return. MAVSDK does 3 retransmission(s) until acked so it is really unlikely that
    // we set the value and all 3 ack's are lost (which would be the generals problem and then the frequenies are out of sync).
    const bool air_success=MavlinkSettingsModel::instanceAir().try_update_parameter(param_id,value);
    if(!air_success){
        std::stringstream ss;
        ss<<"Air rejected "<<param_id.toStdString()<<":"<<value<<" nothing changed";
         makePopupMessage(ss.str().c_str());
        return;
    }
    // we have changed the air freq, now change the ground
    const bool ground_success=MavlinkSettingsModel::instanceGround().try_update_parameter(param_id,value);
    if(!ground_success){
        std::stringstream ss;
        ss<<"Air changed but ground rejected - unfortunately you have to manually fix "<<param_id.toStdString();
        makePopupMessage(ss.str().c_str());
        return;
    }
    std::stringstream ss;
    ss<<"Successfully changed "<<param_id.toStdString()<<" to "<<value<<" ,please repower air and ground unit";
    makePopupMessage(ss.str().c_str());

}
