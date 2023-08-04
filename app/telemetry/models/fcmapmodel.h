#ifndef FCMAPMODEL_H
#define FCMAPMODEL_H

#include <qobject.h>



//
// This model extends the fcmavlinksystem model for map-specific features
// R.n it only exposes the flght path as a coordinate points such that we can draw the corresponding Poly Line in qml
//
class FCMapModel : public QObject
{
    Q_OBJECT
public:
    explicit FCMapModel(QObject *parent = nullptr);
    // singleton for accessing the model from c++
    static FCMapModel& instance();
};

#endif // FCMAPMODEL_H
