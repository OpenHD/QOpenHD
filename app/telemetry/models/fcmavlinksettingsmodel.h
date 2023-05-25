#ifndef FCMAVLINKSETTINGSMODEL_H
#define FCMAVLINKSETTINGSMODEL_H

#include <QObject>
#include "../mavsdk_include.h"


// For changing settings on the FC itself (not OpenHD !)
// Works a bit different
// ARGH - The prams I was initially after are int16_t (not int32_t) and therefore not supported in mavsdk param yet
// -> stub for now
class FCMavlinkSettingsModel: public QObject
{
    Q_OBJECT
public:
    explicit FCMavlinkSettingsModel(QObject *parent = nullptr);
    // singleton for accessing the model from c++
    static FCMavlinkSettingsModel& instance();
    // Called by fcmavlinksystem once discovered
    void set_system(std::shared_ptr<mavsdk::System> system);
    // Ardupilot is a bit quirky if you connect to telem1 port
    // Here we just set that the FC broadcasts all messages we need in fitting intervals.
    Q_INVOKABLE bool set_ardupilot_message_rates();
private:
    // set by fcmavlinksystem once discovered
    std::shared_ptr<mavsdk::Param> param_client=nullptr;
    std::shared_ptr<mavsdk::System> m_system=nullptr;
};

#endif // FCMAVLINKSETTINGSMODEL_H
