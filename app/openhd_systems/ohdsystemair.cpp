#include "ohdsystemair.h"

OHDSystemAir::OHDSystemAir(QObject *parent)
    : QObject{parent}
{

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
