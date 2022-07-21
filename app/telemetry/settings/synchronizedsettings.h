#ifndef SynchronizedSettings_H
#define SynchronizedSettings_H

#include <QObject>

// Helper for settings that MUST STAY IN SYNC on the ground and air pi, since otherwise the wifibroadcast link is lost
// and the user needs to manually recover the link
// It does not fix the 2 general's problem (this is a unfixable problem) but it makes it really unlikely to happen.
class SynchronizedSettings : public QObject
{
    Q_OBJECT
public:
    explicit SynchronizedSettings(QObject *parent = nullptr);

    static SynchronizedSettings& instance();
    static constexpr auto PARAM_ID_WB_FREQ="WB_FREQUENCY";
    static constexpr auto PARAM_ID_WB_CHANNEL_WIDTH="WB_CHANNEL_W";
    static constexpr auto PARAM_ID_WB_MCS_INDEX="WB_MCS_INDEX";

    // Air and ground should always match, otherwise something weird has happenened.
    // Note that this would be "really" weird, since on not matching params there should be no connectivitiy.
    Q_INVOKABLE bool get_param_air_and_ground(QString param_id);

    Q_INVOKABLE void change_param_air_and_ground(QString param_id,int value);

    Q_INVOKABLE void change_param_air_and_ground_frequency(int value){
        change_param_air_and_ground(PARAM_ID_WB_FREQ,value);
    }

    Q_INVOKABLE void change_param_air_and_ground_mcs(int value){
        change_param_air_and_ground(PARAM_ID_WB_CHANNEL_WIDTH,value);
    }

    Q_INVOKABLE void change_param_air_and_ground_channel_width(int value){
        change_param_air_and_ground(PARAM_ID_WB_MCS_INDEX,value);
    }

signals:

};

#endif // SynchronizedSettings_H
