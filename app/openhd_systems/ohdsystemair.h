#ifndef OHDSYSTEMAIR_H
#define OHDSYSTEMAIR_H

#include <QObject>
#include <QDebug>
#include <QTimer>

#include "../telemetry/mavlink_include.h"
#include "wifiadapter.h"

/**
 * @brief This class contains information (basically like a model) about the OpenHD Air instance (if connected)
 * NOTE: Please keep FC Telemetry data out of here, we have a seperate model for the FC !!!!
 * It uses QT signals to propagate changes of its data member(s) (Like cpu temperature, usw).
 * QOpenHD can only talk to one OHD Air system at a time, so we can make this class a singleton.
 */
class OHDSystemAir : public QObject
{
    Q_OBJECT
public:
    explicit OHDSystemAir(QObject *parent = nullptr);
    static OHDSystemAir& instance();
public:
    Q_PROPERTY(int cpuload_air MEMBER m_cpuload_air WRITE set_cpuload_air NOTIFY cpuload_air_changed)
    void set_cpuload_air(int cpuload_air);
    Q_PROPERTY(int temp_air MEMBER m_temp_air WRITE set_temp_air NOTIFY temp_air_changed)
    void set_temp_air(int temp_air);
    Q_PROPERTY(QString m_openhd_version_air MEMBER m_openhd_version_air WRITE set_openhd_version_air NOTIFY openhd_version_air_changed)
    void set_openhd_version_air(QString openhd_version_air);
    Q_PROPERTY(bool air_undervolt MEMBER m_air_undervolt WRITE set_air_undervolt NOTIFY air_undervolt_changed)
    void set_air_undervolt(bool air_undervolt);
    Q_PROPERTY(QList<int> air_gpio MEMBER m_air_gpio WRITE set_air_gpio NOTIFY air_gpio_changed)
    void set_air_gpio(QList<int> air_gpio);
    Q_PROPERTY(bool air_gpio_busy MEMBER m_air_gpio_busy WRITE set_air_gpio_busy NOTIFY air_gpio_busy_changed)
    void set_air_gpio_busy(bool air_gpio_busy);
    Q_PROPERTY(int air_freq MEMBER m_air_freq WRITE set_air_freq NOTIFY air_freq_changed)
    void set_air_freq(int air_freq);
    Q_PROPERTY(bool air_freq_busy MEMBER m_air_freq_busy WRITE set_air_freq_busy NOTIFY air_freq_busy_changed)
    void set_air_freq_busy(bool air_freq_busy);
    Q_PROPERTY(double air_vout MEMBER m_air_vout WRITE set_air_vout NOTIFY air_vout_changed)
    void set_air_vout(double air_vout);
    Q_PROPERTY(double air_iout MEMBER m_air_iout WRITE set_air_iout NOTIFY air_iout_changed)
    void set_air_iout(double air_iout);
    Q_PROPERTY(QString last_ping_result_openhd_air MEMBER  m_last_ping_result_openhd_air WRITE set_last_ping_result_openhd_air NOTIFY last_ping_result_openhd_air_changed)
    void set_last_ping_result_openhd_air(QString last_ping_result_openhd_air);
    Q_PROPERTY(qint64 last_openhd_heartbeat MEMBER m_last_openhd_heartbeat WRITE set_last_openhd_heartbeat NOTIFY last_openhd_heartbeat_changed)
    void set_last_openhd_heartbeat(qint64 last_openhd_heartbeat);
    Q_PROPERTY(bool is_alive MEMBER m_is_alive WRITE set_is_alive NOTIFY is_alive_changed)
    void set_is_alive(bool alive);
    //
    //Q_PROPERTY(QString wifi_adapter MEMBER  m_wifi_adapter WRITE set_wifi_adapter NOTIFY wifi_adapter_changed)
    // TODO somehow make the struct available to qt
    void set_wifi_adapter(unsigned int received_packet_count,int current_signal_dbm,int signal_good);
    //
    Q_PROPERTY(int wifibroadcast_rssi MEMBER  m_wifibroadcast_rssi WRITE set_wifibroadcast_rssi NOTIFY wifibroadcast_rssi_changed)
    void set_wifibroadcast_rssi(int wifibroadcast_rssi);
    //
    Q_INVOKABLE void setAirGPIO(int pin, bool state);
    Q_INVOKABLE void setAirFREQ(int air_freq);
signals:
    void cpuload_air_changed(int cpuload_air);
    void temp_air_changed(int temp_air);
    void save_air_gpio(QList<int> air_gpio);
    void air_gpio_busy_changed(bool air_gpio_busy);

    void save_air_freq(int air_freq);
    void air_freq_busy_changed(bool air_freq_busy);
    void air_undervolt_changed(bool air_undervolt);
    void openhd_version_air_changed(QString openhd_version_air);
    void air_gpio_changed(QList<int> air_gpio);

    void air_freq_changed(int air_freq);
    void gnd_freq_changed(int gnd_freq);

    void air_reboot();
    void air_shutdown();

    void air_vout_changed(double air_vout);
    void air_iout_changed(double air_iout);
    void last_ping_result_openhd_air_changed(QString last_ping_result_openhd_air);
    void last_openhd_heartbeat_changed(qint64 last_openhd_heartbeat);
    void is_alive_changed(bool alive);

    void wifi_adapter_changed(unsigned int received_packet_count,int current_signal_dbm,int signal_good);
    void wifibroadcast_rssi_changed(int wifibroadcast_rssi);
public:
    int m_cpuload_air = 0;
    int m_temp_air = 0;
    bool m_air_undervolt = false;
    QList<int> m_air_gpio;
    bool m_air_gpio_busy = false;

    int m_air_freq;
    bool m_air_freq_busy = false;
    double m_air_vout = -1;
    double m_air_iout = -1;
    QString m_openhd_version_air="NA";
    // All these get set by the proper responses and can be used in UI
    QString m_last_ping_result_openhd_air="NA";
    qint64 m_last_openhd_heartbeat = -1;
    bool m_is_alive=false; // see alive timer
    // Air unit only has one (wifibroadcast) wifi adapter
    WifiAdapter m_wifi_adapter;
    // argh, dulicated but we need that for the qt u element
    int m_wifibroadcast_rssi=-127;
private:
    // Sets the alive boolean if no heartbeat / message has been received in the last X seconds
    QTimer* m_alive_timer = nullptr;
    void update_alive();
};

#endif // OHDSYSTEMAIR_H
