#ifndef BLACKBOXMODEL_H
#define BLACKBOXMODEL_H
#include <QObject>
#include <QtQuick>

#include "constants.h"
#include "util.h"

#include <QAbstractListModel>
#include <QGeoCoordinate>

class BlackBox
{
public:
    BlackBox(const QString &flight_mode,
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
             const double &flight_distance);

    QString flight_mode() const;
    QString time() const;
    double lat() const;
    double lon() const;
    double alt() const;
    double speed() const;
    int heading() const;
    double vertical() const;
    double pitch() const;
    double roll() const;
    double throttle() const;
    int control_pitch() const;
    int control_roll() const;
    int control_yaw() const;
    int control_throttle() const;
    int rssi_up() const;
    int rssi_down() const;
    unsigned int lost_packet_cnt_rc() const;
    unsigned int lost_packet_cnt_telemetry_up() const;
    unsigned int skipped_packet_cnt() const;
    unsigned int injection_fail_cnt() const;
    double kbitrate() const;
    double kbitrate_measured() const;
    unsigned int damaged_block_cnt() const;
    int damaged_block_percent() const;
    unsigned int lost_packet_cnt() const;
    int lost_packet_percent() const;
    int airpi_load() const;
    int airpi_temp() const;
    double air_batt_v() const;
    int flight_mah() const;
    //double total_mah() const;
    int distance() const;
    double home_course() const;
    double homelat() const;
    double homelon() const;
    QString flight_time() const;
    double flight_distance() const;

private:
    QString m_flight_mode;
    QString m_time;
    double m_lat;
    double m_lon;
    double m_alt;
    double m_speed;
    int m_heading;
    double m_vertical;
    double m_pitch;
    double m_roll;
    double m_throttle;
    int m_control_pitch;
    int m_control_roll;
    int m_control_yaw;
    int m_control_throttle;
    int m_rssi_up;
    int m_rssi_down;
    unsigned int m_lost_packet_cnt_rc;
    unsigned int m_lost_packet_cnt_telemetry_up;
    unsigned int m_skipped_packet_cnt;
    unsigned int m_injection_fail_cnt;
    double m_kbitrate;
    double m_kbitrate_measured;
    unsigned int m_damaged_block_cnt;
    int m_damaged_block_percent;
    unsigned int m_lost_packet_cnt;
    int m_lost_packet_percent;
    int m_airpi_load;
    int m_airpi_temp;
    double m_air_batt_v;
    int m_flight_mah;
    //double total_mah;
    int m_distance;
    double m_home_course;
    double m_homelat;
    double m_homelon;
    QString m_flight_time;
    double m_flight_distance;
};



class BlackBoxModel : public QAbstractListModel {
    Q_OBJECT


public:
    explicit BlackBoxModel(QObject *parent = nullptr);

    static BlackBoxModel* instance();

    enum BlackBoxRoles {
        Flight_Mode = Qt::UserRole + 1,
        Time,
        Lat,
        Lon,
        Alt,
        Speed,
        Heading,
        Vertical,
        Pitch,
        Roll,
        Throttle,
        Control_pitch,
        Control_roll,
        Control_yaw,
        Control_throttle,
        Rssi_Up,
        Rssi_Down,
        Lost_packet_cnt_rc,
        Lost_packet_cnt_telemetry_up,
        Skipped_packet_cnt,
        Injection_fail_cnt,
        Kbitrate,
        Kbitrate_measured,
        Damaged_block_cnt,
        Damaged_block_percent,
        Lost_packet_cnt,
        Lost_packet_percent,
        Airpi_Load,
        Airpi_Temp,
        Air_Batt_V,
        Flight_mah,
        Distance,
        Home_course,
        Homelat,
        Homelon,
        Flight_time,
        Flight_distance
        };



    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

    QHash<int, QByteArray> roleNames() const override;

    //Q_INVOKABLE void playBlackBoxObject(int index);
    Q_INVOKABLE BlackBox getBlackBoxObject(int index) const;

signals:
    //void blackBoxModelChanged(int rows);

public slots:
    void initBlackBoxModel();
    void addBlackBoxObject(const BlackBox &blackbox);
    void removeAllBlackBoxMarkers();
    void playBlackBoxObject(int index);

private:
    QList<BlackBox> m_blackbox;
    //int m_row_limit;
    //QSettings settings;
};

#endif // BLACKBOXMODEL_H
