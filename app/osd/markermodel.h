#ifndef MARKERMODEL_H
#define MARKERMODEL_H
#include <QObject>
#include <QtQuick>

#include "constants.h"
#include "util.h"

#include <QAbstractListModel>
#include <QGeoCoordinate>

class Traffic
{
public:
    Traffic(const QString &callsign, const int &contact, const double &lat, const double &lon,
            const double &alt, const double &velocity, const double &track, const double &vertical,
            const int &distance);

    QString callsign() const;
    int contact() const;
    double lat() const;
    double lon() const;
    double alt() const;
    double velocity() const;
    double track() const;
    double vertical() const;
    int distance() const;

private:
    QString m_callsign= "---";
    int m_contact= 0;
    double m_lat= 0.0;
    double m_lon= 0.0;
    double m_alt= 99999;
    double m_velocity= 0;
    double m_track= 0.0;
    double m_vertical= 0.0;
    int m_distance= 0;
};



class MarkerModel : public QAbstractListModel {
    Q_OBJECT


public:
    explicit MarkerModel(QObject *parent = nullptr);

    static MarkerModel* instance();

    enum MarkerRoles {
            Callsign = Qt::UserRole + 1,
            Contact,
            Lat,
            Lon,
            Alt,
            Velocity,
            Track,
            Vertical,
            Distance
        };

    Q_INVOKABLE Traffic getMarker(int index) const;

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

    QHash<int, QByteArray> roleNames() const override;

    Q_PROPERTY(int adsb_radius MEMBER m_adsb_radius WRITE set_adsb_radius NOTIFY adsb_radius_changed)
    void set_adsb_radius(int adsb_radius);

signals:
    void adsb_radius_changed(int adsb_radius);

public slots:
    void initMarkerModel();
    void addMarker(int current_row , int total_rows, const Traffic &traffic);
    void doneAddingMarkers();
    void removeAllMarkers();
    //int getAdsbRadius();

private:
    QList<Traffic> m_traffic;
    int m_row_limit;
    QSettings settings;
    int m_adsb_radius;
};

#endif // MARKERMODEL_H
