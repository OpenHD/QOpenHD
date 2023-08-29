#include "fcmsgintervalhandler.h"


FCMsgIntervalHandler &FCMsgIntervalHandler::instance()
{
    static FCMsgIntervalHandler instance;
    return instance;
}
