#ifndef OHDSYSTEMGROUND_H
#define OHDSYSTEMGROUND_H

#include <QObject>
#include <QDebug>

/**
 * @brief This class contains information (basically like a model) about the OpenHD Air instance (if connected)
 * It uses QT signals to propagate changes of its data member(s) (Like weather the system is connected, usw)
 * QOpenHD can only talk to one OHD Ground system at a time, so we can make this class a singleton.
 */
class OHDSystemGround : public QObject
{
    Q_OBJECT
public:
    explicit OHDSystemGround(QObject *parent = nullptr);
    static OHDSystemGround& instance();
public:
    Q_PROPERTY(int cpuload_gnd MEMBER m_cpuload_gnd WRITE set_cpuload_gnd NOTIFY cpuload_gnd_changed)
    void set_cpuload_gnd(int cpuload_gnd);
    Q_PROPERTY(int temp_gnd MEMBER m_temp_gnd WRITE set_temp_gnd NOTIFY temp_gnd_changed)
    void set_temp_gnd(int temp_gnd);
    //
    //
    Q_PROPERTY(int ground_battery_percent MEMBER m_ground_battery_percent WRITE set_ground_battery_percent NOTIFY ground_battery_percent_changed)
    void set_ground_battery_percent(int ground_battery_percent);
    Q_PROPERTY(QString ground_battery_gauge MEMBER m_ground_battery_gauge WRITE set_ground_battery_gauge NOTIFY ground_battery_gauge_changed)
    void set_ground_battery_gauge(QString ground_battery_gauge);
    //
    Q_PROPERTY(QString m_openhd_version_ground MEMBER m_openhd_version_ground WRITE set_openhd_version_ground NOTIFY openhd_version_ground_changed)
    void set_openhd_version_ground(QString openhd_version_ground);
    Q_PROPERTY(QList<int> ground_gpio MEMBER m_ground_gpio WRITE set_ground_gpio NOTIFY ground_gpio_changed)
    void set_ground_gpio(QList<int> ground_gpio);

    Q_PROPERTY(bool ground_gpio_busy MEMBER m_ground_gpio_busy WRITE set_ground_gpio_busy NOTIFY ground_gpio_busy_changed)
    void set_ground_gpio_busy(bool ground_gpio_busy);
    Q_PROPERTY(double ground_vin MEMBER m_ground_vin WRITE set_ground_vin NOTIFY ground_vin_changed)
    void set_ground_vin(double ground_vin);

    Q_PROPERTY(double ground_vout MEMBER m_ground_vout WRITE set_ground_vout NOTIFY ground_vout_changed)
    void set_ground_vout(double ground_vout);

    Q_PROPERTY(double ground_vbat MEMBER m_ground_vbat WRITE set_ground_vbat NOTIFY ground_vbat_changed)
    void set_ground_vbat(double ground_vbat);

    Q_PROPERTY(double ground_iout MEMBER m_ground_iout WRITE set_ground_iout NOTIFY ground_iout_changed)
    void set_ground_iout(double ground_iout);
signals:
    void cpuload_gnd_changed(int cpuload_gnd);
    void temp_gnd_changed(int temp_gnd);
    //
    void save_ground_gpio(QList<int> ground_gpio);
    void ground_gpio_busy_changed(bool ground_gpio_busy);
    void ground_battery_percent_changed(int ground_battery_percent);
    void ground_battery_gauge_changed(QString ground_battery_gauge);
    void openhd_version_ground_changed(QString openhd_version_ground);
    void ground_gpio_changed(QList<int> ground_gpio);
    void ground_reboot();
    void ground_shutdown();

    void ground_vin_changed(double ground_vin);
    void ground_vout_changed(double ground_vout);
    void ground_vbat_changed(double ground_vbat);
    void ground_iout_changed(double ground_iout);
    //
    void last_ping_result_openhd_ground_changed(QString last_ping_result_openhd_ground);
    void save_gnd_freq(int gnd_freq);

    void gnd_freq_busy_changed(bool gnd_freq_busy);
    void gnd_freq_changed(int gnd_freq);
public:
    int m_cpuload_gnd = 0;
    int m_temp_gnd = 0;
    int m_ground_battery_percent = 0;
    QString m_ground_battery_gauge = "\uf091";
    QList<int> m_ground_gpio;
    bool m_ground_gpio_busy = false;
    double m_ground_vin = -1;
    double m_ground_vout = -1;
    double m_ground_vbat = -1;
    double m_ground_iout = -1;
    QString m_openhd_version_ground="NA";
    QString m_last_ping_result_openhd_ground="NA";
    Q_PROPERTY(QString last_ping_result_openhd_ground MEMBER  m_last_ping_result_openhd_ground WRITE set_last_ping_result_openhd_ground NOTIFY last_ping_result_openhd_ground_changed)
    void set_last_ping_result_openhd_ground(QString last_ping_result_openhd_ground);
    int m_gnd_freq;
    bool m_gnd_freq_busy = false;
    Q_PROPERTY(int gnd_freq MEMBER m_gnd_freq WRITE set_gnd_freq NOTIFY gnd_freq_changed)
    void set_gnd_freq(int gnd_freq);

    Q_PROPERTY(bool gnd_freq_busy MEMBER m_gnd_freq_busy WRITE set_gnd_freq_busy NOTIFY gnd_freq_busy_changed)
    void set_gnd_freq_busy(bool gnd_freq_busy);
};

#endif // OHDSYSTEMGROUND_H
