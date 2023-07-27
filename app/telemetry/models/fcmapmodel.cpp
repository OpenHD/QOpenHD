#include "fcmapmodel.h"



FCMapModel::FCMapModel(QObject *parent): QObject(parent) {

}

FCMapModel &FCMapModel::instance()
{
    static FCMapModel instance;
    return instance;
}
