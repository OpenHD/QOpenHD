#include "mavlinkcommand.h"


// Copy pasted all the stuff from mavlinkbase here that might be usefully for later things
// but will probably replaced by mavsdk stuff

typedef enum MavlinkState {
    MavlinkStateDisconnected,
    MavlinkStateConnected,
    MavlinkStateGetParameters,
    MavlinkStateIdle
} MavlinkState;


/*
 * This is the entry point for sending mavlink commands to any component, including flight
 * controllers and microservices.
 *
 * We accept a MavlinkCommand subclass with the fields set according to the type of command
 * being sent, and then we switch the state machine running in commandStateLoop() to the
 * sending state.
 *
 * The state machine then takes care of waiting for a command acknowledgement, and if one
 * is not received within the timeout, the command is resent up to 5 times.
 *
 * Subclasses are responsible for connecting a slot to the commandDone and commandFailed
 * signals to further handle the result.
 *
 */
/*void MavlinkBase::sendCommand(MavlinkCommand command) {
    m_current_command.reset(new MavlinkCommand(command));
    m_command_state = MavlinkCommandStateSend;
}


void MavlinkBase::commandStateLoop() {
    switch (m_command_state) {
        case MavlinkCommandStateReady: {
            // do nothing, no command being sent
            break;
        }
        case MavlinkCommandStateSend: {
        qDebug() << "CMD SEND";
            mavlink_message_t msg;
            m_command_sent_timestamp = QDateTime::currentMSecsSinceEpoch();
            auto mavlink_sysid= QOpenHDMavlinkHelper::getSysId();
            //qDebug() << "SYSID=" << mavlink_sysid;
            //qDebug() << "Target SYSID=" << targetSysID;

            if (m_current_command->m_command_type == MavlinkCommandTypeLong) {
                mavlink_msg_command_long_pack(mavlink_sysid, MAV_COMP_ID_MISSIONPLANNER, &msg, targetSysID, targetCompID, m_current_command->command_id, m_current_command->long_confirmation, m_current_command->long_param1, m_current_command->long_param2, m_current_command->long_param3, m_current_command->long_param4, m_current_command->long_param5, m_current_command->long_param6, m_current_command->long_param7);
            } else {
                mavlink_msg_command_int_pack(mavlink_sysid, MAV_COMP_ID_MISSIONPLANNER, &msg, targetSysID, targetCompID, m_current_command->int_frame, m_current_command->command_id, m_current_command->int_current, m_current_command->int_autocontinue, m_current_command->int_param1, m_current_command->int_param2, m_current_command->int_param3, m_current_command->int_param4, m_current_command->int_param5, m_current_command->int_param6, m_current_command->int_param7);
            }
            sendData(msg);

            // now wait for ack
            m_command_state = MavlinkCommandStateWaitACK;

            break;
        }
        case MavlinkCommandStateWaitACK: {
        qDebug() << "CMD ACK";
            qint64 current_timestamp = QDateTime::currentMSecsSinceEpoch();
            auto elapsed = current_timestamp - m_command_sent_timestamp;

            if (elapsed > 200) {
                // no ack in 200ms, cancel or resend
                qDebug() << "CMD RETRY";
                if (m_current_command->retry_count >= 5) {
                    m_command_state = MavlinkCommandStateFailed;
                    m_current_command.reset();
                    return;
                }
                m_current_command->retry_count = m_current_command->retry_count + 1;
                if (m_current_command->m_command_type == MavlinkCommandTypeLong) {
                    // incremement the confirmation parameter according to the Mavlink command
                    //   documentation
                    m_current_command->long_confirmation = m_current_command->long_confirmation + 1;
                }
                m_command_state = MavlinkCommandStateSend;
            }
            break;
        }
        case MavlinkCommandStateDone: {
            qDebug() << "CMD DONE";
            m_current_command.reset();
            emit commandDone();
            m_command_state = MavlinkCommandStateReady;
            break;
        }
        case MavlinkCommandStateFailed: {
            qDebug() << "CMD FAIL";
            m_current_command.reset();
            emit commandFailed();
            m_command_state = MavlinkCommandStateReady;
            break;
        }
    }
}*/



/*void MavlinkBase::stateLoop() {
    qint64 current_timestamp = QDateTime::currentMSecsSinceEpoch();
    set_last_heartbeat(current_timestamp - last_heartbeat_timestamp);

    set_last_attitude(current_timestamp - last_attitude_timestamp);
    set_last_battery(current_timestamp - last_battery_timestamp);
    set_last_gps(current_timestamp - last_gps_timestamp);
    set_last_vfr(current_timestamp - last_vfr_timestamp);

    return;

    switch (state) {
        case MavlinkStateDisconnected: {
            set_loading(false);
            set_saving(false);
            if (m_ground_available) {
                state = MavlinkStateConnected;
            }
            break;
        }
        case MavlinkStateConnected: {
            if (initialConnectTimer == -1) {
                initialConnectTimer = QDateTime::currentMSecsSinceEpoch();
            } else if (current_timestamp - initialConnectTimer < 5000) {
                state = MavlinkStateGetParameters;
                resetParamVars();
                fetchParameters();
            }
            break;
        }
        case MavlinkStateGetParameters: {
            set_loading(true);
            set_saving(false);
            qint64 currentTime = QDateTime::currentMSecsSinceEpoch();

            if (isConnectionLost()) {
                resetParamVars();
                m_ground_available = false;
                state = MavlinkStateDisconnected;
            }

            if ((parameterCount != 0) && parameterIndex == (parameterCount - 1)) {
                emit allParametersChanged();
                state = MavlinkStateIdle;
            }

            if (currentTime - parameterLastReceivedTime > 7000) {
                resetParamVars();
                m_ground_available = false;
                state = MavlinkStateDisconnected;
            }
            break;
        }
        case MavlinkStateIdle: {
            set_loading(false);

            if (isConnectionLost()) {
                resetParamVars();
                m_ground_available = false;
                state = MavlinkStateDisconnected;
            }

            break;
        }
    }
}*/


/*void MavlinkBase::processMavlinkTCPData() {
    QByteArray data = mavlinkSocket->readAll();
    processData(data);
}


void MavlinkBase::processMavlinkUDPDatagrams() {
    QByteArray datagram;

    while ( ((QUdpSocket*)mavlinkSocket)->hasPendingDatagrams()) {
        m_ground_available = true;

        datagram.resize(int(((QUdpSocket*)mavlinkSocket)->pendingDatagramSize()));
        QHostAddress _groundAddress;
        quint16 groundPort;
         ((QUdpSocket*)mavlinkSocket)->readDatagram(datagram.data(), datagram.size(), &_groundAddress, &groundPort);
        groundUDPPort = groundPort;
        processData(datagram);
    }
}*/


/*void MavlinkBase::processData(QByteArray data) {
    typedef QByteArray::Iterator Iterator;
    mavlink_message_t msg;

    for (Iterator i = data.begin(); i != data.end(); i++) {
        char c = *i;

        uint8_t res = mavlink_parse_char(MAVLINK_COMM_0, (uint8_t)c, &msg, &r_mavlink_status);

        if (res) {
            //Not the target we're talking to, so reject it
            if (m_restrict_sysid && (msg.sysid != targetSysID)) {
                return;
            }

            if (m_restrict_compid && (msg.compid != targetCompID)) {
                return;
            }

            // process ack messages in the base class, subclasses will receive a signal
            // to indicate success or failure
            if (msg.msgid == MAVLINK_MSG_ID_COMMAND_ACK) {
                mavlink_command_ack_t ack;
                mavlink_msg_command_ack_decode(&msg, &ack);
                switch (ack.result) {
                    case MAV_CMD_ACK_OK: {
                        m_command_state = MavlinkCommandStateDone;
                        break;
                    }
                    default: {
                        m_command_state = MavlinkCommandStateFailed;
                        break;
                    }
                }
            } else {
                emit processMavlinkMessage(msg);
            }
        }
    }
}*/
