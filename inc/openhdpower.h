#ifndef OPENHDPOWER_H
#define OPENHDPOWER_H

#include <QObject>
#include <QtQuick>
#include <QProcess>
#include <QProcessEnvironment>

typedef enum OpenHDPowerProvider {
    OpenHDPowerProviderNone,
    #if defined(ENABLE_LIFEPOWERED_PI)
    OpenHDPowerProviderLiFePO4weredPi,
    #endif
    #if defined(ENABLE_INA2XX)
    OpenHDPowerProviderINA2XX,
    #endif
} OpenHDPowerProvider;




class OpenHDPower : public QObject {
    Q_OBJECT

public:
    explicit OpenHDPower(QObject *parent = nullptr);
    void init();

    Q_PROPERTY(QString battery_percent MEMBER m_battery_percent WRITE set_battery_percent NOTIFY battery_percent_changed)
    void set_battery_percent(QString battery_percent);

    Q_PROPERTY(QString battery_gauge MEMBER m_battery_gauge WRITE set_battery_gauge NOTIFY battery_gauge_changed)
    void set_battery_gauge(QString battery_gauge);

    Q_PROPERTY(QString vin MEMBER m_vin NOTIFY vin_changed)
    void set_vin(QString vin);

    Q_PROPERTY(float vin_raw MEMBER m_vin_raw NOTIFY vin_raw_changed)
    void set_vin_raw(float vin_raw);


    Q_PROPERTY(QString vout MEMBER m_vout NOTIFY vout_changed)
    void set_vout(QString vout);

    Q_PROPERTY(float vout_raw MEMBER m_vout_raw  NOTIFY vout_raw_changed)
    void set_vout_raw(float vout_raw);


    Q_PROPERTY(QString iout MEMBER m_iout NOTIFY iout_changed)
    void set_iout(QString iout);

    Q_PROPERTY(float iout_raw MEMBER m_iout_raw NOTIFY iout_raw_changed)
    void set_iout_raw(float iout_raw);



    Q_PROPERTY(QString vbat MEMBER m_vbat NOTIFY vbat_changed)
    void set_vbat(QString vbat);

    Q_PROPERTY(float vbat_raw MEMBER m_vbat_raw NOTIFY vbat_raw_changed)
    void set_vbat_raw(float vbat_raw);



    Q_PROPERTY(bool vbat_is_lifepo4 MEMBER m_vbat_is_lifepo4 NOTIFY vbat_is_lifepo4_changed)
    void set_vbat_is_lifepo4(bool vbat_is_lifepo4);

private:
    void update();

    OpenHDPowerProvider m_provider;

    QString m_battery_percent = "0%";
    QString m_battery_gauge = "\uf091";


    bool ina2xx_initialized = false;

    float m_vin_raw  = -1; // Unit: V,   example: 11.54
    float m_vout_raw = -1; // Unit: V,   example: 5.02
    float m_iout_raw = -1; // Unit: A,   example: 1.3
    float m_vbat_raw = -1; // Unit: V,   example: 3.45

    QString m_vin  = "N/A";
    QString m_vout = "N/A";
    QString m_iout = "N/A";
    QString m_vbat = "N/A";

    bool m_vbat_is_lifepo4 = false;

signals:
    void battery_percent_changed(QString battery_percent);
    void battery_gauge_changed(QString battery_gauge);

    void vin_changed(QString vin);
    void vin_raw_changed(float vin);

    void vout_changed(QString vout);
    void vout_raw_changed(float vout);

    void iout_changed(QString iout);
    void iout_raw_changed(float iout);

    void vbat_changed(QString vbat);
    void vbat_raw_changed(float vbat);

    void vbat_is_lifepo4_changed(bool vbat_is_lifepo4);


};

#endif // OPENHDPOWER_H
