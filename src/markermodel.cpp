#include <QThread>
#include <QtConcurrent>
#include <QFutureWatcher>
#include <QFuture>

#include "constants.h"

#include "markermodel.h"
#include "opensky.h"


Traffic::Traffic(const QString &callsign, const int &contact, const double &lat, const double &lon,
                 const double &alt, const double &velocity, const double &track, const double &vertical,
                 const int &distance)
                : m_callsign(callsign), m_contact(contact), m_lat(lat), m_lon(lon), m_alt(alt),
                  m_velocity(velocity), m_track(track), m_vertical(vertical), m_distance(distance)
{
}

QString Traffic::callsign() const{
    return m_callsign;
}
int Traffic::contact() const{
    return m_contact;
}
double Traffic::lat() const{
    return m_lat;
}
double Traffic::lon() const{
    return m_lon;
}
double Traffic::alt() const{
    return m_alt;
}
double Traffic::velocity() const{
    return m_velocity;
}
double Traffic::track() const{
    return m_track;
}
double Traffic::vertical() const{
    return m_vertical;
}
int Traffic::distance() const{
    return m_distance;
}


static MarkerModel* _instance = nullptr;

MarkerModel* MarkerModel::instance() {
    if (_instance == nullptr) {
        _instance = new MarkerModel();
    }
    return _instance;
}

MarkerModel::MarkerModel(QObject *parent): QAbstractListModel(parent){
    qDebug() << "MarkerModel::MarkerModel()";
}

void MarkerModel::initMarkerModel() {
    qDebug() << "MarkerModel::initMarkerModel()";
    //auto openSky = OpenSky::instance();
}

void MarkerModel::addMarker(int current_row, int total_rows, const Traffic &traffic){

    if (current_row == 0){
        //LIMIT HOW MANY OF THE NEAREST MARKERS APPEAR
         m_row_limit = settings.value("adsb_marker_limit").toInt();

        if (total_rows<m_row_limit){
            m_row_limit=total_rows-1;
        }
        //qDebug() << "begin insert " << m_row_limit;
        beginInsertRows(QModelIndex(), 0, m_row_limit);
    }

    int rowcount=rowCount();

    //sort to find nearest
    if (rowcount>0){
        //int distance=traffic.distance();

        for (int i = 0; i < rowcount; ++i) {
            Traffic compare_traffic=m_traffic.at(i);
            if (traffic.distance() < compare_traffic.distance()){
                m_traffic.insert(i, traffic);
                break;
            }
            if (i == rowcount-1){
                m_traffic.insert(i+1, traffic);
                break;
            }
        }
    }
    else {
        //first entry
        m_traffic.insert(0, traffic);
    }
}

void MarkerModel::doneAddingMarkers(){
    //qDebug() << "onDoneAddingMarkers rowcount=" << rowCount();
    endInsertRows();

    //get the last displayed row and distance of that object
        Traffic distant_traffic=m_traffic.at(m_row_limit);
        set_adsb_radius(distant_traffic.distance()*1000);

    // not necessary- endinsertrows sends signal
   // emit dataChanged(this->index(0),this->index(rowCount()));
}

void MarkerModel::set_adsb_radius(int adsb_radius){
    m_adsb_radius=adsb_radius;
    //qDebug() << "adsbradius=" << m_adsb_radius;
    emit adsb_radius_changed(m_adsb_radius);
}

void MarkerModel::removeAllMarkers(){
    //remove all rows before adding new
    beginResetModel();
    m_traffic.clear();
    endResetModel();
    emit dataChanged(this->index(0),this->index(rowCount()));
}

Traffic MarkerModel::getMarker(int index)const {
    return m_traffic.at(index);
}

int MarkerModel::rowCount(const QModelIndex &parent) const{
    if (parent.isValid())
        return 0;
    return m_traffic.count();
}

QVariant MarkerModel::data(const QModelIndex &index, int role) const{
    if (index.row() < 0 || index.row() >= m_traffic.count())
        return QVariant();

    const Traffic &traffic = m_traffic[index.row()];

    if(role == Callsign)
        return traffic.callsign();
    else if (role == Contact)
        return traffic.contact();
    else if (role == Lat)
        return traffic.lat();
    else if (role == Lon)
        return traffic.lon();
    else if (role == Alt)
        return traffic.alt();
    else if (role == Velocity)
        return traffic.velocity();
    else if (role == Track)
        return traffic.track();
    else if (role == Vertical)
        return traffic.vertical();
    else if (role == Distance)
        return traffic.distance();
    return QVariant();
}

QHash<int, QByteArray> MarkerModel::roleNames() const{
    QHash<int, QByteArray> roles;
    roles[Callsign] = "callsign";
    roles[Contact] = "contact";
    roles[Lat] = "lat";
    roles[Lon] = "lon";
    roles[Alt] = "alt";
    roles[Velocity] = "velocity";
    roles[Track] = "track";
    roles[Vertical] = "vertical";
    roles[Distance] = "distance";
    return roles;
}
