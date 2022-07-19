#include "OHDConnection.h"

#include "qopenhdmavlinkhelper.hpp"
#include "telemetry/openhd_defines.hpp"

#include "settings/mavlinksettingsmodel.h"

OHDConnection::OHDConnection(QObject *parent,bool useTcp):QObject(parent),USE_TCP(useTcp)
{
#ifndef X_USE_MAVSDK
    if(USE_TCP){
        tcpClientSock = new QTcpSocket(this);
        connect(tcpClientSock, &QTcpSocket::readyRead, this, &OHDConnection::tcpReadyRead);
        connect(tcpClientSock, &QTcpSocket::connected, this, &OHDConnection::tcpConnected);
        connect(tcpClientSock, &QTcpSocket::disconnected, this, &OHDConnection::tcpDisconnected);
    }else{
        udpSocket = new QUdpSocket(this);
        //auto bindStatus = udpSocket->bind(QHostAddress::Any,QOPENHD_GROUND_CLIENT_UDP_PORT_IN);
        // this is how it is done int QGroundCOntroll:
        //  _telemetrySocket->bind(QHostAddress::LocalHost, 0, QUdpSocket::ShareAddress);
        //auto bindStatus = udpSocket->bind(QHostAddress::LocalHost,QOPENHD_GROUND_CLIENT_UDP_PORT_IN);
        auto bindStatus = udpSocket->bind(QHostAddress::Any,QOPENHD_GROUND_CLIENT_UDP_PORT_IN);
        if (!bindStatus) {
            qDebug() <<"Cannot bind UDP Socket";
        }
        connect(udpSocket, &QUdpSocket::readyRead, this, &OHDConnection::udpReadyRead);
    }
    start();
#endif //X_USE_MAVSDK
#ifdef X_USE_MAVSDK
    mavsdk=std::make_shared<mavsdk::Mavsdk>();
    mavsdk::log::subscribe([](mavsdk::log::Level level,   // message severity level
                              const std::string& message, // message text
                              const std::string& file,    // source file from which the message was sent
                              int line) {                 // line number in the source file
      // process the log message in a way you like
      qDebug()<<"MAVSDK::"<<message.c_str();
      // returning true from the callback disables printing the message to stdout
      return level < mavsdk::log::Level::Warn;
    });
    // NOTE: subscribe before adding any connection(s)
    mavsdk->subscribe_on_new_system([this]() {
        // hacky, fucking hell. mavsdk might call this callback with more than 1 system added.
        auto systems=mavsdk->systems();
        for(int i=mavsdk_already_known_systems;i<systems.size();i++){
            auto new_system=systems.at(i);
            this->onNewSystem(new_system);
        }
        mavsdk_already_known_systems=systems.size();
        //qDebug()<<this->mavsdk->systems().size();
        //auto system = this->mavsdk->systems().back();
        //this->onNewSystem(system);
    });
    mavsdk::ConnectionResult connection_result = mavsdk->add_udp_connection(QOPENHD_GROUND_CLIENT_UDP_PORT_IN);
    std::stringstream ss;
    ss<<"MAVSDK connection: " << connection_result;
    qDebug()<<ss.str().c_str();
    start();
#endif //X_USE_MAVSDK
}

void OHDConnection::onNewSystem(std::shared_ptr<mavsdk::System> system){
    const auto components=system->component_ids();
    qDebug()<<"System found"<<(int)system->get_system_id()<<" with components:"<<components.size();
    for(const auto& component:components){
        qDebug()<<"Component:"<<(int)component;
    }
    if(system->get_system_id()==OHD_SYS_ID_GROUND){
        qDebug()<<"Found OHD Ground station";
        systemOhdGround=system;
        passtroughOhdGround=std::make_shared<mavsdk::MavlinkPassthrough>(system);
        qDebug()<<"XX:"<<passtroughOhdGround->get_target_sysid();
        passtroughOhdGround->subscribe_message_async(MAVLINK_MSG_ID_ONBOARD_COMPUTER_STATUS,[](const mavlink_message_t& msg){
            //qDebug()<<"Got MAVLINK_MSG_ID_ONBOARD_COMPUTER_STATUS";
        });
        passtroughOhdGround->intercept_incoming_messages_async([this](mavlink_message_t& msg){
            //qDebug()<<"Intercept:Got message"<<msg.msgid;
            if(this->callback!=nullptr){
                 this->callback(msg);
            }
            return true;
        });
        passtroughOhdGround->intercept_outgoing_messages_async([](mavlink_message_t& msg){
            //qDebug()<<"Intercept:send message"<<msg.msgid;
            return true;
        });
        MavlinkSettingsModel::instanceGround().set_param_client(system);
        /*system->register_component_discovered_id_callback([](mavsdk::System::ComponentType comp_type, uint8_t comp_id){
            qDebug()<<"Ground component discovered:"<<(int)comp_id;
        });*/
    }else if(system->get_system_id()==OHD_SYS_ID_AIR){
        qDebug()<<"Found OHD AIR station";
        systemOhdAir=system;
        MavlinkSettingsModel::instanceAir().set_param_client(system);
        MavlinkSettingsModel::instanceAirCamera().set_param_client(system);

    }else if(system->has_autopilot()){
        // we got the flight controller
        telemetryFC=std::make_unique<mavsdk::Telemetry>(system);
        auto res=telemetryFC->set_rate_attitude(60);
        std::stringstream ss;
        ss<<res;
        qDebug()<<"Set rate result:"<<ss.str().c_str();
    }
    system->subscribe_is_connected([this,system](bool is_connected){
        qDebug()<<"System: "<<system->get_system_id()<<"connected: "<<(is_connected ? "Y" : "N");
    });
}

void OHDConnection::start(){
    // we only need a reconnection timer for tcp, in case of UDP it is safe to assume that
    // we never loose the port (data might or might not arrive at it though)
    if(USE_TCP){
        reconnectTimer = new QTimer(this);
        connect(reconnectTimer, &QTimer::timeout, this, &OHDConnection::reconnectIfDisconnected);
        reconnectTimer->start(1000);
    }
    // the heartbeat timer runs regardless of TCP or UDP
    heartbeatTimer = new QTimer(this);
    connect(heartbeatTimer, &QTimer::timeout, this, &OHDConnection::onHeartbeat);
    heartbeatTimer->start(1000);
}

void OHDConnection::stop(){
    if(USE_TCP){
        reconnectTimer->stop();
        tcpClientSock->disconnectFromHost();
    }
    heartbeatTimer->stop();
}

// called by the reconnect timer
void OHDConnection::reconnectIfDisconnected(){
    if (tcpClientSock->state() == QAbstractSocket::UnconnectedState) {
        qDebug() << "OHDConnection::reconnectIfDisconnected";
        tcpClientSock->connectToHost(QOPENHD_GROUND_CLIENT_TCP_ADDRESS, QOPENHD_GROUND_CLIENT_TCP_PORT);
    }
}

void OHDConnection::registerNewMessageCalback(MAV_MSG_CALLBACK cb){
    if(callback!= nullptr){
        // this might be a common programming mistake - you can only register one callback here
         qDebug()<<"OHDConnection::Overwriting already existing callback\n";
    }
    callback=std::move(cb);
}

void OHDConnection::sendMessage(mavlink_message_t msg){
    const auto sys_id=QOpenHDMavlinkHelper::getSysId();
    const auto comp_id=QOpenHDMavlinkHelper::getCompId();
    if(msg.sysid!=sys_id){
        // probably a programming error, the message was not packed with the right sys id
        qDebug()<<"WARN Sending message with sys id:"<<msg.sysid<<" instead of"<<sys_id;
    }
    if(msg.compid!=comp_id){
        // probably a programming error, the message was not packed with the right comp id
        qDebug()<<"WARN Sending message with comp id:"<<msg.compid<<" instead of"<<comp_id;
    }
#ifdef X_USE_MAVSDK
    if(mavsdk!=nullptr){
        if(passtroughOhdGround!=nullptr){
            passtroughOhdGround->send_message(msg);
        }else{
            // If the passtrough is not created yet, a connection to the OHD ground unit has not yet been established.
            //qDebug()<<"MAVSDK passtroughOhdGround not created";
            qDebug()<<"No OHD Ground unit connected";
        }
        return;
    }
#endif //X_USE_MAVSDK
    const auto buf=QOpenHDMavlinkHelper::mavlinkMessageToSendBuffer(msg);
    sendData(buf.data(),buf.size());
}

void OHDConnection::parseNewData(const uint8_t* data, int data_len){
    //qDebug()<<"OHDConnection::parseNewData"<<data_len;
    mavlink_message_t msg;
    for(int i=0;i<data_len;i++){
        uint8_t res = mavlink_parse_char(MAVLINK_COMM_0, (uint8_t)data[i], &msg, &receiveMavlinkStatus);
        if (res) {
            //qDebug()<<"Got new mavlink message";
            lastMavlinkMessage=std::chrono::steady_clock::now();
            if(callback!= nullptr){
                //qDebug()<<"Forwarding new mavlink message";
                callback(msg);
            }else{
                qDebug()<<"OHDConnection::No callback set,did you forget to add it ?";
            }
        }
    }
}

void OHDConnection::tcpReadyRead() {
    qDebug() << "OHDConnection::tcpReadyRead";
    QByteArray data = tcpClientSock->readAll();
    parseNewData((uint8_t*)data.data(),data.size());
}

void OHDConnection::tcpConnected() {
    qDebug() << "OHDConnection::tcpConnected";
}

void OHDConnection::tcpDisconnected() {
    qDebug() << "OHDConnection::tcpDisconnected";
    reconnectIfDisconnected();
}

void OHDConnection::udpReadyRead() {
    //qDebug() << "OHDConnection::udpReadyRead";
    QByteArray datagram;
    while (udpSocket->hasPendingDatagrams()) {
        datagram.resize(int(udpSocket->pendingDatagramSize()));
        QHostAddress _groundAddress;
        quint16 groundPort;
        udpSocket->readDatagram(datagram.data(), datagram.size(), &_groundAddress, &groundPort);
        parseNewData((uint8_t*)datagram.data(),datagram.size());
        foundSenderPort=groundPort;
        foundSenderHostAddress=_groundAddress;
        senderInfohasBeenFound=true;
        //qDebug()<<"foundSenderIp:"<<foundSenderIp<<" foundSenderPort:"<<foundSenderPort;
    }
    //QByteArray data = udpSocket->readAll();
    //parseNewData((uint8_t*)data.data(),data.size());
}

void OHDConnection::sendData(const uint8_t* data,int data_len){
    //qDebug() << "OHDConnection::sendData";
    if(USE_TCP){
        if (tcpClientSock->state() == QAbstractSocket::ConnectedState) {
            tcpClientSock->write((char*)data, data_len);
        }
    }else{
        if(!senderInfohasBeenFound){
            qDebug()<<"Cannot send data, sender ip and port unknown";
            return;
        }
        if(udpSocket==nullptr){
            qDebug()<<"Error send data udp socket null";
            return;
        }
        //udpSocket->writeDatagram((char*)data, data_len, QHostAddress(QOPENHD_GROUND_CLIENT_UDP_ADDRESS), QOPENHD_GROUND_CLIENT_UDP_PORT_OUT);
        udpSocket->writeDatagram((char*)data, data_len, foundSenderHostAddress, foundSenderPort);
    }
}

void OHDConnection::request_openhd_version()
{
    mavlink_command_long_t command;
    command.command=MAV_CMD_REQUEST_MESSAGE;
    command.param1=static_cast<float>(MAVLINK_MSG_ID_OPENHD_VERSION_MESSAGE);
    send_command_long_oneshot(command);
}

void OHDConnection::send_command_long_oneshot(const mavlink_command_long_t &command)
{
    mavlink_message_t msg;
    mavlink_msg_command_long_encode(QOpenHDMavlinkHelper::getSysId(),QOpenHDMavlinkHelper::getCompId(), &msg,&command);
    sendMessage(msg);
}


void OHDConnection::onHeartbeat(){
    //qDebug() << "OHDConnection::onHeartbeat";
    mavlink_message_t msg;
    // values from QGroundControll
    mavlink_msg_heartbeat_pack(QOpenHDMavlinkHelper::getSysId(),QOpenHDMavlinkHelper::getCompId(), &msg,MAV_TYPE_GCS,            // MAV_TYPE
                               MAV_AUTOPILOT_INVALID,   // MAV_AUTOPILOT
                               MAV_MODE_MANUAL_ARMED,   // MAV_MODE
                               0,                       // custom mode
                               MAV_STATE_ACTIVE);       // MAV_STATE
    sendMessage(msg);
}
