import QtQuick 2.12

Item{
    width: 180
    height: 32

    PillSlider{
        id: slider_arm
        m_pill_description: "ARM"
        visible: !_fcMavlinkSystem.armed

        Timer {
            id: selectionResetTimer
            running: false
            interval: 3000
            repeat: false
            onTriggered: {
               slider_arm.reset_to_dragable()
            }
        }

        onDraggedRight : {
            _fcMavlinkAction.arm_fc_async(true);
            selectionResetTimer.start()
        }
    }

    PillSlider{
        id: slider_disarm
        m_pill_description: "DISARM"
        visible: _fcMavlinkSystem.armed

        Timer {
            id: selectionResetTimer2
            running: false
            interval: 3000
            repeat: false
            onTriggered: {
               slider_disarm.reset_to_dragable()
            }
        }

        onDraggedRight : {
            _fcMavlinkAction.arm_fc_async(false);
            selectionResetTimer2.start()
        }
    }

}


