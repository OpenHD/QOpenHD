import QtQuick 2.12

PillSlider{
    id: slider
    // Needs to be overridden
    property string flight_mode_text: "TODO"

    m_pill_description: flight_mode_text

    visible: false

    property string m_ardupilot_mav_type: _fcMavlinkAction.ardupilot_mav_type

    onM_ardupilot_mav_typeChanged: {
        //console.log("onM_ardupilot_mav_typeChanged");
        var valid = _fcMavlinkAction.has_mapping(flight_mode_text);
        slider.visible = valid;
    }

    Timer {
        id: selectionResetTimer
        running: false
        interval: 5000
        repeat: false
        onTriggered: {
           slider.reset_to_dragable()
        }
    }

    onDraggedRight : {
        console.log("FM slider onDraggedRight");
        _fcMavlinkAction.flight_mode_cmd_async_string(flight_mode_text)
        selectionResetTimer.start()
        flightModeWidget.bw_manually_close_action_popup()
    }

}
