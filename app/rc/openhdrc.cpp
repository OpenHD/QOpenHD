#include "openhdrc.h"

#include <QtNetwork>

#include "util/util.h"

#if defined(ENABLE_GAMEPADS)
#include <QGamepad>
#endif

#if defined(ENABLE_JOYSTICKS)
#include <QJoysticks.h>
#endif

#include "telemetry/mavlinktelemetry.h"

#define BUFLEN 21
#define PORT 5565 // UDP port for OpenHD RC


OpenHDRC::OpenHDRC(QObject *parent): QObject(parent) {

    #if defined(__rasp_pi__)
    groundAddress = "127.0.0.1";
    #endif

    rcSocket = new QUdpSocket(this);
    rcSocket->bind(QHostAddress::Any);

    connect(rcSocket, &QUdpSocket::readyRead, this, &OpenHDRC::processRCDatagrams);

#if defined(ENABLE_SPEECH)
    m_speech = new QTextToSpeech(this);
#endif


#if defined(ENABLE_GAMEPADS)
    qDebug() << "OpenHDRC: using QGamepad";
    QGamepadManager* ginstance = QGamepadManager::instance();
    QList<int> l = ginstance->connectedGamepads();
    connect(ginstance, &QGamepadManager::connectedGamepadsChanged, this, &OpenHDRC::connectedGamepadsChanged);
#endif

#if defined(ENABLE_JOYSTICKS)
    qDebug() << "OpenHDRC: using QJoysticks";
    QJoysticks* jinstance = QJoysticks::getInstance();
   //THIS IS ENABLED BELOW FOR TESTING
   //TODO TURN OFF VIRTUAL JOYSTICK FOR RELEASE!!
    jinstance->setVirtualJoystickRange(1);
    jinstance->setVirtualJoystickEnabled(false);
    //jinstance->setVirtualJoystickAxisSensibility(0.7) - from newer version

    connect(jinstance, &QJoysticks::countChanged, this, &OpenHDRC::connectedJoysticksChanged);
    connect(jinstance, &QJoysticks::axisChanged, this, &OpenHDRC::axisChanged);

    auto mavlink = MavlinkTelemetry::instance();
    connect(this, &OpenHDRC::rc1_changed, mavlink, &MavlinkTelemetry::rc1_changed);
    connect(this, &OpenHDRC::rc2_changed, mavlink, &MavlinkTelemetry::rc2_changed);
    connect(this, &OpenHDRC::rc3_changed, mavlink, &MavlinkTelemetry::rc3_changed);
    connect(this, &OpenHDRC::rc4_changed, mavlink, &MavlinkTelemetry::rc4_changed);
    connect(this, &OpenHDRC::rc5_changed, mavlink, &MavlinkTelemetry::rc5_changed);
    connect(this, &OpenHDRC::rc6_changed, mavlink, &MavlinkTelemetry::rc6_changed);
    connect(this, &OpenHDRC::rc7_changed, mavlink, &MavlinkTelemetry::rc7_changed);
    connect(this, &OpenHDRC::rc8_changed, mavlink, &MavlinkTelemetry::rc8_changed);
    connect(this, &OpenHDRC::rc9_changed, mavlink, &MavlinkTelemetry::rc9_changed);
    connect(this, &OpenHDRC::rc10_changed, mavlink, &MavlinkTelemetry::rc10_changed);
    connect(this, &OpenHDRC::rc11_changed, mavlink, &MavlinkTelemetry::rc11_changed);
    connect(this, &OpenHDRC::rc12_changed, mavlink, &MavlinkTelemetry::rc12_changed);
    connect(this, &OpenHDRC::rc13_changed, mavlink, &MavlinkTelemetry::rc13_changed);
    connect(this, &OpenHDRC::rc14_changed, mavlink, &MavlinkTelemetry::rc14_changed);
    connect(this, &OpenHDRC::rc15_changed, mavlink, &MavlinkTelemetry::rc15_changed);
    connect(this, &OpenHDRC::rc16_changed, mavlink, &MavlinkTelemetry::rc16_changed);
    connect(this, &OpenHDRC::rc17_changed, mavlink, &MavlinkTelemetry::rc17_changed);
    connect(this, &OpenHDRC::rc18_changed, mavlink, &MavlinkTelemetry::rc18_changed);

    connect(this, &OpenHDRC::set_Joystick_Present, mavlink, &MavlinkBase::joystick_Present_Changed);
#endif

    QTimer *timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &OpenHDRC::channelTrigger);
    timer->start(15); // about 60Hz

}


void OpenHDRC::setGroundIP(QString address) {
    groundAddress = address;
}


void OpenHDRC::channelTrigger() {
    emit channelUpdate(m_rc1, m_rc2, m_rc3, m_rc4, m_rc5, m_rc6, m_rc7, m_rc8, m_rc9, m_rc10
                       ,m_rc11,m_rc12,m_rc13,m_rc14,m_rc15,m_rc16,m_rc17,m_rc18);
/*this is Stuff Stephen wrote and interferes
#if defined(ENABLE_RC)
    QSettings settings;
    auto enable_rc = settings.value("enable_rc", false).toBool();

    if (enable_rc) {
        QByteArray rcChannels(BUFLEN, 0);

        rcChannels[0] = m_rc1 & 0xFF;
        rcChannels[1] = (m_rc1 >> 8) & 0xFF;

        rcChannels[2] = m_rc2 & 0xFF;
        rcChannels[3] = (m_rc2 >> 8) & 0xFF;

        rcChannels[4] = m_rc3 & 0xFF;
        rcChannels[5] = (m_rc3 >> 8) & 0xFF;

        rcChannels[6] = m_rc4 & 0xFF;
        rcChannels[7] = (m_rc4 >> 8) & 0xFF;

        rcChannels[8] = m_rc5 & 0xFF;
        rcChannels[9] = (m_rc5 >> 8) & 0xFF;

        rcChannels[10] = m_rc6 & 0xFF;
        rcChannels[11] = (m_rc6 >> 8) & 0xFF;

        rcChannels[12] = m_rc7 & 0xFF;
        rcChannels[13] = (m_rc7 >> 8) & 0xFF;

        rcChannels[14] = m_rc8 & 0xFF;
        rcChannels[15] = (m_rc8 >> 8) & 0xFF;

        rcChannels[16] = seqno;
        rcChannels[17] = 0;

        // is16
        rcChannels[18] = 0;

        // these would be the buttons, disabled for now.
        rcChannels[19] = 1;
        rcChannels[20] = 1;

        rcSocket->writeDatagram(rcChannels, rcChannels.length(), QHostAddress(groundAddress), PORT);

        seqno++;
    }
#endif
*/
}

void OpenHDRC::processRCDatagrams() {
    // no return data necessary from UDP socket
}

#if defined(ENABLE_GAMEPADS)
void OpenHDRC::connectedGamepadsChanged() {
    qDebug() << "OpenHDRC::connectedGamepadsChanged()";

    QGamepadManager* instance = QGamepadManager::instance();
    QList<int> l = instance->connectedGamepads();
    foreach(int gamepad, l) {
        set_selectedGamepad(gamepad);
    }
}

void OpenHDRC::set_selectedGamepadName(QString selectedGamepadName) {
    m_selectedGamepadName = selectedGamepadName;
    emit selectedGamepadNameChanged(m_selectedGamepadName);
}

void OpenHDRC::set_selectedGamepad(int selectedGamepad) {

    if (currentGamepad != nullptr) {
        delete currentGamepad;
    }
    currentGamepad = new QGamepad(selectedGamepad);
    auto currentGamepadName = currentGamepad->name();
    set_selectedGamepadName(currentGamepadName);
    qDebug() << "Found gamepad: " << currentGamepad->name();
    qDebug() << "Connected: " << currentGamepad->isConnected();


    connect(currentGamepad, &QGamepad::axisLeftXChanged, this, &OpenHDRC::axisLeftXChanged);
    connect(currentGamepad, &QGamepad::axisRightXChanged, this, &OpenHDRC::axisRightXChanged);
    connect(currentGamepad, &QGamepad::axisLeftYChanged, this, &OpenHDRC::axisLeftYChanged);
    connect(currentGamepad, &QGamepad::axisRightYChanged, this, &OpenHDRC::axisRightYChanged);
    connect(currentGamepad, &QGamepad::buttonAChanged, this, &OpenHDRC::buttonAChanged);
    connect(currentGamepad, &QGamepad::buttonBChanged, this, &OpenHDRC::buttonBChanged);
    connect(currentGamepad, &QGamepad::buttonXChanged, this, &OpenHDRC::buttonXChanged);
    connect(currentGamepad, &QGamepad::buttonYChanged, this, &OpenHDRC::buttonYChanged);
    connect(currentGamepad, &QGamepad::buttonL1Changed, this, &OpenHDRC::buttonL1Changed);
    connect(currentGamepad, &QGamepad::buttonR1Changed, this, &OpenHDRC::buttonR1Changed);
    connect(currentGamepad, &QGamepad::buttonL2Changed, this, &OpenHDRC::buttonL2Changed);
    connect(currentGamepad, &QGamepad::buttonR2Changed, this, &OpenHDRC::buttonR2Changed);
    connect(currentGamepad, &QGamepad::buttonSelectChanged, this, &OpenHDRC::buttonSelectChanged);
    connect(currentGamepad, &QGamepad::buttonStartChanged, this, &OpenHDRC::buttonStartChanged);
    connect(currentGamepad, &QGamepad::buttonL3Changed, this, &OpenHDRC::buttonL3Changed);
    connect(currentGamepad, &QGamepad::buttonR3Changed, this, &OpenHDRC::buttonR3Changed);
    connect(currentGamepad, &QGamepad::buttonUpChanged, this, &OpenHDRC::buttonUpChanged);
    connect(currentGamepad, &QGamepad::buttonDownChanged, this, &OpenHDRC::buttonDownChanged);
    connect(currentGamepad, &QGamepad::buttonLeftChanged, this, &OpenHDRC::buttonLeftChanged);
    connect(currentGamepad, &QGamepad::buttonRightChanged, this, &OpenHDRC::buttonRightChanged);
    connect(currentGamepad, &QGamepad::buttonCenterChanged, this, &OpenHDRC::buttonCenterChanged);
    connect(currentGamepad, &QGamepad::buttonGuideChanged, this, &OpenHDRC::buttonGuideChanged);
    connect(currentGamepad, &QGamepad::nameChanged, this, &OpenHDRC::nameChanged);
    connect(currentGamepad, &QGamepad::connectedChanged, this, &OpenHDRC::connectedChanged);

    m_selectedGamepad = selectedGamepad;
    emit selectedGamepadChanged(m_selectedGamepad);
}

void OpenHDRC::nameChanged(QString name) {
    qDebug() << "Name: " << name;
    set_selectedGamepadName(name);
}

#endif



#if defined(ENABLE_JOYSTICKS)
void OpenHDRC::connectedJoysticksChanged() {
    qDebug() << "OpenHDRC::connectedJoysticksChanged()";

    auto joystick_count=0;

    QJoysticks* instance = QJoysticks::getInstance();

    QList<QJoystickDevice*> l = instance->inputDevices();

    foreach(QJoystickDevice* joystick, l) {
        qDebug() << "Found joystick: " << joystick->name;

        joystick_count=joystick_count+1;
    }
    if (joystick_count == 0){
        qDebug() << "OpenHDRC::connectedJoysticksChanged() NO JOYSTICKS FOUND!";
        m_joystick_present=false;
        emit set_Joystick_Present(m_joystick_present);

    }
    else {
        qDebug() << "OpenHDRC::connectedJoysticksChanged() At least 1 Joystick present!";
        m_joystick_present=true;
        emit set_Joystick_Present(m_joystick_present);
    }
}

void OpenHDRC::set_selectedJoystickName(QString selectedJoystickName) {
    m_selectedJoystickName = selectedJoystickName;
    emit selectedJoystickNameChanged(m_selectedJoystickName);
}
void OpenHDRC::set_selectedJoystick(int selectedJoystick) {
    m_selectedJoystick = selectedJoystick;
    emit selectedJoystickChanged(m_selectedJoystick);
}
#endif

void OpenHDRC::set_rc1(uint rc1) {
    m_rc1 = rc1;
    emit rc1_changed(m_rc1);
    qDebug() << "Openhdrc::rc1=" << m_rc1;
}

void OpenHDRC::set_rc2(uint rc2) {
    m_rc2 = rc2;
    emit rc2_changed(m_rc2);
    qDebug() << "Openhdrc::rc2=" << m_rc2;
}

void OpenHDRC::set_rc3(uint rc3) {
    m_rc3 = rc3;
    emit rc3_changed(m_rc3);
    qDebug() << "Openhdrc::rc3=" << m_rc3;
}

void OpenHDRC::set_rc4(uint rc4) {
    m_rc4 = rc4;
    emit rc4_changed(m_rc4);
    qDebug() << "Openhdrc::rc4=" << m_rc4;
}


void OpenHDRC::set_rc5(uint rc5) {
    m_rc5 = rc5;
    emit rc5_changed(m_rc5);
    qDebug() << "Openhdrc::rc5=" << m_rc5;
}

void OpenHDRC::set_rc6(uint rc6) {
    m_rc6 = rc6;
    emit rc6_changed(m_rc6);
    qDebug() << "Openhdrc::rc6=" << m_rc6;
}

void OpenHDRC::set_rc7(uint rc7) {
    m_rc7 = rc7;
    emit rc7_changed(m_rc7);
    qDebug() << "Openhdrc::rc7=" << m_rc7;
}

void OpenHDRC::set_rc8(uint rc8) {
    m_rc8 = rc8;
    emit rc8_changed(m_rc8);
    qDebug() << "Openhdrc::rc8=" << m_rc8;
}

void OpenHDRC::set_rc9(uint rc9) {
    m_rc9 = rc9;
    emit rc9_changed(m_rc9);
    qDebug() << "Openhdrc::rc9=" << m_rc9;
}

void OpenHDRC::set_rc10(uint rc10) {
    m_rc10 = rc10;
    emit rc10_changed(m_rc10);
    qDebug() << "Openhdrc::rc10=" << m_rc10;
}

void OpenHDRC::set_rc11(uint rc11) {
    m_rc11 = rc11;
    emit rc11_changed(m_rc11);
    qDebug() << "Openhdrc::rc11=" << m_rc11;
}

void OpenHDRC::set_rc12(uint rc12) {
    m_rc12 = rc12;
    emit rc12_changed(m_rc12);
    qDebug() << "Openhdrc::rc12=" << m_rc12;
}

void OpenHDRC::set_rc13(uint rc13) {
    m_rc13 = rc13;
    emit rc13_changed(m_rc13);
    qDebug() << "Openhdrc::rc13=" << m_rc13;
}

void OpenHDRC::set_rc14(uint rc14) {
    m_rc14 = rc14;
    emit rc14_changed(m_rc14);
    qDebug() << "Openhdrc::rc14=" << m_rc14;
}

void OpenHDRC::set_rc15(uint rc15) {
    m_rc15 = rc15;
    emit rc15_changed(m_rc15);
    qDebug() << "Openhdrc::rc15=" << m_rc15;
}

void OpenHDRC::set_rc16(uint rc16) {
    m_rc16 = rc16;
    emit rc16_changed(m_rc16);
    qDebug() << "Openhdrc::rc16=" << m_rc16;
}

void OpenHDRC::set_rc17(uint rc17) {
    m_rc17 = rc17;
    emit rc17_changed(m_rc17);
    qDebug() << "Openhdrc::rc17=" << m_rc17;
}

void OpenHDRC::set_rc18(uint rc18) {
    m_rc18 = rc18;
    emit rc18_changed(m_rc18);
    qDebug() << "Openhdrc::rc18=" << m_rc18;
}

void OpenHDRC::axisChanged(const int js, const int axis, const qreal value) {
    Q_UNUSED(js)
    Q_UNUSED(axis)

    //qDebug() << "OpenHDRC::axisChanged()";
    switch (axis) {
        case 0:
        set_rc1(m_util.map(value, -1, 1, 1000, 2000));
        break;

        case 1:
        set_rc2(m_util.map(value, -1, 1, 1000, 2000));
        break;

        case 2:
        set_rc3(m_util.map(value, -1, 1, 1000, 2000));
        break;

        case 3:
        set_rc4(m_util.map(value, -1, 1, 1000, 2000));
        break;

        case 4:
        set_rc5(m_util.map(value, -1, 1, 1000, 2000));
        break;

        case 5:
        set_rc6(m_util.map(value, -1, 1, 1000, 2000));
        break;

        case 6:
        set_rc7(m_util.map(value, -1, 1, 1000, 2000));
        break;

        case 7:
        set_rc8(m_util.map(value, -1, 1, 1000, 2000));
        break;

        case 8:
        set_rc9(m_util.map(value, -1, 1, 1000, 2000));
        break;

        case 9:
        set_rc10(m_util.map(value, -1, 1, 1000, 2000));
        break;

        default:
        break;
    }

    qDebug() << "Axis " << axis << ": " << value;
}

void OpenHDRC::connectedChanged(bool value) {
    Q_UNUSED(value)

    qDebug() << "Joystick Connection Changed ";

    QSettings settings;

#if defined(ENABLE_SPEECH)
    auto enable_speech = settings.value("enable_speech", QVariant(0));
    if (value && enable_speech == 1) {
        m_speech->say("Game pad connected");
    } else if (enable_speech == 1) {
        m_speech->say("Game pad disconnected");
    }
#endif
}

/* RC channel slots arranged in channel order */

void OpenHDRC::axisLeftXChanged(double value) {
    set_rc4(m_util.map(value, -1, 1, 1000, 2000));
}

void OpenHDRC::axisLeftYChanged(double value) {
    set_rc3(m_util.map(value, -1, 1, 1000, 2000));
}

void OpenHDRC::axisRightYChanged(double value) {
    set_rc2(m_util.map(value, -1, 1, 1000, 2000));
}

void OpenHDRC::axisRightXChanged(double value) {
    set_rc1(m_util.map(value, -1, 1, 1000, 2000));
}

void OpenHDRC::buttonAChanged(bool value) {
    Q_UNUSED(value)
}

void OpenHDRC::buttonBChanged(bool value) {
    Q_UNUSED(value)
}

void OpenHDRC::buttonXChanged(bool value) {
    Q_UNUSED(value)
}

void OpenHDRC::buttonYChanged(bool value) {
    Q_UNUSED(value)
}

void OpenHDRC::buttonL1Changed(bool value) {
    Q_UNUSED(value)
}

void OpenHDRC::buttonR1Changed(bool value) {
    Q_UNUSED(value)
}

void OpenHDRC::buttonL2Changed(double value) {
    Q_UNUSED(value)
}

void OpenHDRC::buttonR2Changed(double value) {
    Q_UNUSED(value)
}

void OpenHDRC::buttonSelectChanged(bool value) {
    Q_UNUSED(value)
}

void OpenHDRC::buttonStartChanged(bool value) {
    Q_UNUSED(value)
}

void OpenHDRC::buttonL3Changed(bool value) {
    Q_UNUSED(value)
}

void OpenHDRC::buttonR3Changed(bool value) {
    Q_UNUSED(value)
}

void OpenHDRC::buttonUpChanged(bool value) {
    Q_UNUSED(value)
}

void OpenHDRC::buttonDownChanged(bool value) {
    Q_UNUSED(value)
}

void OpenHDRC::buttonLeftChanged(bool value) {
    Q_UNUSED(value)
}

void OpenHDRC::buttonRightChanged(bool value) {
    Q_UNUSED(value)
}

void OpenHDRC::buttonCenterChanged(bool value) {
    Q_UNUSED(value)
}

void OpenHDRC::buttonGuideChanged(bool value) {
    Q_UNUSED(value)

}
