#ifndef OHDACTION_H
#define OHDACTION_H

#include <QObject>
#include <QString>
#include <QVariantList>

#include "../tutil/mavlink_include.h"

/**
 * @brief This is the only class (other than param /settings) where one can talk to the OpenHD air / ground unit.
 * THE REST IS BROADCAST !
 */
class OHDAction : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool formatAirSdCardBusy READ formatAirSdCardBusy NOTIFY formatAirSdCardStatusChanged)
    Q_PROPERTY(QString formatAirSdCardStatus READ formatAirSdCardStatus NOTIFY formatAirSdCardStatusChanged)
    Q_PROPERTY(QVariantList airStorageDevices READ airStorageDevices NOTIFY airStorageDevicesChanged)
public:
    explicit OHDAction(QObject *parent = nullptr);

    static OHDAction& instance();
public:
    // request the OpenHD version, both OpenHD air and ground unit will respond to that message.
    // Deprecated, version is now broadcasted, too
    //Q_INVOKABLE void request_openhd_version_async();
    // send the reboot / shutdown command to openhd air or ground unit
    // @param system_id: 0 for ground, 1 for air, 2 for FC
    Q_INVOKABLE bool send_command_reboot_air(bool reboot);
    Q_INVOKABLE bool send_command_reboot_gnd(bool reboot);
    // Starts formatting storage 1 (the air unit's RECORDINGS SD card).
    // Completion is reported by formatAirSdCardStatusChanged.
    Q_INVOKABLE bool send_command_format_air_sd_card();
    Q_INVOKABLE bool refresh_air_storage();
    Q_INVOKABLE bool format_air_storage(int storageId);
    Q_INVOKABLE bool repartition_air_storage(int storageId);
    Q_INVOKABLE bool mount_air_storage_for_recording(int storageId);
    Q_INVOKABLE bool siyi_gimbal_rate(float pitchRate, float yawRate);
    Q_INVOKABLE bool siyi_gimbal_center();
    Q_INVOKABLE bool siyi_zoom(float rate);
    Q_INVOKABLE bool siyi_focus(float rate);
    Q_INVOKABLE bool siyi_autofocus();
    Q_INVOKABLE bool siyi_take_photo();
    Q_INVOKABLE bool siyi_set_recording(bool recording);
    Q_INVOKABLE bool camera_gimbal_rate(float pitchRate, float yawRate,
                                        int cameraIndex=0);
    Q_INVOKABLE bool camera_gimbal_roll_rate(float rollRate,
                                             int cameraIndex=0);
    Q_INVOKABLE bool camera_gimbal_center(int cameraIndex=0);
    Q_INVOKABLE bool camera_gimbal_calibrate(int cameraIndex=0);
    Q_INVOKABLE bool camera_gimbal_mode(int mode, int cameraIndex=0);
    Q_INVOKABLE bool camera_zoom(float rate, int cameraIndex=0);
    Q_INVOKABLE bool camera_focus(float rate, int cameraIndex=0);
    Q_INVOKABLE bool camera_autofocus(int cameraIndex=0);
    Q_INVOKABLE bool camera_take_photo(int cameraIndex=0);
    Q_INVOKABLE bool camera_set_recording(bool recording, int cameraIndex=0);
    Q_INVOKABLE bool camera_set_image_type(int imageType, int cameraIndex=0);
    Q_INVOKABLE bool camera_set_thermal_palette(int palette,
                                                int cameraIndex=0);
    bool process_message(const mavlink_message_t& message);
    bool formatAirSdCardBusy() const { return m_format_air_sd_card_busy; }
    QString formatAirSdCardStatus() const { return m_format_air_sd_card_status; }
    QVariantList airStorageDevices() const { return m_air_storage_devices; }

    // Sent to the ground unit only
    bool send_command_analyze_channels_blocking(int freq_bands);
    bool send_command_start_scan_channels_blocking(int freq_bands,int channel_widths);
signals:
    void formatAirSdCardStatusChanged();
    void airStorageDevicesChanged();
private:
    bool send_camera_command(uint16_t command, int cameraIndex=0,
                           float param1=0.0F,
                           float param2=0.0F, float param3=0.0F,
                           float param4=0.0F, float param5=0.0F,
                           float param6=0.0F, float param7=0.0F);
    bool send_storage_action(int action, int storageId,
                             const QString& runningText);
    bool m_format_air_sd_card_busy=false;
    QString m_format_air_sd_card_status="Idle";
    QVariantList m_air_storage_devices;
};

#endif // OHDACTION_H
