#ifndef MAVLINKCOMMAND_H
#define MAVLINKCOMMAND_H

#include <QObject>
#include <QtQuick>
#include <openhd/mavlink.h>

// This is from stephen, here for legacy but might get re-used to some degree
typedef enum MavlinkCommandState {
    MavlinkCommandStateReady,
    MavlinkCommandStateSend,
    MavlinkCommandStateWaitACK,
    MavlinkCommandStateDone,
    MavlinkCommandStateFailed
} MavlinkCommandState;

typedef enum MavlinkCommandType {
    MavlinkCommandTypeLong,
    MavlinkCommandTypeInt
} MavlinkCommandType;

class MavlinkCommand  {
public:
    MavlinkCommand(MavlinkCommandType command_type) : m_command_type(command_type) {}
    MavlinkCommandType m_command_type;
    uint16_t command_id = 0;
    uint8_t retry_count = 0;

    uint8_t long_confirmation = 0;
    float long_param1 = 0;
    float long_param2 = 0;
    float long_param3 = 0;
    float long_param4 = 0;
    float long_param5 = 0;
    float long_param6 = 0;
    float long_param7 = 0;


    uint8_t int_frame = 0;
    uint8_t int_current = 0;
    uint8_t int_autocontinue = 0;
    float int_param1 = 0;
    float int_param2 = 0;
    float int_param3 = 0;
    float int_param4 = 0;
    int   int_param5 = 0;
    int   int_param6 = 0;
    float int_param7 = 0;
};

class MavlinkStateMachine{
public:
private:

};



#endif // MAVLINKCOMMAND_H
