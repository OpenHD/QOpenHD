#include <QThread>
#include <QtConcurrent>
#include <QFutureWatcher>
#include <QFuture>

#include "constants.h"

#include "blackboxmodel.h"

#include "openhd.h"

BlackBox::BlackBox(const QString &flight_mode,
                   const QString &time,
                   const double &lat,
                   const double &lon,
                   const double &alt,
                   const double &speed,
                   const int &heading,
                   const double &vertical,
                   const double &pitch,
                   const double &roll,
                   const double &throttle,
                   const int &control_pitch,
                   const int &control_roll,
                   const int &control_yaw,
                   const int &control_throttle,
                   const int &rssi_up,
                   const int &rssi_down,
                   const unsigned int &lost_packet_cnt_rc,
                   const unsigned int &lost_packet_cnt_telemetry_up,
                   const unsigned int &skipped_packet_cnt,
                   const unsigned int &injection_fail_cnt,
                   const double &kbitrate,
                   const double &kbitrate_measured,
                   const unsigned int &damaged_block_cnt,
                   const int &damaged_block_percent,
                   const unsigned int &lost_packet_cnt,
                   const int &lost_packet_percent,
                   const int &airpi_load,
                   const int &airpi_temp,
                   const double &air_batt_v,
                   const int &flight_mah,
                   const int &distance,
                   const double &home_course,
                   const double &homelat,
                   const double &homelon,
                   const QString &flight_time,
                   const double &flight_distance)
                    : m_flight_mode(flight_mode),
                    m_time(time),
                    m_lat(lat),
                    m_lon(lon),
                    m_alt(alt),
                    m_speed(speed),
                    m_heading(heading),
                    m_vertical(vertical),
                    m_pitch(pitch),
                    m_roll(roll),
                    m_throttle(throttle),
                    m_control_pitch(control_pitch),
                    m_control_roll(control_roll),
                    m_control_yaw(control_yaw),
                    m_control_throttle(control_throttle),
                    m_rssi_up(rssi_up),
                    m_rssi_down(rssi_down),
                    m_lost_packet_cnt_rc(lost_packet_cnt_rc),
                    m_lost_packet_cnt_telemetry_up(lost_packet_cnt_telemetry_up),
                    m_skipped_packet_cnt(skipped_packet_cnt),
                    m_injection_fail_cnt(injection_fail_cnt),
                    m_kbitrate(kbitrate),
                    m_kbitrate_measured(kbitrate_measured),
                    m_damaged_block_cnt(damaged_block_cnt),
                    m_damaged_block_percent(damaged_block_percent),
                    m_lost_packet_cnt(lost_packet_cnt),
                    m_lost_packet_percent(lost_packet_percent),
                    m_airpi_load(airpi_load),
                    m_airpi_temp(airpi_temp),
                    m_air_batt_v(air_batt_v),
                    m_flight_mah(flight_mah),
                    m_distance(distance),
                    m_home_course(home_course),
                    m_homelat(homelat),
                    m_homelon(homelon),
                    m_flight_time(flight_time),
                    m_flight_distance(flight_distance)
{
}

QString BlackBox::flight_mode() const{
    return m_flight_mode;
}
QString BlackBox::time() const{
    return m_time;
}
double BlackBox::lat() const{
    return m_lat;
}
double BlackBox::lon() const{
    return m_lon;
}
double BlackBox::alt() const{
    return m_alt;
}
double BlackBox::speed() const{
    return m_speed;
}
int BlackBox::heading() const{
    return m_heading;
}
double BlackBox::vertical() const{
    return m_vertical;
}
double BlackBox::pitch() const{
    return m_pitch;
}
double BlackBox::roll() const{
    return m_roll;
}
double BlackBox::throttle() const{
    return m_throttle;
}
int BlackBox::control_pitch() const{
    return m_control_pitch;
}
int BlackBox::control_roll() const{
    return m_control_roll;
}
int BlackBox::control_yaw() const{
    return m_control_yaw;
}
int BlackBox::control_throttle() const{
    return m_control_throttle;
}
int BlackBox::rssi_up() const{
    return m_rssi_up;
}
int BlackBox::rssi_down() const{
    return m_rssi_down;
}
unsigned int BlackBox::lost_packet_cnt_rc() const{
    return m_lost_packet_cnt_rc;
}
unsigned int BlackBox::lost_packet_cnt_telemetry_up() const{
    return m_lost_packet_cnt_telemetry_up;
}
unsigned int BlackBox::skipped_packet_cnt() const{
    return m_skipped_packet_cnt;
}
unsigned int BlackBox::injection_fail_cnt() const{
    return m_injection_fail_cnt;
}
double BlackBox::kbitrate() const{
    return m_kbitrate;
}
double BlackBox::kbitrate_measured() const{
    return m_kbitrate_measured;
}
unsigned int BlackBox::damaged_block_cnt() const{
    return m_damaged_block_cnt;
}
int BlackBox::damaged_block_percent() const{
    return m_damaged_block_percent;
}
unsigned int BlackBox::lost_packet_cnt() const{
    return m_lost_packet_cnt;
}
int BlackBox::lost_packet_percent() const{
    return m_lost_packet_percent;
}
int BlackBox::airpi_load() const{
    return m_airpi_load;
}
int BlackBox::airpi_temp() const{
    return m_airpi_temp;
}
double BlackBox::air_batt_v() const{
    return m_air_batt_v;
}
int BlackBox::flight_mah() const{
    return m_flight_mah;
}
int BlackBox::distance() const{
    return m_distance;
}
double BlackBox::home_course() const{
    return m_home_course;
}
double BlackBox::homelat() const{
    return m_homelat;
}
double BlackBox::homelon() const{
    return m_homelon;
}
QString BlackBox::flight_time() const{
    return m_flight_time;
}
double BlackBox::flight_distance() const{
    return m_flight_distance;
}

static BlackBoxModel* _instance = nullptr;

BlackBoxModel* BlackBoxModel::instance() {
    if (_instance == nullptr) {
        _instance = new BlackBoxModel();
    }
    return _instance;
}

BlackBoxModel::BlackBoxModel(QObject *parent): QAbstractListModel(parent){
    qDebug() << "BlackBoxModel::BlackBoxModel()";
}

void BlackBoxModel::initBlackBoxModel() {
    qDebug() << "BlackBoxModel::initBlackBoxModel()";
}

void BlackBoxModel::addBlackBoxObject(const BlackBox &blackbox){
        //qDebug() << "BlackBoxModel::addBlackBoxMarker()";

        beginInsertRows(QModelIndex(), rowCount(), rowCount());

        m_blackbox.insert(rowCount(), blackbox);

        endInsertRows();

       emit dataChanged(this->index(rowCount()),this->index(rowCount()));

        //qDebug() << "BlackBoxModel rowcount=" << rowCount();

        //blackBoxModelChanged(rowCount());

        //playBlackBoxObject(rowCount()-1);
        //qDebug() << "BlackBoxModel test flight mode=" << mblackbox.alt();

}



void BlackBoxModel::removeAllBlackBoxMarkers(){
    //remove all rows before adding new
    beginResetModel();
    m_blackbox.clear();
    endResetModel();
    emit dataChanged(this->index(0),this->index(rowCount()));
}

int BlackBoxModel::rowCount(const QModelIndex &parent) const{
    if (parent.isValid())
        return 0;
    return m_blackbox.count();
}

QVariant BlackBoxModel::data(const QModelIndex &index, int role) const{
    if (index.row() < 0 || index.row() >= m_blackbox.count())
        return QVariant();

    const BlackBox &blackbox = m_blackbox[index.row()];

    if(role == Flight_Mode)
        return blackbox.flight_mode();
    else if (role == Time)
        return blackbox.time();
    else if (role == Lat)
        return blackbox.lat();
    else if (role == Lon)
        return blackbox.lon();
    else if (role == Alt)
        return blackbox.alt();
    else if (role == Speed)
        return blackbox.speed();
    else if (role == Heading)
        return blackbox.heading();
    else if (role == Vertical)
        return blackbox.vertical();
    else if (role == Pitch)
        return blackbox.pitch();
    else if (role == Roll)
        return blackbox.roll();
    else if (role == Throttle)
        return blackbox.throttle();
    else if (role == Control_pitch)
        return blackbox.control_pitch();
    else if (role == Control_roll)
        return blackbox.control_roll();
    else if (role == Control_yaw)
        return blackbox.control_yaw();
    else if (role == Control_throttle)
        return blackbox.control_throttle();
    else if (role == Rssi_Up)
        return blackbox.rssi_up();
    else if (role == Rssi_Down)
        return blackbox.rssi_down();
    else if (role == Lost_packet_cnt_rc)
        return blackbox.lost_packet_cnt_rc();
    else if (role == Lost_packet_cnt_telemetry_up)
        return blackbox.lost_packet_cnt_telemetry_up();
    else if (role == Skipped_packet_cnt)
        return blackbox.skipped_packet_cnt();
    else if (role == Injection_fail_cnt)
        return blackbox.injection_fail_cnt();
    else if (role == Kbitrate)
        return blackbox.kbitrate();
    else if (role == Kbitrate_measured)
        return blackbox.kbitrate_measured();
    else if (role == Damaged_block_cnt)
        return blackbox.damaged_block_cnt();
    else if (role == Damaged_block_percent)
        return blackbox.damaged_block_percent();
    else if (role == Lost_packet_cnt)
        return blackbox.lost_packet_cnt();
    else if (role == Lost_packet_percent)
        return blackbox.lost_packet_percent();
    else if (role == Airpi_Load)
        return blackbox.airpi_load();
    else if (role == Airpi_Temp)
        return blackbox.airpi_temp();
    else if (role == Air_Batt_V)
        return blackbox.air_batt_v();
    else if (role == Flight_mah)
        return blackbox.flight_mah();
    else if (role == Distance)
        return blackbox.distance();
    else if (role == Home_course)
        return blackbox.home_course();
    else if (role == Homelat)
        return blackbox.homelat();
    else if (role == Homelon)
        return blackbox.homelon();
    else if (role == Flight_time)
        return blackbox.flight_time();
    else if (role == Flight_distance)
        return blackbox.flight_distance();

    return QVariant();
}

QHash<int, QByteArray> BlackBoxModel::roleNames() const{
    QHash<int, QByteArray> roles;
    roles[Flight_Mode] = "flight_mode";
    roles[Time] = "time";
    roles[Lat] = "lat";
    roles[Lon] = "lon";
    roles[Alt] = "alt";
    roles[Speed] = "speed";
    roles[Heading] = "heading";
    roles[Vertical] = "vertical";
    roles[Pitch] = "pitch";
    roles[Roll] = "roll";
    roles[Throttle] = "throttle";
    roles[Control_pitch] = "control_pitch";
    roles[Control_roll] = "control_roll";
    roles[Control_yaw] = "control_yaw";
    roles[Control_throttle] = "control_throttle";
    roles[Rssi_Up] = "rssi_up";
    roles[Rssi_Down] = "rssi_down";
    roles[Lost_packet_cnt_rc] = "lost_packet_cnt_rc";
    roles[Lost_packet_cnt_telemetry_up] = "lost_packet_cnt_telemetry_up";
    roles[Skipped_packet_cnt] = "skipped_packet_cnt";
    roles[Injection_fail_cnt] = "injection_fail_cnt";
    roles[Kbitrate] = "kbitrate";
    roles[Kbitrate_measured] = "kbitrate_measured";
    roles[Damaged_block_cnt] = "damaged_block_cnt";
    roles[Damaged_block_percent] = "damaged_block_percent";
    roles[Lost_packet_cnt] = "lost_packet_cnt";
    roles[Lost_packet_percent] = "lost_packet_percent";
    roles[Airpi_Load] = "airpi_load";
    roles[Airpi_Temp] = "airpi_temp";
    roles[Air_Batt_V] = "air_batt_v";
    roles[Flight_mah] = "flight_mah";
    roles[Distance] = "distance";
    roles[Home_course] = "home_course";
    roles[Homelat] = "homelat";
    roles[Homelon] = "homelon";
    roles[Flight_time] = "flight_time";
    roles[Flight_distance] = "flight_distance";

    return roles;
}

BlackBox BlackBoxModel::getBlackBoxObject(int index)const {
    return m_blackbox.at(index);
}

void BlackBoxModel::playBlackBoxObject(int index){
    qDebug() << "playBlackBoxMarker: " << index;
    if (index>=rowCount()){
        index=rowCount()-1;
    }
    auto blackbox= getBlackBoxObject(index);

    OpenHD::instance()->set_flight_mode(blackbox.flight_mode());
    OpenHD::instance()->set_lat(blackbox.lat());
    OpenHD::instance()->set_lon(blackbox.lon());
    OpenHD::instance()->set_alt_rel(blackbox.alt());
    OpenHD::instance()->set_speed(blackbox.speed());
    OpenHD::instance()->set_hdg(blackbox.heading());
    OpenHD::instance()->set_vsi(blackbox.vertical());
    OpenHD::instance()->set_pitch(blackbox.pitch());
    OpenHD::instance()->set_roll(blackbox.roll());
    OpenHD::instance()->set_throttle(blackbox.throttle());
    OpenHD::instance()->set_control_pitch(blackbox.control_pitch());
    OpenHD::instance()->set_control_roll(blackbox.control_roll());
    OpenHD::instance()->set_control_yaw(blackbox.control_yaw());
    OpenHD::instance()->set_control_throttle(blackbox.control_throttle());
    OpenHD::instance()->set_downlink_rssi(blackbox.rssi_down());
    OpenHD::instance()->set_current_signal_joystick_uplink(blackbox.rssi_up());
    OpenHD::instance()->set_lost_packet_cnt_rc(blackbox.lost_packet_cnt_rc());
    OpenHD::instance()->set_lost_packet_cnt_telemetry_up(blackbox.lost_packet_cnt_telemetry_up());
    OpenHD::instance()->set_skipped_packet_cnt(blackbox.skipped_packet_cnt());
    OpenHD::instance()->set_injection_fail_cnt(blackbox.injection_fail_cnt());
    OpenHD::instance()->set_kbitrate(blackbox.kbitrate());
    OpenHD::instance()->set_kbitrate_measured(blackbox.kbitrate_measured());
    OpenHD::instance()->set_damaged_block_cnt(blackbox.damaged_block_cnt());
    OpenHD::instance()->set_damaged_block_percent(blackbox.damaged_block_percent());
    OpenHD::instance()->set_lost_packet_cnt(blackbox.lost_packet_cnt());
    OpenHD::instance()->set_lost_packet_percent(blackbox.lost_packet_percent());
    OpenHD::instance()->set_cpuload_air(blackbox.airpi_load());
    OpenHD::instance()->set_temp_air(blackbox.airpi_temp());
    OpenHD::instance()->set_battery_voltage(blackbox.air_batt_v());
    OpenHD::instance()->set_flight_mah(blackbox.flight_mah());
    //maybe blackbox.distance should be blackbox.home_distance
    OpenHD::instance()->set_home_distance(blackbox.distance());
    OpenHD::instance()->set_home_course(blackbox.home_course());
    OpenHD::instance()->set_homelat(blackbox.homelat());
    OpenHD::instance()->set_homelon(blackbox.homelon());
    OpenHD::instance()->set_flight_time(blackbox.flight_time());
    OpenHD::instance()->set_flight_distance(blackbox.flight_distance());

}
