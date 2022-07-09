#include "ohdsystemground.h"

OHDSystemGround::OHDSystemGround(QObject *parent)
    : QObject{parent}
{

}

OHDSystemGround &OHDSystemGround::instance()
{
    static OHDSystemGround* instance=new OHDSystemGround();
    return *instance;
}

void OHDSystemGround::set_cpuload_gnd(int cpuload_gnd) {
    m_cpuload_gnd = cpuload_gnd;
    emit cpuload_gnd_changed(m_cpuload_gnd);
}

void OHDSystemGround::set_temp_gnd(int temp_gnd) {
    m_temp_gnd = temp_gnd;
    emit temp_gnd_changed(m_temp_gnd);
}
