#ifndef MAVLINKTELEMETRY_H
#define MAVLINKTELEMETRY_H

#include <QObject>
#include <QtQuick>


#include <openhd/mavlink.h>

#include "../util/util.h"

#include "mavlinkbase.h"


class QUdpSocket;



class MavlinkTelemetry: public MavlinkBase {
    Q_OBJECT

public:
    explicit MavlinkTelemetry(QObject *parent = nullptr);
    static MavlinkTelemetry* instance();

public slots:
    void onSetup();
    void pauseTelemetry(bool toggle);
    void requestSysIdSettings();
    void requested_Flight_Mode_Changed(int mode);
    void requested_ArmDisarm_Changed(int arm_disarm);
    void FC_Reboot_Shutdown_Changed(int reboot_shutdown);

    #if defined(ENABLE_RC)
    void rc1_changed(uint rc1);
    void rc2_changed(uint rc2);
    void rc3_changed(uint rc3);
    void rc4_changed(uint rc4);
    void rc5_changed(uint rc5);
    void rc6_changed(uint rc6);
    void rc7_changed(uint rc7);
    void rc8_changed(uint rc8);
    void rc9_changed(uint rc9);
    void rc10_changed(uint rc10);
    void rc11_changed(uint rc11);
    void rc12_changed(uint rc12);
    void rc13_changed(uint rc13);
    void rc14_changed(uint rc14);
    void rc15_changed(uint rc15);
    void rc16_changed(uint rc16);
    void rc17_changed(uint rc17);
    void rc18_changed(uint rc18);
    #endif

private slots:
    void onProcessMavlinkMessage(mavlink_message_t msg);

signals:
    //void adsbVehicleUpdate(const ADSBVehicle::VehicleInfo_t vehicleInfo);
    //void deleteMissionWaypoints();

    #if defined(ENABLE_RC)
    void update_RC_MavlinkBase(
                       uint rc1,
                       uint rc2,
                       uint rc3,
                       uint rc4,
                       uint rc5,
                       uint rc6,
                       uint rc7,
                       uint rc8,
                       uint rc9,
                       uint rc10,
                       uint rc11,
                       uint rc12,
                       uint rc13,
                       uint rc14,
                       uint rc15,
                       uint rc16,
                       uint rc17,
                       uint rc18
                               );
    #endif

private:
    bool pause_telemetry;
    int m_mode=0;
    int m_arm_disarm=99;
    int m_reboot_shutdown=99;
    int m_total_waypoints=0;
    bool sent_autopilot_request=false;
    int ap_version=0;

    #if defined(ENABLE_RC)
    uint m_rc1 = 0;
    uint m_rc2 = 0;
    uint m_rc3 = 0;
    uint m_rc4 = 0;
    uint m_rc5 = 0;
    uint m_rc6 = 0;
    uint m_rc7 = 0;
    uint m_rc8 = 0;
    uint m_rc9 = 0;
    uint m_rc10 = 0;
    uint m_rc11 = 0;
    uint m_rc12 = 0;
    uint m_rc13 = 0;
    uint m_rc14 = 0;
    uint m_rc15 = 0;
    uint m_rc16 = 0;
    uint m_rc17 = 0;
    uint m_rc18 = 0;
    #endif
};

#endif
