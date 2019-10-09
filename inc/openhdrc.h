#ifndef RC_H
#define RC_H

#include <QObject>
#include <QtQuick>
#if defined(ENABLE_SPEECH)
#include <QtTextToSpeech/QTextToSpeech>
#endif

#if defined(ENABLE_GAMEPADS)
#include <QGamepad>
#endif

#if defined(ENABLE_JOYSTICKS)
#include <QJoysticks.h>
#endif

#include <unistd.h>

class QUdpSocket;

class OpenHDRC: public QObject {
    Q_OBJECT

public:
    explicit OpenHDRC(QObject *parent = nullptr);

    void initRC();

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
                       uint rc10);

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

#if defined(ENABLE_GAMEPADS)
    void selectedGamepadChanged(int selectedGamepad);
    void selectedGamepadNameChanged(QString selectedGamepadName);
#endif

#if defined(ENABLE_JOYSTICKS)
    void selectedJoystickChanged(int selectedJoystick);
    void selectedJoystickNameChanged(QString selectedJoystickName);
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
#endif

#if defined(ENABLE_SPEECH)
    QTextToSpeech *m_speech;
#endif

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

};

QObject *openHDRCSingletonProvider(QQmlEngine *engine, QJSEngine *scriptEngine);

#endif //RC_H
