#ifndef AIRCAMERAMODEL_H
#define AIRCAMERAMODEL_H

#include <QObject>

#include "../../../lib/lqtutils_master/lqtutils_prop.h"

// NOTE1: This class exists to avoid duplicated code for primary and secondary camera(stream)-stats displayed in the HUD
// NOTE2: Here we have only stats for one camera / camera stream that are transmitted via lossy
// telemetry messages, aka in regular intervalls.
// NOTE3: Camera settings or similar you won't find here, and it is also discouraged to use the data here
// for anything else than display-only HUD elements. See MavlinkSettingsModel and instanceAirCamera();
class AirCameraModel : public QObject
{
    Q_OBJECT
public:
    explicit AirCameraModel(int m_camera_index,QObject *parent = nullptr);
    const int m_camera_index;
    static AirCameraModel& instance(int cam_index);
public:
    // NOTE: hacky right now, since it is a param but we also want to display it in the HUD
    L_RO_PROP(QString,curr_set_video_bitrate,set_curr_set_video_bitrate,"N/A")
    L_RO_PROP(QString,curr_set_video_codec,set_curr_set_video_codec,"N/A")
    //
    // The following stats are kinda camera related, kinda wb link related
    L_RO_PROP(QString,curr_video_measured_encoder_bitrate,set_curr_video_measured_encoder_bitrate,"N/A")
    L_RO_PROP(QString,curr_video_injected_bitrate,set_curr_video_injected_bitrate,"N/A") //includes FEC overhead
public:
    // NOTE: hacky right now, since it is a param but we also want to display it in the HUD
    void set_curr_set_video_bitrate_int(int value);
    void set_curr_set_video_codec_int(int value);
};

#endif // AIRCAMERAMODEL_H
