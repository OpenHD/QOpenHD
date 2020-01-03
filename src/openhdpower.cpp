#include "openhdpower.h"

#include <QtNetwork>
#include <QThread>
#include <QtConcurrent>
#include <QProcess>
#include <QProcessEnvironment>

#include "util.h"

static OpenHDPower* _instance = new OpenHDPower();


OpenHDPower::OpenHDPower(QObject *parent) : QObject(parent) {
    qDebug() << "OpenHDPower::OpenHDPower()";
    init();
}

OpenHDPower* OpenHDPower::instance() {
    return _instance;
}


void OpenHDPower::init() {
    qDebug() << "OpenHDPower::init()";

    auto timer = new QTimer(this);
    timer->setSingleShot(false);
    connect(timer, &QTimer::timeout, this, &OpenHDPower::update);
    timer->start(1000);
}


void OpenHDPower::update() {
    qDebug() << "OpenHDPower::update()";
}

void OpenHDPower::set_vin(QString vin) {
    m_vin = vin;
    emit vin_changed(m_vin);
}

void OpenHDPower::set_vin_raw(float vin_raw) {
    m_vin_raw = vin_raw;
    emit vin_raw_changed(m_vin_raw);

    set_vin(tr("%1%2").arg(vin_raw, 3, 'f', 2, '0').arg("V"));
}



void OpenHDPower::set_vout(QString vout) {
    m_vout = vout;
    emit vout_changed(m_vout);
}

void OpenHDPower::set_vout_raw(float vout_raw) {
    m_vout_raw = vout_raw;
    emit vout_raw_changed(m_vout_raw);
    set_vout(tr("%1%2").arg(vout_raw, 3, 'f', 2, '0').arg("V"));
}


void OpenHDPower::set_iout(QString iout) {
    m_iout = iout;
    emit iout_changed(m_iout);
}

void OpenHDPower::set_iout_raw(float iout_raw) {
    m_iout_raw = iout_raw;
    emit iout_raw_changed(m_iout_raw);
    set_iout(tr("%1%2").arg(iout_raw, 3, 'f', 2, '0').arg("A"));
}


void OpenHDPower::set_vbat(QString vbat) {
    m_vbat = vbat;
    emit vbat_changed(m_vbat);
}

void OpenHDPower::set_vbat_raw(float vbat_raw) {
    m_vbat_raw = vbat_raw;
    emit vbat_raw_changed(m_vbat_raw);
    set_vbat(tr("%1%2").arg(vbat_raw, 3, 'f', 2, '0').arg("V"));


    auto battery_cells = 1; //settings.value("battery_cells", QVariant(3)).toInt();

    int battery_percent = lifepo4_battery_voltage_to_percent(battery_cells, m_vbat_raw);
    set_battery_percent(QString("%1%").arg(battery_percent));
    QString battery_gauge_glyph = battery_gauge_glyph_from_percentage(battery_percent);
    set_battery_gauge(battery_gauge_glyph);
}


void OpenHDPower::set_vbat_is_lifepo4(bool vbat_is_lifepo4) {
    m_vbat_is_lifepo4 = vbat_is_lifepo4;
    emit vbat_is_lifepo4_changed(m_vbat_is_lifepo4);
}


void OpenHDPower::set_battery_percent(QString battery_percent) {
    m_battery_percent = battery_percent;
    emit battery_percent_changed(m_battery_percent);
}

void OpenHDPower::set_battery_gauge(QString battery_gauge) {
    m_battery_gauge = battery_gauge;
    emit battery_gauge_changed(m_battery_gauge);
}


QObject *openHDPowerSingletonProvider(QQmlEngine *engine, QJSEngine *scriptEngine) {
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    OpenHDPower *s = new OpenHDPower();
    return s;
}
