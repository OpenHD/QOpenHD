#include "ohdsystemair.h"
#include "qdebug.h"

OHDSystemAir::OHDSystemAir(QObject *parent)
    : QObject{parent}
{
    set_air_gpio({0, 0, 0, 0, 0, 0, 0, 0});
}

OHDSystemAir& OHDSystemAir::instance()
{
    static OHDSystemAir* instance=new OHDSystemAir();
    return *instance;
}

void OHDSystemAir::set_cpuload_air(int cpuload_air) {
    m_cpuload_air = cpuload_air;
    emit cpuload_air_changed(m_cpuload_air);
}

void OHDSystemAir::set_temp_air(int temp_air) {
    m_temp_air = temp_air;
    emit temp_air_changed(m_temp_air);
}

void OHDSystemAir::set_air_undervolt(bool air_undervolt) {
    m_air_undervolt = air_undervolt;
    emit air_undervolt_changed(m_air_undervolt);
}

void OHDSystemAir::set_openhd_version_air(QString openhd_version_air){
    m_openhd_version_air=openhd_version_air;
    emit openhd_version_air_changed(openhd_version_air);
}

void OHDSystemAir::set_air_gpio(QList<int> air_gpio){
    m_air_gpio = air_gpio;
    emit air_gpio_changed(m_air_gpio);
}

void OHDSystemAir::set_air_gpio_busy(bool air_gpio_busy){
    m_air_gpio_busy = air_gpio_busy;
    emit air_gpio_busy_changed(air_gpio_busy);
}

void OHDSystemAir::set_air_freq(int air_freq){
    qDebug() << "OPENHD set_air_freq =" <<  air_freq;
    m_air_freq = air_freq;
    emit air_freq_changed(m_air_freq);
}

void OHDSystemAir::set_air_freq_busy(bool air_freq_busy){
    m_air_freq_busy = air_freq_busy;
    emit air_freq_busy_changed(air_freq_busy);
}


void OHDSystemAir::set_air_vout(double air_vout) {
    m_air_vout = air_vout;
    emit air_vout_changed(m_air_vout);
}

void OHDSystemAir::set_air_iout(double air_iout) {
    m_air_iout = air_iout;
    emit air_iout_changed(m_air_iout);
}

void OHDSystemAir::set_last_ping_result_openhd_air(QString last_ping_result_openhd_air)
{
    m_last_ping_result_openhd_air=last_ping_result_openhd_air;
    emit last_ping_result_openhd_air_changed(m_last_ping_result_openhd_air);
}
