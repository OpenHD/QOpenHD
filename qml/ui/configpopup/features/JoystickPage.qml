import QtQuick 2.12
import ".."

AdvancedPage {
    initialFocusItem: mapping
    onBackRequested: settings_form.side_bar_regain_focus()

    JoystickSettingsPanel {
        id: mapping
        anchors.fill: parent
    }
}
