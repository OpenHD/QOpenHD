#include <QtNetwork>

#include "openhdrc.h"
#include "util.h"

#if defined(ENABLE_GAMEPADS)
#include <QGamepad>
#endif

#if defined(ENABLE_JOYSTICKS)
#include <QJoysticks.h>
#endif

#define BUFLEN 21
#define PORT 5565 // UDP port for OpenHD RC

struct rcdata_s {
    unsigned int chan1 : 11;
    unsigned int chan2 : 11;
    unsigned int chan3 : 11;
    unsigned int chan4 : 11;
    unsigned int chan5 : 11;
    unsigned int chan6 : 11;
    unsigned int chan7 : 11;
    unsigned int chan8 : 11;
    unsigned int Is16  : 8;
    unsigned int switches : 16;
}
#ifndef _MSC_VER
__attribute__((packed))
#endif
;
static struct rcdata_s rcdata;


OpenHDRC::OpenHDRC(QObject *parent): QObject(parent) {
    rcSocket = new QUdpSocket(this);
    rcSocket->bind(QHostAddress::Any);
#if defined (__rasp_pi__)
    rcSocket->connectToHost("127.0.0.1", PORT);
#else
    rcSocket->connectToHost("192.168.2.1", PORT);
#endif
    connect(rcSocket, &QUdpSocket::readyRead, this, &OpenHDRC::processRCDatagrams);

#if defined(ENABLE_SPEECH)
    m_speech = new QTextToSpeech(this);
#endif

    initRC();
}

void OpenHDRC::initRC() {
    qDebug() << "OpenHDRC::initRC()";

#if defined(ENABLE_GAMEPADS)
    qDebug() << "OpenHDRC: using QGamepad";
    QGamepadManager* ginstance = QGamepadManager::instance();
    QList<int> l = ginstance->connectedGamepads();
    connect(ginstance, &QGamepadManager::connectedGamepadsChanged, this, &OpenHDRC::connectedGamepadsChanged);
#endif

#if defined(ENABLE_JOYSTICKS)
    qDebug() << "OpenHDRC: using QJoysticks";
    QJoysticks* jinstance = QJoysticks::getInstance();
    connect(jinstance, &QJoysticks::countChanged, this, &OpenHDRC::connectedJoysticksChanged);
    connect(jinstance, &QJoysticks::axisChanged, this, &OpenHDRC::axisChanged);
#endif

    QTimer *timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &OpenHDRC::channelTrigger);
    timer->start(15); // about 60Hz

}

void OpenHDRC::channelTrigger() {
    emit channelUpdate(m_rc1, m_rc2, m_rc3, m_rc4, m_rc5, m_rc6, m_rc7, m_rc8, m_rc9, m_rc10);
#if defined(ENABLE_RC)
    QSettings settings;
    auto enable_rc = settings.value("enable_rc", QVariant::Int);
    if (enable_rc == 1) {
        QNetworkDatagram d;
        rcdata.chan1 = m_rc1;
        rcdata.chan2 = m_rc2;
        rcdata.chan3 = m_rc3;
        rcdata.chan4 = m_rc4;
        rcdata.chan5 = m_rc5;
        rcdata.chan6 = m_rc6;
        rcdata.chan7 = m_rc7;
        rcdata.chan8 = m_rc8;
        rcdata.Is16  = 0;
        rcdata.switches = 0;
        QByteArray rcChannels;
        rcChannels.resize(sizeof(rcdata));
        memcpy(rcChannels.data(), &rcdata, sizeof(rcdata));
        rcSocket->writeDatagram(d);
    }
#endif
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

    QJoysticks* instance = QJoysticks::getInstance();

    QList<QJoystickDevice*> l = instance->inputDevices();

    foreach(QJoystickDevice* joystick, l) {
        qDebug() << "Found joystick: " << joystick->name;
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
}

void OpenHDRC::set_rc2(uint rc2) {
    m_rc2 = rc2;
    emit rc2_changed(m_rc2);
}

void OpenHDRC::set_rc3(uint rc3) {
    m_rc3 = rc3;
    emit rc3_changed(m_rc3);
}

void OpenHDRC::set_rc4(uint rc4) {
    m_rc4 = rc4;
    emit rc4_changed(m_rc4);
}


void OpenHDRC::set_rc5(uint rc5) {
    m_rc5 = rc5;
    emit rc5_changed(m_rc5);
}

void OpenHDRC::set_rc6(uint rc6) {
    m_rc6 = rc6;
    emit rc6_changed(m_rc6);
}

void OpenHDRC::set_rc7(uint rc7) {
    m_rc7 = rc7;
    emit rc7_changed(m_rc7);
}

void OpenHDRC::set_rc8(uint rc8) {
    m_rc8 = rc8;
    emit rc8_changed(m_rc8);
}

void OpenHDRC::set_rc9(uint rc9) {
    m_rc9 = rc9;
    emit rc9_changed(m_rc9);
}

void OpenHDRC::set_rc10(uint rc10) {
    m_rc10 = rc10;
    emit rc10_changed(m_rc10);
}

void OpenHDRC::axisChanged(const int js, const int axis, const qreal value) {
    Q_UNUSED(js)
    Q_UNUSED(axis)

    qDebug() << "OpenHDRC::axisChanged()";
    qDebug() << "Axis " << axis << ": " << value;
}

void OpenHDRC::connectedChanged(bool value) {
    Q_UNUSED(value)

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
    set_rc4(map(value, -1, 1, 1000, 2000));
}

void OpenHDRC::axisLeftYChanged(double value) {
    set_rc3(map(value, -1, 1, 1000, 2000));
}

void OpenHDRC::axisRightYChanged(double value) {
    set_rc2(map(value, -1, 1, 1000, 2000));
}

void OpenHDRC::axisRightXChanged(double value) {
    set_rc1(map(value, -1, 1, 1000, 2000));
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

QObject *openHDRCSingletonProvider(QQmlEngine *engine, QJSEngine *scriptEngine) {
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    OpenHDRC *s = new OpenHDRC();
    return s;
}
