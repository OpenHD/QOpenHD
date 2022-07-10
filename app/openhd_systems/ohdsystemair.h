#ifndef OHDSYSTEMAIR_H
#define OHDSYSTEMAIR_H

#include <QObject>
#include <QDebug>

#include <openhd/mavlink.h>

/**
 * @brief This class contains information (basically like a model) about the OpenHD Air instance (if connected)
 * NOTE: Please keep FC Telemetry data out of here, we have a seperate model for the FC !!!!
 * It uses QT signals to propagate changes of its data member(s) (Like weather the system is connected, usw).
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
};

#endif // OHDSYSTEMAIR_H
