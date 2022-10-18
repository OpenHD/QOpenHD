#ifndef RC_H
#define RC_H

#include <QObject>
#include <QtQuick>
#if defined(ENABLE_SPEECH)
#include <QtTextToSpeech/QTextToSpeech>
#endif

#include "util/util.h"

#if defined(ENABLE_GAMEPADS)
#include <QGamepad>
#endif

#if defined(ENABLE_JOYSTICKS)
#include <QJoysticks.h>
#endif

class QUdpSocket;

class OpenHDRC: public QObject {
    Q_OBJECT

public:
    explicit OpenHDRC(QObject *parent = nullptr);
    static OpenHDRC& instance();

    Q_INVOKABLE void setGroundIP(QString address);


#if defined(ENABLE_GAMEPADS)
    Q_PROPERTY(int connectedGamepad MEMBER m_selectedGamepad WRITE set_selectedGamepad NOTIFY selectedGamepadChanged)
    void set_selectedGamepad(int selectedGamepad);

    Q_PROPERTY(QString selectedGamepadName MEMBER m_selectedGamepadName WRITE set_selectedGamepadName NOTIFY selectedGamepadNameChanged)
    void set_selectedGamepadName(QString selectedGamepadName);
#endif

#if defined(ENABLE_JOYSTICKS)
    Q_PROPERTY(int connectedJoystick MEMBER m_selectedJoystick WRITE set_selectedJoystick NOTIFY selectedJoystickChanged)
    void set_selectedJoystick(int selectedJoystick);

    Q_PROPERTY(QString selectedJoystickName MEMBER m_selectedJoystickName WRITE set_selectedJoystickName NOTIFY selectedJoystickNameChanged)
    void set_selectedJoystickName(QString selectedJoystickName);
#endif



    Q_PROPERTY(uint rc1 MEMBER m_rc1 WRITE set_rc1 NOTIFY rc1_changed)
    void set_rc1(uint rc1);

    Q_PROPERTY(uint rc2 MEMBER m_rc2 WRITE set_rc2 NOTIFY rc2_changed)
    void set_rc2(uint rc2);

    Q_PROPERTY(uint rc3 MEMBER m_rc3 WRITE set_rc3 NOTIFY rc3_changed)
    void set_rc3(uint rc3);

    Q_PROPERTY(uint rc4 MEMBER m_rc4 WRITE set_rc4 NOTIFY rc4_changed)
    void set_rc4(uint rc4);

    Q_PROPERTY(uint rc5 MEMBER m_rc5 WRITE set_rc5 NOTIFY rc5_changed)
    void set_rc5(uint rc5);

    Q_PROPERTY(uint rc6 MEMBER m_rc6 WRITE set_rc6 NOTIFY rc6_changed)
    void set_rc6(uint rc6);

    Q_PROPERTY(uint rc7 MEMBER m_rc7 WRITE set_rc7 NOTIFY rc7_changed)
    void set_rc7(uint rc7);

    Q_PROPERTY(uint rc8 MEMBER m_rc8 WRITE set_rc8 NOTIFY rc8_changed)
    void set_rc8(uint rc8);

    Q_PROPERTY(uint rc9 MEMBER m_rc9 WRITE set_rc9 NOTIFY rc9_changed)
    void set_rc9(uint rc9);

    Q_PROPERTY(uint rc10 MEMBER m_rc10 WRITE set_rc10 NOTIFY rc10_changed)
    void set_rc10(uint rc10);

    Q_PROPERTY(uint rc11 MEMBER m_rc11 WRITE set_rc11 NOTIFY rc11_changed)
    void set_rc11(uint rc11);

    Q_PROPERTY(uint rc12 MEMBER m_rc12 WRITE set_rc12 NOTIFY rc12_changed)
    void set_rc12(uint rc12);

    Q_PROPERTY(uint rc13 MEMBER m_rc13 WRITE set_rc13 NOTIFY rc13_changed)
    void set_rc13(uint rc13);

    Q_PROPERTY(uint rc14 MEMBER m_rc14 WRITE set_rc14 NOTIFY rc14_changed)
    void set_rc14(uint rc14);

    Q_PROPERTY(uint rc15 MEMBER m_rc15 WRITE set_rc15 NOTIFY rc15_changed)
    void set_rc15(uint rc15);

    Q_PROPERTY(uint rc16 MEMBER m_rc16 WRITE set_rc16 NOTIFY rc16_changed)
    void set_rc16(uint rc16);

    Q_PROPERTY(uint rc17 MEMBER m_rc17 WRITE set_rc17 NOTIFY rc17_changed)
    void set_rc17(uint rc17);

    Q_PROPERTY(uint rc18 MEMBER m_rc18 WRITE set_rc18 NOTIFY rc18_changed)
    void set_rc18(uint rc18);
signals:
    void channelUpdate(uint rc1,
                       uint rc2,
                       uint rc3,
                       uint rc4,
                       uint rc5,
                       uint rc6,
                       uint rc7,
                       uint rc8,
                       uint rc9,
                       uint rc10,
                       uint rc11,
                       uint rc12,
                       uint rc13,
                       uint rc14,
                       uint rc15,
                       uint rc16,
                       uint rc17,
                       uint rc18);

    void rc1_changed(uint rc1);
    void rc2_changed(uint rc2);
    void rc3_changed(uint rc3);
    void rc4_changed(uint rc4);
    void rc5_changed(uint rc5);
    void rc6_changed(uint rc6);
    void rc7_changed(uint rc7);
    void rc8_changed(uint rc8);
    void rc9_changed(uint rc9);
    void rc10_changed(uint rc10);
    void rc11_changed(uint rc11);
    void rc12_changed(uint rc12);
    void rc13_changed(uint rc13);
    void rc14_changed(uint rc14);
    void rc15_changed(uint rc15);
    void rc16_changed(uint rc16);
    void rc17_changed(uint rc17);
    void rc18_changed(uint rc18);

#if defined(ENABLE_GAMEPADS)
    void selectedGamepadChanged(int selectedGamepad);
    void selectedGamepadNameChanged(QString selectedGamepadName);
#endif

#if defined(ENABLE_JOYSTICKS)
    void selectedJoystickChanged(int selectedJoystick);
    void selectedJoystickNameChanged(QString selectedJoystickName);
    void set_Joystick_Present(bool joystick_present);
#endif


private slots:
    void channelTrigger();
#if defined(ENABLE_GAMEPADS)
    void connectedGamepadsChanged();
    void nameChanged(QString name);
#endif

#if defined(ENABLE_JOYSTICKS)
    void connectedJoysticksChanged();
#endif
    void processRCDatagrams();

    void axisChanged (const int js, const int axis, const qreal value);

    void connectedChanged(bool value);
    void axisLeftXChanged(double value);
    void axisLeftYChanged(double value);
    void axisRightXChanged(double value);
    void axisRightYChanged(double value);
    void buttonAChanged(bool value);
    void buttonBChanged(bool value);
    void buttonXChanged(bool value);
    void buttonYChanged(bool value);
    void buttonL1Changed(bool value);
    void buttonR1Changed(bool value);
    void buttonL2Changed(double value);
    void buttonR2Changed(double value);
    void buttonSelectChanged(bool value);
    void buttonStartChanged(bool value);
    void buttonL3Changed(bool value);
    void buttonR3Changed(bool value);
    void buttonUpChanged(bool value);
    void buttonDownChanged(bool value);
    void buttonLeftChanged(bool value);
    void buttonRightChanged(bool value);
    void buttonCenterChanged(bool value);
    void buttonGuideChanged(bool value);

private:
    QUdpSocket *rcSocket = nullptr;

    QString groundAddress;

#if defined(ENABLE_GAMEPADS)
    QList<int> m_connectedGamepads;
    int m_selectedGamepad = -1;
    QGamepad *currentGamepad = nullptr;
    QString m_selectedGamepadName;
#endif


#if defined(ENABLE_JOYSTICKS)
    QList<int> m_connectedJoysticks;
    int m_selectedJoystick = -1;
    QJoystickDevice *currentJoystick = nullptr;
    QString m_selectedJoystickName;
    bool m_joystick_present = false;
#endif

#if defined(ENABLE_SPEECH)
    QTextToSpeech *m_speech;
#endif

    uint8_t  seqno = 0;

    uint m_rc1 = 1500;
    uint m_rc2 = 1500;
    uint m_rc3 = 1500;
    uint m_rc4 = 1500;
    uint m_rc5 = 1500;
    uint m_rc6 = 1500;
    uint m_rc7 = 1500;
    uint m_rc8 = 1500;
    uint m_rc9 = 1500;
    uint m_rc10 = 1500;
    uint m_rc11 = 1500;
    uint m_rc12 = 1500;
    uint m_rc13 = 1500;
    uint m_rc14 = 1500;
    uint m_rc15 = 1500;
    uint m_rc16 = 1500;
    uint m_rc17 = 1500;
    uint m_rc18 = 1500;

};

#endif //RC_H
