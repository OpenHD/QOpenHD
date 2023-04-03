#include "fcmavlinkmissionitemsmodel.h"

FCMavlinkMissionItemsModel::FCMavlinkMissionItemsModel()
{

}

FCMavlinkMissionItemsModel& FCMavlinkMissionItemsModel::instance()
{
    static FCMavlinkMissionItemsModel instance;
    return instance;
}
